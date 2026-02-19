variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnets for ECS service"
  type        = list(string)
}

variable "ecs_security_groups" {
  description = "List of security groups to attach to ECS service"
  type        = list(string)
  default     = []
}

variable "task_definition_containers" {
  description = <<EOT
List of container definitions for the ECS task.
Should be in the same format as the 'container_definitions' JSON in aws_ecs_task_definition.
Example:
[
  {
    name      = "app"
    image     = "nginx:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      { containerPort = 80, hostPort = 80 }
    ]
  }
]
EOT
  type        = list(any)
}

variable "cpu" {
  description = "CPU units for the ECS task"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memory for the ECS task"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "enable_alb" {
  description = "Whether to create an ALB for this ECS service"
  type        = bool
  default     = true
}

variable "alb_name" {
  description = "Name of an existing ALB to attach listener rules"
  type        = string
  default     = ""
}

# variable "alb_listener_arn" {
#   description = "ARN of an existing ALB listener to attach listener rules"
#   type        = string
#   default     = ""
# }

variable "alb_protocol" {
  description = "Protocol for ALB listener"
  type        = string
  default     = "HTTP"
}

variable "alb_listener_rule_host_headers" {
  description = "Optional list of host headers for routing"
  type        = list(string)
  default     = []
}

variable "alb_listener_rule_path_patterns" {
  description = "Optional list of path patterns for routing"
  type        = list(string)
  default     = []
}

variable "alb_security_groups" {
  description = "List of security groups for the ALB"
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Optional domain name for host-based routing (e.g., app.example.com)"
  type        = string
  default     = ""
}

variable "zone_name" {
  description = "Route 53 hosted zone name to create the record in (e.g., example.com)"
  type        = string
  default     = ""
}
