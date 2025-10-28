# Kubernetes Deployment Guide

Deploy the NCAA Football Viewer application to your EKS cluster.

## Architecture

```
Internet
   │
   ▼
AWS Load Balancer (NLB)
   │
   ▼
┌──────────────────────────────────────┐
│    Kubernetes Cluster (EKS)          │
│                                      │
│  ┌────────────────┐                 │
│  │ Football Viewer│                 │
│  │  (Flask)       │──────┐          │
│  │  Port: 5000    │      │          │
│  └────────────────┘      │          │
│         │                │          │
│         │                │          │
│         ▼                ▼          │
│  ┌────────────────┐  ┌─────────┐   │
│  │   NCAA API     │  │ Secret  │   │
│  │  (Node.js)     │  │         │   │
│  │  Port: 3000    │  └─────────┘   │
│  └────────────────┘                 │
│                                      │
│  Namespace: scenario-lab             │
└──────────────────────────────────────┘
```

## Prerequisites

- EKS cluster running (see [infra/README.md](../infra/README.md))
- kubectl configured to access your cluster
- AWS CLI with SSO configured
- Podman installed (for multi-arch builds)

## Quick Start

### 1. Login to AWS SSO

```bash
aws sso login --profile dd-ese
```

### 2. Update kubeconfig

```bash
# Replace with your cluster name
export CLUSTER_NAME="your-cluster-name"

aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region us-west-2 \
  --profile dd-ese

# Verify connection
kubectl get nodes
```

### 3. Build and Push Container Image

```bash
# Verify Podman is installed
podman --version

# Build and push to ECR
cd /Users/collin.woo/projects/scenario-lab
./scripts/build-and-push.sh
```

This will:
- Create ECR repository if it doesn't exist
- Build ARM64 image (for t4g instances)
- Push to ECR
- Output the image URL

### 4. Update Deployment with ECR Image

Edit `k8s/app/deployment.yaml` and replace `<YOUR_ECR_REPO>` with your actual ECR repository URL:

```yaml
image: 123456789012.dkr.ecr.us-west-2.amazonaws.com/football-viewer:latest
```

### 5. Deploy to Kubernetes

```bash
./scripts/deploy.sh
```

This will:
- Create the `scenario-lab` namespace
- Deploy NCAA API backend
- Deploy Football Viewer frontend
- Create LoadBalancer service
- Wait for everything to be ready

### 6. Access Your Application

The script will output the LoadBalancer URL. It may take 2-3 minutes for AWS to provision the load balancer.

```bash
# Get the URL
kubectl get svc football-viewer -n scenario-lab

# Example output:
# NAME              TYPE           EXTERNAL-IP
# football-viewer   LoadBalancer   a1b2c3d4...elb.amazonaws.com
```

Visit: `http://<EXTERNAL-IP>`

## Manual Deployment

If you prefer to deploy manually:

### 1. Create Namespace

```bash
kubectl apply -f k8s/base/namespace.yaml
```

### 2. Deploy NCAA API Backend

```bash
kubectl apply -f k8s/base/ncaa-api/
```

### 3. Deploy Football Viewer Frontend

```bash
# Option A: Using kustomize (recommended)
kubectl apply -k k8s/app/

# Option B: Direct apply
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml
```

## Configuration

### NCAA API Secret

The NCAA API key is stored in `k8s/base/ncaa-api/secret.yaml`. Update it if needed:

```yaml
stringData:
  api-key: "your-secure-api-key"
```

Then reapply:

```bash
kubectl apply -f k8s/base/ncaa-api/secret.yaml
kubectl rollout restart deployment/football-viewer -n scenario-lab
```

### Scaling

Scale the number of replicas:

```bash
# Football Viewer
kubectl scale deployment/football-viewer --replicas=3 -n scenario-lab

# NCAA API
kubectl scale deployment/ncaa-api --replicas=3 -n scenario-lab
```

### Resource Limits

Edit resource requests/limits in deployment files:

```yaml
resources:
  requests:
    cpu: 100m      # Minimum CPU
    memory: 256Mi  # Minimum memory
  limits:
    cpu: 500m      # Maximum CPU
    memory: 512Mi  # Maximum memory
```

## Using Ingress (Optional)

Instead of LoadBalancer, you can use an Ingress for:
- Multiple applications on one load balancer
- Path-based routing
- SSL/TLS termination

### Prerequisites

Install AWS Load Balancer Controller:

```bash
# Follow AWS guide:
# https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
```

### Deploy with Ingress

1. **Disable LoadBalancer service**:

Edit `k8s/app/service.yaml` and change `type: LoadBalancer` to `type: ClusterIP`

2. **Enable Ingress**:

Edit `k8s/app/kustomization.yaml` and uncomment the ingress line:

```yaml
resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml  # Uncomment this
```

3. **Apply changes**:

```bash
kubectl apply -k k8s/app/
```

4. **Get Ingress URL**:

```bash
kubectl get ingress -n scenario-lab
```

## Monitoring

### View Logs

```bash
# Football Viewer logs
./scripts/logs.sh football-viewer

# NCAA API logs
./scripts/logs.sh ncaa-api

# All pods in namespace
kubectl logs -n scenario-lab --all-containers=true -l app=football-viewer
```

### Check Pod Status

```bash
kubectl get pods -n scenario-lab
kubectl describe pod <pod-name> -n scenario-lab
```

### Check Service

```bash
kubectl get svc -n scenario-lab
kubectl describe svc football-viewer -n scenario-lab
```

### Port Forward (for debugging)

```bash
# Forward local port to pod
kubectl port-forward deployment/football-viewer 5000:5000 -n scenario-lab

# Access at http://localhost:5000
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n scenario-lab

# Describe pod for events
kubectl describe pod <pod-name> -n scenario-lab

# Check logs
kubectl logs <pod-name> -n scenario-lab
```

### Common issues:

**ImagePullBackOff**:
- Image doesn't exist in ECR
- Missing ECR permissions
- Wrong image name in deployment

**CrashLoopBackOff**:
- Application error (check logs)
- Missing environment variables
- NCAA API not accessible

**ErrImagePull**:
- ECR authentication issue
- Image doesn't exist for ARM64 architecture
- Wrong image URL in deployment manifest

### LoadBalancer not getting external IP

```bash
# Check service events
kubectl describe svc football-viewer -n scenario-lab

# Common causes:
# - AWS service limits
# - VPC/subnet configuration
# - Security group issues
```

### Application can't reach NCAA API

```bash
# Check if NCAA API is running
kubectl get pods -n scenario-lab

# Test DNS resolution from pod
kubectl exec -it deployment/football-viewer -n scenario-lab -- \
  curl http://ncaa-api:3000

# Check service endpoints
kubectl get endpoints -n scenario-lab
```

## Cleanup

### Delete everything

```bash
./scripts/cleanup.sh
```

Or manually:

```bash
kubectl delete namespace scenario-lab
```

### Delete ECR repository

```bash
aws ecr delete-repository \
  --repository-name football-viewer \
  --region us-west-2 \
  --profile dd-ese \
  --force
```

## File Structure

```
k8s/
├── README.md                    # This file
├── app/
│   ├── deployment.yaml         # Football Viewer deployment
│   ├── service.yaml            # LoadBalancer service
│   ├── ingress.yaml            # Optional Ingress
│   └── kustomization.yaml      # Kustomize config
└── base/
    ├── namespace.yaml          # Namespace definition
    └── ncaa-api/
        ├── deployment.yaml     # NCAA API deployment
        ├── service.yaml        # NCAA API service
        └── secret.yaml         # API key secret
```

## Scripts

| Script | Description |
|--------|-------------|
| `build-and-push.sh` | Build Docker image and push to ECR |
| `deploy.sh` | Deploy application to Kubernetes |
| `cleanup.sh` | Delete all Kubernetes resources |
| `logs.sh` | View application logs |

## Security Notes

- Pods run as non-root user (UID 1000)
- Secrets stored in Kubernetes Secrets (base64 encoded)
- Multi-stage container builds for smaller images
- Network policies can be added for enhanced security
- LoadBalancer exposes app to internet (use Ingress + ALB for better control)

## Next Steps

1. ✅ Deploy application
2. ⬜ Set up monitoring (Prometheus/Grafana)
3. ⬜ Configure autoscaling (HPA)
4. ⬜ Add SSL/TLS certificates
5. ⬜ Set up CI/CD pipeline
6. ⬜ Configure custom domain
7. ⬜ Add network policies

## Additional Resources

- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## Support

For issues:
1. Check logs: `./scripts/logs.sh`
2. Check pod status: `kubectl get pods -n scenario-lab`
3. Check events: `kubectl get events -n scenario-lab --sort-by='.lastTimestamp'`
4. Review this troubleshooting guide

