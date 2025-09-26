pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS' // This requires NodeJS plugin and configured tool in Jenkins
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

        stage('Setup Tools') {
            steps {
                script {
                    // Check and install Node.js without sudo
                    sh '''
                        echo "Checking Node.js installation..."
                        if command -v node &> /dev/null; then
                            echo "Node.js found: $(node --version)"
                            echo "NPM found: $(npm --version)"
                        else
                            echo "Node.js not found. Installing via NodeSource..."
                            # Download and install Node.js without sudo
                            curl -fsSL https://nodejs.org/dist/v18.19.0/node-v18.19.0-linux-x64.tar.xz -o node.tar.xz
                            tar -xf node.tar.xz
                            export PATH=$PWD/node-v18.19.0-linux-x64/bin:$PATH
                            echo "Node.js installed: $(node --version)"
                        fi
                    '''
                    
                    // Install kubectl without sudo
                    sh '''
                        echo "Installing kubectl..."
                        if ! command -v kubectl &> /dev/null; then
                            curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            export PATH=$PWD:$PATH
                            echo "kubectl installed: $(./kubectl version --client --short 2>/dev/null || echo 'kubectl ready')"
                        else
                            echo "kubectl already available: $(kubectl version --client --short 2>/dev/null || echo 'kubectl ready')"
                        fi
                    '''
                }
            }
        }

        stage('Build & Unit Test') {
            steps {
                script {
                    // Set PATH to include local Node.js installation
                    sh '''
                        export PATH=$PWD/node-v18.19.0-linux-x64/bin:$PATH
                        
                        echo "Node version: $(node --version)"
                        echo "NPM version: $(npm --version)"
                        
                        if [ -f package.json ]; then
                            echo "Installing dependencies..."
                            npm ci --only=production || npm install --only=production
                            
                            if grep -q '"test"' package.json; then
                                echo "Running tests..."
                                npm test
                            else
                                echo "No tests found in package.json, skipping test stage"
                            fi
                        else
                            echo "No package.json found, skipping npm steps"
                        fi
                    '''
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                not { 
                    expression { 
                        return params.ROLLBACK == true 
                    }
                }
            }
            steps {
                script {
                    // Use Docker if available, otherwise skip
                    def dockerAvailable = sh(script: 'command -v docker', returnStatus: true) == 0
                    
                    if (dockerAvailable) {
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
                    } else {
                        echo "Docker not available in this environment. Skipping Docker build."
                        echo "Please ensure Docker is installed and accessible to Jenkins."
                        error("Docker not available")
                    }
                }
            }
        }

        stage('Update Deployment Image') {
            when {
                not { 
                    expression { 
                        return params.ROLLBACK == true 
                    }
                }
            }
            steps {
                withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG')]) {
                    sh '''
                        # Use local kubectl if installed in previous stage
                        KUBECTL_CMD="kubectl"
                        if [ -f ./kubectl ]; then
                            KUBECTL_CMD="./kubectl"
                            export PATH=$PWD:$PATH
                        fi
                        
                        echo "Using kubectl: $KUBECTL_CMD"
                        echo "Updating deployment image to: $DOCKER_IMAGE"
                        $KUBECTL_CMD --kubeconfig=$KUBECONFIG set image deployment/$KUBE_DEPLOYMENT sample-app=$DOCKER_IMAGE -n $KUBE_NAMESPACE
                        
                        echo "Waiting for rollout to complete..."
                        $KUBECTL_CMD --kubeconfig=$KUBECONFIG rollout status deployment/$KUBE_DEPLOYMENT -n $KUBE_NAMESPACE --timeout=300s
                    '''
                }
            }
        }

        stage('Rollback') {
            when {
                expression { 
                    return params.ROLLBACK == true 
                }
            }
            steps {
                withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG')]) {
                    sh '''
                        # Use local kubectl if installed in previous stage
                        KUBECTL_CMD="kubectl"
                        if [ -f ./kubectl ]; then
                            KUBECTL_CMD="./kubectl"
                            export PATH=$PWD:$PATH
                        fi
                        
                        echo "Using kubectl: $KUBECTL_CMD"
                        echo "Rolling back deployment: $KUBE_DEPLOYMENT"
                        $KUBECTL_CMD --kubeconfig=$KUBECONFIG rollout undo deployment/$KUBE_DEPLOYMENT -n $KUBE_NAMESPACE
                        
                        echo "Waiting for rollback to complete..."
                        $KUBECTL_CMD --kubeconfig=$KUBECONFIG rollout status deployment/$KUBE_DEPLOYMENT -n $KUBE_NAMESPACE --timeout=300s
                    '''
                }
            }
        }
    }

    post {
        always {
            // Only clean Docker if it's available
            script {
                def dockerAvailable = sh(script: 'command -v docker', returnStatus: true) == 0
                if (dockerAvailable) {
                    sh 'docker system prune -f || true'
                    sh 'docker logout || true'
                } else {
                    echo 'Docker not available, skipping cleanup'
                }
            }
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}