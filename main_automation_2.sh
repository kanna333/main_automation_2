#!/bin/bash

# ==============================
# Ready-to-run Docker & Kubernetes deploy script
# Usage: ./main_automation.sh <app_name> <version>
# Example: ./main_automation.sh frontend 1.0.0
# ==============================

# Check for parameters
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <app_name> <version>"
    exit 1
fi

# Parameters
APP_NAME=$1
DOCKER_IMAGE_TAG=$2

# Docker Hub username
DOCKER_USER="73333"
DOCKER_IMAGE_NAME="$DOCKER_USER/$APP_NAME"

# Paths to template files
DEPLOYMENT_TEMPLATE="./deployment.yaml"
SERVICE_TEMPLATE="./service.yaml"

# Output files (unique per app)
DEPLOYMENT_YAML="./${APP_NAME}-deployment.yaml"
SERVICE_YAML="./${APP_NAME}-service.yaml"

# Git repo details
GIT_REPO_URL="https://github.com/kanna333/main_automation_2.git"
REPO_NAME="main_automation_2"

# Clone repo if not exists
if [ ! -d "$REPO_NAME" ]; then
    git clone $GIT_REPO_URL
else
    echo "Repo already exists, skipping clone."
fi

# Build & push Docker image
cd $REPO_NAME || { echo "Repo directory not found"; exit 1; }
docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG .
docker push $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
cd ..

# Create app-specific Deployment YAML from template
if [ -f "$DEPLOYMENT_TEMPLATE" ]; then
    sed "s|APP_NAME|$APP_NAME|g; s|DOCKER_IMAGE_TAG|$DOCKER_IMAGE_TAG|g" \
        "$DEPLOYMENT_TEMPLATE" > "$DEPLOYMENT_YAML"
else
    echo "Error: $DEPLOYMENT_TEMPLATE not found!"
    exit 1
fi

# Create app-specific Service YAML from template
if [ -f "$SERVICE_TEMPLATE" ]; then
    sed "s|APP_NAME|$APP_NAME|g" \
        "$SERVICE_TEMPLATE" > "$SERVICE_YAML"
else
    echo "Error: $SERVICE_TEMPLATE not found!"
    exit 1
fi

# Apply Deployment
kubectl apply -f "$DEPLOYMENT_YAML"

# Apply Service
kubectl apply -f "$SERVICE_YAML"

echo "✅ Deployment of $APP_NAME:$DOCKER_IMAGE_TAG completed successfully!"
echo "   - Deployment file: $DEPLOYMENT_YAML"
echo "   - Service file: $SERVICE_YAML"
