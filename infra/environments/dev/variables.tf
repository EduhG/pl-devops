# variable "project_name" {
#   description = "Name prefix used for all created AWS resources (e.g. myapp, demo-api)."
#   type        = string
# }

# variable "vpc_id" {
#   description = "ID of the VPC where the Application Load Balancer and ECS service will be deployed."
#   type        = string
# }

# variable "public_subnet_ids" {
#   description = "List of public subnet IDs where the Application Load Balancer will be provisioned."
#   type        = list(string)
# }

# variable "certificate_arn" {
#   description = "ARN of the ACM certificate to be attached to the HTTPS listener of the ALB."
#   type        = string
# }

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
