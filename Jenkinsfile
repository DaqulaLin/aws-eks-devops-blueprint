pipeline {
  agent {
    kubernetes {
      cloud 'kubernetes' // ←修改为你的
      inheritFrom 'kaniko-template' // ←修改为你的
      //label 'k8s-kaniko'
      defaultContainer 'jnlp'
    }
  }

  environment {
    AWS_REGION     = 'us-east-1'
    ACCOUNT_ID     = credentials('git-push-token') // 可选：若你习惯做成凭据；也可直接写死
    ECR_REGISTRY   = "160885250897.dkr.ecr.us-east-1.amazonaws.com"
    ECR_REPOSITORY = 'myapp'
    IMAGE_TAG      = "${env.GIT_COMMIT.take(7)}"
    // 你的 GitLab 仓库（https 方式）
    GIT_HTTP       = "https://gitlab.com/lintime0223/project-eks.git"  // ←修改为你的
  }

  stages {
    stage('Guard (anti-loop)') {
      steps {
        container('tools') {
          script {
            // 计算是否跳过（1=跳过，0=不跳过）
            env.SKIP_BUILD = (
              sh(returnStatus: true, script: """
                set -eo pipefail
                REPO="\$WORKSPACE"
                git config --global --add safe.directory "\$REPO"
                MSG=\$(git -C "\$REPO" log -1 --pretty=%B    || true)
                AUTHOR=\$(git -C "\$REPO" log -1 --pretty=%ae || true)
                echo "last commit: \$AUTHOR :: \$MSG"
                if echo "\$MSG" | grep -Ei '\\[(skip ci|ci skip)\\]' || echo "\$AUTHOR" | grep -qi '${CI_BOT_EMAIL}'; then
                  exit 0   # 命中条件：应跳过
                else
                  exit 1   # 不跳过
                fi
              """) == 0 ? '1' : '0'
            )
          }
        }
      }
    }
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
              set -euo pipefail
              REPO="$WORKSPACE"

              echo "PWD=$(pwd)"; echo "REPO=$REPO"
              ls -la "$REPO" | head || true

              # 工具
              apk add --no-cache yq

              # 关键修复：允许以 root 操作由 uid=1000 检出的仓库
              git config --global --add safe.directory "$REPO"
              #（更省事也可用：git config --global --add safe.directory '*'）

              # ① 所有 git 都加 -C "$REPO"，强制在仓库根目录操作
              git -C "$REPO" config user.email "jenkins@yourcorp.local"
              git -C "$REPO" config user.name  "jenkins"

              # ② 写入新 tag
              yq -i '.image.tag = env(IMAGE_TAG)' "$REPO/charts/myapp/values-dev.yaml"

              git -C "$REPO" add charts/myapp/values-dev.yaml
              git -C "$REPO" commit -m "ci(jenkins): bump dev image.tag -> ${IMAGE_TAG} [skip ci]" || true

              
              # 计算目标分支名：优先 Jenkins 的 BRANCH_NAME；否则取远端默认分支；再兜底 main
              BR="${BRANCH_NAME:-}"
              if [ -z "$BR" ] || [ "$BR" = "HEAD" ]; then
                BR="$(git -C "$REPO" remote show origin | awk "/HEAD branch/ {print \\$NF}")" || true
              fi
              : "${BR:=main}"
              echo "Will push to branch: ${BR}"

              # ③ 用 token 改远端并推送（写死仓库 URL 最稳）
              git -C "$REPO" remote set-url origin "https://oauth2:${GIT_PUSH_TOKEN}@gitlab.com/lintime0223/project-eks.git"
              git -C "$REPO" push origin HEAD:refs/heads/"$BR"
            '''
          }
          
        }
      }
    }
  }

  //options { timestamps() }
}
