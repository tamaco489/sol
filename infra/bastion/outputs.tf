output "sg" {
  value = {
    id   = aws_security_group.bastion.id
    arn  = aws_security_group.bastion.arn
    name = aws_security_group.bastion.name
  }
}
