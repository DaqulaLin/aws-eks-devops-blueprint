# EKS Cluster
resource "aws_eks_cluster" "this" {
  name    = "${var.name_prefix}-eks"
  version = var.eks_version

  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }
  upgrade_policy {
    support_type = upper(var.upgrade_policy.support_type) # 默认 STANDARD
  }
  tags = var.tags
}

# Cluster Role
resource "aws_iam_role" "eks_cluster" {
  name               = "${var.name_prefix}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}
data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# NodeGroup Role
resource "aws_iam_role" "nodegroup" {
  name               = "${var.name_prefix}-nodegroup-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}
data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}




locals {
  lt_user_data = <<-EOT
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="==BOUNDARY=="

    --==BOUNDARY==
    Content-Type: text/x-shellscript; charset="us-ascii"

    #!/bin/bash
    /etc/eks/bootstrap.sh ${aws_eks_cluster.this.name} \
      --use-max-pods true \
      --cni-prefix-delegation-enabled ${var.enable_prefix_delegation}
    --==BOUNDARY==--
  EOT
}
  
resource "aws_launch_template" "ng" {
  name_prefix             = "${var.name_prefix}-ng-"
  update_default_version  = true
  user_data = base64encode(local.lt_user_data)   # 关键：multi-part + base64
}


# Managed Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-ng"
  node_role_arn   = aws_iam_role.nodegroup.arn
  subnet_ids      = var.use_public_nodes ? var.public_subnet_ids : var.private_subnet_ids
  capacity_type   = "ON_DEMAND" # 后面 Day12 做成 MIXED/Spot
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }
  launch_template {
    id      = aws_launch_template.ng.id
    version = "$Latest"
  }
  force_update_version = true
  update_config { max_unavailable = 1 }

  tags = merge(
    var.tags,
    {
       "k8s.io/cluster-autoscaler/enabled"                       = "true"
       "k8s.io/cluster-autoscaler/${aws_eks_cluster.this.name}"  = "owned"
    }
  )    

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_eks_cluster.this
  ]
}

# OIDC Provider（IRSA 前提）
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}
