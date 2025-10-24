module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.kubernetes_version
  enable_irsa                     = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Grant cluster creator admin access (v20+ uses Access Entries API)
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2_ARM_64"
      instance_types = var.node_instance_types

      min_size     = var.ng_min_size
      max_size     = var.ng_max_size
      desired_size = var.ng_desired_size

      capacity_type = "ON_DEMAND"
      disk_size     = 20

      subnet_ids = module.vpc.private_subnets

      labels = {
        "workload" = "general"
      }

      tags = merge(var.tags, { "Name" = "${var.cluster_name}-mng" })
    }
  }

  tags = var.tags
}

data "aws_caller_identity" "current" {}

