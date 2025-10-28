#!/bin/bash
set -e

# Deploy to Kubernetes
# Usage: ./deploy.sh

AWS_REGION=${AWS_REGION:-us-west-2}
AWS_PROFILE=${AWS_PROFILE:-dd-ese}
CLUSTER_NAME=${CLUSTER_NAME:-$(cd infra && terraform output -raw cluster_name 2>/dev/null || echo "")}

if [ -z "$CLUSTER_NAME" ]; then
    echo "Error: Could not determine cluster name"
    echo "Please set CLUSTER_NAME environment variable or ensure Terraform state exists"
    exit 1
fi

echo "=== Deploying to EKS Cluster: $CLUSTER_NAME ==="

# Update kubeconfig
echo "Updating kubeconfig..."
aws eks update-kubeconfig \
    --name $CLUSTER_NAME \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

# Verify connection
echo "Verifying cluster connection..."
kubectl cluster-info
echo ""

# Create namespace if it doesn't exist
echo "Creating namespace..."
kubectl apply -f k8s/base/namespace.yaml

# Deploy NCAA API backend
echo "Deploying NCAA API backend..."
kubectl apply -f k8s/base/ncaa-api/

# Wait for NCAA API to be ready
echo "Waiting for NCAA API to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/ncaa-api -n scenario-lab

# Deploy Football Viewer frontend
echo "Deploying Football Viewer app..."
kubectl apply -k k8s/app/

# Wait for deployment
echo "Waiting for Football Viewer to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/football-viewer -n scenario-lab

# Get service URL
echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "Resources:"
kubectl get all -n scenario-lab

echo ""
echo "Getting service URL (this may take a few minutes)..."
echo "Waiting for LoadBalancer to be provisioned..."

# Wait for external IP
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc football-viewer -n scenario-lab -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ ! -z "$EXTERNAL_IP" ]; then
        break
    fi
    echo -n "."
    sleep 10
done

echo ""
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "✅ Application is accessible at: http://$EXTERNAL_IP"
else
    echo "⚠️  LoadBalancer is still provisioning. Run this to get the URL when ready:"
    echo "   kubectl get svc football-viewer -n scenario-lab"
fi

echo ""
echo "Useful commands:"
echo "  View logs:     kubectl logs -f deployment/football-viewer -n scenario-lab"
echo "  Get services:  kubectl get svc -n scenario-lab"
echo "  Get pods:      kubectl get pods -n scenario-lab"
echo "  Delete all:    kubectl delete namespace scenario-lab"

