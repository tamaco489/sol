data "aws_ami" "amazonlinux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  # 基本設定
  ami                  = data.aws_ami.amazonlinux_2.id
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  instance_type        = var.instance_type

  # ネットワーク設定
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = data.terraform_remote_state.network.outputs.vpc.private_subnet_ids[0]

  tags = {
    Name = "${local.fqn}-bastion"
  }

  # NOTE: メタデータ IMDSv2（Instance Metadata Service version 2）の設定
  # AWS EC2インスタンスにおいてメタデータとユーザーデータを取得するためのサービス
  # IMDSv2はメタデータの取得にPUTやトークンを指定したGETヘッダーを使用し、セキュアなアクセスを提供する
  metadata_options {
    # メタデータ取得時にトークンを必須にする
    http_tokens = "required"
  }

  lifecycle {
    # AMIに対する変更を無視(構成外のAMIの更新によるインスタンスの再作成を防ぐ)
    ignore_changes = [ami]
  }

  # ユーザデータ設定
  user_data = <<DATA
#cloud-config
disable_root: 1
ssh_pwauth: 0
repo_upgrade: low
runcmd:
  - yum install -y mysql
DATA
}
