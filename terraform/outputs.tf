############################################################
# SQL Server Outputs
############################################################
output "primary_sql_server_fqdn" {
  value       = azurerm_mssql_server.project1_sql_server.fully_qualified_domain_name
  description = "Primary SQL Server FQDN"
}

output "secondary_sql_server_fqdn" {
  value       = azurerm_mssql_server.secondary_sql_server.fully_qualified_domain_name
  description = "Secondary SQL Server FQDN"
}

output "primary_database_id" {
  value       = azurerm_mssql_database.primary_db.id
  description = "Primary Database ID"
}

output "secondary_database_id" {
  value       = azurerm_mssql_database.secondary_db.id
  description = "Secondary Database ID"
}
