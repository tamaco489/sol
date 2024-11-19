output "kms" {
  value = {
    "arn" = aws_kms_key.this.arn
    "id"  = aws_kms_key.this.key_id
  }
}
