

# module "cloud_run" {
#   source  = "./modules/cloud-run"
#   # Required variables
#   service_name           = "<SERVICE NAME>"
#   project_id             = "<PROJECT ID>"
#   location               = "<LOCATION>"
#   image                  = var.container_image #TODO: add container image
# }

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
# }
