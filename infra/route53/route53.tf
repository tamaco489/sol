resource "aws_route53_zone" "sol_host_zone" {
  name = var.domain
  tags = { Name = var.domain }
}
