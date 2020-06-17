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

resource "azurerm_log_analytics_workspace" "test_la" {
  name                = "${module.naming.resource_group.slug}-${module.naming.log_analytics_workspace.slug}-min-test-${local.unique_name_stub}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

resource "azurerm_storage_account" "test_sa" {
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

module "workspace" {
  source                              = "git::https://github.com/Azure/terraform-azurerm-sec-databricks-workspace"
  resource_group_name                 = var.resource_group_name
  log_analytics_resource_group_name   = azurerm_log_analytics_workspace.test_la.resource_group_name
  log_analytics_name                  = azurerm_log_analytics_workspace.test_la.name
  storage_account_resource_group_name = azurerm_storage_account.test_sa.resource_group_name
  storage_account_name                = azurerm_storage_account.test_sa.name
  prefix                              = [local.unique_name_stub]
  suffix                              = [local.unique_name_stub]
  databricks_workspace_sku            = "premium"
  module_depends_on                   = ["module.azurerm_log_analytics_workspace.test_la"]
}

# Force cluster deployment to wait to avoid state error
resource "time_sleep" "wait_5_mins" {
  depends_on = [module.workspace.azurerm_databricks_workspace]
  create_duration = "300s"
}


module "terraform-databricks-sec-resources" {
    source = "../../"
    databricks_workspace = module.workspace.azurerm_databricks_workspace
    sp_client_id = var.service_principal_client_id
    sp_client_secret = var.service_principal_client_secret
    subscription_id = var.azure_subscription_id
    tenant_id = var.azure_tenant_id
    cluster_default_packages = ["https://files.pythonhosted.org/packages/85/a0/21c1c33d6e3961d774184d26fc8baf31bc79250b531dc8c0217ccb788883/bokeh_plot-0.1.5-py3-none-any.whl"]
    clusters_depend_on = [time_sleep.wait_5_mins]
}