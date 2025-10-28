#!/bin/bash
set -e

# Deploy Datadog Cluster Agent
# Usage: ./deploy-datadog.sh

echo "=== Deploying Datadog Cluster Agent ==="

# Check if DD_API_KEY is set
if [ -z "$DD_API_KEY" ]; then
    echo "❌ Error: DD_API_KEY environment variable not set"
    echo ""
    echo "Please set your Datadog API key:"
    echo "  export DD_API_KEY='your-api-key-here'"
    echo ""
    echo "Get your API key from:"
    echo "  https://app.datadoghq.com/organization-settings/api-keys"
    exit 1
fi

# Add Datadog Helm repository
echo "Adding Datadog Helm repository..."
helm repo add datadog https://helm.datadoghq.com
helm repo update

# Create namespace
echo "Creating datadog namespace..."
kubectl create namespace datadog --dry-run=client -o yaml | kubectl apply -f -

# Create or update secret
echo "Creating Datadog secret..."
kubectl create secret generic datadog-secret \
  --from-literal=api-key=$DD_API_KEY \
  --namespace=datadog \
  --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade Datadog
echo "Installing/Upgrading Datadog Agent..."
helm upgrade --install datadog datadog/datadog \
  --namespace datadog \
  --values k8s/observability/datadog/values.yaml \
  --set datadog.apiKeyExistingSecret=datadog-secret \
  --wait \
  --timeout 5m

echo ""
echo "=== Datadog Installation Complete! ==="
echo ""
echo "Check status:"
echo "  kubectl get pods -n datadog"
echo ""
echo "View logs:"
echo "  kubectl logs -n datadog -l app=datadog-cluster-agent"
echo "  kubectl logs -n datadog -l app=datadog"
echo ""
echo "View in Datadog:"
echo "  https://app.datadoghq.com/infrastructure/map"
echo "  https://app.datadoghq.com/containers"
echo ""
echo "To remove Datadog:"
echo "  helm uninstall datadog --namespace datadog"
echo "  kubectl delete namespace datadog"

