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
  source                   = "../../modules/eks"
  name_prefix              = local.name_prefix
  eks_version              = var.eks_version
  private_subnet_ids       = module.vpc.private_subnet_ids
  public_subnet_ids        = module.vpc.public_subnet_ids
  use_public_nodes         = var.use_public_nodes
  node_instance_types      = var.node_instance_types
  node_desired_size        = var.node_desired_size
  node_min_size            = var.node_min_size
  node_max_size            = var.node_max_size
  upgrade_policy           = { support_type = "STANDARD" }
  enable_prefix_delegation = var.enable_prefix_delegation
  enable_vpc_cni_addon     = var.enable_vpc_cni_addon
  tags                     = local.tags

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


module "ca_irsa" {
  source               = "../../modules/cluster-autoscaler-irsa"
  cluster_name         = module.eks.cluster_name
  oidc_issuer_url      = module.eks.oidc_issuer
  namespace            = "kube-system"
  service_account_name = "cluster-autoscaler"

}


module "gitlab_runner_irsa" {
  source               = "../../modules/gitlab-runner-irsa"
  cluster_name         = module.eks.cluster_name
  oidc_issuer          = module.eks.oidc_issuer
  namespace            = "ci"
  service_account_name = "gitlab-runner"

  aws_region          = "us-east-1"
  ecr_repository_name = "myapp"
  scope_to_repo       = true
}

module "jenkins_agent_irsa" {
  source               = "../../modules/jenkins-agent-irsa"
  cluster_name         = module.eks.cluster_name
  oidc_issuer          = module.eks.oidc_issuer # 形如 https://oidc.eks.us-east-1.amazonaws.com/id/xxxx
  namespace            = "jenkins"
  service_account_name = "jenkins-agent"
  tags                 = var.tags
  # include_aud_condition = true  # 若你之前遇到 aud 兼容问题，可设为 false 试下
}

module "ebs_csi_addon" {
  source       = "../../modules/ebs-csi-addon"
  cluster_name = module.eks.cluster_name    # 你的 EKS 模块输出
  k8s_version  = module.eks.cluster_version # 可选，选个匹配的版本
  oidc_issuer  = module.eks.oidc_issuer     # 你的 EKS 模块输出
  tags         = var.tags
}


module "eso_dev_ssm_irsa" {
  source       = "../../modules/ssm-irsa"
  cluster_name = module.eks.cluster_name
  oidc_issuer  = module.eks.oidc_issuer

}