output "iam" {
  value = {
    vpc_lambda_policy_arn  = aws_iam_policy.lambda_vpc.arn
    vpc_lambda_policy_id   = aws_iam_policy.lambda_vpc.id
    vpc_lambda_policy_name = aws_iam_policy.lambda_vpc.name

    logging_lambda_policy_arn  = aws_iam_policy.lambda_logging.arn
    logging_lambda_policy_id   = aws_iam_policy.lambda_logging.id
    logging_lambda_policy_name = aws_iam_policy.lambda_logging.name
  }
}