# Monitoring with Datadog

Complete guide to monitoring your EKS cluster and applications with Datadog.

## 📊 Overview

This setup provides full-stack observability:
- **Infrastructure**: CPU, memory, disk, network for all nodes
- **Containers**: Resource usage, health status, lifecycle events
- **Kubernetes**: Cluster state, deployments, services, pods
- **Applications**: Performance metrics, traces, logs
- **Network**: Service-to-service communication, latency

## 🚀 Quick Start

### 1. Get Datadog API Key

1. Sign up at https://www.datadoghq.com/ (14-day free trial)
2. Get API key: https://app.datadoghq.com/organization-settings/api-keys
3. Set environment variable:
```bash
export DD_API_KEY="your-api-key-here"
```

### 2. Deploy Datadog Agent

```bash
# One command deployment
./scripts/deploy-datadog.sh
```

### 3. Verify Installation

```bash
# Check pods are running
kubectl get pods -n datadog

# Should see:
# - 1x datadog-cluster-agent (2 replicas for HA)
# - 3x datadog-agent (one per node)
# - 2x datadog-cluster-checks-runner
```

### 4. View Your Data

Open these Datadog pages:
- **Infrastructure Map**: https://app.datadoghq.com/infrastructure/map
- **Containers**: https://app.datadoghq.com/containers
- **Kubernetes**: https://app.datadoghq.com/orchestration/overview
- **Logs**: https://app.datadoghq.com/logs
- **APM**: https://app.datadoghq.com/apm/home

## 📁 Project Structure

```
scenario-lab/
├── k8s/observability/datadog/
│   ├── values.yaml                  # Datadog configuration
│   ├── values-secrets.yaml.example  # Secret template
│   └── README.md                    # Detailed guide
│
├── scripts/
│   └── deploy-datadog.sh           # Deployment script
│
└── infra/
    ├── datadog.tf                  # (Optional) Terraform setup
    └── datadog-variables.tf.example
```

## 🔧 Configuration

### Current Setup

The `values.yaml` is pre-configured for your EKS cluster:

✅ **Cluster Name**: `cwoo-test-env-eks`  
✅ **Logs Collection**: Enabled (all containers)  
✅ **APM**: Enabled (port 8126)  
✅ **Process Monitoring**: Enabled  
✅ **Network Monitoring**: Enabled  
✅ **Kubernetes State**: Enabled  

### Customize Configuration

Edit `k8s/observability/datadog/values.yaml`:

```yaml
datadog:
  site: datadoghq.com         # Change if using EU/US3/US5
  clusterName: your-cluster   # Update for different cluster
  tags:
    - "env:prod"              # Add your tags
```

## 📱 Monitor Your Applications

### Option 1: Basic Monitoring (No Code Changes)

Add labels to your deployments for automatic log collection:

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
        # Auto-configure log collection
        ad.datadoghq.com/football-viewer.logs: '[{"source":"python","service":"football-viewer"}]'
      labels:
        # Unified service tagging
        tags.datadoghq.com/env: "prod"
        tags.datadoghq.com/service: "football-viewer"
        tags.datadoghq.com/version: "1.0"
```

Then redeploy:
```bash
kubectl apply -k k8s/app/
```

### Option 2: Advanced APM (Application Performance Monitoring)

Add Datadog APM library to your Flask app:

**1. Update `app/requirements.txt`:**
```
ddtrace>=2.0.0
```

**2. Update `app/Dockerfile`:**
```dockerfile
# Change the CMD to use ddtrace-run
CMD ["ddtrace-run", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "120", "src.main:app"]
```

**3. Add environment variables to deployment:**
```yaml
# k8s/app/deployment.yaml
env:
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: DD_SERVICE
  value: "football-viewer"
- name: DD_ENV
  value: "prod"
- name: DD_VERSION
  value: "1.0"
- name: DD_LOGS_INJECTION
  value: "true"
- name: DD_TRACE_SAMPLE_RATE
  value: "1"  # 100% sampling for testing
```

**4. Rebuild and deploy:**
```bash
./scripts/build-and-push.sh v1.2
kubectl set image deployment/football-viewer football-viewer=<ECR_URL>:v1.2 -n scenario-lab
```

### Option 3: Custom Metrics

Add custom metrics to your Flask app:

```python
# In app/src/main.py
from datadog import initialize, statsd

# Initialize
initialize(statsd_host=os.getenv('DD_AGENT_HOST'), statsd_port=8125)

# Send custom metrics
@app.route('/')
def index():
    statsd.increment('football.page_views')
    statsd.gauge('football.games_displayed', len(games))
    # ... rest of code
```


