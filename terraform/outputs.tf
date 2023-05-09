output "instance_connection_name" {
  value       = module.mssql_db.instance_connection_name
  description = "The connection name of the master instance to be used in connection strings"
}