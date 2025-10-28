# NCAA Football Viewer - AWS EKS Deployment

A production-ready NCAA college football game viewer deployed on AWS EKS (Kubernetes).

## 🏗️ Architecture

```
Internet → AWS Load Balancer → EKS Cluster
                                   ├─ Football Viewer (Flask) 
                                   └─ NCAA API (Node.js)
```

- **Frontend**: Flask web application with beautiful responsive UI
- **Backend**: NCAA API service for game data
- **Infrastructure**: AWS EKS on ARM instances (t4g.medium)
- **Deployment**: Kubernetes with auto-healing and scaling

## 📋 Project Structure

```
scenario-lab/
├── app/                    # Flask application
│   ├── src/
│   │   ├── main.py        # Main application
│   │   └── webui/         # Templates and static files
│   ├── Dockerfile         # Multi-stage container build
│   └── requirements.txt   # Python dependencies
│
├── k8s/                   # Kubernetes manifests
│   ├── app/              # Football Viewer deployment
│   ├── base/             # Shared resources (namespace, NCAA API)
│   └── observability/    # Monitoring stack (Datadog)
│
├── infra/                # Terraform infrastructure
│   ├── eks.tf           # EKS cluster configuration
│   ├── vpc.tf           # VPC and networking
│   └── README.md        # Infrastructure guide
│
├── scripts/              # Automation scripts
│   ├── build-and-push.sh # Build and push to ECR
│   ├── deploy.sh         # Deploy to Kubernetes
│   ├── deploy-datadog.sh # Deploy Datadog monitoring
│   ├── cleanup.sh        # Delete resources
│   └── logs.sh           # View logs
│
└── DEPLOYMENT.md         # 👈 START HERE for deployment
```

## 🚀 Quick Start

### Prerequisites

- AWS account with EKS cluster running
- AWS CLI with SSO configured
- kubectl installed
- Podman installed

### Deploy in 5 Steps

```bash
# 1. Login to AWS
aws sso login --profile dd-ese

# 2. Configure kubectl
aws eks update-kubeconfig --name your-cluster-name --region us-west-2 --profile dd-ese

# 3. Build and push Docker image
./scripts/build-and-push.sh

# 4. Update k8s/app/deployment.yaml with your ECR image URL

# 5. Deploy to Kubernetes
./scripts/deploy.sh
```

**📖 For detailed instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)**

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | **Main deployment guide** - Start here! |
| [infra/README.md](infra/README.md) | EKS cluster setup with Terraform |
| [k8s/README.md](k8s/README.md) | Kubernetes deployment details |
| [app/README.md](app/README.md) | Flask application documentation |
| [infra/SSO_SETUP.md](infra/SSO_SETUP.md) | AWS SSO configuration |

## ✨ Features

### Application
- 📅 7-day NCAA football schedule
- 🏈 Live scores and game status
- 📺 TV network information
- 🎨 Beautiful, responsive UI
- 🔄 Auto-refresh capability
- 🏥 Health check endpoints

### Infrastructure
- ☁️ AWS EKS managed Kubernetes
- 💪 ARM-based instances (AWS Graviton2)
- 🔒 Secure with SSO authentication
- 📊 Auto-healing and scaling
- 🌐 Internet-facing LoadBalancer
- 🔐 Secrets management

## 🛠️ Common Commands

```bash
# View logs
./scripts/logs.sh football-viewer

# Get application URL
kubectl get svc football-viewer -n scenario-lab

# Check pod status
kubectl get pods -n scenario-lab

# Scale application
kubectl scale deployment/football-viewer --replicas=3 -n scenario-lab

# Update application
./scripts/build-and-push.sh v1.1
kubectl set image deployment/football-viewer football-viewer=<ECR>/football-viewer:v1.1 -n scenario-lab

# Delete everything
./scripts/cleanup.sh
```

## 🔧 Technology Stack

### Application
- **Flask 3.0**: Python web framework
- **Gunicorn**: Production WSGI server
- **Requests**: HTTP client for NCAA API
- **Jinja2**: Template engine

### Infrastructure
- **AWS EKS**: Managed Kubernetes
- **Terraform**: Infrastructure as code
- **Podman**: Container platform
- **ECR**: Container registry

### Deployment
- **Kubernetes**: Container orchestration
- **Kustomize**: Kubernetes configuration management
- **AWS NLB**: Network load balancer

## 📊 System Requirements

### Development
- Python 3.11+
- Podman 4.0+
- kubectl 1.28+
- Terraform 1.6+
- AWS CLI v2

### Production (AWS)
- EKS 1.30
- 3x t4g.medium instances (ARM64)
- VPC with public/private subnets
- NAT Gateway

## 🔐 Security

### Implemented
✅ Non-root containers  
✅ Resource limits  
✅ Health checks  
✅ Kubernetes secrets  
✅ ECR image scanning  
✅ Multi-stage container builds  
✅ SSO authentication  

### Recommended for Production
- [ ] HTTPS/TLS with ACM
- [ ] Network policies
- [ ] Pod security policies
- [ ] AWS WAF
- [ ] Monitoring/alerting
- [ ] Backup strategy

## 🐛 Troubleshooting

### Pods not starting?
```bash
kubectl describe pod <pod-name> -n scenario-lab
kubectl logs <pod-name> -n scenario-lab
```

### Can't access application?
```bash
# Check LoadBalancer status
kubectl get svc football-viewer -n scenario-lab

# Check events
kubectl get events -n scenario-lab --sort-by='.lastTimestamp'
```

### Application errors?
```bash
# View logs
./scripts/logs.sh football-viewer

# Test NCAA API connectivity
kubectl exec -it deployment/football-viewer -n scenario-lab -- curl http://ncaa-api:3000
```

**For more troubleshooting, see [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting)**

## 📈 Roadmap

- [x] Flask application
- [x] Docker containerization
- [x] Kubernetes manifests
- [x] EKS infrastructure (Terraform)
- [x] Deployment automation
- [x] Monitoring setup (Datadog)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Horizontal Pod Autoscaling
- [ ] Custom domain + SSL/TLS
- [ ] Database integration
- [ ] User authentication

## 🤝 Contributing

1. Make changes to your branch
2. Test locally with `podman build` and `podman run`
3. Deploy to dev environment
4. Create pull request

## 📝 License

See LICENSE file for details.

## 🆘 Support

**Getting Started:**
- Follow [DEPLOYMENT.md](DEPLOYMENT.md) step-by-step
- Review [infra/README.md](infra/README.md) for infrastructure setup
- Check troubleshooting sections in docs

**Common Issues:**
- Credential expiration → See [SSO_SETUP.md](infra/SSO_SETUP.md)
- Pod failures → Check logs with `./scripts/logs.sh`
- Network issues → Verify VPC/security groups in Terraform

## 🎯 Next Steps

1. **First Time?** → Read [DEPLOYMENT.md](DEPLOYMENT.md)
2. **Need EKS Cluster?** → Follow [infra/README.md](infra/README.md)
3. **Ready to Deploy?** → Run `./scripts/deploy.sh`
4. **Having Issues?** → Check troubleshooting guides

---

**Built with ❤️ using AWS EKS, Kubernetes, and Flask**

