terraform {
  backend "azurerm" {
    resource_group_name  = "project1-RG"
    storage_account_name = "p1tfstate75154"
    container_name       = "tfstate"
    key                  = "project1-infra.tfstate"
  }
}