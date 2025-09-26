pipeline {
    agent { 
        docker { 
            image 'node:18-alpine'
            args '-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker'
        } 
    }
    
    environment {
        HOME = '.'
        DOCKER_IMAGE = "gargkrishna730/aws-devops-assignment:${env.BUILD_NUMBER}"
        KUBE_DEPLOYMENT = "sample-app"
        KUBE_NAMESPACE = "awsdevopsassignment"
        DOCKERHUB_CREDENTIALS = "dockerhub-creds"
        KUBECONFIG_CREDENTIALS = "kubeconfig-creds"
    }

    parameters {
        booleanParam(name: 'ROLLBACK', defaultValue: false, description: 'Trigger rollback to previous deployment')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Unit Test') {
            steps {
                sh '''
                    npm ci --only=production
                    if [ -f package.json ] && grep -q '"test"' package.json; then
                        npm test
                    else
                        echo "No tests found, skipping test stage"
                    fi
                '''
            }
        }

        stage('Docker Build & Push') {
            when {
                not { params.ROLLBACK }
            }
            steps {
                script {
                    // Install Docker if not available
                    sh '''
                        if ! command -v docker &> /dev/null; then
                            apk add --no-cache docker
                        fi
                    '''
                }
                
                withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "Building Docker image: $DOCKER_IMAGE"
                        docker build -t $DOCKER_IMAGE .
                        echo "Logging in to Docker Hub"
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        echo "Pushing Docker image"
                        docker push $DOCKER_IMAGE
                        echo "Cleaning up local image"
                        docker rmi $DOCKER_IMAGE || true
                    '''
                }
            }
        }

        stage('Update Deployment Image') {
            when {
                not { params.ROLLBACK }
            }
            steps {
                script {
                    // Install kubectl if not available
                    sh '''
                        if ! command -v kubectl &> /dev/null; then
                            apk add --no-cache curl
                            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            mv kubectl /usr/local/bin/
                        fi
                    '''
                }
                
                withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG')]) {
                    sh '''
                        echo "Updating deployment image to: $DOCKER_IMAGE"
                        kubectl --kubeconfig=$KUBECONFIG set image deployment/$KUBE_DEPLOYMENT sample-app=$DOCKER_IMAGE -n $KUBE_NAMESPACE
                        
                        echo "Waiting for rollout to complete..."
                        kubectl --kubeconfig=$KUBECONFIG rollout status deployment/$KUBE_DEPLOYMENT -n $KUBE_NAMESPACE --timeout=300s
                    '''
                }
            }
        }

        stage('Rollback') {
            when {
                expression { return params.ROLLBACK }
            }
            steps {
                script {
                    // Install kubectl if not available
                    sh '''
                        if ! command -v kubectl &> /dev/null; then
                            apk add --no-cache curl
                            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            mv kubectl /usr/local/bin/
                        fi
                    '''
                }
                
                withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG')]) {
                    sh '''
                        echo "Rolling back deployment: $KUBE_DEPLOYMENT"
                        kubectl --kubeconfig=$KUBECONFIG rollout undo deployment/$KUBE_DEPLOYMENT -n $KUBE_NAMESPACE
                        
                        echo "Waiting for rollback to complete..."
                        kubectl --kubeconfig=$KUBECONFIG rollout status deployment/$KUBE_DEPLOYMENT -n $KUBE_NAMESPACE --timeout=300s
                    '''
                }
            }
        }
    }

    post {
        always {
            // Clean up Docker images to save space
            sh 'docker system prune -f || true'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}