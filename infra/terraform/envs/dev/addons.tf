# VPC CNI（可开关）
variable "enable_vpc_cni_addon" {
  type    = bool
  default = true
}
variable "enable_prefix_delegation" {
  type    = bool
  default = false
}
variable "warm_prefix_target" {
  type    = number
  default = 1
}
variable "minimum_ip_target" {
  type    = number
  default = 0
}
variable "external_snat" {
  type    = bool
  default = true
}

locals {
  vpc_cni_env = [
    { name = "ENABLE_PREFIX_DELEGATION", value = var.enable_prefix_delegation ? "true" : "false" },
    { name = "WARM_PREFIX_TARGET", value = tostring(var.warm_prefix_target) },
    { name = "MINIMUM_IP_TARGET", value = tostring(var.minimum_ip_target) },
    { name = "AWS_VPC_K8S_CNI_EXTERNALSNAT", value = var.external_snat ? "true" : "false" },
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  cluster_name = module.eks.cluster_name # 现在你已从模块 outputs 暴露
  addon_name   = "vpc-cni"               # << 必填！关键修复
  # addon_version = "v1.18.1-eksbuild.1"   # 可选：想固定版本再放开

  # 关键修复：env 用 map，而不是 [{name=..., value=...}, ...]
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION     = var.enable_prefix_delegation ? "true" : "false"
      WARM_PREFIX_TARGET           = tostring(var.warm_prefix_target)
      MINIMUM_IP_TARGET            = tostring(var.minimum_ip_target)
      AWS_VPC_K8S_CNI_EXTERNALSNAT = var.external_snat ? "true" : "false"
    }
  })

  # 如有手工安装过 CNI，建议放开以下两行避免冲突
  # resolve_conflicts_on_create = "OVERWRITE"
  # resolve_conflicts_on_update = "OVERWRITE"

  # 防止隐式依赖不生效
  depends_on = [module.eks]
}
