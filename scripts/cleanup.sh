#!/bin/bash
set -e

# Cleanup Kubernetes resources
# Usage: ./cleanup.sh

echo "=== Cleaning up Kubernetes resources ==="

# Delete namespace (this deletes everything in it)
echo "Deleting scenario-lab namespace and all resources..."
kubectl delete namespace scenario-lab --ignore-not-found

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "To redeploy, run: ./scripts/deploy.sh"

