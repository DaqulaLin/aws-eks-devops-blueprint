pipeline {
  agent {
    kubernetes {
      label 'k8s-kaniko'
      defaultContainer 'jnlp'
    }
  }

  environment {
    AWS_REGION     = 'us-east-1'
    ACCOUNT_ID     = credentials('aws-account-id') // 可选：若你习惯做成凭据；也可直接写死
    ECR_REGISTRY   = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    ECR_REPOSITORY = 'myapp'
    IMAGE_TAG      = "${env.GIT_COMMIT.take(7)}"
    // 你的 GitLab 仓库（https 方式）
    GIT_HTTP       = "https://gitlab.com/<NAMESPACE>/<REPO>.git"  // ←修改为你的
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Push (Kaniko)') {
      steps {
        container('kaniko') {
          sh '''
          /kaniko/executor \
            --context "$WORKSPACE/apps/myapp" \
            --dockerfile "$WORKSPACE/apps/myapp/Dockerfile" \
            --destination "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" \
            --destination "$ECR_REGISTRY/$ECR_REPOSITORY:jenkins-$IMAGE_TAG" \
            --snapshotMode=redo --use-new-run
          '''
        }
      }
    }

    stage('Bump values-dev & Push') {
      steps {
        container('tools') {
          withCredentials([string(credentialsId: 'git-push-token', variable: 'GIT_PUSH_TOKEN')]) {
            sh '''
            apk add --no-cache git yq

            git config user.email "jenkins@yourcorp.local"
            git config user.name  "jenkins"

            # 更新镜像 tag
            yq -i '.image.tag = env(IMAGE_TAG)' charts/myapp/values-dev.yaml

            git add charts/myapp/values-dev.yaml
            git commit -m "ci(jenkins): bump dev image.tag -> $IMAGE_TAG [skip ci]" || true

            BRANCH="$(git rev-parse --abbrev-ref HEAD)"

            # 用 token 改写 remote 再推送
            git remote set-url origin "https://oauth2:${GIT_PUSH_TOKEN}@${GIT_HTTP#https://}"
            git push origin "HEAD:${BRANCH}"
            '''
          }
        }
      }
    }
  }

  options { timestamps() }
}
