# VPC Lambda Policy (共通)
data "aws_iam_policy_document" "lambda_vpc" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",    # Lambda関数がENI（Elastic Network Interface）を作成できるようにする。VPC内でLambda関数を実行するために必要。
      "ec2:DescribeNetworkInterfaces", # 既存のネットワークインターフェースの情報を取得するに必要。
      "ec2:DeleteNetworkInterface",    # ENIを削除するために必要
      "ec2:AssignPrivateIpAddresses",  # ENIにプライベートIPアドレスを割り当てるために必要。
      "ec2:UnassignPrivateIpAddresses" # ENIからプライベートIPアドレスを割り当て解除するために必要。
    ]

    resources = ["*"] # 全てのリソースに適用
  }
}

resource "aws_iam_policy" "lambda_vpc" {
  name        = "${local.fqn}-lambda-vpc"
  description = "Policy for Lambda to access VPC resources"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_vpc.json

  tags = { Name = "${local.fqn}-lambda-vpc" }
}

# Lambda logging policy(共通)
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",  # ロググループを作成するために必要
      "logs:CreateLogStream", # ログストリームを作成するために必要
      "logs:PutLogEvents",    # ログイベントを記録するために必要
    ]

    resources = ["arn:aws:logs:*:*:*"] # 全てのリージョン、全てのアカウントのCloudWatchログリソースに適用。
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "${local.fqn}-lambda-logging"
  description = "Policy for Lambda to write logs"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}