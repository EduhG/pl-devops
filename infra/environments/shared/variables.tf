variable "domain_name" {
  description = "A domain name for which the application will be accessed from"
  type        = string
}

variable "zone_name" {
  description = "The name of the hosted zone in Route53 to DNS records in."
  type        = string
}
