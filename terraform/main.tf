# Resource Group
resource "azurerm_resource_group" "app_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Container Apps Environment
resource "azurerm_container_app_environment" "app_env" {
  name                       = "${var.app_name_prefix}-env"
  resource_group_name        = azurerm_resource_group.app_rg.name
  location                   = azurerm_resource_group.app_rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.app_logs.id
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "app_logs" {
  name                = "${var.app_name_prefix}-logs"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Frontend Container App
resource "azurerm_container_app" "frontend" {
  name                         = "${var.app_name_prefix}-frontend"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name          = azurerm_resource_group.app_rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.acr.login_server}/frontend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "REACT_APP_API_URL"
        value = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
      }
    }
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    traffic_weight {
      percentage = 100
    }
  }
}

# Backend Container App
resource "azurerm_container_app" "backend" {
  name                         = "${var.app_name_prefix}-backend"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name          = azurerm_resource_group.app_rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "backend"
      image  = "${azurerm_container_registry.acr.login_server}/backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DATABASE_URL"
        value = "postgresql://user:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.db.fqdn}:5432/mydb?sslmode=require"
      }
    }
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  ingress {
    external_enabled = true
    target_port      = 5000
    traffic_weight {
      percentage = 100
    }
  }
}

# Azure Database for PostgreSQL
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "${var.app_name_prefix}-postgres"
  resource_group_name    = azurerm_resource_group.app_rg.name
  location               = azurerm_resource_group.app_rg.location
  version                = "16"
  administrator_login    = "user"
  administrator_password = var.postgres_admin_password
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768

  # Ensure public access for simplicity (use VNet integration in production)
  public_network_access_enabled = true
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "mydb"
  server_id = azurerm_postgresql_flexible_server.db.id
}

# Allow Container Apps to access PostgreSQL
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_container_apps" {
  name             = "allow-container-apps"
  server_id        = azurerm_postgresql_flexible_server.db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
