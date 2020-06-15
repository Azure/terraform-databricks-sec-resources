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

resource "azurerm_resource_group" "test_group" {
  name     = "${module.naming.resource_group.slug}-${module.naming.databricks_workspace.slug}-min-test-${local.unique_name_stub}"
  location = "uksouth"
}

resource "azurerm_log_analytics_workspace" "test_la" {
  name                = "${module.naming.resource_group.slug}-${module.naming.log_analytics_workspace.slug}-min-test-${local.unique_name_stub}"
  location            = azurerm_resource_group.test_group.location
  resource_group_name = azurerm_resource_group.test_group.name
  sku                 = "PerGB2018"
}

resource "azurerm_storage_account" "test_sa" {
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.test_group.name
  location                 = azurerm_resource_group.test_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

module "workspace" {
  source                              = "git::https://github.com/Azure/terraform-azurerm-sec-databricks-workspace"
  resource_group_name                 = azurerm_resource_group.test_group.name
  log_analytics_resource_group_name   = azurerm_log_analytics_workspace.test_la.resource_group_name
  log_analytics_name                  = azurerm_log_analytics_workspace.test_la.name
  storage_account_resource_group_name = azurerm_storage_account.test_sa.resource_group_name
  storage_account_name                = azurerm_storage_account.test_sa.name
  prefix                              = [local.unique_name_stub]
  suffix                              = [local.unique_name_stub]
  databricks_workspace_sku            = "premium"
  module_depends_on                   = ["module.azurerm_log_analytics_workspace.test_la"]
}

module "terraform-databricks-sec-resources" {
    source = "../../"
    databricks_host = module.workspace.azurerm_databricks_workspace.workspace_url
    databricks_api_token = "Insert valid PAT token here"
    cluster_default_packages = ["https://files.pythonhosted.org/packages/85/a0/21c1c33d6e3961d774184d26fc8baf31bc79250b531dc8c0217ccb788883/bokeh_plot-0.1.5-py3-none-any.whl"]
    whl_upload_script_path = "../scripts/whls_to_dbfs.sh"
}