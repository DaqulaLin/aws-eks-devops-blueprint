variable "cluster_name" {}
variable "oidc_issuer" {}
variable "namespace" { default = "ci" }
variable "service_account_name" { default = "gitlab-runner" }


# ECR 最小权限相关
variable "aws_region"             { 
  type = string
  default = "us-east-1" 
}
variable "ecr_repository_name"    { 
  type = string
  default = "myapp"  
}
variable "scope_to_repo"          { 
  type = bool
  default = true 
}  # true=只授予单仓库