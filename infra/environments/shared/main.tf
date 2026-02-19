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
  project_name      = var.project_name
  vpc_id            = data.aws_vpc.default_vpc.id
  public_subnet_ids = data.aws_subnets.default_subnets.ids
}

module "acm" {
  source = "../../modules/acm"

  domain_name = var.domain_name
  zone_id     = var.zone_id
}

module "ecr" {
  source = "../../modules/ecr"

  repositories = {
    "php-ecs-app" = {
      image_tag_mutability = "MUTABLE"
    }

    "php-ecs-nginx" = {
      image_tag_mutability = "IMMUTABLE"
    }
  }
}

module "alb" {
  source = "../../modules/alb"

  project_name       = var.project_name
  load_balancer_type = "application"
  vpc_id             = local.vpc_id
  subnet_ids         = local.public_subnet_ids
  certificate_arn    = module.acm.certificate_arn
}


resource "aws_sns_topic" "ecs_alerts" {
  name = "${local.project_name}-ecs-alerts"
}
