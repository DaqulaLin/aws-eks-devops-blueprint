# EKS GitOps Platform (Helm + Argo CD) / 基于 EKS 的 GitOps 平台

**TL;DR**
- EKS + Argo CD (App of Apps) + Helm，三环境：**dev / staging / prod**
- CI（Jenkins/GitLab）→ Kaniko 构建 ECR → 回写 `values-*.yaml` → **Argo CD 自动发布**
- 安全：**IRSA + External Secrets**（AWS SM/SSM），密钥不进 Git/镜像
- 可观测：Prometheus/Grafana，NGINX Ingress 限流，Loki/Promtail（可选）
- 渐进式发布（可选 Day11）：**Argo Rollouts + NGINX + Prometheus 自动回滚**

---

## Architecture / 架构
```mermaid
flowchart LR
  Dev[Dev/Staging/Prod Repos] -->|commit & tag| CI[(Jenkins/GitLab CI)]
  CI -->|build (Kaniko)| ECR[(Amazon ECR)]
  CI -->|bump values-*.yaml| Git[Helm Chart Repo]
  Argo[Argo CD] -->|sync| EKS[(EKS Cluster)]
  EKS -->|Ingress| Users[Users]
  EKS -->|metrics/logs| Mon[Prometheus/Grafana & Loki]
  

Features / 特性

GitOps：App-of-Apps 管理 add-ons + apps；每个环境独立 values-*.yaml

CI/CD：Kaniko 无密钥构建，自动回写镜像 tag 触发同步

Security：IRSA 最小权限；External Secrets Operator 同步 SM/SSM 到 K8s Secret

Scalability：HPA + Cluster Autoscaler；NGINX 限流与熔断示例

Progressive Delivery (opt.)：Argo Rollouts（10→30→50 + 自动验收 + 手动 promote/abort）




charts/myapp/                # Helm Chart (app)
  ├─ templates/              # Deployment/Service/Ingress/HPA or Rollout
  ├─ values.yaml             # defaults
  ├─ values-dev.yaml         # dev overrides
  ├─ values-staging.yaml     # staging overrides
  └─ values-prod.yaml        # prod overrides
manifests/argocd/            # Argo CD apps (App of Apps)
manifests/addons/            # prometheus / ingress-nginx / external-secrets / loki ...
.gitlab-ci.yml or Jenkinsfile
