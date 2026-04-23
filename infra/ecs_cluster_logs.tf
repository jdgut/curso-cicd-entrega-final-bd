resource "aws_cloudwatch_log_group" "db_logs" {
  name              = "/ecs/${local.resource_prefix}-task"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = local.common_tags
}

resource "aws_ecs_cluster" "db" {
  name = "${local.resource_prefix}-cluster"

  tags = local.common_tags
}
