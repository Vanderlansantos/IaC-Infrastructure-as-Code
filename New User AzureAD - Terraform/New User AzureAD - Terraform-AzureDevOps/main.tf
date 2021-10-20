provider "azurerm" {
    version = "~> 2.29.0"
    features {}
}

terraform {
  backend "azurerm" {}
}
data "azuread_client_config" "current" {}

resource "azuread_user" "azure_new_user" {
  user_principal_name = "teste@onmicrosoft.com"
  display_name = "Teste"
  mail_nickname = "Teste"
  password = "teste@123"
}
