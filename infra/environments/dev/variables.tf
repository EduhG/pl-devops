variable "domain_name" {
  description = "A domain name for which the application will be accessed from"
  type        = string
}

variable "zone_name" {
  description = "The name of the hosted zone in Route53 to DNS records in."
  type        = string
}

variable "region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "eu-west-3"
}

variable "nginx_image_url" {
  description = "URL of the Nginx Docker image to be used in the ECS task definition."
  type        = string
}

variable "php_app_image_url" {
  description = "URL of the PHP App Docker image to be used in the ECS task definition."
  type        = string
}

variable "alb_name" {
  description = "Name of the Application Load Balancer to be used"
  type        = string
  default     = ""
}

variable "api_key" {
  description = "API key for the application"
  type        = string
  default     = "somethingverysecret"
  sensitive   = true
}

variable "alerts_email" {
  description = "Email address to receive CloudWatch alarms"
  type        = string
  default     = ""
}

variable "topic_arn" {
  description = "SNS topic ARN for ECS alerts"
  type        = string
  default     = ""
}
