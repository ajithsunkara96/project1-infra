terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.52"
    }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
  subscription_id = "d4481482-42bd-4025-8676-245aabd6f2db"  # your correct subscription
  tenant_id       = "edd9a64b-9b14-4418-b513-95ea88d93a37"  # your tenant ID
}