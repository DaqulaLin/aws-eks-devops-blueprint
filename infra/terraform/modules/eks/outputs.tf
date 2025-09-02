output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "oidc_issuer" { value = aws_eks_cluster.this.identity[0].oidc[0].issuer }
output "nodegroup_name" { value = aws_eks_node_group.this.node_group_name }
output "oidc_provider_arn"{ value = aws_iam_openid_connect_provider.this.arn }
output "enable_prefix_delegation" { value = var.enable_prefix_delegation }
output "enable_vpc_cni_addon" { value = var.enable_vpc_cni_addon }