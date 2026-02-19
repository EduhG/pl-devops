# variable "domain_name" {
#   description = "A domain name for which the application will be accessed from"
#   type        = string
# }

# variable "zone_name" {
#   description = "The name of the hosted zone in Route53 to DNS records in."
#   type        = string
# }

variable "zone_id" {
  description = "The ID of the hosted zone in Route53 to DNS records in."
  type        = string
}

variable "certificate_arn" {
  description = "Optional existing ACM certificate ARN"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for HTTPS (required if certificate_arn not provided)"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Unique project identifier used as a prefix for naming AWS resources."
  type        = string

  validation {
    condition     = length(var.project_name) > 2
    error_message = "project_name must be at least 3 characters long."
  }
}
