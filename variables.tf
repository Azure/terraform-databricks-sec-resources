# Required variables
variable "databricks_workspace" {
    description = "Databricks workspace to deploy resources to."
}

variable "notebook_path" {
  type = string
  description = "Relative path to a local Jupyter notebook to deploy to the workspace."
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

variable "notebook_name" {
  type = string
  description = "Desired name of the deployed notebook as it will appear in the workspace."
  default = "mynotebook"
}
