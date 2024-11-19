output "alb" {
  value = {
    arn                 = aws_alb.alb.arn
    id                  = aws_alb.alb.id
    zone_id             = aws_alb.alb.zone_id
    name                = aws_alb.alb.name
    dns_name            = aws_alb.alb.dns_name
    security_group_arn  = aws_security_group.alb.arn
    security_group_id   = aws_security_group.alb.id
    security_group_name = aws_security_group.alb.name
  }
}
