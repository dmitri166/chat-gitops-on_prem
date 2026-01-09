# Security Module
# Handles ArgoCD, RBAC, Sealed Secrets, and security policies

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

variable "argocd_ip" {
  description = "Static IP for ArgoCD"
  type        = string
  default     = "172.18.255.101"
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  sensitive   = true
}

# Providers configured at root level


variable "enable_argocd" {
  description = "Enable ArgoCD GitOps"
  type        = bool
  default     = true
}

variable "enable_sealed_secrets" {
  description = "Enable Sealed Secrets"
  type        = bool
  default     = true
}

variable "sealed_secrets_key_rotation" {
  description = "Enable automatic key rotation"
  type        = bool
  default     = true
}

variable "sealed_secrets_key_rotation_interval" {
  description = "Key rotation interval (e.g., '720h' for 30 days)"
  type        = string
  default     = "720h"
}

# Install Sealed Secrets
resource "helm_release" "sealed_secrets" {
  count = var.enable_sealed_secrets ? 1 : 0

  name       = "sealed-secrets"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.15.0"
  namespace  = "sealed-secrets"

  create_namespace = true

  values = [
    yamlencode({
      # Sealed Secrets controller configuration
      sealedSecrets = {
        keyRotation = {
          enabled = var.sealed_secrets_key_rotation
          interval = var.sealed_secrets_key_rotation_interval
        }
      }
    })
  ]
}

# Generate ArgoCD server secret key
resource "random_password" "argocd_secretkey" {
  count   = var.enable_argocd ? 1 : 0
  length  = 32
  special = true
}

# Install ArgoCD
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  depends_on = [helm_release.sealed_secrets, random_password.argocd_secretkey]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.4.0"
  namespace  = "argocd"

  create_namespace = true
  force_update     = false  # Don't force updates - prevents constant modifications
  timeout          = 600    # 10 minutes - ArgoCD can take time to deploy
  wait             = false  # Don't wait - ArgoCD is already running
  skip_crds        = true   # Skip CRD installation (they may already exist)
  atomic           = false  # Don't rollback on timeout

  values = [
    yamlencode({
      # ArgoCD configuration using Helm chart values
      configs = {
        secret = {
          argocdServerAdminPassword     = var.argocd_admin_password
          argocdServerAdminPasswordMtime = ""
          # server.secretkey is required for JWT token signing and session validation
          # Generate with: openssl rand -base64 32
          serverSecretkey = base64encode(random_password.argocd_secretkey[0].result)
        }
        cm = {
          url = "https://${var.argocd_ip}"
        }
      }

      server = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "metallb.universe.tf/loadBalancerIPs" = var.argocd_ip
          }
        }
        extraArgs = ["--insecure"]  # For development only
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      repoServer = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      applicationSet = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      notifications = {
        enabled = false
      }
    })
  ]

  lifecycle {
    ignore_changes = [
      # Ignore changes to prevent constant updates when ArgoCD is already running
      values,
    ]
  }
}

# Sealed Secrets backup configuration moved to Terraform
# (infrastructure security, not application deployment)

# RBAC and security policies handled by Helm charts

output "argocd_url" {
  description = "ArgoCD access URL"
  value       = "http://${var.argocd_ip}"  # --insecure flag allows HTTP
}
