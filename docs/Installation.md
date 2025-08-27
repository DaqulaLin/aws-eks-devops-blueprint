PowerShell 版命令

先确保你已连上集群：
aws eks update-kubeconfig --region us-east-1 --name <your-cluster>

1) 安装 & 验证 metrics-server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system --create-namespace --set args='{--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP}'
# 如 kubectl top 报证书问题，可加：
#  --set args='{--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP,--kubelet-insecure-tls}'


验证：

kubectl get pods -n kube-system | Select-String metrics-server
kubectl top nodes
kubectl top pods -A


2) 安装 ingress-nginx（NLB + target-type=ip）
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.replicaCount=2 --set controller.metrics.enabled=true --set-string controller.config.use-forwarded-headers=true --set-string controller.config.compute-full-forwarded-for=true --set-string controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb --set-string controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing --set-string controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-nlb-target-type"=ip --set-string controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-cross-zone-enabled"=true

取 NLB 域名（EXTERNAL-IP）：

$ing = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
$ing


3) 创建命名空间与基础 RBAC（从你目录直接 apply）

你的目录已分好了 k8s/namespaces/dev|staging|prod，可以直接：

# 只应用 dev
kubectl apply -f .\k8s\namespaces\dev\

# 递归一把梭（dev/staging/prod 全部）
kubectl apply -R -f .\k8s\namespaces\


4) 部署 echo 应用并打通 Ingress（按你的 kustomize 结构）
kubectl apply -k .\k8s\apps\echo\overlays\dev\






curl.exe "http://$ing/" -H "Host: echo.dev" -I