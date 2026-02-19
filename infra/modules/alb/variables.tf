variable "project_name" {
  description = "Unique project identifier used as a prefix for naming AWS resources."
  type        = string

  validation {
    condition     = length(var.project_name) > 2
    error_message = "project_name must be at least 3 characters long."
  }
}

variable "vpc_id" {
  description = "Identifier of the VPC where the security group will be created"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "Optional existing ACM certificate ARN"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "load_balancer_type" {
  description = "The type of load balancer to create. Possible values are `application`, `gateway`, or `network`. The default value is `application`"
  type        = string
  default     = "application"
}

variable "subnet_ids" {
  description = "A list of subnet IDs to attach to the LB."
  type        = list(string)
  default     = null
}

variable "enable_deletion_protection" {
  description = "If `true`, deletion of the load balancer will be disabled via the AWS API."
  type        = bool
  default     = true
}
