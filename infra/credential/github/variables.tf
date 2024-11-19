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

variable "github_actions_oidc_provider_arn" {
  description = "The ARN of the OpenID Connect (OIDC) identity provider that is trusted by the Github Actions"
  type        = string
  default     = ""
}

variable "github_actions_repo" {
  description = "The repository name of the Github Actions"
  type        = string
  default     = ""
}

locals {
  fqn = "${var.env}-${var.product}"
}
