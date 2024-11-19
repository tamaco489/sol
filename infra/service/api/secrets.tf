resource "aws_secretsmanager_secret" "rds" {
  name = "${var.product}/${var.env}/rds-cluster"
}
