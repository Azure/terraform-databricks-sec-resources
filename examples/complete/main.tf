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

# Hack required to avoid errors resulting from premature reporting
# from Azure API that Azure Databricks workspace setup is complete
resource "time_sleep" "wait_5_mins" {
  depends_on = [azurerm_databricks_workspace.test_ws]
  create_duration = "300s"
}

module "terraform-databricks-sec-resources" {
    source = "../../"
    databricks_workspace = azurerm_databricks_workspace.test_ws
    service_principal_client_id = var.service_principal_client_id
    service_principal_client_secret = var.service_principal_client_secret
    subscription_id = var.azure_subscription_id
    tenant_id = var.azure_tenant_id
    cluster_default_packages = ["https://files.pythonhosted.org/packages/85/a0/21c1c33d6e3961d774184d26fc8baf31bc79250b531dc8c0217ccb788883/bokeh_plot-0.1.5-py3-none-any.whl"]
    clusters_depend_on = [time_sleep.wait_5_mins]
    prefix              = [local.unique_name_stub]
    suffix              = [local.unique_name_stub]
}