variable "cluster_name"       { type = string }
variable "k8s_version"        { type = string } # 用于选 add-on 版本，可选
variable "oidc_issuer"    { type = string } # 形如 https://oidc.eks.<region>.amazonaws.com/id/XXXX
variable "tags"               { 
  type = map(string) 
  default = {} 
  }