pipeline {
    agent {
        label 'docker'
    }

    environment {
        DOCKER_IMAGE    = 'meaza/depi4ops'
        NETWORK_NAME    = "jenkins-depi4ops-${BUILD_NUMBER}"
        MONGO_CONTAINER = "mongo-depi4ops-${BUILD_NUMBER}"
        DATABASE_URL    = "mongodb://${MONGO_CONTAINER}:27017/StarkOps"
        // Generate a random secret key for testing
        PAYLOAD_SECRET  = 'testingsecretkey1234567890'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    bat 'docker login -u %DOCKER_USERNAME% -p %DOCKER_PASSWORD%'
                }
            }
        }

        stage('Start MongoDB') {
            steps {
                // Create an isolated network and start MongoDB (mirrors docker-compose)
                bat "docker network create ${NETWORK_NAME}"
                bat """
                    docker run -d ^
                        --name ${MONGO_CONTAINER} ^
                        --network ${NETWORK_NAME} ^
                        -p 27017 ^
                        mongo:latest ^
                        --storageEngine=wiredTiger
                """
                // Wait for MongoDB to be ready
                bat """
                    for /L %%i in (1,1,30) do (
                        docker exec ${MONGO_CONTAINER} mongosh --eval "db.runCommand('ping').ok" --quiet
                        if not errorlevel 1 (
                            echo MongoDB is ready
                            goto :done
                        )
                        echo Waiting for MongoDB... %%i/30
                        timeout /t 2 /nobreak >nul
                    )
                    :done
                """
            }
        }

        stage('Build Test Image') {
            steps {
                // Build up to the 'builder' stage which has all deps (cross-env, vitest, etc.)
                bat "docker build -t ${DOCKER_IMAGE}:test --target builder -f Dockerfile ."
            }
        }

        stage('Run Tests') {
            steps {
                bat """
                    docker run --rm ^
                        --network ${NETWORK_NAME} ^
                        -e CI=true ^
                        -e DATABASE_URL=${DATABASE_URL} ^
                        -e PAYLOAD_SECRET=${PAYLOAD_SECRET} ^
                        ${DOCKER_IMAGE}:test ^
                        npm run test:int
                """
            }
        }

        stage('Build Production Image') {
            steps {
                bat "docker build -t ${DOCKER_IMAGE} -f Dockerfile ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                bat "docker push ${DOCKER_IMAGE}"
            }
        }

        stage('Artifactory') {
            steps {
                // Create deployment package excluding git files
                powershell "Compress-Archive -Path * -Exclude .git -DestinationPath deploy.zip -Force"
                // Archive the artifact in Jenkins
                archiveArtifacts artifacts: 'deploy.zip', fingerprint: true
            }
        }
    }

    post {
        always {
            // Clean up MongoDB container and network
            bat "docker rm -f ${MONGO_CONTAINER} >nul 2>&1 || exit 0"
            bat "docker network rm ${NETWORK_NAME} >nul 2>&1 || exit 0"
        }
    }
}