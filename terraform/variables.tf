variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "project_number" {
  description = "Google Cloud Project Number"
  type        = string
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west2"
}
