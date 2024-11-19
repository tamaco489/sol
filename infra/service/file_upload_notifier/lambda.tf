# NOTE: 初回構築時はECRにコンテナイメージが存在している必要がある。
resource "aws_lambda_function" "sol_file_upload_notifier" {
  function_name = "${local.fqn}-file-upload-notifier" // NOTE: e.g stg-sol-file-upload-notifier
  description   = "SOL File Upload Notifier Lambda function"
  role          = aws_iam_role.file_upload_notifier.arn
  package_type  = "Image"
  image_uri     = "${data.terraform_remote_state.ecr.outputs.file_upload_notifier_ecr.url}:latest"
  timeout       = 60
  memory_size   = 256

  vpc_config {
    security_group_ids = [aws_security_group.sol_file_upload_notifier.id]
    subnet_ids         = data.terraform_remote_state.network.outputs.vpc.private_subnet_ids
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      ENV          = var.env
      SERVICE_NAME = "${var.product}-file-upload-notifier"
    }
  }

  tags = {
    Name = "${local.fqn}-sol-file-upload-notifier",
  }
}

# S3からLambdaへのアクセス許可
resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sol_file_upload_notifier.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.terraform_remote_state.s3.outputs.image.arn
}

resource "aws_s3_bucket_notification" "file_upload_notifier" {
  bucket = data.terraform_remote_state.s3.outputs.image.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.sol_file_upload_notifier.arn
    events              = ["s3:ObjectCreated:*"]
  }
}
