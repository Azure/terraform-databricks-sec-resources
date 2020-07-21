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
    notebook_path = "notebooks/notebook.ipynb"
}
