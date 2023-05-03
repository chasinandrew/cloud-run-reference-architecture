data "google_project" "project" {
  project_id = var.project_id
}

data "google_cloud_run_service" "container" {
  project  = var.project_id
  name     = var.frontend_service_name
  location = var.region
}

resource "google_service_account" "container_service_account" {
  account_id   = "container-sa"
  display_name = "Container Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = google_service_account.container_service_account.member
}

resource "google_project_iam_member" "object_creator" {
  project = var.project_id
  role    = "roles/storage.objectCreator"
  member  = google_service_account.container_service_account.member
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = google_service_account.container_service_account.member
}


resource "google_tags_location_tag_binding" "binding" {
  count     = var.first_run ? 0 : 1
  parent    = "//run.googleapis.com/projects/${data.google_project.project.number}/locations/${var.region}/services/${var.frontend_service_name}"
  tag_value = "tagValues/1067211650924"
  location  = var.region
  depends_on = [
    data.google_cloud_run_service.container
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


resource "google_cloud_run_service_iam_policy" "noauth" {
  count       = var.first_run ? 0 : 1
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
  count                 = var.first_run ? 0 : 1
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
  count   = var.first_run ? 0 : 1
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
          group = google_compute_region_network_endpoint_group.cloudrun_sneg.id[0]
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

  # provisioner "local-exec" {
  #   working_dir = "${path.module}/../code/database"
  #   command     = "./load_schema.sh ${var.project_id} ${google_sql_database_instance.main.name}"
  # }
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

