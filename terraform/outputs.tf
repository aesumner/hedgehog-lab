output "frontend_url" {
  description = "URL of the frontend application"
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "backend_url" {
  description = "URL of the backend API"
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "postgres_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.db.fqdn
}
