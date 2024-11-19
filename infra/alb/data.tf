data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "network/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "route53" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "route53/terraform.tfstate"
    region = var.region
  }
}
