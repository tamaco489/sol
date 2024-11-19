data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.env}-sol-tfstate"
    key    = "network/terraform.tfstate"
    region = var.region
  }
}