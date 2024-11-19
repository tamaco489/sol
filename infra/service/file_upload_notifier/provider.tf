provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Product = var.product
      Service = "sol-file-upload-notifier"
      Env     = var.env
    }
  }
}

terraform {
  required_version = "1.7.4"
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}
