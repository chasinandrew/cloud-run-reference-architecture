
# module "gh_oidc" { 
#     source = "./modules/wif"
#     project_id = var.project_id
#     pool_id = "oidc-pool-gh"
#     provider_id = "oidc-provider-gh"
#     issuer_uri = "https://token.actions.githubusercontent.com"
#     sa_mapping = {
#       "gh-oidc" = {
#         attribute = "attribute.repository/user/repo"
#         sa_name = google_service_account.gh_oidc.id
#       }
#     }
#     attribute_mapping = {
#         "google.subject" = "assertion.repository"
#     }
#     attribute_condition = "google.subject.contains(\"chasinandrew/cloud-run-reference-architecture\")"
#     depends_on = [
#       google_service_account.gh_oidc
#     ]
# }

resource "google_service_account" "gh_oidc" {
    account_id = "gh-oidc-wif"
    display_name = "Service Account for authenticating from GitHub to GCP to push container images."
}

# # resource "random_id" "repo_suffix" {
# #     byte_length = 3
# # }

# # resource "google_artifact_registry_repository" "docker_repo" { 
# #     project = var.project_id
# #     repository_id = format("%s-%s" ,var.project_id, random_id.repo_suffix.hex)
# #     format = "DOCKER"
# # }