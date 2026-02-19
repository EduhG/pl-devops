variable "domain_name" {
  type        = string
  description = "Primary domain name"

  validation {
    condition     = length(var.domain_name) > 1
    error_message = "domain_name can not be empty."
  }
}

variable "zone_id" {
  type        = string
  description = "Route53 hosted zone ID"
}
