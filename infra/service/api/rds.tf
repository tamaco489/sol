# RDSで利用するサブネットグループ
resource "aws_db_subnet_group" "rds" {
  name       = "${local.fqn}-rds-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.vpc.private_subnet_ids

  tags = { Name = "${local.fqn}-rds-subnet-group" }
}

# WARNING: [重要]
# 漏洩防止のため、RDSのパスワードはリソース作成後AWSコンソールから変更する。
# また、設定したパスワードsecrets managerに保存する(aws_secretsmanager_secret.rdsに設定すること)。
# 設定するオブジェクトのフォーマットは以下の通り。
# {"username":"<username>","password":"<password>","host":"<proxy_endpoint>"}
# rdsへはrds proxyを介してアクセスするため、hostにはrds proxyのエンドポイントを指定する
# また、このフォーマットを変更するとrds proxyが正常に動作しないため注意すること。

# RDSクラスターの設定
resource "aws_rds_cluster" "rds" {
  # NOTE: 基本設定
  cluster_identifier = "${local.fqn}-rds-cluster"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.06.0"
  database_name      = "sol"
  master_username    = "sol"
  master_password    = "password0#"

  # NOTE: ネットワークの設定
  db_subnet_group_name   = aws_db_subnet_group.rds.name # DBクラスタを配置するVPCを指定
  vpc_security_group_ids = [aws_security_group.db.id]   # DBクラスタが属するVPC内での通信を制御するセキュリティグループを指定

  # NOTE: メンテナンスの設定
  final_snapshot_identifier    = "${local.fqn}-rds-cluster-final-snapshot" # クラスター削除時に取得される最終スナップショットの名前
  backup_retention_period      = 7                                         # 自動バックアップの保持期間(日数)
  preferred_backup_window      = "03:00-04:00"                             # バックアップの取得時間帯
  preferred_maintenance_window = "sun:05:00-sun:06:00"                     # メンテナンスの実行時間帯 (3-4時のバックアップ後にメンテナンスを実施)
  allow_major_version_upgrade  = true                                      # メジャーバージョンアップグレードを許可

  # NOTE: パフォーマンス関連の設定
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds.name   # DBクラスタに適用するパラメータグループを指定
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"] # AWS CloudWatch Logsにエクスポートするログタイプを指定 (監査, エラー, 一般, スロークエリをを指定)

  # NOTE: ライフサイクルの設定
  lifecycle {
    ignore_changes  = [master_password] # パスワードが変更された場合でも変更を無視(クラスタ、及びインスタンス作成後に変更するため)
    prevent_destroy = false             # WARNING: [重要] RDSクラスターの削除を許可、本番運用時は`true`に設定すること
  }

  tags = { Name = "${local.fqn}-rds-cluster" }
}

# RDSクラスターのエンドポイント
resource "aws_rds_cluster_instance" "rds" {
  # NOTE: 基本設定
  cluster_identifier = aws_rds_cluster.rds.id
  engine             = aws_rds_cluster.rds.engine
  engine_version     = aws_rds_cluster.rds.engine_version
  identifier         = "${local.fqn}-instance"
  instance_class     = "db.t4g.medium"

  # NOTE: ネットワークの設定
  publicly_accessible  = false                      # インターネット経由を経由したパブリックなアクセスを許可しない
  db_subnet_group_name = aws_db_subnet_group.rds.id # インスタンスを配置するサブネットグループを指定

  # NOTE: メンテナンスの設定
  auto_minor_version_upgrade = false # マイナーバージョンの自動アップグレードを無効化

  # TODO: モニタリング用のIAMロール作成後に有効化
  # monitoring_role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/rds-monitoring-role" # モニタリング用のIAMロールを指定
  # monitoring_interval        = "60"                                                                                   # モニタリングの間隔(秒)

  # NOTE: パフォーマンス関連の設定
  performance_insights_enabled = true # パフォーマンスインサイトを有効化

  # NOTE: ライフサイクルの設定
  lifecycle {
    prevent_destroy = false # WARNING: [重要] RDSインスタンスの削除を許可、本番運用時は`true`に設定すること
  }

  tags = { "Name" = "${local.fqn}-rds-cluster-instance" }
}

# RDSクラスターに設定するパラメータグループ
resource "aws_rds_cluster_parameter_group" "rds" {
  name   = "${local.fqn}-rds-parameter-group"
  family = "aurora-mysql8.0"

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}
