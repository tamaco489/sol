variable "env" {
  description = "The environment in which the Network will be created"
  type        = string
  default     = "stg"
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
