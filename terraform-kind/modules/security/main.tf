# Security Module
# Handles ArgoCD, RBAC, Sealed Secrets, and security policies

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

variable "argocd_ip" {
  description = "Static IP for ArgoCD"
  type        = string
  default     = "172.18.255.101"
}

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

variable "sealed_secrets_backup_enabled" {
  description = "Enable automatic key backup"
  type        = bool
  default     = true
}

variable "sealed_secrets_key_rotation" {
  description = "Enable automatic key rotation"
  type        = bool
  default     = true
}

variable "sealed_secrets_key_rotation_interval" {
  description = "Key rotation interval"
  type        = string
  default     = "720h"  # 30 days
}

variable "sealed_secrets_backup_enabled" {
  description = "Enable automatic key backup"
  type        = bool
  default     = true
}

# Install ArgoCD
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.5"
  namespace  = "argocd"

  create_namespace = true

  values = [
    yamlencode({
      global = {
        image = {
          repository = "quay.io/argoproj/argocd"
          tag        = "v2.11.0"
        }
      }

      server = {
        replicas = 1

        service = {
          type = "LoadBalancer"
          annotations = {
            "metallb.universe.tf/loadBalancerIPs" = var.argocd_ip
          }
        }

        extraArgs = [
          "--insecure"
        ]

        config = {
          repositories = [
            {
              type = "git"
              url  = "https://github.com/dmitri166/chat-gitops.git"
              name = "chat-gitops"
            }
          ]
        }

        rbacConfig = {
          "policy.csv" = "g, argocd-admin, role:admin\ng, dev-team, role:developer, allow, dev/*\ng, staging-team, role:developer, allow, staging/*\ng, prod-team, role:developer, allow, prod/*"
          "policy.default" = "role:readonly"
          "scopes" = "[groups]"
        }

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

        nodeSelector = {
          "env" = "system"
        }

        tolerations = [
          {
            key      = "env"
            operator = "Equal"
            value    = "system"
            effect   = "NoSchedule"
          }
        ]
      }

      repoServer = {
        replicas = 1

        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "300m"
            memory = "512Mi"
          }
        }

        nodeSelector = {
          "env" = "system"
        }

        tolerations = [
          {
            key      = "env"
            operator = "Equal"
            value    = "system"
            effect   = "NoSchedule"
          }
        ]
      }

      applicationSet = {
        replicaCount = 1

        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }

      controller = {
        replicas = 1

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

        nodeSelector = {
          "env" = "system"
        }

        tolerations = [
          {
            key      = "env"
            operator = "Equal"
            value    = "system"
            effect   = "NoSchedule"
          }
        ]
      }

      redis = {
        enabled = true

        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }

      dex = {
        enabled = false
      }

      configs = {
        secret = {
          argocdServerAdminPassword = var.argocd_admin_password
        }
      }

      notifications = {
        enabled = false
      }

      server = {
        persistence = {
          enabled     = true
          accessMode  = "ReadWriteOnce"
          size        = "5Gi"
        }
      }
    })
  ]
}

# Install Sealed Secrets with production best practices
resource "helm_release" "sealed_secrets" {
  count = var.enable_sealed_secrets ? 1 : 0

  name       = "sealed-secrets"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.14.0"
  namespace  = "sealed-secrets"

  create_namespace = true

  values = [
    yamlencode({
      # Production security settings
      secretName = "sealed-secrets-key"

      # Key rotation (PRODUCTION BEST PRACTICE)
      keyRotation = var.sealed_secrets_key_rotation
      keyRotationInterval = var.sealed_secrets_key_rotation_interval

      # Security context
      securityContext = {
        runAsUser  = 1001
        runAsGroup = 1001
        fsGroup    = 1001
      }

      # Resource limits
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      # Network policies
      networkPolicy = {
        enabled = true
      }

      # Metrics
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
          namespace = "monitoring"
        }
      }
    })
  ]
}

# Automated key backup job (PRODUCTION BEST PRACTICE)
resource "kubectl_manifest" "sealed_secrets_key_backup" {
  count = var.enable_sealed_secrets && var.sealed_secrets_backup_enabled ? 1 : 0

  depends_on = [helm_release.sealed_secrets]

  yaml_body = yamlencode({
    apiVersion = "batch/v1"
    kind       = "CronJob"

    metadata = {
      name      = "sealed-secrets-key-backup"
      namespace = "sealed-secrets"
      labels = {
        "app.kubernetes.io/name" = "sealed-secrets"
        "app.kubernetes.io/component" = "key-backup"
      }
    }

    spec = {
      schedule = "0 2 * * *"  # Daily at 2 AM
      jobTemplate = {
        spec = {
          template = {
            spec = {
              serviceAccountName = "sealed-secrets-controller"
              restartPolicy      = "OnFailure"

              containers = [
                {
                  name  = "key-backup"
                  image = "bitnami/kubectl:1.28"

                  command = [
                    "/bin/sh",
                    "-c"
                  ]

                  args = [
                    <<-EOF
                    # Create timestamp
                    TIMESTAMP=$(date +%Y%m%d-%H%M%S)

                    # Backup current keys
                    kubectl get secret -n sealed-secrets \
                      -l sealedsecrets.bitnami.com/sealed-secrets-key \
                      -o yaml > /tmp/sealed-secrets-keys-${TIMESTAMP}.yaml

                    # Create backup ConfigMap (persisted in etcd)
                    kubectl create configmap sealed-secrets-key-backup-${TIMESTAMP} \
                      --from-file=keys-${TIMESTAMP}.yaml=/tmp/sealed-secrets-keys-${TIMESTAMP}.yaml \
                      --dry-run=client -o yaml | kubectl apply -f -

                    # Log backup completion
                    echo "Sealed Secrets keys backed up at ${TIMESTAMP}"

                    # Cleanup old backups (keep last 7 days)
                    kubectl get configmap -n sealed-secrets \
                      -l app.kubernetes.io/component=key-backup \
                      --sort-by=.metadata.creationTimestamp \
                      -o jsonpath='{.items[*].metadata.name}' | \
                      head -n -7 | xargs -r kubectl delete configmap -n sealed-secrets
                    EOF
                  ]

                  securityContext = {
                    allowPrivilegeEscalation = false
                    runAsNonRoot            = true
                    runAsUser               = 1001
                    capabilities = {
                      drop = ["ALL"]
                    }
                  }
                }
              ]
            }
          }
        }
      }
    }
  })
}

# RBAC for key backup (PRODUCTION BEST PRACTICE)
resource "kubectl_manifest" "sealed_secrets_backup_rbac" {
  count = var.enable_sealed_secrets && var.sealed_secrets_backup_enabled ? 1 : 0

  depends_on = [helm_release.sealed_secrets]

  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "Role"

    metadata = {
      name      = "sealed-secrets-key-backup"
      namespace = "sealed-secrets"
    }

    rules = [
      {
        apiGroups = [""]
        resources = ["secrets", "configmaps"]
        verbs     = ["get", "list", "create", "update", "patch"]
      }
    ]
  })
}

resource "kubectl_manifest" "sealed_secrets_backup_rolebinding" {
  count = var.enable_sealed_secrets && var.sealed_secrets_backup_enabled ? 1 : 0

  depends_on = [kubectl_manifest.sealed_secrets_backup_rbac]

  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "RoleBinding"

    metadata = {
      name      = "sealed-secrets-key-backup"
      namespace = "sealed-secrets"
    }

    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "Role"
      name     = "sealed-secrets-key-backup"
    }

    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "sealed-secrets-controller"
        namespace = "sealed-secrets"
      }
    ]
  })
}

output "argocd_url" {
  description = "ArgoCD access URL"
  value       = "http://${var.argocd_ip}"
}

output "argocd_credentials" {
  description = "ArgoCD login credentials"
  value       = "admin / admin123"
  sensitive   = true
}
