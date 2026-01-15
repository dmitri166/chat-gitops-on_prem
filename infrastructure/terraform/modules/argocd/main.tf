# ArgoCD Module
# GitOps operator for continuous deployment

terraform {
  required_version = ">= 1.5"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

# Input variables
variable "cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "admin_password" {
  description = "ArgoCD admin password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values
locals {
  common_tags = merge(var.tags, {
    "component"   = "gitops"
    "managed-by"  = "terraform"
    "environment"  = var.environment
  })
}

# Install ArgoCD using Helm chart
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.0"
  timeout    = 600

  create_namespace = true

  # ArgoCD configuration
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
  
  set {
    name  = "server.service.servicePortHttp"
    value = "80"
  }
  
  set {
    name  = "server.service.servicePortHttps"
    value = "443"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.admin_password
  }

  set {
    name  = "configs.cm.application.instanceLabelKey"
    value = "app.kubernetes.io/instance"
  }

  set {
    name  = "dex.enabled"
    value = "false"
  }

  # Enable notifications
  set {
    name  = "notifications.enabled"
    value = "true"
  }

  # Enable applicationsets
  set {
    name  = "applicationsets.enabled"
    value = "true"
  }

  depends_on = [
    null_resource.wait_for_cluster
  ]
}

# Wait for cluster to be ready
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = "kubectl cluster-info"
  }
  
  depends_on = [
    time_sleep.wait_for_kubeconfig
  ]
}

# Wait for kubeconfig to be created
resource "time_sleep" "wait_for_kubeconfig" {
  create_duration = "10s"
}

# Outputs
output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = helm_release.argocd.namespace
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = "http://argocd.${var.namespace}.svc.cluster.local"
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = var.admin_password
  sensitive   = true
}
