
variable "project_id" {
  type        = string
  description = "The GCP project id to create Terraform resources within."
}

variable "region" {
  type        = string
  description = "The region to create GCP resources within."
}

variable "frontend_container_image" {
  type        = string
  description = "The container image of the frontend Cloud Run instance."
}

variable "frontend_service_name" {
  type        = string
  description = "The service name of the frontend Cloud Run instance."
}


variable "database_username_secret_name" {
  type        = string
  description = "The name of the secret that will be created for the Cloud SQL username. "
  # sensitive   = true
}

variable "database_username_secret_data" {
  type        = string
  description = "The data that will inserted as a version to the secret for the Cloud SQL username. "
  # sensitive   = true
}

variable "database_password_secret_name" {
  type        = string
  description = "The name of the secret that will be created for the Cloud SQL password. "
  sensitive   = true
}

variable "database_password_secret_data" {
  type        = string
  description = "The data that will inserted as a version to the secret for the Cloud SQL password. "
  sensitive   = true
}