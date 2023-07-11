data "google_project" "project" {
  project_id = var.project_id
}

data "google_cloud_run_service" "container" {
  project  = var.project_id
  name     = var.frontend_service_name
  location = var.region
  depends_on = [
    google_cloud_run_v2_service.default
  ]
}

