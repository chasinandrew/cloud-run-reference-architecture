# Cloud Run Deployment Pattern with Terraform Cloud & GitHub Actions 

This repository handles the basic deployment of containerized application on Cloud Run, along with a Global External Load Balancer and IAM for the service.

The resources/services/activations/deletions that this module will create/trigger are: 

* Creates a Cloud Run service with provided name, application code and optional parameters for the container
* Creates a Global HTTPS load balancer with a Google-managed SSL certificate, forwarding rule, URL map and serverless network endpoint group
* Applies a tag for excluding the Cloud Run service from Domain Restricted Sharing organization policy
* Creates a Cloud Storage bucket if needed within your application 
* Prepares Cloud Run instance for connection to Cloud SQL instances with environment variables and Secrets Manager
* Deployment pipeline facilitates the container image build and push to Artifact Registry

## Architecture Diagram
![alt text](./architecture-diagram.jpg "Serverless Web App")


## Assumptions and Prerequisites 

This repository assumes that the below mentioned prerequisites are in place before consuming the module. 

* All required APIs are enabled in the GCP Project
* Terraform workspace has been created and the team token is stored in Github secrets
* Workload Identity Federation is configured for the service account to authenticate from Github and Terraform Cloud
* Github secrets are created for **TF_API_TOKEN**, **WIF_PROVIDER**, **WIF_SA**
* Artifact Registry repository has been created
* Static external IP address has been reserved 
* DNS A record has been created with the external IP address and domain name to be used for Cloud Run 
* Cloud SQL (optional) 
* VPC Connector in the Shared VPC network host project (optional)
* Secrets created and stored in Secrets Manager or HashiCorp Vault (optional)

## Required APIs
* artifactregistry.googleapis.com
* monitoring.googleapis.com
* run.googleapis.com
* pubsub.googleapis.com
* storage-component.googleapis.com
* certificatemanager.googleapis.com
* dns.googleapis.com
* iamcredentials.googleapis.com
* container.googleapis.com
* iam.googleapis.com
* logging.googleapis.com
* sql-component.googleapis.com
* sqladmin.googleapis.com
* vpcaccess.googleapis.com
* serviceusage.googleapis.com
* cloudresourcemanager.googleapis.com


## Permissions Required for Terraform Service Account

* roles/artifactregistry.admin
* roles/cloudsql.admin
* roles/instanceAdmin.v1
* roles/iam.projectIamAdmin
* roles/compute.loadBalancerAdmin
* roles/iam.workloadIdentityPoolAdmin
* roles/artifactregsitry.writer 
* roles/resourcemanager.tagUser


## How to use this repository

1. Change the following environment variables in the workflow located at _.github/workflows/deployment.yml_
  **PROJECT_ID**: Google project ID  
  **WORKLOAD_IDENTITY_PROVIDER**: Do not change this, the secret will be inserted at runtime  
  **SERVICE_ACCOUNT**: Do not change this, the secret will be inserted at runtime  
  **GAR_LOCATION**: Google Artifact Registry location  
  **REPOSITORY**: Artifact Registry repository name from preparation step 4  
  **SERVICE**: Name of your service that will be associated with the fully qualified image name   
  **APP_CODE_DIRECTORY**: Root directory of your application code where your Dockerfile is located   
  **IMAGE_TAG**: Tag of the image, can be set to the Github commit hash for dev testing but should follow an image release process for higher environments   
  **TF_ENV**: Application environment, either dev, qa or prod  
  **TF_PATH**: Path to the Terraform working directory  
  **TF_WORKSPACE**: Terraform workspace that will be used to deploy the infrastructure  

2. Navigate to this file [environments/dev-gcp/providers.tf](./environments/dev-gcp/providers.tf)  
3. Change the following code to link to your workspace. 
  ```hcl
    cloud {
    organization = "google-test-org"
    workspaces {
      name = "YOUR_WORKSPACE"
    }
  }
  ```
3. Navigate to this file [environments/dev-gcp/main.tf](./environments/dev-gcp/main.tf)
4. Change the following HCL code to be specific to your application. 
  ```hcl
  locals {
    gcp_project_id = "YOUR_GCP_PROJECT"
    gcp_region     = "YOUR_REGION" #us-east4 or us-central1

    labels = {
      cost_id         = "YOUR_COST_ID"
      classification  = "YOUR_DATA_CLASSIFICATION"
      department_id   = "YOUR_DEPARTMENT_ID"
      tco_id          = "YOUR_TCO_ID"
      app_code        = "YOUR_APP_CODE"
      app_environment = "ENVIRONMENT"
      region          = local.gcp_region
    }

    bucket_name = "YOUR_BUCKET_NAME"

    cloud_run = {
      service_name = "YOUR_APPLICATION_SERVICE_NAME"
      domain_name  = "YOUR_DOMAIN_NAME" 
      env_vars = [
          {
          name  = "SAMPLE_ENVIRONMENT_VARIABLE_NAME"
          value = "SAMPLE_ENVIRONMENT_VARIABLE_VALUE"
          }
      ]
      port = YOUR_APPLICATION_PORT #8080 for HTTPS
    }

    username_secret       = "YOUR_USERNAME_SECRET" #Enter the secret name, NOT details of the secret
    password_secret       = "YOUR_PASSWORD_SECRET" #Enter the secret name, NOT details of the secret
    external_address_name = "YOUR_STATIC_EXTERNAL_IP"
  }

  module "reference_architecture" {
    source                = "../../modules"
    service_name          = local.cloud_run.service_name
    bucket_name           = local.bucket_name
    gcp_project_id        = local.gcp_project_id
    gcp_region            = local.gcp_region
    labels                = local.labels
    container_image       = var.container_image
    env_vars              = local.cloud_run.env_vars
    domain_name           = local.cloud_run.domain_name
    port                  = local.cloud_run.port
    user_secret_name      = local.username_secret
    password_secret_name  = local.password_secret
    external_address_name = local.external_address_name
  }
  ```


