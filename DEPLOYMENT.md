# 🚀 Deployment Guide - NCAA Football Viewer

Complete guide to deploy your Flask application to AWS EKS.

## Overview

This project deploys a NCAA Football game viewer application with:
- **Frontend**: Flask web app (Python)
- **Backend**: NCAA API service (Node.js)
- **Infrastructure**: AWS EKS cluster on ARM instances (t4g.medium)
- **Kubernetes**: Managed deployments with auto-healing and scaling

## Prerequisites Checklist

- [x] EKS cluster deployed (see [infra/README.md](infra/README.md))
- [ ] AWS CLI configured with SSO
- [ ] kubectl installed
- [ ] Podman installed
- [ ] AWS SSO logged in

## Deployment Steps

### Step 1: Authenticate with AWS

```bash
# Login to AWS SSO
aws sso login --profile dd-ese

# Verify authentication
aws sts get-caller-identity --profile dd-ese
```

### Step 2: Configure kubectl

```bash
# Get your cluster name from Terraform
cd infra
terraform output cluster_name

# Update kubeconfig (replace with your cluster name)
aws eks update-kubeconfig \
  --name your-cluster-name \
  --region us-west-2 \
  --profile dd-ese

# Verify connection
kubectl get nodes
```

You should see 3 nodes in Ready state.

### Step 3: Build and Push Container Image

The app needs to be containerized and pushed to AWS ECR (Elastic Container Registry).

```bash
# Verify Podman is installed
podman --version

# Build for ARM64 and push to ECR
./scripts/build-and-push.sh

# This will:
# 1. Create ECR repository (if needed)
# 2. Build container image for ARM64
# 3. Push to ECR
# 4. Output the image URL
```

**Example output:**
```
✅ Successfully built and pushed football-viewer:latest

Image pushed to:
  - 123456789012.dkr.ecr.us-west-2.amazonaws.com/football-viewer:latest

Next steps:
  1. Update k8s/app/deployment.yaml with image: ...
```

### Step 4: Update Kubernetes Deployment

Edit `k8s/app/deployment.yaml` and replace `<YOUR_ECR_REPO>` with your actual ECR image URL from Step 3:

```yaml
containers:
- name: football-viewer
  image: 123456789012.dkr.ecr.us-west-2.amazonaws.com/football-viewer:latest
```

### Step 5: Deploy to Kubernetes

```bash
# Deploy everything
./scripts/deploy.sh
```

This automated script will:
1. Create the `scenario-lab` namespace
2. Deploy NCAA API backend (2 replicas)
3. Deploy Football Viewer frontend (2 replicas)
4. Create LoadBalancer service
5. Wait for all pods to be ready
6. Display the application URL

**Expected output:**
```
=== Deployment Complete! ===

Resources:
NAME                              READY   STATUS    RESTARTS   AGE
pod/football-viewer-xxx-xxx       1/1     Running   0          2m
pod/ncaa-api-xxx-xxx              1/1     Running   0          2m

NAME                      TYPE           EXTERNAL-IP
service/football-viewer   LoadBalancer   a1b2c3...elb.amazonaws.com

✅ Application is accessible at: http://a1b2c3...elb.amazonaws.com
```

### Step 6: Access Your Application

Visit the LoadBalancer URL from Step 5.

**Note**: It may take 2-3 minutes for the LoadBalancer to be fully provisioned by AWS.

If the URL isn't ready yet:
```bash
# Check status
kubectl get svc football-viewer -n scenario-lab -w

# Once EXTERNAL-IP appears (not <pending>), you're ready!
```

## Verification

### Check Pod Status

```bash
kubectl get pods -n scenario-lab
```

All pods should be `Running` with `READY 1/1`.

### View Logs

```bash
# Football Viewer logs
./scripts/logs.sh football-viewer

# NCAA API logs  
./scripts/logs.sh ncaa-api
```

### Test Application

```bash
# Get the LoadBalancer URL
LOAD_BALANCER=$(kubectl get svc football-viewer -n scenario-lab -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test health endpoint
curl http://$LOAD_BALANCER/health

# Test NCAA API connectivity
curl http://$LOAD_BALANCER/api/ncaa-status

# Visit web UI
open http://$LOAD_BALANCER
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                    Internet                         │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│         AWS Network Load Balancer (NLB)             │
│              Port 80 → 5000                         │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│              AWS EKS Cluster                        │
│         Namespace: scenario-lab                     │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Football Viewer (Flask)                     │  │
│  │  - 2 replicas                                │  │
│  │  - Port 5000                                 │  │
│  │  - ARM64 containers                          │  │
│  │  - Health checks enabled                     │  │
│  └───────────────┬──────────────────────────────┘  │
│                  │                                  │
│                  │ http://ncaa-api:3000             │
│                  │                                  │
│                  ▼                                  │
│  ┌──────────────────────────────────────────────┐  │
│  │  NCAA API (Node.js)                          │  │
│  │  - 2 replicas                                │  │
│  │  - Port 3000                                 │  │
│  │  - ClusterIP service                         │  │
│  │  - Uses API key from Secret                  │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Kubernetes Secrets                          │  │
│  │  - NCAA API key                              │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  Node: t4g.medium (ARM64)                          │
│  Node: t4g.medium (ARM64)                          │
│  Node: t4g.medium (ARM64)                          │
└─────────────────────────────────────────────────────┘
```

## Common Tasks

### Update Application Code

After making changes to the app:

```bash
# 1. Build new image with version tag
./scripts/build-and-push.sh v1.1

# 2. Update deployment to use new version
kubectl set image deployment/football-viewer \
  football-viewer=<ECR_REPO>/football-viewer:v1.1 \
  -n scenario-lab

# 3. Watch rollout
kubectl rollout status deployment/football-viewer -n scenario-lab
```

### Scale Application

```bash
# Scale up
kubectl scale deployment/football-viewer --replicas=5 -n scenario-lab

# Scale down
kubectl scale deployment/football-viewer --replicas=1 -n scenario-lab
```

### Restart Deployment

```bash
# Restart pods (useful after secret changes)
kubectl rollout restart deployment/football-viewer -n scenario-lab
kubectl rollout restart deployment/ncaa-api -n scenario-lab
```

### Update NCAA API Key

```bash
# Edit secret
kubectl edit secret ncaa-api-secret -n scenario-lab

# Or apply updated secret file
kubectl apply -f k8s/base/ncaa-api/secret.yaml

# Restart deployments to use new secret
kubectl rollout restart deployment/ncaa-api -n scenario-lab
kubectl rollout restart deployment/football-viewer -n scenario-lab
```

## Troubleshooting

### Issue: Pods not starting (ImagePullBackOff)

**Cause**: Can't pull image from ECR or wrong architecture

**Solution**:
```bash
# 1. Check if image exists in ECR
aws ecr describe-images \
  --repository-name football-viewer \
  --region us-west-2 \
  --profile dd-ese

# 2. Verify deployment has correct image URL
kubectl get deployment football-viewer -n scenario-lab -o yaml | grep image:

# 3. Check pod events
kubectl describe pod <pod-name> -n scenario-lab
```

### Issue: Pods CrashLoopBackOff

**Cause**: Application error

**Solution**:
```bash
# Check logs
./scripts/logs.sh football-viewer

# Common fixes:
# - NCAA API not reachable (check if ncaa-api pods are running)
# - Missing environment variables
# - Application code errors
```

### Issue: Can't access application (LoadBalancer pending)

**Cause**: LoadBalancer still provisioning

**Solution**:
```bash
# Wait and check status
kubectl get svc football-viewer -n scenario-lab -w

# If stuck for >5 minutes, check events
kubectl describe svc football-viewer -n scenario-lab

# Verify security groups allow traffic
# Verify VPC/subnet configuration in Terraform
```

### Issue: Application shows "NCAA API connection error"

**Cause**: Frontend can't reach backend

**Solution**:
```bash
# 1. Verify NCAA API is running
kubectl get pods -n scenario-lab | grep ncaa-api

# 2. Check NCAA API service exists
kubectl get svc ncaa-api -n scenario-lab

# 3. Test connectivity from frontend pod
kubectl exec -it deployment/football-viewer -n scenario-lab -- \
  curl http://ncaa-api:3000

# 4. Check NCAA API logs
./scripts/logs.sh ncaa-api
```

### Issue: 503 errors or timeouts

**Cause**: Resource limits too low or pods not ready

**Solution**:
```bash
# Check pod resources
kubectl top pods -n scenario-lab

# Check pod status
kubectl get pods -n scenario-lab

# Increase resource limits in deployment.yaml if needed
# Then apply changes:
kubectl apply -k k8s/app/
```

## Cleanup

### Delete Application (Keep Cluster)

```bash
# Delete all resources
./scripts/cleanup.sh

# Or manually
kubectl delete namespace scenario-lab
```

### Delete Everything (Cluster + App)

```bash
# Delete application
./scripts/cleanup.sh

# Delete EKS cluster
cd infra
terraform destroy
```

## Security Best Practices

✅ **Implemented:**
- Pods run as non-root user
- Resource limits defined
- Health checks configured
- Secrets stored in Kubernetes Secrets
- Multi-stage container build (smaller images)
- Image scanning enabled in ECR

⬜ **Recommended for Production:**
- [ ] Enable HTTPS with SSL/TLS certificates
- [ ] Set up network policies
- [ ] Use private ECR scanning
- [ ] Implement pod security policies
- [ ] Enable audit logging
- [ ] Set up monitoring (Prometheus/Grafana)
- [ ] Configure autoscaling (HPA)
- [ ] Use managed secrets (AWS Secrets Manager)

## Next Steps

1. ✅ Deploy application
2. ⬜ Set up custom domain name
3. ⬜ Configure SSL/TLS with ACM
4. ⬜ Set up monitoring and alerts
5. ⬜ Configure horizontal pod autoscaling
6. ⬜ Set up CI/CD pipeline
7. ⬜ Add integration tests

## Quick Reference

| Command | Description |
|---------|-------------|
| `./scripts/build-and-push.sh` | Build and push to ECR |
| `./scripts/deploy.sh` | Deploy to Kubernetes |
| `./scripts/logs.sh <app>` | View application logs |
| `./scripts/cleanup.sh` | Delete all resources |
| `kubectl get pods -n scenario-lab` | List pods |
| `kubectl get svc -n scenario-lab` | List services |
| `kubectl describe pod <name> -n scenario-lab` | Pod details |
| `kubectl port-forward deployment/football-viewer 5000:5000 -n scenario-lab` | Local access |

## Documentation

- [Infrastructure Guide](infra/README.md) - EKS cluster setup
- [Application Guide](app/README.md) - Flask app details
- [Kubernetes Guide](k8s/README.md) - Detailed K8s deployment
- [SSO Setup](infra/SSO_SETUP.md) - AWS SSO configuration

## Support

If you encounter issues:
1. Check the Troubleshooting section above
2. Review logs: `./scripts/logs.sh`
3. Check pod status: `kubectl get pods -n scenario-lab`
4. View events: `kubectl get events -n scenario-lab --sort-by='.lastTimestamp'`

For AWS/EKS issues, see [infra/README.md](infra/README.md)

---

**Happy Deploying! 🚀**

