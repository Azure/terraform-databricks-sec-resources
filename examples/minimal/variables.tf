variable "service_principal_client_id" {
    type = string
    description = "Client ID of a service principal with contributor access to the resource group."
}


variable "service_principal_client_secret" {
    type = string
    description = "Client secret of a service principal with contributor access to the resource group."
}

variable "azure_tenant_id" {
    type = string
    description = "ID of the Azure tenant in which the Databricks workspace is located."
}

variable "azure_subscription_id" {
    type = string
    description = "ID of the Azure subscription in which the Databricks workspace is located."
}