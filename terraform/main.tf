# Telling Terraform to use Google Cloud APIs
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Using a variable (project_id) so we don’t hardcode it
provider "google" {
  project = var.project_id
}

# Define the Workload Identity Pool Once
# This creates the Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github"
  display_name             = "GitHub Actions Pool"
}


# Add an Identity Provider for All Repos
# Creates an OIDC Identity Provider that trusts all repos in your GitHub Org.
# Uses GitHub's OIDC provider (https://token.actions.githubusercontent.com).
# Only allows requests from your GitHub Org (assertion.repository_owner).
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Identity Provider"
  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.actor"         = "assertion.actor"
    "attribute.repository"    = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }
  attribute_condition = "assertion.repository_owner == \"hanzalahsuriya\""
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create a Service Account for GitHub Actions
# Creates a service account github-actions, which GitHub repos will use to interact with GCP.
resource "google_service_account" "github_sa" {
  account_id   = "github-actions"
  display_name = "GitHub Actions Service Account"
}

# Allow GitHub Actions to Use the Service Account
# Now we let any repo in your GitHub Org authenticate as this service account.
resource "google_service_account_iam_binding" "github_sa_binding" {
  service_account_id = google_service_account.github_sa.id
  role               = "roles/iam.workloadIdentityUser"
  members           = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository_owner/hanzalahsuriya"
  ]
}

# Grants GitHub Actions permission to push Docker images to Google Artifact Registry.
resource "google_project_iam_binding" "github_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  members = [
    "serviceAccount:${google_service_account.github_sa.email}"
  ]
}