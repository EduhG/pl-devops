data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

locals {
  cluster_name = "php-ecs-app-cluster"
  subnet_ids   = data.aws_subnets.default_subnets.ids
}

module "ecs_app" {
  source = "../../modules/ecs"

  cluster_name = local.cluster_name
  vpc_id       = data.aws_vpc.default_vpc.id
  subnet_ids   = local.subnet_ids

  task_definition_containers = [
    {
      name      = "nginx"
      image     = var.nginx_image_url
      cpu       = 128
      memory    = 256
      essential = true
      portMappings = [
        { containerPort = 80, hostPort = 80 }
      ]
      environment = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.cluster_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    },
    {
      name         = "app"
      image        = var.php_app_image_url
      cpu          = 128
      memory       = 256
      essential    = false
      portMappings = []
      environment = [
        {
          name  = "API_KEY"
          value = "${var.api_key}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.cluster_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ]

  desired_count       = 1
  max_capacity        = 4
  cpu                 = "256"
  memory              = "512"
  ecs_security_groups = []

  enable_alb   = true
  alb_protocol = "HTTPS"
  domain_name  = var.domain_name
  alb_name     = var.alb_name
  zone_name    = var.zone_name

  enable_monitoring = true
  topic_arn         = var.topic_arn
  alerts_email      = var.alerts_email
}

output "public_url" {
  value = module.ecs_app.public_url
}
