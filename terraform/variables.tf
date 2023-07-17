
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

variable "repository_name" {
  type        = string
  description = "Repository name where Cloud Run will be deployed from." 
}

variable "artifact_registry_format" { 
  type = string
  description = "Type of Artifact Registry repository."
  default = "DOCKER"
}

variable "domain_restricted_sharing_exclusion_tag" { 
  type = string
  description = "Tag to be applied to Cloud Run to exempt the instance from domain restricted sharing."
}

variable "partially_qualified_domain_name" {
  type = string 
  description = "Domain name for Global Load Balancer with Cloud Run. "
}
