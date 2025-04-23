variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "three-tier-app-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "threetieracr"
}

variable "postgres_admin_password" {
  description = "Admin password for PostgreSQL"
  type        = string
  sensitive   = true
}

variable "app_name_prefix" {
  description = "Prefix for app names"
  type        = string
  default     = "threetier"
}
