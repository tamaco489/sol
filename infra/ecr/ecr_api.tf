resource "aws_ecr_repository" "sol_api" {
  name                 = "${local.fqn}-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = "${local.fqn}-api" }
}

# NOTE: ECRのライフサイクルポリシー設定
# セマンティックバージョニングのタグ付きイメージを20世代保持
# タグ付けされていないイメージを1日で削除
# セマンティックバージョニング以外のタグが付いたイメージを30日で削除
resource "aws_ecr_lifecycle_policy" "sol_api" {
  repository = aws_ecr_repository.sol_api.name

  policy = jsonencode(
    {
      "rules" : [
        {
          "rulePriority" : 1,
          "description" : "Keep version tagged 20 images",
          "selection" : {
            "tagStatus" : "tagged",
            "tagPrefixList" : ["v"],
            "countType" : "imageCountMoreThan",
            "countNumber" : 20
          },
          "action" : {
            "type" : "expire"
          }
        },
        {
          "rulePriority" : 2,
          "description" : "Delete untagged images in a day",
          "selection" : {
            "tagStatus" : "untagged",
            "countType" : "sinceImagePushed",
            "countUnit" : "days",
            "countNumber" : 1
          },
          "action" : {
            "type" : "expire"
          }
        },
        {
          "rulePriority" : 3,
          "description" : "Delete other tagged images in 30 days",
          "selection" : {
            "tagStatus" : "any",
            "countType" : "sinceImagePushed",
            "countUnit" : "days",
            "countNumber" : 30
          },
          "action" : {
            "type" : "expire"
          }
        }
      ]
    }
  )
}