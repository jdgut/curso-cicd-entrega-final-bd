output "database_nlb_dns_name" {
  description = "DNS del Network Load Balancer para PostgreSQL"
  value       = aws_lb.db.dns_name
}

output "database_endpoint" {
  description = "Endpoint DNS:puerto para conexion a PostgreSQL"
  value       = "${aws_lb.db.dns_name}:${var.db_container_port}"
}

output "ecs_cluster_name" {
  description = "Nombre del ECS Cluster"
  value       = aws_ecs_cluster.db.name
}

output "ecs_service_name" {
  description = "Nombre del ECS Service"
  value       = aws_ecs_service.db.name
}

output "ecs_task_definition_family" {
  description = "Familia de la ECS Task Definition"
  value       = aws_ecs_task_definition.db.family
}

output "efs_file_system_id" {
  description = "ID del sistema EFS usado para persistencia de PostgreSQL"
  value       = aws_efs_file_system.db_data.id
}
