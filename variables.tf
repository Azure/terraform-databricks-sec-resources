# Required variables
variable "databricks_workspace" {
    description = "Databricks workspace to deploy resources to."
}

variable "service_principal_client_id" {
    type = string
    description = "Service Principal or App Registration Client ID for workspace auth."
}


variable "service_principal_client_secret" {
    type = string
    description = "Service Principal or App Registration Client secret for workspace auth."
}

variable "tenant_id" {
    type = string
    description = "ID of the Azure tenant in which the Databricks workspace is located."
}

variable "subscription_id" {
    type = string
    description = "ID of the Azure subscription in which the Databricks workspace is located."
}

# Optional variables

variable "cluster_default_packages" {
    type = list(string)
    description = "List of uris for any custom Python packages (.whl) to install on clusters by default."
    default = []
}

variable "whl_upload_script_path" {
    type = string
    description = "Path to a bash script which downloads the whls in cluster_default_packages, and uploads them to dbfs."
    default = ""
}

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
