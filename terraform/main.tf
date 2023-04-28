module "frontend_cloud_run" {
  source  = "./modules/cloud-run"
  # Required variables
  service_name           = "frontend"
  project_id             = var.project_id
  location               = var.region
  image                  = var.frontend_container_image
  service_account_email = google_service_account.frontend_service_account.email
  env_vars = [
    name = "EDITOR_UPSTREAM_RENDERER_URL"
    value = module.backend_cloud_run.service_url
  ]
  depends_on = [
    module.backend_cloud_run
  ]
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

module "backend_cloud_run" {
  source  = "./modules/cloud-run"
  # Required variables
  service_name           = "backend"
  project_id             = var.project_id
  location               = var.region
  image                  = var.backend_container_image
  service_account_email = google_service_account.backend_service_account.email
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


# resource "google_sql_database_instance" "main" {
#   name             = "${var.basename}-db-${random_id.id.hex}"
#   database_version = "MYSQL_5_7"
#   region           = var.region
#   project          = var.project_id
#   settings {
#     tier                  = "db-g1-small"
#     disk_autoresize       = true
#     disk_autoresize_limit = 0
#     disk_size             = 10
#     disk_type             = "PD_SSD"
#     ip_configuration {
#       ipv4_enabled    = false
#       private_network = google_compute_network.main.id
#     }
#     location_preference {
#       zone = var.zone
#     }
#   }
#   deletion_protection = false
#   depends_on = [
#     google_project_service.all,
#     google_service_networking_connection.main
#   ]

#   provisioner "local-exec" {
#     working_dir = "${path.module}/../code/database"
#     command     = "./load_schema.sh ${var.project_id} ${google_sql_database_instance.main.name}"
#   }
# }#
