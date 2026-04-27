
pipeline {
    agent any

    // options {
    //     timeout(time: 30, unit: 'MINUTES')
    //     buildDiscarder(logRotator(numToKeepStr: '10'))
    //     timestamps()
    // }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'])
        booleanParam(name: 'SKIP_SECURITY_SCAN', defaultValue: false)
    }

    environment {
        // Git (public)
        GIT_REPOSITORY = 'https://github.com/app.git'
        GIT_BRANCH = 'main'

        // App
        APP_NAME = 'test-app'
        ENVIRONMENT = "${params.ENVIRONMENT}"
        VERSION_TAG = "${ENVIRONMENT}-${BUILD_NUMBER}"

        // AWS
        AWS_CREDENTIALS_ID = 'creds'
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '0000'

        AWS_ECR_HOST = "${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com"
        AWS_ECR_REPO = 'gitops-app'
        IMAGE_NAME = "${AWS_ECR_HOST}/${AWS_ECR_REPO}"
        IMAGE_TAG = "${VERSION_TAG}"

        // K8s
        K8S_NAMESPACE = "${ENVIRONMENT}"
    }

    stages {

        stage('clone-repo') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "refs/heads/${GIT_BRANCH}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'CheckoutOption', timeout: 10],
                                [$class: 'CloneOption', noTags: false, shallow: false, depth: 0]],
                    userRemoteConfigs: [[url: "${GIT_REPOSITORY}"]]
                ])
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build \
                      -t ${IMAGE_NAME}:${IMAGE_TAG} \
                      .
                '''
            }
        }

        stage('Security Scan (Trivy)') {
            when {
                expression { return !params.SKIP_SECURITY_SCAN }
            }
            steps {
                sh '''
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format json \
                        --output trivy-report.json \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ECR_HOST}
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Update GitOps Manifest') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh '''
                        git config user.name "Jenkins"
                        git config user.email "jenkins@local"

                        sed -i "s|${IMAGE_NAME}:.*|${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/test-app-${ENVIRONMENT}.yaml

                        git add k8s/test-app-${ENVIRONMENT}.yaml
        
                        git commit -m "update image to ${IMAGE_TAG}" || echo "No changes"

                        # Use username:token to authenticate for push
                        git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@github.com/Benny-17/jenkins-argocd-eks-pipeline.git
                        git push origin HEAD:${GIT_BRANCH}
                    '''
                }
            }
        }
    
    }
    
    post {
    success {
        withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_WEBHOOK_URL')]) {
            sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}\\nEnv: ${ENVIRONMENT}\\nImage: ${IMAGE_NAME}:${IMAGE_TAG}\"}' $SLACK_WEBHOOK_URL"
        }
    }

    failure {
        withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_WEBHOOK_URL')]) {
            sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"FAILED: ${JOB_NAME} #${BUILD_NUMBER}\\nCheck logs: ${BUILD_URL}\"}' $SLACK_WEBHOOK_URL"
        }
    }
}
}
