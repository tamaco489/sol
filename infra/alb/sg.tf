resource "aws_security_group" "alb" {
  name        = "${local.fqn}-alb"
  description = "Allow inbound HTTP and HTTPS traffic to ALB"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc.id
  tags        = { Name = "${local.fqn}-sg-alb" }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow inbound HTTP traffic to ALB"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow inbound HTTPS traffic to ALB"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic to external"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
