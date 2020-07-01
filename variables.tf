# Required variables
variable "databricks_workspace" {
    description = "Databricks workspace to deploy resources to."
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
