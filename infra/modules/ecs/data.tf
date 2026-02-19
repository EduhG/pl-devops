data "aws_lb" "existing_alb" {
  name = var.alb_name
}

data "aws_lb_listener" "https_listener" {
  load_balancer_arn = data.aws_lb.existing_alb.arn
  port              = 443
}

data "aws_route53_zone" "zone" {
  name         = var.zone_name
  private_zone = false
}
