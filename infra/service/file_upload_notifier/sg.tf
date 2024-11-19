resource "aws_security_group" "sol_file_upload_notifier" {
  name        = "${local.fqn}-file-upload-notifier-sg"
  description = "Security group overseeing access control on SOL File Upload Notifier Lambda function"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc.id

  tags = { Name = "${local.fqn}-file-upload-notifier-sg" }
}

resource "aws_security_group_rule" "api_egress" {
  description       = "Allow outbound traffic from SOL File Upload Notifier Lambda function to anywhere"
  security_group_id = aws_security_group.sol_file_upload_notifier.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
