# Datadog Cluster Agent Installation

Datadog monitoring setup for the EKS cluster.

## Prerequisites

1. **Datadog Account**: Sign up at https://www.datadoghq.com/
2. **Datadog API Key**: Get from https://app.datadoghq.com/organization-settings/api-keys
3. **Helm 3** installed: `brew install helm`

## Quick Start

### 1. Add Datadog Helm Repository

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update
```

### 2. Create Kubernetes Secret for API Key

```bash
# Set your Datadog API key
export DD_API_KEY="your-datadog-api-key-here"

# Create secret in datadog namespace
kubectl create namespace datadog
kubectl create secret generic datadog-secret \
  --from-literal=api-key=$DD_API_KEY \
  --namespace=datadog
```

### 3. Install Datadog Agent

**Option A: Using our custom values file**

```bash
helm install datadog datadog/datadog \
  --namespace datadog \
  --values values.yaml \
  --set datadog.apiKeyExistingSecret=datadog-secret
```

**Option B: Using command-line values (quick test)**

```bash
helm install datadog datadog/datadog \
  --namespace datadog \
  --set datadog.apiKey=$DD_API_KEY \
  --set datadog.site=datadoghq.com \
  --set datadog.clusterName=cwoo-test-env-eks \
  --set datadog.logs.enabled=true \
  --set datadog.apm.portEnabled=true \
  --set clusterAgent.enabled=true
```

### 4. Verify Installation

```bash
# Check pods
kubectl get pods -n datadog

# Check cluster agent
kubectl get pods -n datadog -l app=datadog-cluster-agent

# Check node agents (should be one per node)
kubectl get daemonset -n datadog

# View logs
kubectl logs -n datadog -l app=datadog -f
```

## Configuration

### Update Cluster Name

Edit `values.yaml`:
```yaml
datadog:
  clusterName: your-cluster-name  # Change this
```

### Update Datadog Site (Region)

If you're not in US1 region:
```yaml
datadog:
  site: us5.datadoghq.com  # or us3, eu, etc.
```

### Enable/Disable Features

```yaml
datadog:
  logs:
    enabled: true          # Log collection
  apm:
    portEnabled: true      # APM traces
  processAgent:
    enabled: true          # Process monitoring
  networkMonitoring:
    enabled: true          # Network performance
```

## Monitoring Your Applications

### Auto-Instrumentation for Flask App

Add labels to your application deployment:

```yaml
# k8s/app/deployment.yaml
metadata:
  labels:
    tags.datadoghq.com/env: "prod"
    tags.datadoghq.com/service: "football-viewer"
    tags.datadoghq.com/version: "1.0"
spec:
  template:
    metadata:
      annotations:
        ad.datadoghq.com/football-viewer.logs: '[{"source":"python","service":"football-viewer"}]'
      labels:
        tags.datadoghq.com/env: "prod"
        tags.datadoghq.com/service: "football-viewer"
        tags.datadoghq.com/version: "1.0"
```

### Add Datadog Python APM to Flask App

1. **Update `requirements.txt`:**
```
ddtrace>=2.0.0
```

2. **Run with ddtrace:**
```dockerfile
# In Dockerfile, change CMD to:
CMD ["ddtrace-run", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "src.main:app"]
```

Or set environment variables in deployment:
```yaml
env:
- name: DD_SERVICE
  value: "football-viewer"
- name: DD_ENV
  value: "prod"
- name: DD_VERSION
  value: "1.0"
- name: DD_LOGS_INJECTION
  value: "true"
- name: DD_TRACE_SAMPLE_RATE
  value: "1"
```

## Upgrade Datadog

```bash
# Pull latest chart
helm repo update

# Upgrade with your values
helm upgrade datadog datadog/datadog \
  --namespace datadog \
  --values values.yaml \
  --set datadog.apiKeyExistingSecret=datadog-secret
```

## Uninstall

```bash
# Remove Datadog
helm uninstall datadog --namespace datadog

# Delete namespace
kubectl delete namespace datadog

# Delete secret
kubectl delete secret datadog-secret --namespace datadog
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n datadog <pod-name>

# Check events
kubectl get events -n datadog --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n datadog <pod-name>
```

### API Key Issues

```bash
# Verify secret exists
kubectl get secret datadog-secret -n datadog

# Check secret content (base64 encoded)
kubectl get secret datadog-secret -n datadog -o yaml
```

### Missing Metrics

1. Check Datadog UI: https://app.datadoghq.com/infrastructure/map
2. Verify cluster name matches: `kubectl get cm -n datadog`
3. Check agent status: `kubectl exec -it -n datadog <agent-pod> -- agent status`

## View in Datadog

After installation, view your cluster at:
- **Infrastructure Map**: https://app.datadoghq.com/infrastructure/map
- **Container Map**: https://app.datadoghq.com/containers
- **Kubernetes Dashboard**: https://app.datadoghq.com/orchestration/overview
- **Logs**: https://app.datadoghq.com/logs
- **APM**: https://app.datadoghq.com/apm/home

## Additional Resources

- [Datadog Helm Chart Documentation](https://github.com/DataDog/helm-charts/tree/main/charts/datadog)
- [Datadog Kubernetes Integration](https://docs.datadoghq.com/containers/kubernetes/)
- [Datadog Python APM](https://docs.datadoghq.com/tracing/setup_overview/setup/python/)
- [Datadog Log Collection](https://docs.datadoghq.com/logs/log_collection/kubernetes/)

