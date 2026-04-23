resource "aws_security_group" "efs_sg" {
  name        = "${local.resource_prefix}-efs-sg"
  description = "Permite NFS desde tareas ECS hacia EFS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS desde ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_efs_file_system" "db_data" {
  creation_token = "${local.resource_prefix}-efs"
  encrypted      = true

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-efs"
  })
}

resource "aws_efs_mount_target" "db" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.db_data.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_access_point" "db" {
  file_system_id = aws_efs_file_system.db_data.id

  posix_user {
    uid = 999
    gid = 999
  }

  root_directory {
    path = "/var/lib/postgresql/data"

    creation_info {
      owner_uid   = 999
      owner_gid   = 999
      permissions = "750"
    }
  }

  tags = local.common_tags
}
