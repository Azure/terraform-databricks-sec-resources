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

resource "azurerm_resource_group" "test_rg" {
  name     = "examplerg"
  location = "UK South"
}

resource "azurerm_databricks_workspace" "test_ws" {
  name                      = local.unique_name_stub
  resource_group_name       = azurerm_resource_group.test_rg.name
  location                  = azurerm_resource_group.test_rg.location
  sku                       = "premium"
}

# Please ensure your service principal has contributor rights to the
# subscription in which the test resource group will be created,
# which should have id == var.subscription_id
module "terraform-databricks-sec-resources" {
    source = "../../"
    databricks_workspace = azurerm_databricks_workspace.test_ws
    service_principal_client_id = var.service_principal_client_id
    service_principal_client_secret = var.service_principal_client_secret
    subscription_id = var.azure_subscription_id
    tenant_id = var.azure_tenant_id
    cluster_default_packages = ["https://files.pythonhosted.org/packages/85/a0/21c1c33d6e3961d774184d26fc8baf31bc79250b531dc8c0217ccb788883/bokeh_plot-0.1.5-py3-none-any.whl"]
    prefix              = [local.unique_name_stub]
    suffix              = [local.unique_name_stub]
}