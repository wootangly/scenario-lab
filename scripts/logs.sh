#!/bin/bash

# View application logs
# Usage: ./logs.sh [app-name]

APP=${1:-football-viewer}
NAMESPACE=scenario-lab

echo "=== Streaming logs for $APP ==="
echo "Press Ctrl+C to stop"
echo ""

kubectl logs -f deployment/$APP -n $NAMESPACE --all-containers=true --tail=50

