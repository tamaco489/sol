resource "aws_cloudwatch_log_group" "lambda_sol_api" {
  name              = "/aws/lambda/${aws_lambda_function.sol_api.function_name}"
  retention_in_days = var.log_retention_in_days

  tags = { Name = "${local.fqn}-api" }
}
