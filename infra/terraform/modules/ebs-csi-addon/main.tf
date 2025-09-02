data "aws_caller_identity" "cur" {}

locals {
  oidc_url = trimsuffix(replace(var.oidc_issuer, "https://", ""), "/")
}

# IRSA 角色：绑定 kube-system:ebs-csi-controller-sa
resource "aws_iam_role" "ebs_csi" {
  name               = "${var.cluster_name}-EbsCsiRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.cur.account_id}:oidc-provider/${local.oidc_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
  tags = var.tags
}

# 授权托管策略
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

#（可选）选一个与集群版本匹配的最新 add-on 版本
data "aws_eks_addon_version" "ebs" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.k8s_version
  most_recent        = true
}

# EKS Add-on 资源
resource "aws_eks_addon" "ebs_csi" {
  cluster_name               = var.cluster_name
  addon_name                 = "aws-ebs-csi-driver"
  addon_version              = try(data.aws_eks_addon_version.ebs.version, null)
  service_account_role_arn   = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi
  ]
}
