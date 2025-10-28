# Observability Stack

Monitoring and observability tools for the EKS cluster.

## Components

### Datadog (Recommended)

Full-stack observability platform with infrastructure monitoring, APM, logs, and more.

**Location**: `datadog/`

**Features**:
- Infrastructure & container monitoring
- Application Performance Monitoring (APM)
- Log management & analytics
- Network Performance Monitoring
- Kubernetes monitoring & orchestrator explorer
- Custom metrics & alerting

**Setup**: See [datadog/README.md](datadog/README.md)

**Quick Start**:
```bash
# Set API key
export DD_API_KEY="your-key-here"

# Deploy
../../../scripts/deploy-datadog.sh
```

## Folder Structure

```
observability/
├── README.md              # This file
└── datadog/              # Datadog cluster agent
    ├── values.yaml       # Helm configuration
    ├── values-secrets.yaml.example
    └── README.md
```

## Best Practices

1. **Use Namespaces**: Keep monitoring tools in separate namespace (e.g., `datadog`, `monitoring`)
2. **Resource Limits**: Set appropriate CPU/memory limits
3. **High Availability**: Run multiple replicas of critical components
4. **Secure Secrets**: Never commit API keys; use Kubernetes secrets or AWS Secrets Manager
5. **Tag Everything**: Use consistent tagging for better organization
6. **Monitor Data Volume**: Track ingestion volume for logs, metrics, and spans

## Monitoring Your Applications

### Add Labels to Deployments

```yaml
metadata:
  labels:
    tags.datadoghq.com/env: "prod"
    tags.datadoghq.com/service: "football-viewer"
    tags.datadoghq.com/version: "1.0"
```

### Add Log Annotations

```yaml
metadata:
  annotations:
    ad.datadoghq.com/football-viewer.logs: '[{"source":"python","service":"football-viewer"}]'
```

### Environment Variables for APM

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
```

## Useful Links

- [Datadog Documentation](https://docs.datadoghq.com/)
- [Kubernetes Monitoring Guide](https://docs.datadoghq.com/containers/kubernetes/)
- [Datadog Helm Chart](https://github.com/DataDog/helm-charts)
- [Python APM Setup](https://docs.datadoghq.com/tracing/setup_overview/setup/python/)

