variable "name_prefix" { type = string }
variable "tags" { type = map(string) }
variable "github_org" { type = string }
variable "github_repo" { type = string }
# 传入则复用既有 Provider；为空则（可选）由模块创建
variable "oidc_provider_arn" { type = string }


