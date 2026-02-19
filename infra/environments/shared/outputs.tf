output "repository_urls" {
  value = module.ecr.repository_urls
}

output "alb_https_listener_arn" {
  value = module.alb.https_listener_arn
}

output "alb_security_group_id" {
  value = module.alb.alb_security_group_id
}

output "alb_name" {
  value = module.alb.alb_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.ecs_alerts.arn
}
