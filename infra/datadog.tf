# Datadog Cluster Agent - Managed by Terraform
# Alternative to Helm-based deployment in k8s/observability/

# Uncomment to use Terraform-managed Datadog deployment
# You'll need to set DD_API_KEY environment variable or use AWS Secrets Manager

# provider "helm" {
#   kubernetes {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args = [
#         "eks",
#         "get-token",
#         "--cluster-name",
#         module.eks.cluster_name,
#         "--region",
#         var.region,
#         "--profile",
#         var.aws_profile
#       ]
#     }
#   }
# }

# resource "kubernetes_namespace" "datadog" {
#   metadata {
#     name = "datadog"
#     labels = {
#       name = "datadog"
#     }
#   }
# }

# resource "kubernetes_secret" "datadog_api_key" {
#   metadata {
#     name      = "datadog-secret"
#     namespace = kubernetes_namespace.datadog.metadata[0].name
#   }

#   data = {
#     api-key = var.datadog_api_key  # Define this variable
#   }

#   type = "Opaque"
# }

# resource "helm_release" "datadog" {
#   name       = "datadog"
#   repository = "https://helm.datadoghq.com"
#   chart      = "datadog"
#   version    = "3.60.0"  # Check for latest: https://github.com/DataDog/helm-charts
#   namespace  = kubernetes_namespace.datadog.metadata[0].name

#   values = [
#     file("${path.module}/datadog-values.yaml")
#   ]

#   set_sensitive {
#     name  = "datadog.apiKeyExistingSecret"
#     value = kubernetes_secret.datadog_api_key.metadata[0].name
#   }

#   set {
#     name  = "datadog.clusterName"
#     value = var.cluster_name
#   }

#   set {
#     name  = "datadog.site"
#     value = var.datadog_site
#   }

#   depends_on = [
#     module.eks,
#     kubernetes_namespace.datadog,
#     kubernetes_secret.datadog_api_key
#   ]
# }

# # Optional: Store Datadog API key in AWS Secrets Manager
# # resource "aws_secretsmanager_secret" "datadog_api_key" {
# #   name        = "${var.cluster_name}-datadog-api-key"
# #   description = "Datadog API Key for ${var.cluster_name}"
# #   tags        = var.tags
# # }

# # resource "aws_secretsmanager_secret_version" "datadog_api_key" {
# #   secret_id     = aws_secretsmanager_secret.datadog_api_key.id
# #   secret_string = var.datadog_api_key
# # }

