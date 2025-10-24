# EKS (3-node) with Terraform

A Terraform configuration to deploy a production-ready Amazon EKS cluster with 3 worker nodes running on AWS Graviton (ARM) processors.

## Architecture

- **VPC**: Custom VPC with public/private subnets across 3 availability zones
- **EKS Cluster**: Kubernetes 1.30 with IRSA (IAM Roles for Service Accounts) enabled
- **Node Group**: 3x t4g.medium instances (ARM-based AWS Graviton2)
- **AMI Type**: Amazon Linux 2 ARM (AL2_ARM_64)
- **Access Management**: EKS Access Entries API (v20+ feature) for admin permissions

## Prerequisites

- Terraform >= 1.6
- AWS CLI v2
- kubectl installed
- AWS SSO access (recommended) or IAM user credentials

## ⚠️ Important: Authentication Method

**Use AWS SSO for Terraform operations.** EKS cluster creation takes 15+ minutes, and temporary credentials in `~/.aws/credentials` will expire during deployment, causing failures. SSO credentials auto-refresh and are designed for long-running operations.

See [SSO_SETUP.md](SSO_SETUP.md) for detailed SSO configuration instructions.

## Setup

### Step 1: Configure AWS SSO

```bash
aws configure sso
```

Follow the prompts:
- **SSO session name**: `dd-sso` (or your preference)
- **SSO start URL**: Your organization's AWS SSO portal URL (e.g., `https://d-xxxxxxxxx.awsapps.com/start`)
- **SSO Region**: Region where SSO is configured (e.g., `us-east-1`)
- **SSO registration scopes**: Press Enter (default: `sso:account:access`)
- **Account**: Select your AWS account from the list
- **Role**: Select the role (e.g., `account-admin`)
- **CLI default client Region**: `us-west-2` (match your Terraform region)
- **CLI default output format**: `json` (or press Enter)
- **Profile name**: `dd-ese` (or your preference)

### Step 2: Verify SSO Configuration

```bash
# Login to SSO
aws sso login --profile dd-ese

# Verify credentials work
aws sts get-caller-identity --profile dd-ese
```

You should see your account ID and role ARN.

### Step 3: Configure Terraform

#### Copy Example Files

```bash
cd infra

# Copy example files
cp variables.tf.example variables.tf
cp terraform.tfvars.example terraform.tfvars
```

#### Edit Configuration Files

**variables.tf**: Update default tags with your project/team info

```hcl
variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    project = "your-project-name"
    creator = "your-name"
    team    = "your-team"
  }
}
```

**terraform.tfvars**: Set your AWS profile and cluster settings

```hcl
region             = "us-west-2"
aws_profile        = "dd-ese"  # Your SSO profile name
cluster_name       = "your-cluster-name"
kubernetes_version = "1.30"

# Optional: Customize instance types and scaling
node_instance_types = ["t4g.medium"]  # ARM instances (or t3.medium for x86)
ng_desired_size     = 3
ng_min_size         = 3
ng_max_size         = 5
```

## Deploy

### 1. Authenticate with SSO

```bash
# Login to SSO (opens browser)
aws sso login --profile dd-ese

# Verify authentication
aws sts get-caller-identity --profile dd-ese
```

### 2. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure (takes ~15 minutes)
terraform apply
```

The deployment will create:
- VPC with public/private subnets across 3 AZs
- NAT Gateway and Internet Gateway
- EKS control plane
- Managed node group with 3 t4g.medium instances
- Security groups and IAM roles
- KMS key for encryption

### 3. Configure kubectl

```bash
# Update kubeconfig to connect to your cluster
aws eks update-kubeconfig --name your-cluster-name --region us-west-2 --profile dd-ese

# Verify connection
kubectl get nodes
kubectl get pods -A
```

You should see 3 nodes in a Ready state.

## Outputs

After successful deployment, Terraform will output:

- `cluster_endpoint`: EKS API server endpoint
- `cluster_name`: Name of the EKS cluster
- `cluster_certificate_authority_data`: CA certificate (sensitive)
- `nodegroup_arn`: ARN of the managed node group
- `update_kubeconfig_command`: Command to configure kubectl

## Instance Types & Architecture

This configuration uses **t4g.medium** instances, which are ARM-based AWS Graviton2 processors.

### Benefits of ARM (Graviton):
- ✅ Better price/performance ratio (~20% cost savings)
- ✅ Better energy efficiency
- ✅ Compatible with most containerized workloads

### To Switch to x86 Instances:

**1. Update `variables.tf`:**
```hcl
variable "node_instance_types" {
  default = ["t3.medium"]  # or t3a.medium, t3.large, etc.
}
```

**2. Update `eks.tf`:**
```hcl
ami_type = "AL2_x86_64"  # Instead of AL2_ARM_64
```

## Troubleshooting

### Credential Issues

**Error: "InvalidClientTokenId" or "ExpiredTokenException"**

This means your credentials expired during the Terraform run (common with temporary credentials).

**Solution:**
```bash
# Refresh SSO session
aws sso login --profile dd-ese

# Verify credentials work
aws sts get-caller-identity --profile dd-ese

# Continue Terraform operation
terraform apply
```

**Why this happens:**
- Temporary credentials in `~/.aws/credentials` expire after 1-12 hours
- EKS cluster creation takes 15+ minutes
- If credentials expire mid-operation, Terraform fails
- **Solution**: Use SSO, which auto-refreshes credentials

### State Drift Issues

**Error: "Cluster already exists"**

This happens when Terraform created the cluster but didn't write it to state (due to credential expiration or interruption).

**Solution:**
```bash
# Untaint the cluster resource
terraform untaint 'module.eks.aws_eks_cluster.this[0]'

# Refresh state to sync with AWS
terraform refresh

# Continue with apply
terraform apply
```

### Instance Type Mismatch

**Error: "is not a valid instance type for requested amiType"**

ARM and x86 instances require different AMI types.

**Fix:**
- ARM instances (t4g.*): Use `ami_type = "AL2_ARM_64"`
- x86 instances (t3.*, t3a.*): Use `ami_type = "AL2_x86_64"`

### Permission Errors

**Error: "You are not authorized to perform this operation"**

Your SSO role may lack required permissions.

**Solution:**
- Ensure your SSO role has `AdministratorAccess` or equivalent EKS/VPC permissions
- Contact your AWS administrator to grant necessary permissions
- Required permissions: EC2, EKS, IAM, VPC, KMS, CloudWatch

## Cleanup

To destroy all resources:

```bash
# Ensure you're authenticated
aws sso login --profile dd-ese

# Destroy infrastructure
terraform destroy

# Confirm with: yes
```

**Warning**: This will permanently delete:
- EKS cluster and all workloads
- Node group and EC2 instances
- VPC, subnets, and networking resources
- Security groups and IAM roles

Ensure you've backed up any important data before destroying!

## Files

### Committed to Git
- `eks.tf` - EKS cluster and node group configuration
- `vpc.tf` - VPC, subnets, NAT gateway configuration
- `providers.tf` - AWS, Kubernetes, and Helm provider configuration
- `variables.tf.example` - Example variable definitions
- `terraform.tfvars.example` - Example variable values
- `outputs.tf` - Output definitions
- `versions.tf` - Terraform and provider version constraints
- `README.md` - This file
- `SSO_SETUP.md` - Detailed SSO setup guide

### Ignored by Git (`.gitignore`)
- `variables.tf` - Your actual variable definitions with personal tags
- `terraform.tfvars` - Your actual configuration with profile name
- `terraform.tfstate*` - Terraform state files
- `.terraform/` - Terraform plugins and modules
- `.terraform.lock.hcl` - Provider version lock file

## Security Notes

- **No Credentials in Code**: `variables.tf` and `terraform.tfvars` are gitignored to prevent accidental credential exposure
- **SSO Authentication**: Uses AWS SSO for secure, temporary credential management
- **EKS Access Entries**: Uses modern EKS Access Entries API (v20+ feature) instead of deprecated ConfigMap approach
- **IRSA Enabled**: IAM Roles for Service Accounts enabled for pod-level permissions
- **Encryption**: Secrets encrypted at rest using AWS KMS
- **Network Security**: Private subnets for nodes, security groups with least privilege

## Cost Estimation

Approximate monthly costs (us-west-2 region, 24/7 usage):

| Resource | Cost |
|----------|------|
| EKS Control Plane | ~$73/month |
| 3x t4g.medium nodes (ARM) | ~$75/month |
| NAT Gateway | ~$33/month |
| EBS volumes (60GB total) | ~$6/month |
| Data transfer | ~$5-10/month |
| **Total** | **~$190-200/month** |

### Cost Optimization Tips:

**Development/Testing:**
- Use `t4g.small` or `t4g.micro` instead of `t4g.medium`
- Reduce node count to 1
- Destroy when not in use

**Production:**
- Use Spot instances for non-critical workloads
- Enable cluster autoscaler to scale down during off-hours
- Use AWS Savings Plans for long-term commitments

## SSO vs IAM User Credentials

### SSO (Recommended) ✅
- Credentials auto-refresh during long operations
- More secure (temporary, scoped credentials)
- Required for Terraform operations (EKS creation takes 15+ min)
- Centrally managed by your organization

### IAM User with Access Keys ❌
- Permanent credentials (security risk if leaked)
- Can be used for Terraform (if not temporary)
- Not recommended for production use

### Temporary Credentials (Avoid) ⚠️
- Credentials in `~/.aws/credentials` with `aws_session_token`
- Expire after 1-12 hours
- **Will fail during long Terraform runs**
- Common when using `aws sts assume-role` manually

## Common Workflow

```bash
# 1. Daily workflow - start with SSO login
aws sso login --profile dd-ese

# 2. Make infrastructure changes
vim eks.tf  # or terraform.tfvars

# 3. Preview changes
terraform plan

# 4. Apply changes
terraform apply

# 5. Verify cluster
kubectl get nodes

# 6. Deploy applications
kubectl apply -f your-app.yaml
```

## Migrating Between Accounts

If you need to move the cluster to a different AWS account:

1. **Destroy in old account:**
   ```bash
   # Update terraform.tfvars with old profile
   terraform destroy
   ```

2. **Clean state:**
   ```bash
   rm terraform.tfstate terraform.tfstate.backup
   ```

3. **Deploy to new account:**
   ```bash
   # Update terraform.tfvars with new profile
   terraform init
   terraform apply
   ```

## Additional Resources

- [AWS SSO Configuration Guide](SSO_SETUP.md) - Detailed SSO setup instructions
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/) - AWS official guide
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) - Module documentation
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) - Kubernetes commands
- [AWS Graviton](https://aws.amazon.com/ec2/graviton/) - ARM processor information

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review [SSO_SETUP.md](SSO_SETUP.md) for authentication issues
3. Consult the [EKS module documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
4. Check AWS service health dashboard for regional issues
