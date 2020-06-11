# Required variables
variable "databricks_host" {
    type = string
    description = "URL to the Databricks workspace to interact with."
}

variable "databricks_api_token" {
    type = string
    description = "A PAT or other valid token to authorise interaction with the Databricks host."
}

# Optional variables

variable "cluster_default_packages" {
    type = list(string)
    description = "List of names or urls for any custom Python packages (.whl) to install on clusters by default."
    default = []
}

variable "whl_upload_script_name" {
    type = string
    description = "Name of a bash script which downloads the whls in cluster_default_packages, and uploads them to dbfs."
    default = "whls_to_dbfs.sh"
}