terraform {
  required_version = ">=0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.9.0, < 5.0.0"
    }
  }
  cloud {
    organization = "google-testing-org"
    workspaces {
      name = "cloud-run-reference-architecture"
    }
  } #
}
