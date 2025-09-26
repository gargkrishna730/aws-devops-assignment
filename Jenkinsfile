pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "gargkrishna730/aws-devops-assignment:${env.BUILD_NUMBER}"
    KUBE_DEPLOYMENT = "sample-app"
    KUBE_NAMESPACE = "awsdevopsassignment"
    DOCKERHUB_CREDENTIALS = "dockerhub-creds"
    KUBECONFIG_CREDENTIALS = "kubeconfig-creds"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Unit Test') {
      steps {
        sh 'npm install'
        sh 'npm test' // assumes you have tests
      }
    }

    stage('Docker Build & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh """
            docker build -t $DOCKER_IMAGE .
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker push $DOCKER_IMAGE
          """
        }
      }
    }

    stage('Update Deployment Image') {
      steps {
        withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG')]) {
          sh """
            kubectl --kubeconfig=$KUBECONFIG set image deployment/$KUBE_DEPLOYMENT sample-app=$DOCKER_IMAGE -n $KUBE_NAMESPACE
          """
        }
      }
    }

    stage('Rollback') {
      when {
        expression { return params.ROLLBACK }
      }
      steps {
        withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG')]) {
          sh """
            kubectl --kubeconfig=$KUBECONFIG rollout undo deployment/$KUBE_DEPLOYMENT -n $KUBE_NAMESPACE
          """
        }
      }
    }
  }

  parameters {
    booleanParam(name: 'ROLLBACK', defaultValue: false, description: 'Trigger rollback to previous deployment')
  }
}