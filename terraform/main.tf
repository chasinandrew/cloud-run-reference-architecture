module "frontend_cloud_run" {
  source  = "./modules/cloud-run"
  # Required variables
  service_name           = "frontend"
  project_id             = var.project_id
  location               = var.region
  image                  = var.frontend_container_image
  service_account_email = google_service_account.frontend_service_account.email
  env_vars = [
    {
    name = "EDITOR_UPSTREAM_RENDERER_URL"
    value = ""#module.backend_cloud_run.service_url
    }
  ]
  depends_on = [
    module.backend_cloud_run
  ]
}


module "backend_cloud_run" {
  source  = "./modules/cloud-run"
  # Required variables
  service_name           = "backend"
  project_id             = var.project_id
  location               = var.region
  image                  = var.backend_container_image
  service_account_email = google_service_account.backend_service_account.email
}

resource "google_tags_location_tag_binding" "binding" {
    parent = "//run.googleapis.com/projects/823495727548/locations/${var.region}/services/frontend"
    tag_value = "tagValues/1067211650924"
    location = var.region
}

resource "google_service_account" "frontend_service_account" {
  account_id   = "frontend-sa"
  display_name = "Frontend Service Account"
  project = var.project_id
}

resource "google_cloud_run_service_iam_member" "frontend_invokes_backend" {
  location = var.region
  service  = "backend"
  role     = "roles/run.invoker"
  member   = google_service_account.frontend_service_account.member
  project = var.project_id
}


data "google_iam_policy" "noauth" {
  provider = google-beta
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = var.region
  project  = var.project_id
  service  = "frontend"
  policy_data = data.google_iam_policy.noauth.policy_data
}
 
resource "google_service_account" "backend_service_account" {
  account_id   = "backend-sa"
  display_name = "Backend Service Account"
  project = var.project_id
}


module "mssql" {
  source = "./modules/mssql"
  project_id = var.project_id
  name = "mssql"
  region = var.region
  zone = "us-east4-a"
}

#   provisioner "local-exec" {
#     working_dir = "${path.module}/../code/database"
#     command     = "./load_schema.sh ${var.project_id} ${google_sql_database_instance.main.name}"
#   }
# }
