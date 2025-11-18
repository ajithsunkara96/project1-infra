############################################################
# Step 3a: Primary SQL Database on Primary SQL Server
############################################################
resource "azurerm_mssql_database" "primary_db" {
  name           = "project1db"
  server_id      = azurerm_mssql_server.project1_sql_server.id
  sku_name       = "GP_Gen5_2"
  max_size_gb    = 10
  zone_redundant = false
  create_mode    = "Default"
  collation      = "SQL_Latin1_General_CP1_CI_AS"
}

############################################################
# Step 3b: Secondary SQL Server in Canada Central Region
############################################################
resource "azurerm_mssql_server" "secondary_sql_server" {
  name                         = "project1-sqlserver-secondary-01"
  resource_group_name          = "project1-RG"
  location                     = "canadacentral"
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = var.sql_admin_password

  identity {
    type = "SystemAssigned"
  }

  azuread_administrator {
    login_username              = "ajithsunkara1996_gmail.com#EXT#@ajithsunkara1996gmail.onmicrosoft.com"
    tenant_id                   = "edd9a64b-9b14-4418-b513-95ea88d93a37"
    object_id                   = "4febffc6-2366-4f76-b837-e44143b0568d"
    azuread_authentication_only = true
  }

  depends_on = [
    azurerm_mssql_server.project1_sql_server
  ]
}

############################################################
# Step 3c: Secondary SQL Database (Geo-Replication)
############################################################
resource "azurerm_mssql_database" "secondary_db" {
  name                        = "project1db"
  server_id                   = azurerm_mssql_server.secondary_sql_server.id
  create_mode                 = "Secondary"
  creation_source_database_id = azurerm_mssql_database.primary_db.id
  sku_name                    = "GP_Gen5_2"

  depends_on = [
    azurerm_mssql_database.primary_db,
    azurerm_mssql_server.secondary_sql_server
  ]
}