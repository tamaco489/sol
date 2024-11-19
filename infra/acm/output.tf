output "acm" {
  value = {
    arn  = aws_acm_certificate.cert.arn
    id   = aws_acm_certificate.cert.id
    name = aws_acm_certificate.cert.domain_name
  }
}
