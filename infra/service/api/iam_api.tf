# Lambda APIで利用する Assume Role Policy
data "aws_iam_policy_document" "lambda_execution_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "sol_api_execution_role" {
  name               = "${local.fqn}-api-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_assume_role.json

  inline_policy {
    name   = "${local.fqn}-api-execution"
    policy = data.aws_iam_policy_document.sol_api.json
  }

  tags = { Name = "${local.fqn}-sol-api" }
}

# DataDog, KMS, S3へのアクセス権限設定
data "aws_iam_policy_document" "sol_api" {
  # AWS Secret Manager, DataDogへのアクセス権限
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:aws:secretsmanager:us-west-2:123456789012:secret:dummy", # TODO: Datadog構築後に正式なパラメータを設定、それまでは一旦ダミーのARNを設定
      aws_secretsmanager_secret.rds.arn,
    ]
  }

  # KMSへのアクセス権限
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [data.aws_kms_key.secretsmanager.arn]
  }

  # S3バケットへのアクセス権限
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${data.terraform_remote_state.s3.outputs.image.arn}/*"]
  }
}


resource "aws_iam_role_policy_attachment" "sol_api_logs" {
  policy_arn = data.terraform_remote_state.lambda_iam.outputs.iam.logging_lambda_policy_arn
  role       = aws_iam_role.sol_api_execution_role.name
}

resource "aws_iam_role_policy_attachment" "sol_api_vpc" {
  policy_arn = data.terraform_remote_state.lambda_iam.outputs.iam.vpc_lambda_policy_arn
  role       = aws_iam_role.sol_api_execution_role.name
}
