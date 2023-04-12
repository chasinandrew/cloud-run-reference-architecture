# Terraform Cloud Run Deployment Pattern

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
* roles/hcacloudrunbinding


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
    organization = "hca-healthcare"
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
      hca_project_id  = "YOUR_HCA_PROJECT_ID"
      tco_id          = "YOUR_TCO_ID"
      app_code        = "YOUR_APP_CODE"
      app_environment = "ENVIRONMENT"
      region          = local.gcp_region
    }

    bucket_name = "YOUR_BUCKET_NAME"

    cloud_run = {
      service_name = "YOUR_APPLICATION_SERVICE_NAME"
      domain_name  = "YOUR_DOMAIN_NAME" #example: cloud-run-test.hcahealthcare.cloud
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


# Terraform Docs
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.9.0, < 5.0.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.9.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 4.58.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud_run"></a> [cloud\_run](#module\_cloud\_run) | app.terraform.io/hca-healthcare/cloud-run/gcp | 1.0.2 |
| <a name="module_external-lb-https"></a> [external-lb-https](#module\_external-lb-https) | app.terraform.io/hca-healthcare/external-lb-https/gcp | 0.0.1 |
| <a name="module_prep-resources"></a> [prep-resources](#module\_prep-resources) | ../prep-resources | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | app.terraform.io/hca-healthcare/storage/gcp | 4.0.0 |
| <a name="module_tagging"></a> [tagging](#module\_tagging) | app.terraform.io/hca-healthcare/tagging/hca | 0.0.7 |

## Resources

| Name | Type |
|------|------|
| [google_compute_region_network_endpoint_group.cloudrun_sneg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_endpoint_group) | resource |
| [google_tags_location_tag_binding.binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_location_tag_binding) | resource |
| [random_integer.sneg_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [google_compute_global_address.external](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_global_address) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argument"></a> [argument](#input\_argument) | The arguments field specifies arguments passed to the command. Arguments passed to the ENTRYPOINT command, include these only if image entrypoint needs arguments. An ENTRYPOINT instruction is used to set executables that will always run when the container is initiated. | `list(string)` | `[]` | no |
| <a name="input_artifact_registry_admin_group"></a> [artifact\_registry\_admin\_group](#input\_artifact\_registry\_admin\_group) | List of users to assign roles/artifactregistry.admin role | `list(string)` | `[]` | no |
| <a name="input_artifact_registry_description"></a> [artifact\_registry\_description](#input\_artifact\_registry\_description) | Description of what the artifact registry repository will be used for. | `string` | `"Artifact Registry"` | no |
| <a name="input_artifact_registry_format"></a> [artifact\_registry\_format](#input\_artifact\_registry\_format) | Format of images stored in artifact registry. | `string` | `"DOCKER"` | no |
| <a name="input_artifact_registry_naming_prefix"></a> [artifact\_registry\_naming\_prefix](#input\_artifact\_registry\_naming\_prefix) | Prefix for the name of artifact registry repository. | `string` | `"docker-repository"` | no |
| <a name="input_artifact_registry_reader_group"></a> [artifact\_registry\_reader\_group](#input\_artifact\_registry\_reader\_group) | List of users to assign roles/artifactregistry.reader role | `list(string)` | `[]` | no |
| <a name="input_artifact_registry_repo_admin_group"></a> [artifact\_registry\_repo\_admin\_group](#input\_artifact\_registry\_repo\_admin\_group) | List of users to assign roles/artifactregistry.repoAdmin role | `list(string)` | `[]` | no |
| <a name="input_artifact_registry_writer_group"></a> [artifact\_registry\_writer\_group](#input\_artifact\_registry\_writer\_group) | List of users to assign roles/artifactregistry.writer role | `list(string)` | `[]` | no |
| <a name="input_autoscaling_maximum"></a> [autoscaling\_maximum](#input\_autoscaling\_maximum) | n/a | `number` | `3` | no |
| <a name="input_autoscaling_minimum"></a> [autoscaling\_minimum](#input\_autoscaling\_minimum) | n/a | `number` | `3` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Bucket name for a bucket created for an application. | `string` | `"gcp-ref"` | no |
| <a name="input_bucket_sa_display_name"></a> [bucket\_sa\_display\_name](#input\_bucket\_sa\_display\_name) | Display name for bucket Service Account | `string` | `"GCS Service Account for DSA"` | no |
| <a name="input_certificate_mode"></a> [certificate\_mode](#input\_certificate\_mode) | n/a | `string` | `"AUTOMATIC"` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | Container command specifies the actual command run by the container. Leave blank to use the ENTRYPOINT command defined in the container image, include these only if image entrypoint should be overwritten. An ENTRYPOINT instruction is used to set executables that will always run when the container is initiated. | `list(string)` | `[]` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | (Required) Docker container image name. This is most often a reference to a container located in the container registry, such as gcr.io/cloudrun/hello <br>  More info: https://kubernetes.io/docs/concepts/containers/images"<br>  example: "us-east4-docker.pkg.dev/hca-ccoe-tf-standards-sbx/module-testing-repository/nginx-image:1.0" | `string` | n/a | yes |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | n/a | `string` | `"1000m"` | no |
| <a name="input_cr_service_account_roles"></a> [cr\_service\_account\_roles](#input\_cr\_service\_account\_roles) | Roles to be bound to the cloud run service account upon instance creation. | `list(string)` | `[]` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Cloud SQL database name to be inserted as an environment variable. | `string` | `""` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name that is registered with DNS and associated with an SSL certificate. | `string` | `""` | no |
| <a name="input_enable_bucket"></a> [enable\_bucket](#input\_enable\_bucket) | n/a | `bool` | `true` | no |
| <a name="input_env_secret_vars"></a> [env\_secret\_vars](#input\_env\_secret\_vars) | Environment variables (Secret Manager) | <pre>list(object({<br>    name = string<br>    value_from = set(object({<br>      secret_key_ref = map(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | Environment variables (cleartext) | <pre>list(object({<br>    value = string<br>    name  = string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "ing",<br>    "value": "test"<br>  }<br>]</pre> | no |
| <a name="input_external_address_name"></a> [external\_address\_name](#input\_external\_address\_name) | External IP address for global address and forwarding rule. | `string` | `""` | no |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | The ID of the project in which the resource belongs. | `string` | n/a | yes |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | Location for GCP Resource Deployment | `string` | n/a | yes |
| <a name="input_http_framing_layer"></a> [http\_framing\_layer](#input\_http\_framing\_layer) | HTTPS framing layer for Cloud Run. This can either be HTTP/1 which is http1 or HTTP/2 which is http2 input for this module. | `string` | `"http1"` | no |
| <a name="input_ingress_service_annotation"></a> [ingress\_service\_annotation](#input\_ingress\_service\_annotation) | n/a | `string` | `"internal-and-cloud-load-balancing"` | no |
| <a name="input_instance_connection_name"></a> [instance\_connection\_name](#input\_instance\_connection\_name) | Cloud SQL instance connection name to be inserted as an environment variable. | `string` | `""` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A set of key/value label pairs to assign to the resource. | `map(string)` | n/a | yes |
| <a name="input_members"></a> [members](#input\_members) | List of users, Google groups or service accounts that will be assigned conditional IAM. | `list(string)` | `[]` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | n/a | `string` | `"512Mi"` | no |
| <a name="input_network"></a> [network](#input\_network) | The name of the network where the subnet will be placed. This should be within the host project of the Shared VPC. | `string` | `"hca-dsa-train-notebooks-shared-vpc"` | no |
| <a name="input_number_of_buckets"></a> [number\_of\_buckets](#input\_number\_of\_buckets) | Number of buckets that an application needs. | `number` | `1` | no |
| <a name="input_password_secret_name"></a> [password\_secret\_name](#input\_password\_secret\_name) | Name of the secret for the database password stored in secrets manager. | `string` | n/a | yes |
| <a name="input_port"></a> [port](#input\_port) | n/a | `number` | `8080` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | n/a | `map(map(string))` | `null` | no |
| <a name="input_service_annotations"></a> [service\_annotations](#input\_service\_annotations) | n/a | `map(string)` | `{}` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | (Required) Name must be unique within a namespace, within a Cloud Run region.<br>  Name is primarily intended for creation idempotence and configuration definition. <br>  Cannot be updated. More info: http://kubernetes.io/docs/user-guide/identifiers#names. <br>  Resource name must use only lowercase letters, numbers and '-'.<br>  It also must begin with a letter and cannot end with a '-' and has a maximum length of 63 characters" | `string` | n/a | yes |
| <a name="input_template_annotations"></a> [template\_annotations](#input\_template\_annotations) | n/a | `map(string)` | `{}` | no |
| <a name="input_timeout_seconds"></a> [timeout\_seconds](#input\_timeout\_seconds) | n/a | `number` | `120` | no |
| <a name="input_traffic_split"></a> [traffic\_split](#input\_traffic\_split) | Managing traffic routing to the service revsion. | <pre>list(object({<br>    latest_revision = bool<br>    percent         = number<br>    revision_name   = string<br>  }))</pre> | <pre>[<br>  {<br>    "latest_revision": true,<br>    "percent": 100,<br>    "revision_name": null<br>  }<br>]</pre> | no |
| <a name="input_user_secret_name"></a> [user\_secret\_name](#input\_user\_secret\_name) | Name of the secret for the database username stored in secrets manager. | `string` | n/a | yes |
| <a name="input_volume_mounts"></a> [volume\_mounts](#input\_volume\_mounts) | Volume mounts to be attached to the container. | <pre>list(object({<br>    mount_path = string<br>    name       = string<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_access_egress"></a> [vpc\_access\_egress](#input\_vpc\_access\_egress) | n/a | `string` | `"private-ranges-only"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->