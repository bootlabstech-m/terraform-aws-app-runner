variable "service_name" {
  description = "Name of the App Runner service"
  type        = string
}

variable "image_repository_type" {
  description = "The type of image repository (ECR or PUBLIC)"
  type        = string
  default     = "ECR"
}

variable "image_identifier" {
  description = "Image URI or public image name (with tag) to deploy"
  type        = string
}

variable "cpu" {
  description = "CPU for the App Runner service"
  type        = string
  default     = "1024"
}

variable "memory" {
  description = "Memory for the App Runner service"
  type        = string
  default     = "2048"
}

variable "port" {
  description = "Port your application listens on"
  type        = number
}

variable "environment_variables" {
  description = "Environment variables map for App Runner service"
  type        = map(string)
  default     = {}
}

variable "auto_scaling_configuration" {
  description = "ARN of an App Runner auto scaling configuration (optional)"
  type        = string
  default     = null
}

variable "region" {
    type = string
    description = "the region where you want to deploy the app"
    default = "ap-south-1"
}

variable "subnet_ids" {
  type = list(string)
  description = "subnet ids for vpc connector"
}

variable "vpc_id" {
  type = string
  description = "vpc id for endpoint creation"
}

variable "auto_deployments_enabled" {
  type = bool
  description = "to enable the auto deployments"
  default = false
}