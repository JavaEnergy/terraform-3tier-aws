#!/bin/bash
# Usage: ./build_and_push.sh <primary-ecr-url> <secondary-ecr-url>
# Example:
#   ./build_and_push.sh \
#     123456789.dkr.ecr.us-east-1.amazonaws.com/myapp-dev-primary \
#     123456789.dkr.ecr.us-west-2.amazonaws.com/myapp-dev-secondary

set -e

PRIMARY_ECR=$1
SECONDARY_ECR=$2

if [ -z "$PRIMARY_ECR" ] || [ -z "$SECONDARY_ECR" ]; then
  echo "Usage: $0 <primary-ecr-url> <secondary-ecr-url>"
  echo "Get URLs from: terraform output primary_ecr_url / secondary_ecr_url"
  exit 1
fi

IMAGE_TAG="latest"

echo "==> Building Docker image..."
docker build -t myapp:$IMAGE_TAG .

echo "==> Logging in to ECR (us-east-1)..."
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin "$PRIMARY_ECR"

echo "==> Pushing to primary ECR (us-east-1)..."
docker tag myapp:$IMAGE_TAG "$PRIMARY_ECR:$IMAGE_TAG"
docker push "$PRIMARY_ECR:$IMAGE_TAG"

echo "==> Logging in to ECR (us-west-2)..."
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin "$SECONDARY_ECR"

echo "==> Pushing to secondary ECR (us-west-2)..."
docker tag myapp:$IMAGE_TAG "$SECONDARY_ECR:$IMAGE_TAG"
docker push "$SECONDARY_ECR:$IMAGE_TAG"

echo ""
echo "Done! Now update terraform.tfvars:"
echo "  primary_container_image   = \"$PRIMARY_ECR:$IMAGE_TAG\""
echo "  secondary_container_image = \"$SECONDARY_ECR:$IMAGE_TAG\""
echo ""
echo "Then run: terraform apply"
