provider "azurerm" {
    version = "=2.78.0"
    features {}
}

terraform {
  backend "azurerm" {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resource_group_terraform" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "azure_aksvanderlan01" {
  name = var.aks
  location = azurerm_resource_group.resource_group_terraform.location
  resource_group_name = azurerm_resource_group.resource_group_terraform.name
  dns_prefix          = "aks123"

  default_node_pool {
    name = "default"
    node_count = 1
    vm_size = "Standard_a2_v2"
  }
  
  identity {
    type = "SystemAssigned"
  }


}