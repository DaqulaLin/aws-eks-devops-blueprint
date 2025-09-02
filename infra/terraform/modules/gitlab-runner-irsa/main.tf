data "aws_caller_identity" "current" {}

locals {
  oidc_url = trimsuffix(replace(var.oidc_issuer, "https://", ""), "/")
  ecr_repo_arn = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"
}


data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals { 
      type = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_url}"]
    }
    condition {
      test = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
    condition {
      test = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gitlab_runner" {
  name               = "${var.cluster_name}-GitLabRunnerECR"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}



data "aws_iam_policy_document" "ecr_minimal" {
  # 1) 登录令牌：必须 *
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # 2) 推送/获取镜像层 & 镜像清单（可收敛至单仓库）
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = var.scope_to_repo ? [local.ecr_repo_arn] : ["*"]
  }
}

resource "aws_iam_policy" "ecr_minimal" {
  name   = "${var.cluster_name}-GitLabRunnerECR"
  policy = data.aws_iam_policy_document.ecr_minimal.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr" {
  role       = aws_iam_role.gitlab_runner.name
  policy_arn = aws_iam_policy.ecr_minimal.arn
}

