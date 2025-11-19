resource "azurerm_mssql_server" "project1_sql_server" {
  name                = "project1-sqlserver"
  resource_group_name = "project1-RG"
  location            = "canadacentral"
  version             = "12.0"

  # Required SQL login (Terraform requires it)
  administrator_login          = "sqladminuser"
  administrator_login_password = var.sql_admin_password

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Azure AD admin (new method in azurerm v4+)
  azuread_administrator {
    login_username              = "ajithsunkara1996_gmail.com#EXT#@ajithsunkara1996gmail.onmicrosoft.com"
    tenant_id                   = "edd9a64b-9b14-4418-b513-95ea88d93a37"
    object_id                   = "4febffc6-2366-4f76-b837-e44143b0568d"
    azuread_authentication_only = true
  }
  # Tell Terraform to ignore password changes
  lifecycle {
    ignore_changes = [
      administrator_login_password
    ]
  }
}