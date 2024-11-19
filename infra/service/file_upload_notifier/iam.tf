# Lambda 実行 Assume policy (共通)
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

resource "aws_iam_role" "file_upload_notifier" {
  name               = "${local.fqn}-file-upload-notifier"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_assume_role.json

  inline_policy {
    name   = "${local.fqn}-file-upload-notifier"
    policy = data.aws_iam_policy_document.file_upload_notifier.json
  }
}

# DataDog, KMS, S3へのアクセス権限設定
data "aws_iam_policy_document" "file_upload_notifier" {
  # AWS Secret Manager, DataDogへのアクセス権限
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      data.aws_secretsmanager_secret.rds.arn,
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

resource "aws_iam_role_policy_attachment" "file_upload_notifier_logs" {
  role       = aws_iam_role.file_upload_notifier.name
  policy_arn = data.terraform_remote_state.lambda_iam.outputs.iam.logging_lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "file_upload_notifier_vpc" {
  role       = aws_iam_role.file_upload_notifier.name
  policy_arn = data.terraform_remote_state.lambda_iam.outputs.iam.vpc_lambda_policy_arn
}
