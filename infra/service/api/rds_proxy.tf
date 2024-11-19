# RDS Proxyの設定
# APIサービスにLambdaを採用しているため、RDS Proxyを利用してコネクションプーリングを行う必要あり
resource "aws_db_proxy" "rds_proxy" {
  engine_family          = "MYSQL"
  name                   = "${local.fqn}-rds-proxy"
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = data.terraform_remote_state.network.outputs.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]

  # アイドル状態のクライアント接続がタイムアウトになるまでの時間を明示的に設定
  # ここでは60秒アクティビティがない接続の場合は自動的に切断
  idle_client_timeout = 60

  # RDS Proxy -> RDS へアクセスする際の認証設定
  auth {
    description = "RDS Proxy authentication"
    auth_scheme = "SECRETS"                         # AWS Secrets Managerを使用
    iam_auth    = "DISABLED"                        # IAM認証を無効化
    secret_arn  = aws_secretsmanager_secret.rds.arn # RDS Proxyが利用するSecrets ManagerのARN
  }
}

# RDS Proxy用のデフォルトターゲットグループの設定
resource "aws_db_proxy_default_target_group" "rds_proxy" {
  db_proxy_name = aws_db_proxy.rds_proxy.name

  connection_pool_config {
    connection_borrow_timeout    = 120 # 接続をプールから借りる際のタイムアウト時間(秒)、ここでは接続が利用可能になるまでの最大待機時間を120秒に設定
    max_connections_percent      = 90  # DBインスタンスの最大接続数に対するプロキシによる接続の最大割合、ここでは利用可能なデータベース接続の最大90%をProxyが使用することを許可
    max_idle_connections_percent = 45  # プール内のアイドル(未使用)接続が占めることが許可される最大割合、ここでは全接続の最大45%がアイドル状態になるように指定
  }

  lifecycle {
    prevent_destroy = false # WARNING: [重要] RDS Proxyの削除を許可、本番運用時は`true`に設定すること
  }
}

# RDS ProxyとRDSクラスターの関連付け
resource "aws_db_proxy_target" "rds_proxy" {
  db_cluster_identifier = aws_rds_cluster.rds.id                           # RDS Proxyが接続するRDSクラスターのID
  db_proxy_name         = aws_db_proxy.rds_proxy.name                      # RDS Proxyの名前
  target_group_name     = aws_db_proxy_default_target_group.rds_proxy.name # RDS Proxyのデフォルトターゲットグループの名前

  lifecycle {
    prevent_destroy = false # WARNING: [重要] RDS Proxyの削除を許可、本番運用時は`true`に設定すること
  }
}

# RDS Proxy用のIAMロールポリシーをIAMロールにアタッチ
resource "aws_iam_role_policy_attachment" "rds_proxy" {
  role       = aws_iam_role.rds_proxy.name
  policy_arn = aws_iam_policy.rds_proxy.arn
}

# RDS Proxy用のIAMロール
resource "aws_iam_role" "rds_proxy" {
  name               = "${local.fqn}-rds-proxy"
  assume_role_policy = data.aws_iam_policy_document.assume_rds_proxy.json
}

# RDS Proxyがこのロールを引き受けるために必要なAssumeRoleポリシー(信頼ポリシー)を指定し、特定のAWSサービスがこのロールを引き受けることを許可
data "aws_iam_policy_document" "assume_rds_proxy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

# RDS Proxy用のIAMポリシー
# RDS ProxyがAWS Secrets Managerの操作を行うために必要な権限を定義するIAMポリシーを作成
resource "aws_iam_policy" "rds_proxy" {
  policy = data.aws_iam_policy_document.rds_proxy.json
}

data "aws_iam_policy_document" "rds_proxy" {
  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",   # Secrets Managerのリソースポリシーを取得
      "secretsmanager:GetSecretValue",      # Secrets Managerのシークレット値を取得
      "secretsmanager:DescribeSecret",      # Secrets Managerのシークレット情報を取得
      "secretsmanager:ListSecretVersionIds" # Secrets Managerのシークレットバージョン情報を取得
    ]
    effect = "Allow"
    resources = [
      aws_secretsmanager_secret.rds.arn
    ]
  }

  statement {
    actions = [
      "kms:Decrypt"
    ]
    effect = "Allow"
    resources = [
      aws_secretsmanager_secret.rds.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.ap-northeast-1.amazonaws.com"]
    }
  }
}
