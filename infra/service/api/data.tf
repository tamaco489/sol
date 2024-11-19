data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "network/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "s3/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "ecr/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "lambda_iam" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "lambda/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "alb/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "acm" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "acm/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "bastion" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "bastion/terraform.tfstate"
    region = var.region
  }
}

data "aws_kms_key" "secretsmanager" {
  key_id = "alias/aws/secretsmanager"
}

data "aws_caller_identity" "current" {}
