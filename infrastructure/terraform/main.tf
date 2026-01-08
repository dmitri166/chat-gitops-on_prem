# Main Terraform Configuration (Modular)
# This replaces the monolithic main.tf with clean module calls

terraform {
  required_version = ">= 1.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Configure helm provider
provider "helm" {
  kubernetes {
    config_path = "${path.module}/k3d-config"
  }
}

# All providers automatically use KUBECONFIG environment variable

# Generate secure random passwords
resource "random_password" "argocd_admin" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "random_password" "grafana_admin" {
  length  = 12
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Create Kubernetes cluster with k3d
module "kubernetes" {
  source = "./modules/kubernetes"

  cluster_name       = var.k3d_cluster_name
  kubernetes_version = "v${var.kubernetes_version}"
}

# Setup networking (MetalLB + Ingress)
module "networking" {
  source     = "./modules/networking"
  depends_on = [module.kubernetes]

  metallb_ip_range    = var.metallb_ip_range
  ingress_nginx_ip    = var.ingress_nginx_ip
  enable_ingress      = true  # Re-enabled - ingress-nginx working
  ingress_replicas    = 1
}

# Install monitoring stack
module "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  depends_on = [module.networking]
  source     = "./modules/monitoring"

  prometheus_ip             = var.prometheus_ip
  grafana_ip               = var.grafana_ip
  alertmanager_ip          = var.alertmanager_ip
  grafana_admin_password   = var.grafana_admin_password != "" ? var.grafana_admin_password : random_password.grafana_admin.result
  prometheus_storage_size       = "10Gi"
  grafana_storage_size          = "5Gi"
  alertmanager_storage_size     = "2Gi"
  enable_monitoring             = true  # Always true when module is created
  enable_control_plane_monitoring = var.enable_control_plane_monitoring
}

# Install security components
module "security" {
  depends_on = [module.networking]
  source     = "./modules/security"

  # ArgoCD settings
  argocd_ip             = var.argocd_ip
  argocd_admin_password = var.argocd_admin_password != "" ? var.argocd_admin_password : random_password.argocd_admin.result
  enable_argocd        = true

  # Sealed Secrets with production best practices
  enable_sealed_secrets = true
  sealed_secrets_key_rotation = var.sealed_secrets_key_rotation
  sealed_secrets_key_rotation_interval = var.sealed_secrets_key_rotation_interval
}

# Install KEDA for event-driven autoscaling
resource "helm_release" "keda" {
  depends_on = [module.networking]

  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.13.0"
  namespace  = "keda-system"
  create_namespace = true

  set {
    name  = "watchNamespace"
    value = ""
  }
}

# Outputs
output "cluster_name" {
  description = "Name of the created k3d cluster"
  value       = module.kubernetes.cluster_name
}

output "kubeconfig_setup" {
  description = "Commands to configure kubectl for k3d cluster"
  value       = <<-EOT
    # Set KUBECONFIG for k3d cluster
    export KUBECONFIG=./k3d-config
    kubectl get nodes

    # View cluster info:
    kubectl cluster-info
    kubectl get nodes -o wide
  EOT
}

# kubeconfig output removed - Minikube configures kubectl automatically

output "ingress_ip" {
  description = "NGINX Ingress LoadBalancer IP"
  value       = module.networking.ingress_nginx_ip
}

output "argocd_url" {
  description = "ArgoCD access URL"
  value       = module.security.argocd_url
}

output "grafana_url" {
  description = "Grafana access URL"
  value       = var.enable_monitoring ? module.monitoring[0].grafana_url : "Monitoring disabled"
}

output "prometheus_url" {
  description = "Prometheus access URL"
  value       = var.enable_monitoring ? module.monitoring[0].prometheus_url : "Monitoring disabled"
}

output "alertmanager_url" {
  description = "Alertmanager access URL"
  value       = var.enable_monitoring ? module.monitoring[0].alertmanager_url : "Monitoring disabled"
}

output "argocd_admin_password" {
  description = "Generated ArgoCD admin password"
  value       = var.argocd_admin_password != "" ? var.argocd_admin_password : random_password.argocd_admin.result
  sensitive   = true
}

output "grafana_admin_password" {
  description = "Generated Grafana admin password"
  value       = var.grafana_admin_password != "" ? var.grafana_admin_password : random_password.grafana_admin.result
  sensitive   = true
}

output "service_access" {
  description = "Service access information"
  sensitive   = true
  value       = <<-EOT
    # Complete Enterprise Infrastructure Deployed Successfully! 🚀

    # Current status:
    # ✅ Kubernetes cluster: k3d (${var.kubernetes_version})
    # ✅ Storage class: Available (local-path provisioner)
    # ✅ LoadBalancer services: Enabled (MetalLB)
    # ✅ GitOps: Enabled (ArgoCD)
    # ✅ Monitoring: Enabled (Prometheus + Grafana)
    # ✅ Security: Enabled (Sealed Secrets)
    # ✅ Event-Driven Scaling: Enabled (KEDA)

    # Cluster Info:
    # - Nodes: 3 total (1 server, 2 agents)
    # - Running in Docker containers

    # LoadBalancer IPs will be assigned by MetalLB
    # Check with: kubectl get svc -A

    # Access cluster with:
    # export KUBECONFIG=./k3d-config
    # kubectl get nodes

    # Service URLs (LoadBalancer IPs):
    # ArgoCD: http://${var.argocd_ip}
    # Grafana: http://${var.grafana_ip}
    # Prometheus: http://${var.prometheus_ip}
    # Alertmanager: http://${var.alertmanager_ip}

    # Login Credentials:
    # ArgoCD Admin: admin / ${var.argocd_admin_password != "" ? var.argocd_admin_password : "(auto-generated)"}
    # Grafana Admin: admin / ${var.grafana_admin_password != "" ? var.grafana_admin_password : "(auto-generated)"}

    # Direct service access (if LoadBalancer IPs assigned):
    # ArgoCD: http://${var.argocd_ip}
    # Grafana: http://${var.grafana_ip}
    # Prometheus: http://${var.prometheus_ip}
    # Alertmanager: http://${var.alertmanager_ip}

  EOT
}
