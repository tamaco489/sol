resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${local.fqn}-nat" }
}
