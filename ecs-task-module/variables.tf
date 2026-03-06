variable "name" {
  description = "Logical name for the ECS service and task family"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory (MiB)"
  type        = number
  default     = 512
}

variable "image" {
  description = "Container image to run"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "environment" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "command" {
  description = "Optional command override for the container"
  type        = list(string)
  default     = []
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Subnets for the service (Fargate awsvpc network mode)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups for the service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = true
}

variable "task_execution_role_arn" {
  description = "Existing task execution role ARN (if not provided, one will be created)"
  type        = string
  default     = ""
}

variable "task_role_arn" {
  description = "Existing task role ARN (if not provided, one will be created)"
  type        = string
  default     = ""
}

variable "target_group_arn" {
  description = "Optional ALB/NLB target group ARN to attach the service to"
  type        = string
  default     = ""
}
