terraform {
  required_version = ">=0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.9.0, < 5.0.0"
    }
  }
}
cloud {
  organization = "google-org-testing"
  workspaces {
    name = "cloud-run-reference-architecture"
  }
}
# provider "google" {
#   project     = "arched-inkwell-368821"
#   credentials = "/Users/andrewchasin/Documents/service-account-keys/new-demo.json"
# }
