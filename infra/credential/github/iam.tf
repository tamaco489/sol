resource "aws_iam_role" "github_actions_oidc" {
  name               = "${local.fqn}-github-actions-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_oidc_assume_role.json

  tags = { Name = "${local.fqn}-github-actions-oidc-role" }
}

data "aws_iam_policy_document" "github_actions_oidc_assume_role" {
  statement {
    sid     = "GithubActionsOIDCAssumeRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.github_actions_oidc_provider_arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_actions_repo}:*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_oidc" {
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
