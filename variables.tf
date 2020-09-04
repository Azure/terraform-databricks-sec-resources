# Required variables
variable "databricks_workspace" {
  description = "Databricks workspace to deploy resources to."
}

variable "api_management_name" {
  type        = string
  description = "The name of an Azure API Management instance to have the Databricks API's deployed to."
}

variable "api_management_resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group containing the Azure API Management instance."
}

variable "data_lake_name" {
  type        = string
  description = "The name of an Azure Storage Account Datalake Storage Gen2 instance."
}

variable "service_principal_secret" {
  type = string
  description = "The secret for the service principal to stored as a secret within Databricks."
}

# Optional variables
variable "prefix" {
  type        = list(string)
  description = "A naming prefix to be used in the creation of unique names for deployed Databricks resources."
  default     = []
}

variable "suffix" {
  type        = list(string)
  description = "A naming suffix to be used in the creation of unique names for deployed Databricks resources."
  default     = []
}

variable "notebook_path" {
  type        = string
  description = "Relative path to a local Jupyter notebook to deploy to the workspace."
  default     = ""
}

variable "cluster_default_packages" {
  type        = list(string)
  description = "List of uris for any custom Python packages (.whl) to install on clusters by default."
  default     = []
}

variable "whl_upload_script_path" {
  type        = string
  description = "Path to a bash script which downloads the whls in cluster_default_packages, and uploads them to dbfs."
  default     = ""
}

variable "notebook_name" {
  type        = string
  description = "Desired name of the deployed notebook as it will appear in the workspace."
  default     = "mynotebook"
}

variable "libraries_container_name" {
  type        = string
  description = "The name of the Azure Storage Account Blob Container that will be mounted to Databricks that will contain additional libraries."
  default     = "libraries"
}

variable "data_container_name" {
  type        = string
  description = "The name of the Azure Storage Account Blob Container that will be mounted to Databricks that will contain data."
  default     = "data"
}
