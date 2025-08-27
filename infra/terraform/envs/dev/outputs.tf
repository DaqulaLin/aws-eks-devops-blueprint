
output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_oidc_issuer" { value = module.eks.oidc_issuer }
output "nodegroup_name" { value = module.eks.nodegroup_name }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "ecr_repo_url" { value = try(aws_ecr_repository.app[0].repository_url, null) }
