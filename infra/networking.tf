data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "ecs_sg" {
  name        = "${local.resource_prefix}-ecs-sg"
  description = "Permite trafico TCP hacia PostgreSQL dentro de la VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL desde la VPC"
    from_port   = var.db_container_port
    to_port     = var.db_container_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# Se usa NLB porque PostgreSQL requiere trafico TCP en 5432.
resource "aws_lb" "db" {
  name               = "${local.resource_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  tags = local.common_tags
}

resource "aws_lb_target_group" "db_tg" {
  name        = "${local.resource_prefix}-tg"
  port        = var.db_container_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 10
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "db" {
  load_balancer_arn = aws_lb.db.arn
  port              = var.db_container_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_tg.arn
  }
}
