
module "gh_oidc_wif" {
  source      = "./modules/wif"
  project_id  = var.project_id
  pool_id     = "gh-push-auth-pool"
  provider_id = "gh-push-auth-provider"
  sa_mapping = {
    "gh-push" = {
      sa_name   = google_service_account.gh_sa.id
      attribute = "attribute.repository/user/repo"
    }
  }
  attribute_condition = "google.subject.contains(\"chasinandrew/sample-code\")"
  attribute_mapping = {
    "google.subject" = "assertion.repository"
  }
}

resource "google_cloud_run_v2_service" "default" {
  name     = "cloudrun-service"
  location = "us-central1"
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
}

resource "null_resource" "pods" {
  depends_on = [google_cloud_run_v2_service.default]
  condition = not data.google_cloud_run_service.container.exists

  provisioner "local-exec" {
    command = "echo 'Cloud Run service pods does not exist, creating...'"
  }
}

resource "google_service_account" "gh_sa" {
  project      = var.project_id
  account_id   = "gh-wif"
  display_name = "Service Account for auth to push container images and deploy Cloud Run containers."
}

resource "google_project_iam_member" "ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  members = [google_service_account.gh_sa.member]
}

resource "google_project_iam_member" "run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  members = [google_service_account.gh_sa.member]
}

resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.frontend_service_name
  description   = "Docker repository for container images."
  format        = "DOCKER"
}

resource "google_tags_location_tag_binding" "binding" {
  parent    = "//run.googleapis.com/projects/${data.google_project.project.number}/locations/${var.region}/services/${var.frontend_service_name}"
  tag_value = "tagValues/1067211650924"
  location  = var.region
  depends_on = [
    data.google_cloud_run_service.container
  ]
}

resource "time_sleep" "wait_120_seconds" {
  depends_on      = [google_tags_location_tag_binding.binding]
  create_duration = "120s"
}

resource "google_cloud_run_service_iam_member" "noauth" {
  location = var.region
  project  = var.project_id
  service  = var.frontend_service_name
  role     = "roles/run.invoker"
  member   = "allUsers"
  depends_on = [
    data.google_cloud_run_service.container,
    time_sleep.wait_120_seconds
  ]
}

resource "random_integer" "sneg_id" {
  min = 1
  max = 5
}

resource "google_compute_region_network_endpoint_group" "cloudrun_sneg" {
  name                  = format("sneg-%s-%s", var.project_id, random_integer.sneg_id.result)
  project               = var.project_id
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = data.google_cloud_run_service.container.name
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    random_integer.sneg_id,
    data.google_cloud_run_service.container
  ]
}

module "external-lb-https" {
  source  = "./modules/external-lb"
  project = var.project_id
  name    = format("https-lb-%s", var.project_id)
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
  source        = "./modules/mssql"
  project_id    = var.project_id
  name          = "mssql"
  region        = var.region
  zone          = "us-east4-a"
  root_password = random_password.root-password.result
  additional_users = [{
    name            = "sqlusertest"
    password        = ""
    random_password = true
  }]
  additional_databases = [{
    name      = var.database_name
    collation = "SQL_Latin1_General_CP1_CI_AS"
    charset   = "UTF8"
  }]
  deletion_protection = false
}

resource "random_password" "root-password" {
  length  = 8
  special = true
}

module "secret-manager" {
  source     = "./modules/secret-manager"
  project_id = var.project_id
  secrets = [
    {
      name                  = "DB_ROOT_PASSWORD"
      automatic_replication = true
      secret_data           = random_password.root-password.result
    },
    {
      name                  = "DB_ROOT_USERNAME"
      automatic_replication = true
      secret_data           = "sqlserver"
    },
    {
      name                  = "DB_CONNECTION_NAME"
      automatic_replication = true
      secret_data           = module.mssql_db.instance_connection_name
    },
    {
      name                  = "DB_NAME"
      automatic_replication = true
      secret_data           = var.database_name
    },
  ]
} 