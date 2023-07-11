data "google_project" "project" {
  project_id = var.project_id
}

data "google_cloud_run_service" "container_first_run" {
  count    = var.first_run ? 1 : 0
  project  = var.project_id
  name     = "placeholder"
  location = var.region
  depends_on = [
    google_cloud_run_v2_service.default
  ]
}

data "google_cloud_run_service" "container" {
  count    = var.first_run ? 0 : 1
  project  = var.project_id
  name     = var.frontend_service_name
  location = var.region
}

