# Security Module
# Handles ArgoCD, RBAC, Sealed Secrets, and security policies

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

variable "argocd_ip" {
  description = "Static IP for ArgoCD"
  type        = string
  default     = "172.18.255.101"
}

# Providers configured at root level

variable "argocd_admin_password" {
  description = "ArgoCD admin password (bcrypt hashed)"
  type        = string
  default     = "$2y$10$8K1p/5j6Zf0Q9gJfKJ8jUe6N7o6jKsK7o6jKsK7o6jKsK7o6jKsK"  # admin/admin123
  sensitive   = true
}

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

# Install ArgoCD
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  depends_on = [helm_release.sealed_secrets]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.4.0"
  namespace  = "argocd"

  create_namespace = true

  values = [
    yamlencode({
      # ArgoCD configuration
      configs = {
        secret = {
          argocdServerAdminPassword = var.argocd_admin_password
          argocdServerAdminPasswordMtime = "2024-01-01T00:00:00Z"
        }
        cm = {
          url = "https://${var.argocd_ip}"
          dex.config = ""
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

      dex = {
        enabled = false  # Disable for simplicity
      }

      notifications = {
        enabled = false
      }
    })
  ]
}

# Sealed Secrets backup configuration moved to Terraform
# (infrastructure security, not application deployment)

# RBAC and security policies handled by Helm charts

output "argocd_url" {
  description = "ArgoCD access URL"
  value       = "https://${var.argocd_ip}"
}
