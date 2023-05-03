
data "google_project" "project" {
  project_id = var.project_id
}


resource "google_cloud_run_service" "frontend_container" {
  name     = var.frontend_service_name
  location = var.region

  metadata {
    # labels = module.tagging.labels
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing" #ocal.cloud_run.ingress_service_annotation
    }
  }

  template {
    spec {
      service_account_name = google_service_account.frontend_service_account.email
      containers {
        image = var.frontend_container_image
        ports {
          name           = "http1" #local.cloud_run.http_framing_layer
          container_port = 80 #local.cloud_run.port
        }
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "INSTANCE_CONNECTION_NAME"
          value = module.mssql_db.instance_connection_name
        }
        env {
          name  = "DB_NAME"
          value = module.mssql_db.instance_name
        }
        env {
          name  = "DB_PORT"
          value = 1433
        }
        env {
          name  = "DB_USER"
          value = "default"
        }
        env {
          name  = "DB_PASSWORD"
          value = ""
        }
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "1000"
        "autoscaling.knative.dev/minScale" = "3"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations["run.googleapis.com/client-name"],
      metadata[0].annotations["run.googleapis.com/operation-id"],
      template[0].spec[0].containers[0].image,
      template[0].metadata[0].annotations["run.googleapis.com/client-name"],
      template[0].metadata[0].annotations["client.knative.dev/user-image"],
    ]
  }
  depends_on = [
    google_service_account.frontend_service_account,
  ]
}

resource "google_service_account" "frontend_service_account" {
  account_id   = "frontend-sa"
  display_name = "Frontend Service Account"
  project      = var.project_id
}


resource "google_tags_location_tag_binding" "binding" {
  parent    = "//run.googleapis.com/projects/${data.google_project.project.number}/locations/${var.region}/services/${var.frontend_service_name}"
  tag_value = "tagValues/1067211650924"
  location  = var.region
  depends_on = [
    google_tags_tag_value_iam_member.binding
  ]
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


module "mssql_db" {
  source     = "./modules/mssql"
  project_id = var.project_id
  name       = "mssql"
  region     = var.region
  zone       = "us-east4-a"
}

#   provisioner "local-exec" {
#     working_dir = "${path.module}/../code/database"
#     command     = "./load_schema.sh ${var.project_id} ${google_sql_database_instance.main.name}"
#   }
# }
#


resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = var.region
  project     = var.project_id
  service     = var.frontend_service_name
  policy_data = data.google_iam_policy.noauth.policy_data
  depends_on = [
    google_cloud_run_service.frontend_container
  ]
}

resource "random_integer" "sneg_id" {
  min = 1
  max = 1000
}

resource "google_compute_region_network_endpoint_group" "cloudrun_sneg" {
  name                  = format("sneg-%s", random_integer.sneg_id.result)
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.frontend_container.name
  }
  depends_on = [random_integer.sneg_id]
}

module "external-lb-https" {
  source     = "./modules/external-lb"
  project = var.project_id
  # labels     = local.labels
  name       = format("https-lb-%s", random_integer.sneg_id.result)
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



# resource "google_secret_manager_secret" "sqluser" {
#   project = 730509154195 #TODO: change to variable
#   replication {
#       user_managed {
#         replicas {
#           location = local.region
#       }
#     }
#   }
#   rotation {
#     next_rotation_time = "3153600000s"
#   }

#   secret_id = "sqluser"
#   labels = module.tagging.metadata
# }

# resource "google_secret_manager_secret_version" "sqluser" {
#   enabled     = true
#   secret      = "projects/730509154195/secrets/sqluser" #TODO: change to variable
#   secret_data = var.username_secret 
# }

# resource "google_secret_manager_secret" "sqlpassword" {
#   project = 730509154195 #TODO: change to variable
#   replication {
#       user_managed {
#         replicas {
#           location = local.region
#       }
#     }
#   }
#   rotation {
#     next_rotation_time = "3153600000s"
#   }

#   secret_id = "sqlpassword"
#   labels = module.tagging.metadata
# }

# resource "google_secret_manager_secret_version" "sqlpassword" {
#   enabled     = true
#   secret      = "projects/730509154195/secrets/sqluser" #TODO: change to variable
#   secret_data = var.password_secret
# }

