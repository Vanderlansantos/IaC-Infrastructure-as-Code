provider "azurerm" {
    version = "~> 2.29.0"
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

resource "azurerm_container_registry" "acr" {
  name                = var.azurecontainerregistry
  resource_group_name = azurerm_resource_group.resource_group_terraform.name
  location            = azurerm_resource_group.resource_group_terraform.location
  sku                 = "Standard"
  admin_enabled       = false
}