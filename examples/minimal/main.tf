provider "azurerm" {
  version = "~>2.3"
  features {}
}

locals {
  unique_name_stub = substr(module.naming.unique-seed, 0, 5)
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming"
}

resource "azurerm_databricks_workspace" "test_ws" {
  name                      = local.unique_name_stub
  resource_group_name       = var.resource_group_name
  location                  = var.resource_group_location
  sku                       = "premium"
}

# Force cluster deployment to wait to avoid state error
resource "time_sleep" "wait_5_mins" {
  depends_on = [azurerm_databricks_workspace.test_ws]
  create_duration = "300s"
}

module "terraform-databricks-sec-resources" {
    source = "../../"
    databricks_workspace = azurerm_databricks_workspace.test_ws
    sp_client_id = var.service_principal_client_id
    sp_client_secret = var.service_principal_client_secret
    subscription_id = var.azure_subscription_id
    tenant_id = var.azure_tenant_id
    clusters_depend_on = [time_sleep.wait_5_mins]
}