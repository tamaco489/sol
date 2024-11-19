variable "env" {
  description = "The environment in which the Network will be created"
  type        = string
  default     = "stg"
}

variable "instance_type" {
  description = "The instance type to use for the EC2 instance"
  type        = string
  default     = "t3a.nano"
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
