# NOTE: 初回構築時はECRにコンテナイメージが存在している必要がある。
resource "aws_lambda_function" "sol_api" {
  function_name = "${local.fqn}-api"
  description   = "SOL API Lambda function"
  role          = aws_iam_role.sol_api_execution_role.arn
  package_type  = "Image"
  image_uri     = "${data.terraform_remote_state.ecr.outputs.api_ecr.url}:latest"
  timeout       = 20
  memory_size   = 256

  vpc_config {
    security_group_ids = [aws_security_group.sol_api.id]
    subnet_ids         = data.terraform_remote_state.network.outputs.vpc.private_subnet_ids
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      API_SERVICE_NAME             = "${var.product}-api"
      API_ENV                      = var.env
      API_PORT                     = "8080"
      GIN_MODE                     = "release"
      AWS_LWA_READINESS_CHECK_PORT = "8080"
      AWS_LWA_READINESS_CHECK_PATH = "/api/healthcheck"
      ALLOW_ORIGIN                 = var.allow_origin
    }
  }

  tags = {
    Name = "${local.fqn}-sol-api",
  }
}

# ALBからLambdaへのアクセス許可
resource "aws_lambda_permission" "alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sol_api.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_alb_target_group.sol_api.arn
}

# ALBのターゲットグループにLambdaをアタッチ
resource "aws_lb_target_group_attachment" "sol_api" {
  target_group_arn = aws_alb_target_group.sol_api.arn
  target_id        = aws_lambda_function.sol_api.arn
}