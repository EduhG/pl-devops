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
