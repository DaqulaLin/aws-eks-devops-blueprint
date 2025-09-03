pipeline {
  agent {
    kubernetes {
      // 这里的名字要与“Manage Jenkins → Clouds”里那个 Cloud 的名字一致
      cloud 'kubernetes'            // 如果你把 Cloud 重命名成 eks，就写 cloud 'eks'
      // 模板 Name 与 Labels，必须与 Cloud 里的 Pod Template 一致
      inheritFrom 'kaniko-template' // Pod template 的 Name
      //label 'k8s-kaniko'            // Pod template 的 Labels
      defaultContainer 'jnlp'
    }
  }

  stages {
    stage('Hello') {
      steps {
        sh 'echo hello from jnlp'
        container('kaniko') {
          sh 'echo hello from kaniko'
        }
      }
    }
  }
}
