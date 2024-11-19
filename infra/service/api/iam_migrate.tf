# RDS Migration Lambda 実行用
resource "aws_iam_role" "api_migrate" {
  name               = "${local.fqn}-api-migrate"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_assume_role.json

  inline_policy {
    name   = "${local.fqn}-api-migrate-execution"
    policy = data.aws_iam_policy_document.api_migrate.json
  }
}

data "aws_iam_policy_document" "api_migrate" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [aws_secretsmanager_secret.rds.arn]
  }
}

resource "aws_iam_role_policy_attachment" "api_migrate_logs" {
  policy_arn = data.terraform_remote_state.lambda_iam.outputs.iam.logging_lambda_policy_arn
  role       = aws_iam_role.api_migrate.name
}

resource "aws_iam_role_policy_attachment" "api_migrate_vpc" {
  policy_arn = data.terraform_remote_state.lambda_iam.outputs.iam.vpc_lambda_policy_arn
  role       = aws_iam_role.api_migrate.name
}
