
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

variable "database_name" {
  type        = string
  description = "The database name to create. "
}

variable "first_run" {
  type        = bool
  description = "Specifies whether this is the first run of the package"
}