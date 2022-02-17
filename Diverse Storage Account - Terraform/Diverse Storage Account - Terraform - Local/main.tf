terraform {
  backend "local" {}
}
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "resource_storage" {
    count = var.nos_of_storage_accounts
    name = "${var.storage_account_name}${count.index}"
    resource_group_name = azurerm_resource_group.resource_group.name
    location = azurerm_resource_group.resource_group.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    account_kind = "StorageV2"
    min_tls_version = "TLS1_2"
    enable_https_traffic_only = true
}

output storage_account_ids {
 value = azurerm_storage_account.resource_storage[*].id
}


