variable "env" {
  description = "The environment in which the Network will be created"
  type        = string
  default     = "stg"
}

variable "domain" {
  description = "The domain name"
  type        = string
  default     = "example.com"
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
