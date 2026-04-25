resource "aws_ecs_task_definition" "db" {
  family                   = "${local.resource_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  task_role_arn            = var.lab_role_arn
  execution_role_arn       = var.lab_role_arn

  volume {
    name = "postgres_data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.db_data.id
      root_directory     = "/"
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.db.id
        iam             = "DISABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = local.container_name
      image = var.docker_image_uri
      user  = "999:999"

      portMappings = [
        {
          containerPort = var.db_container_port
          hostPort      = var.db_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "POSTGRES_DB"
          value = var.postgres_db
        },
        {
          name  = "POSTGRES_USER"
          value = var.postgres_user
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = var.postgres_password
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "postgres_data"
          containerPath = "/var/lib/postgresql/data"
          readOnly      = false
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.db_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "db" {
  name            = "${local.resource_prefix}-service"
  cluster         = aws_ecs_cluster.db.id
  task_definition = aws_ecs_task_definition.db.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.db_tg.arn
    container_name   = local.container_name
    container_port   = var.db_container_port
  }

  # Single Postgres instance must never share PGDATA across two tasks. EFS is one
  # filesystem: two tasks during deploy (max >100%) = two postmasters → WAL/catalog
  # corruption, "File exists" on CREATE DATABASE, wrong postmaster.pid, etc.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    aws_lb_listener.db,
    aws_efs_mount_target.db
  ]

  tags = local.common_tags
}
