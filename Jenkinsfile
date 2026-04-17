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
                    sh 'docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD'
                }
            }
        }

        stage('Start MongoDB') {
            steps {
                // Create an isolated network and start MongoDB (mirrors docker-compose)
                sh "docker network create ${NETWORK_NAME}"
                sh """
                    docker run -d \
                        --name ${MONGO_CONTAINER} \
                        --network ${NETWORK_NAME} \
                        -p 27017 \
                        mongo:latest \
                        --storageEngine=wiredTiger
                """
                // Wait for MongoDB to be ready
                sh """
                    for i in \$(seq 1 30); do
                        if docker exec ${MONGO_CONTAINER} mongosh --eval 'db.runCommand("ping").ok' --quiet; then
                            echo "MongoDB is ready"
                            break
                        fi
                        echo "Waiting for MongoDB... (\$i/30)"
                        sleep 2
                    done
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE} -f Dockerfile ."
            }
        }

        stage('Run Tests') {
            steps {
                sh """
                    docker run --rm \
                        --network ${NETWORK_NAME} \
                        -e CI=true \
                        -e DATABASE_URL=${DATABASE_URL} \
                        -e PAYLOAD_SECRET=${PAYLOAD_SECRET} \
                        ${DOCKER_IMAGE} \
                        npm run test:int
                """
            }
        }
    }

    post {
        always {
            // Clean up MongoDB container and network
            sh "docker rm -f ${MONGO_CONTAINER} || true"
            sh "docker network rm ${NETWORK_NAME} || true"
        }
    }
}