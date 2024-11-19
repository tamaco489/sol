# 踏み台サーバー向けのセキュリティグループ
resource "aws_security_group" "bastion" {
  name   = "${local.fqn}-bastion-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc.id
}

# 全てのアウトバウンドトラフィックを許可
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}
