data "aws_caller_identity" "current" {}

# 归一化 OIDC URL，并拼出 SA 的 sub
locals {
  oidc_url = trimsuffix(replace(var.oidc_issuer, "https://", ""), "/")

}


data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
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

resource "aws_iam_role" "this" {
  name               = "${var.cluster_name}-JenkinsAgentECR"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
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
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ecr_minimal" {
  name   = "${var.cluster_name}-JenkinsAgentECR"
  policy = data.aws_iam_policy_document.ecr_minimal.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ecr_minimal.arn
}

