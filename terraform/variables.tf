
variable "project_id" {
  type        = string
  description = "The GCP project id to create Terraform resources within."
}

variable "first_run" {
  type        = bool
  description = "Specifies whether this is the first run of the module. A Cloud Run instance must be created first before pulling data source."
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