# NOTE:
# AWSのEC2インスタンスで使用されるIAMロール、ポリシー、インスタンスプロファイルを設定
# EC2インスタンスに静的なアクセスキーを保存せず、SSMを通じてEC2インスタンスにセキュアにアクセスするために必要

# 踏み台サーバ向けインスタンスプロファイルの設定(IAMロールをEC2インスタンスに関連付ける際のコンテナのようなもの)
resource "aws_iam_instance_profile" "bastion" {
  name = "${local.fqn}-bastion"
  role = aws_iam_role.bastion.name

  tags = { Name = "${local.fqn}-bastion-profile" }
}

# SSMポリシーを踏み台サーバ向けIAMロールにアタッチ
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# 踏み台サーバ向けIAMロールの設定
resource "aws_iam_role" "bastion" {
  name               = "${local.fqn}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json

  tags = { Name = "${local.fqn}-bastion-role" }
}

# SSMポリシードキュメントの設定
data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
