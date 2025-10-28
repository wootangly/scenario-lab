#!/bin/bash
set -e

# Build and Push Container Image to ECR using Podman
# Usage: ./build-and-push.sh [version]

VERSION=${1:-latest}
AWS_REGION=${AWS_REGION:-us-west-2}
AWS_PROFILE=${AWS_PROFILE:-dd-ese}
APP_NAME="football-viewer"

echo "=== Building and Pushing $APP_NAME:$VERSION ==="

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
ECR_REPO="$ECR_REGISTRY/$APP_NAME"

echo "AWS Account: $AWS_ACCOUNT_ID"
echo "ECR Registry: $ECR_REGISTRY"
echo "ECR Repo: $ECR_REPO"

# Check if ECR repository exists, create if not
if ! aws ecr describe-repositories --repository-names $APP_NAME --region $AWS_REGION --profile $AWS_PROFILE &> /dev/null; then
    echo "Creating ECR repository: $APP_NAME"
    aws ecr create-repository \
        --repository-name $APP_NAME \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    echo "ECR repository created successfully"
else
    echo "ECR repository already exists"
fi

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | \
    podman login --username AWS --password-stdin $ECR_REGISTRY

# Build multi-platform image (for ARM64 nodes)
echo "Building container image for ARM64..."
cd app/

# Build the image
podman build \
    --platform linux/arm64 \
    -t $ECR_REPO:$VERSION \
    -t $ECR_REPO:latest \
    .

# Push both tags
echo "Pushing images to ECR..."
podman push $ECR_REPO:$VERSION
podman push $ECR_REPO:latest

echo ""
echo "✅ Successfully built and pushed $APP_NAME:$VERSION"
echo ""
echo "Image pushed to:"
echo "  - $ECR_REPO:$VERSION"
echo "  - $ECR_REPO:latest"
echo ""
echo "Next steps:"
echo "  1. Update k8s/app/deployment.yaml with image: $ECR_REPO:latest"
echo "  2. Run: ./scripts/deploy.sh"

