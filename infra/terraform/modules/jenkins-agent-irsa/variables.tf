variable "cluster_name" {}
variable "oidc_issuer" {}
variable "namespace" { default = "jenkins" }
variable "service_account_name" { default = "jenkins-agent" }


# ECR 最小权限相关
variable "aws_region"             { 
  type = string
  default = "us-east-1" 
}
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional tags for IAM resources"
}

/* 可选：若你的环境里加 aud 条件会出兼容问题，可以关掉 */
variable "include_aud_condition" {
  type        = bool
  default     = true
  description = "Whether to include the 'aud=sts.amazonaws.com' condition in the trust policy"
}