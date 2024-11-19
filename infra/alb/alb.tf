resource "aws_alb" "alb" {
  name               = "${local.fqn}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.network.outputs.vpc.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
  tags               = { Name = "${local.fqn}-alb" }
}

resource "aws_route53_record" "api_record" {
  zone_id = data.terraform_remote_state.route53.outputs.host_zone.id
  name    = "api.${data.terraform_remote_state.route53.outputs.host_zone.name}"
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}
