resource "google_service_account" "container_service_account" {
  account_id   = "container-sa"
  display_name = "Container Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "secret_access" {
    project = var.project_id
    role = "roles/secretmanager.secretAccessor"
    member = google_service_account.container_service_account
}

resource "google_project_iam_member" "object_creator" { 
    project = var.project_id
    role = "roles/storage.objectCreator"
    member = google_service_account.container_service_account
}


resource "google_project_iam_member" "cloudsql_client" {
    project = var.project_id
    role = "roles/cloudsql.client"
    member = google_service_account.container_service_account
}

