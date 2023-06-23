
variable "project_id" {
  type        = string
  description = "The GCP project id to create Terraform resources within."
}

variable "region" {
  type        = string
  description = "The region to create GCP resources within."
}

variable "frontend_service_name" {
  type        = string
  description = "The service name of the frontend Cloud Run instance."
}

variable "database_password_secret_name" {
  type        = string
  description = "The name of the secret that will be created for the Cloud SQL password. "
  sensitive   = true
}
