locals {
  project_name      = "php-ecs-app"
  vpc_id            = data.aws_vpc.default_vpc.id
  zone_id           = data.aws_route53_zone.zone.zone_id
  public_subnet_ids = data.aws_subnets.default_subnets.ids
  subdomain         = var.domain_name == var.zone_name ? "@" : replace(var.domain_name, ".${var.zone_name}", "")
}
