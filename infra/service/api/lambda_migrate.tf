# NOTE: 初回構築時はECRにコンテナイメージが存在している必要がある。
resource "aws_lambda_function" "api_migrate" {
  function_name = "${local.fqn}-api-migrate"
  description   = "SOL API DB Migrate Lambda function"
  role          = aws_iam_role.api_migrate.arn
  package_type  = "Image"
  image_uri     = "${data.terraform_remote_state.ecr.outputs.api_migrate_ecr.url}:latest"
  timeout       = 60
  memory_size   = 128
  vpc_config {
    security_group_ids = [aws_security_group.sol_api.id]
    subnet_ids         = data.terraform_remote_state.network.outputs.vpc.private_subnet_ids
  }
  lifecycle {
    ignore_changes = [image_uri]
  }
  environment {
    variables = {
      ENV = var.env
    }
  }
}
