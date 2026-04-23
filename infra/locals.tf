locals {
  resource_prefix = "db-${var.environment_name}"
  container_name  = "${local.resource_prefix}-container"

  common_tags = {
    Environment = var.environment_name
    Service     = "database-backend"
    ManagedBy   = "terraform"
  }
}
