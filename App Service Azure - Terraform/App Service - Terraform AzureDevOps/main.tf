provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
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

resource "azurerm_app_service_plan" "app_service_plan_terraform" {
  name                = var.serviceplan_name
  location            = azurerm_resource_group.resource_group_terraform.location
  resource_group_name = azurerm_resource_group.resource_group_terraform.name

  sku {
    tier = "Standard"
    size = "S3"
  }
}

resource "azurerm_app_service" "app_service_terraform" {
  name                = var.appservice_name
  location            = azurerm_resource_group.resource_group_terraform.location
  resource_group_name = azurerm_resource_group.resource_group_terraform.name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan_terraform.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

}