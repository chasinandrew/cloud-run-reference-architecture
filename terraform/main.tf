resource "google_tags_location_tag_binding" "binding" {
  parent    = "//run.googleapis.com/projects/${data.google_project.project.number}/locations/${var.region}/services/${var.frontend_service_name}"
  tag_value = "tagValues/1067211650924"
  location  = var.region
  depends_on = [
    data.google_cloud_run_service.container
  ]
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = var.region
  project     = var.project_id
  service     = var.frontend_service_name
  policy_data = data.google_iam_policy.noauth.policy_data
  depends_on = [
    data.google_cloud_run_service.container
  ]
}

resource "random_integer" "sneg_id" {
  min = 1
  max = 1000
}

resource "google_compute_region_network_endpoint_group" "cloudrun_sneg" {
  name                  = format("sneg-%s", random_integer.sneg_id.result)
  project               = var.project_id
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = data.google_cloud_run_service.container.name
  }
  depends_on = [
    random_integer.sneg_id,
    data.google_cloud_run_service.container
  ]
}

module "external-lb-https" {
  source  = "./modules/external-lb"
  project = var.project_id
  # labels     = local.labels
  name = format("https-lb-%s", random_integer.sneg_id.result)
  backends = {
    default = {
      description             = null
      enable_cdn              = false
      custom_request_headers  = null
      custom_response_headers = null
      security_policy         = null
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      protocol         = null
      port_name        = null
      compression_mode = null

      groups = [
        {
          group = google_compute_region_network_endpoint_group.cloudrun_sneg.id
        }
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }
  ssl                             = true
  managed_ssl_certificate_domains = ["test.com"]
  create_address                  = true
  depends_on                      = [google_compute_region_network_endpoint_group.cloudrun_sneg]
}

module "mssql_db" {
  source     = "./modules/mssql"
  project_id = var.project_id
  name       = "mssql"
  region     = var.region
  zone       = "us-east4-a"
  root_password = random_password.root-password.result
  additional_users = [{
    name            = "sqlusertest"
    password        = ""
    random_password = true
  }]
  deletion_protection = false
}

resource "random_password" "root-password" {
  length  = 8
  special = true
}

resource "google_secret_manager_secret" "sqlpassword" {
  project = data.google_project.project.number
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  rotation {
    rotation_period    = "31536000s"
    next_rotation_time = timeadd("2023-05-08T17:00:00Z", "31536000s")
  }
  topics {
    name = google_pubsub_topic.topic.id
  }

  secret_id = var.database_password_secret_name
  # labels = module.tagging.metadata
  depends_on = [
    google_pubsub_topic_iam_member.member
  ]
}

resource "google_secret_manager_secret_version" "sqlpassword" {
  enabled     = true
  secret      = "projects/${data.google_project.project.number}/secrets/${var.database_password_secret_name}"
  # secret_data = module.mssql_db.additional_users[0].password
  secret_data = random_password.root-password.result
  depends_on = [
    google_secret_manager_secret.sqlpassword
  ]
}

resource "google_pubsub_topic" "topic" {
  name    = "secret-topic"
  project = var.project_id
}

resource "google_pubsub_topic_iam_member" "member" {
  project = var.project_id
  topic   = google_pubsub_topic.topic.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
  depends_on = [
    google_project_service_identity.sm_sa
  ]
}

resource "google_project_service_identity" "sm_sa" {
  provider = google-beta
  project  = data.google_project.project.project_id
  service  = "secretmanager.googleapis.com"
}