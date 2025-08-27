安全销毁建议（避免遗留收费）

卸载 Helm release

helm -n ingress-nginx uninstall ingress-nginx
helm -n kube-system  uninstall metrics-server


确认没有 LoadBalancer Service

kubectl get svc -A | Select-String LoadBalancer


再执行

terraform destroy