locals {
  name_prefix = "${var.project_name}-${var.env}"
  tags = {
    Project = var.project_name
    Env     = var.env
    Owner   = "you"
  }
}


module "vpc" {
  source          = "../../modules/vpc"
  name_prefix     = local.name_prefix
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  enable_nat      = var.enable_nat
  tags            = local.tags
}


module "eks" {
  source              = "../../modules/eks"
  name_prefix         = local.name_prefix
  eks_version         = var.eks_version
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  use_public_nodes    = var.use_public_nodes
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  upgrade_policy      = { support_type = "STANDARD" }
  tags                = local.tags

}



# 让 k8s/helm provider 能连上 EKS
data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}
data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}



# （Optional） ECR 
resource "aws_ecr_repository" "app" {
  count = var.create_ecr ? 1 : 0
  name  = var.ecr_repo_name
  image_scanning_configuration { scan_on_push = true }
  tags = local.tags
}


module "gha_oidc_ecr" {
  source      = "../../modules/gha-oidc-ecr"
  name_prefix = local.name_prefix
  tags        = local.tags

  github_org  = "DaqulaLin"
  github_repo = "aws-eks-devops-blueprint"

  # 复用既有 Provider：把 ARN 传进来（
  oidc_provider_arn = var.oidc_provider_arn

}

