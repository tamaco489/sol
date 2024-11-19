variable "env" {
  description = "The environment in which the Lambda API will be created"
  type        = string
  default     = "stg"
}

variable "log_retention_in_days" {
  description = "The number of days to retain log events"
  type        = number
  default     = 30
}

variable "allow_origin" {
  description = "The origin to allow access to the API"
  type        = string
  default     = "*"
}

variable "product" {
  description = "The product name"
  type        = string
  default     = "sol"
}

variable "region" {
  description = "The region in which the VPC will be created"
  type        = string
  default     = "ap-northeast-1"
}

locals {
  fqn = "${var.env}-${var.product}"
}
