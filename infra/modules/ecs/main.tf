resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.cluster_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "task" {
  family                   = var.cluster_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode(var.task_definition_containers)
}

locals {
  container_port = try(
    var.task_definition_containers[0].portMappings[0].containerPort,
    null
  )

  attach_alb = var.enable_alb && local.container_port != null && var.alb_name != ""
}

resource "aws_lb_target_group" "tg" {
  count       = local.attach_alb ? 1 : 0
  name        = "${var.cluster_name}-tg"
  port        = local.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "rule" {
  count        = local.attach_alb ? 1 : 0
  listener_arn = data.aws_lb_listener.https_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }

  dynamic "condition" {
    for_each = var.domain_name != "" ? [1] : []
    content {
      host_header {
        values = [var.domain_name]
      }
    }
  }

  dynamic "condition" {
    for_each = length(var.alb_listener_rule_path_patterns) > 0 ? [1] : []
    content {
      path_pattern {
        values = var.alb_listener_rule_path_patterns
      }
    }
  }
}

resource "aws_security_group" "alb" {
  count       = local.attach_alb ? 1 : 0
  name        = "${var.cluster_name}-alb-sg"
  description = "ECS service security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = data.aws_lb.existing_alb.security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "service" {
  name            = "${var.cluster_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = true
    security_groups  = concat(var.ecs_security_groups, local.attach_alb ? [aws_security_group.alb[0].id] : [])
  }

  dynamic "load_balancer" {
    for_each = local.attach_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.tg[0].arn
      container_name   = var.task_definition_containers[0].name
      container_port   = local.container_port
    }
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}

locals {
  zone_id   = data.aws_route53_zone.zone.zone_id
  subdomain = var.domain_name == var.zone_name ? "@" : replace(var.domain_name, ".${var.zone_name}", "")
}

resource "aws_route53_record" "alb_record" {
  count   = var.zone_name != "" ? 1 : 0
  zone_id = local.zone_id
  name    = local.subdomain
  type    = "A"

  alias {
    name                   = data.aws_lb.existing_alb.dns_name
    zone_id                = data.aws_lb.existing_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity = var.desired_count
  max_capacity = var.max_capacity

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "rps" {
  count = local.attach_alb ? 1 : 0

  name               = "rps-scaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = 100 # 100 requests per task

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${data.aws_lb.existing_alb.arn_suffix}/${aws_lb_target_group.tg[0].arn_suffix}"
    }
  }
}

resource "aws_sns_topic_subscription" "google_chat" {
  count     = var.enable_monitoring ? 1 : 0
  topic_arn = var.topic_arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.cluster_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    TargetGroup  = try(aws_lb_target_group.tg[0].arn_suffix, "")
    LoadBalancer = data.aws_lb.existing_alb.arn_suffix
  }

  alarm_actions = [var.topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "${var.cluster_name}-service"
  }

  alarm_actions = [var.topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "at_max_capacity" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.cluster_name}-at-max-capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.max_capacity - 1

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "${var.cluster_name}-service"
  }

  treat_missing_data = "breaching"
  alarm_actions      = [var.topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.cluster_name}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    TargetGroup  = try(aws_lb_target_group.tg[0].arn_suffix, "")
    LoadBalancer = data.aws_lb.existing_alb.arn_suffix
  }

  alarm_actions = [var.topic_arn]
}
