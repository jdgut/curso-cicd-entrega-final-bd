variable "desired_count" {
  description = "Cantidad deseada de tareas ECS para la base de datos."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count debe ser al menos 1."
  }
}

variable "db_container_port" {
  description = "Puerto TCP expuesto por el contenedor PostgreSQL."
  type        = number
  default     = 5432
}

variable "task_cpu" {
  description = "CPU units para la tarea Fargate (ej: 256, 512, 1024)."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memoria (MiB) para la tarea Fargate (ej: 1024, 2048)."
  type        = number
  default     = 1024
}

variable "postgres_db" {
  description = "Valor para la variable de entorno POSTGRES_DB."
  type        = string
}

variable "postgres_user" {
  description = "Valor para la variable de entorno POSTGRES_USER."
  type        = string
}

variable "postgres_password" {
  description = "Valor para la variable de entorno POSTGRES_PASSWORD."
  type        = string
  sensitive   = true
}

variable "cloudwatch_log_retention_days" {
  description = "Retencion en dias para logs de CloudWatch."
  type        = number
  default     = 7
}
