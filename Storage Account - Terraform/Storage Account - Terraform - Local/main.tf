terraform {
  backend "local" {}
}
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "resource_storage" {
    name = var.storage_account_name
    resource_group_name = azurerm_resource_group.resource_group.name
    location = azurerm_resource_group.resource_group.location
    account_tier = "Standard"
    account_replication_type = "LRS"
}


