
output "http_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the ALB HTTPS listener"
  value       = try(aws_lb_listener.https[0].arn, "")
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "alb_name" {
  value = aws_lb.alb.name
}
