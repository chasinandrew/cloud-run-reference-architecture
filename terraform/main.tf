module "frontend_cloud_run" {
  source  = "./modules/cloud-run"
  # Required variables
  service_name           = var.frontend_service_name
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
  service_name           = var.backend_service_name
  project_id             = var.project_id
  location               = var.region
  image                  = var.backend_container_image
  service_account_email = google_service_account.backend_service_account.email
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_tags_tag_key" "key" {
    parent = "projects/${data.google_project.project.number}"
    short_name = "allUseringress"
    description = "For creating a public Cloud Run instance."
}

resource "google_tags_tag_value" "value" {
    parent = "tagKeys/${google_tags_tag_key.key.name}"
    short_name = "true"
    description = "Allow IAM to be set for allUsers."
}

resource "google_tags_location_tag_binding" "binding" {
    parent = "//run.googleapis.com/projects/${data.google_project.project.number}/locations/${var.region}/services/${var.frontend_service_name}"
    tag_value = "tagValues/${google_tags_tag_value.value.name}"
    location = var.region
    depends_on = [
      google_tags_tag_value_iam_member.binding
    ]
}

resource "google_tags_tag_value_iam_member" "binding" {
    role = "roles/resourcemanager.tagUser"
    tag_value = "tagValues/${google_tags_tag_value.value.name}"
    member = "serviceAccount:terraform@arched-inkwell-368821.iam.gserviceaccount.com"
}

resource "google_service_account" "frontend_service_account" {
  account_id   = "frontend-sa"
  display_name = "Frontend Service Account"
  project = var.project_id
}

resource "google_cloud_run_service_iam_member" "frontend_invokes_backend" {
  location = var.region
  service  = var.backend_service_name
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
  service  = var.frontend_service_name
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
#