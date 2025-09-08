
data "aws_caller_identity" "current" {}

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
      values = ["system:serviceaccount:${var.namespace}:eso-dev"]
    }
    condition {
      test = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values = ["sts.amazonaws.com"]
    }
  }


}

resource "aws_iam_role" "this" {
  name               = "${var.cluster_name}-ESO-Dev-SSM"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

data "aws_iam_policy_document" "ssm_minimal" {

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }


  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"

    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ssm_minimal" {
  name   = "${var.cluster_name}-ESO-Dev-SSM"
  policy = data.aws_iam_policy_document.ssm_minimal.json
}

resource "aws_iam_role_policy_attachment" "attach_eso_dev_ssm" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ssm_minimal.arn
}

