
data "aws_iam_policy_document" "gha_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_repo}:pull_request"
      ]
    }
  }
}

resource "aws_iam_role" "gha_ecr" {
  name               = "${var.name_prefix}-gha-ecr"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
  tags               = var.tags

}

# ECR push 需要的最小权限
data "aws_iam_policy_document" "gha_ecr" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart",
      "ecr:BatchGetImage", "ecr:DescribeRepositories", "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_ecr" {
  name   = "${var.name_prefix}-gha-ecr-policy"
  policy = data.aws_iam_policy_document.gha_ecr.json
  tags   = var.tags

}

resource "aws_iam_role_policy_attachment" "gha_ecr_attach" {
  role       = aws_iam_role.gha_ecr.name
  policy_arn = aws_iam_policy.gha_ecr.arn
}
