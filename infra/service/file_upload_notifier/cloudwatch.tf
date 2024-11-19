resource "aws_cloudwatch_log_group" "lambda_sol_file_upload_notifier" {
  name              = "/aws/lambda/${aws_lambda_function.sol_file_upload_notifier.function_name}"
  retention_in_days = var.log_retention_in_days

  tags = { Name = "${local.fqn}-file-upload-notifier" }
}
