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
  cluster_name = "php-ecs-app-cluster-dev"
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
      cpu          = 256
      memory       = 512
      essential    = false
      portMappings = []
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

  desired_count       = 2
  cpu                 = "512"
  memory              = "1024"
  ecs_security_groups = []

  enable_alb          = true
  alb_protocol        = "HTTPS"
  domain_name         = var.domain_name
  alb_name            = "php-ecs-app-alb"
  alb_security_groups = ["sg-0bf494f1c1de1bfea"]
  zone_name           = "l2t.me"
}

output "public_url" {
  value = module.ecs_app.public_url
}
