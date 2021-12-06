provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

terraform {
  backend "local" {}
}
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resource_group_terraform" {
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_storage_account" "azurefunction" {
  name                     = "azurefunctionteste123"
  resource_group_name      = azurerm_resource_group.resource_group_terraform.name
  location                 = azurerm_resource_group.resource_group_terraform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "example" {
  name                = "azure-functions-test-service-plan"
  location            = azurerm_resource_group.resource_group_terraform.location
  resource_group_name = azurerm_resource_group.resource_group_terraform.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "example" {
  name                       = "test-azure-vanderlan"
  location                   = azurerm_resource_group.resource_group_terraform.location
  resource_group_name        = azurerm_resource_group.resource_group_terraform.name
  app_service_plan_id        = azurerm_app_service_plan.example.id
  storage_account_name       = azurerm_storage_account.azurefunction.name
  storage_account_access_key = azurerm_storage_account.azurefunction.primary_access_key
}