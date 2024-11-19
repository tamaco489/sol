output "api_ecr" {
  value = {
    arn  = aws_ecr_repository.sol_api.arn
    id   = aws_ecr_repository.sol_api.id
    name = aws_ecr_repository.sol_api.name
    url  = aws_ecr_repository.sol_api.repository_url
  }
}

output "api_migrate_ecr" {
  value = {
    arn  = aws_ecr_repository.sol_api_migrate.arn
    id   = aws_ecr_repository.sol_api_migrate.id
    name = aws_ecr_repository.sol_api_migrate.name
    url  = aws_ecr_repository.sol_api_migrate.repository_url
  }
}

output "file_upload_notifier_ecr" {
  value = {
    arn  = aws_ecr_repository.sol_file_upload_notifier.arn
    id   = aws_ecr_repository.sol_file_upload_notifier.id
    name = aws_ecr_repository.sol_file_upload_notifier.name
    url  = aws_ecr_repository.sol_file_upload_notifier.repository_url
  }
}
