
variable "cluster_name"        { type = string }
variable "oidc_issuer_url"     { type = string } # 形如 https://oidc.eks.us-east-1.amazonaws.com/id/XXXX
variable "namespace"           { 
  type = string  
  default = "kube-system" 
  }
variable "service_account_name"{ 
  type = string  
  default = "cluster-autoscaler" 
  }
