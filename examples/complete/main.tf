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
  name                = local.unique_name_stub
  resource_group_name = azurerm_resource_group.test_rg.name
  location            = azurerm_resource_group.test_rg.location
  sku                 = "premium"
}

resource "azurerm_api_management" "test_apim" {
  name                = local.unique_name_stub
  location            = azurerm_resource_group.test_rg.location
  resource_group_name = azurerm_resource_group.test_rg.name
  publisher_name      = "My Company"
  publisher_email     = "company@terraform.io"

  sku_name = "Developer_1"
}

resource "azurerm_storage_account" "test_sa" {
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.test_rg.name
  location                 = azurerm_resource_group.test_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

resource "azurerm_role_assignment" "sa_role_assignment" {
  scope                = azurerm_storage_account.test_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_container" "libraries_container" {
  name                  = "libraries"
  storage_account_name  = azurerm_storage_account.test_sa.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "data_container" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.test_sa.name
  container_access_type = "private"
}

# Please ensure your service principal has contributor rights to the
# subscription in which the test resource group will be created,
# which should have id == var.subscription_id
module "terraform-databricks-sec-resources" {
  source                             = "../../"
  databricks_workspace               = azurerm_databricks_workspace.test_ws
  cluster_default_packages           = ["https://files.pythonhosted.org/packages/85/a0/21c1c33d6e3961d774184d26fc8baf31bc79250b531dc8c0217ccb788883/bokeh_plot-0.1.5-py3-none-any.whl"]
  prefix                             = [local.unique_name_stub]
  suffix                             = [local.unique_name_stub]
  notebook_path                      = "notebooks/notebook.ipynb"
  notebook_name                      = "notebook"
  api_management_name                = azurerm_api_management.test_apim.name
  api_management_resource_group_name = azurerm_resource_group.test_rg.location
  data_lake_name                     = azurerm_storage_account.test_sa.name
}
