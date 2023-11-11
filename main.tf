resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  capacity_providers = ["FARGATE"]
}


resource "aws_ecs_task_definition" "task" {
  family                   = var.project_name
  task_role_arn            = var.task_role
  execution_role_arn       = var.execution_role
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_mem
  container_definitions    = var.container_definitions
}

resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = data.aws_subnet_ids.subnets.ids
    security_groups  = [data.aws_security_group.internet_access.id, aws_security_group.sg.id, data.aws_security_group.default.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = var.project_name
    container_port   = var.task_port
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "ast" {
  max_capacity       = var.desired_count
  min_capacity       = 1
  resource_id        = "service/${var.project_name}-cluster/${var.project_name}-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = var.autoscaling_role
}
resource "aws_appautoscaling_policy" "asp-cpu" {
  name               = "${var.project_name}-CPU"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ast.resource_id
  scalable_dimension = aws_appautoscaling_target.ast.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ast.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80
  }
}
resource "aws_appautoscaling_policy" "asp-mem" {
  name               = "${var.project_name}-MEM"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ast.resource_id
  scalable_dimension = aws_appautoscaling_target.ast.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ast.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 50
  }
}

resource "aws_lb" "lb" {
  name                             = var.project_name
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = data.aws_subnet_ids.subnets.ids
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false
}

resource "aws_lb_target_group" "lb_target_group" {
  name                 = var.project_name
  port                 = var.task_port
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = data.aws_vpc.main.id
  deregistration_delay = 300
  health_check {
    interval = 30
    protocol = "TCP"
  }
  stickiness {
    enabled = true
    type    = "source_ip"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.task_port
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}
resource "aws_security_group" "sg" {
  name        = var.project_name
  description = "Allow inbound for ${var.project_name}"
  vpc_id      = data.aws_vpc.main.id
  ingress {
    from_port   = var.task_port
    to_port     = var.task_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "datalab-${var.project_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.lb.dns_name]
}