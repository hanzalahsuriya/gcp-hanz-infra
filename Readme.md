Create a Workload Identity Pool:
# TODO: replace ${PROJECT_ID} with your value below.
gcloud iam workload-identity-pools create "github" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

----------------------------------------------------------------
 Get the full ID of the Workload Identity Pool:
# TODO: replace ${PROJECT_ID} with your value below.
gcloud iam workload-identity-pools describe "github" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)"

 This value should be of the format:
e.g. projects/123456789/locations/global/workloadIdentityPools/github



----------------------------------------------------------------
Create a Workload Identity Provider in that pool:
CAUTION! Always add an Attribute Condition to restrict entry into the Workload Identity Pool. You can further restrict access in IAM Bindings, but always add a basic condition that restricts admission into the pool. A good default option is to restrict admission based on your GitHub organization as demonstrated below. Please see the security considerations for more details.
https://github.com/google-github-actions/auth/blob/main/docs/SECURITY_CONSIDERATIONS.md
# TODO: replace ${PROJECT_ID} and ${GITHUB_ORG} with your values below.

gcloud iam workload-identity-pools providers create-oidc "my-repo" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github" \
  --display-name="My GitHub repo Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"



----------------------------------------------------------------
Extract the Workload Identity Provider resource name:

# TODO: replace ${PROJECT_ID} with your value below.

gcloud iam workload-identity-pools providers describe "my-repo" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github" \
  --format="value(name)"

  ----------------------------------------------------------------







    As needed, allow authentications from the Workload Identity Pool to Google Cloud resources. These can be any Google Cloud resources that support federated ID tokens, and it can be done after the GitHub Action is configured.

The following example shows granting access from a GitHub Action in a specific repository a secret in Google Secret Manager.

# TODO: replace ${PROJECT_ID}, ${WORKLOAD_IDENTITY_POOL_ID}, and ${REPO}
# with your values below.
#
# ${REPO} is the full repo name including the parent GitHub organization,
# such as "my-org/my-repo".
#
# ${WORKLOAD_IDENTITY_POOL_ID} is the full pool id, such as
# "projects/123456789/locations/global/workloadIdentityPools/github".

gcloud secrets add-iam-policy-binding "my-secret" \
  --project="${PROJECT_ID}" \
  --role="roles/secretmanager.secretAccessor" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"
