# APIサーバのアクセス制御を統括するセキュリティグループ
resource "aws_security_group" "sol_api" {
  name        = "${local.fqn}-api"
  description = "Security group overseeing access control on API servers"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc.id

  tags = { Name = "${local.fqn}-api-sg" }
}

# ALBからAPIサーバへのインバウンド通信のアクセスを許可
resource "aws_security_group_rule" "api_ingress_alb" {
  security_group_id        = aws_security_group.sol_api.id
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "TCP"
  source_security_group_id = data.terraform_remote_state.alb.outputs.alb.security_group_id
}

# Lambdaから全アウトバウンド通信のアクセスを許可
resource "aws_security_group_rule" "api_egress" {
  security_group_id = aws_security_group.sol_api.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# RDSのアクセス制御を統括するセキュリティグループ
resource "aws_security_group" "db" {
  name        = "${local.fqn}-sg-db"
  description = "Security group overseeing access control on DB servers"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc.id

  tags = { Name = "${local.fqn}-db-sg" }
}

# APIサーバからDBへのインバウンド通信のアクセスを許可
resource "aws_security_group_rule" "db_port_from_api" {
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.sol_api.id
}

# 踏み台サーバからDBへのインバウンド通信のアクセスを許可
resource "aws_security_group_rule" "db_port_from_bastion" {
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  source_security_group_id = data.terraform_remote_state.bastion.outputs.sg.id
}

# NOTE: Lambda BatchからDBへのインバウンド通信のアクセスを許可
resource "aws_security_group_rule" "db_port_from_file_upload_notifier" {
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  source_security_group_id = var.file_upload_notifier_sg
}

# RDS Proxyのアクセス制御を統括するセキュリティグループ
resource "aws_security_group" "rds_proxy" {
  name        = "${local.fqn}-sg-rds-proxy"
  description = "Security group overseeing access control on RDS Proxy servers"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc.id
  tags        = { "Name" = "${local.fqn}-rds-proxy-sg" }
}

# APIサーバからRDS Proxyへのインバウンド通信のアクセスを許可
resource "aws_security_group_rule" "rds_proxy_port_from_api" {
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.rds_proxy.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.sol_api.id
}

# RDS ProxyからDBへのインバウンド通信のアクセスを許可
resource "aws_security_group_rule" "db_port_from_rds_proxy" {
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.rds_proxy.id
}

# 踏み台サーバからRDS Proxyへのインバウンド通信のアクセスを許可
resource "aws_security_group_rule" "db_proxy_port_from_bastion" {
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.rds_proxy.id
  type                     = "ingress"
  source_security_group_id = data.terraform_remote_state.bastion.outputs.sg.id
}

# NOTE: Lambda BatchからRDS Proxyへのインバウンド通信のアクセスを許可
resource "aws_security_group_rule" "db_proxy_port_from_file_upload_notifier" {
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.rds_proxy.id
  type                     = "ingress"
  source_security_group_id = var.file_upload_notifier_sg
}

# RDS ProxyからRDSへのアウトバウンド通信のアクセス許可
resource "aws_security_group_rule" "db_proxy_port_to_rds" {
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.rds_proxy.id
  type                     = "egress"
  source_security_group_id = aws_security_group.db.id
}
