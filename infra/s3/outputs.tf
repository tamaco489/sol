output "image" {
  value = {
    id     = aws_s3_bucket.image.id
    arn    = aws_s3_bucket.image.arn
    bucket = aws_s3_bucket.image.bucket
  }
}
