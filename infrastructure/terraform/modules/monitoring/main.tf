# Monitoring Module
# Handles Prometheus, Grafana, Alertmanager stack

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

variable "prometheus_ip" {
  description = "Static IP for Prometheus"
  type        = string
  default     = "172.18.255.102"
}

variable "grafana_ip" {
  description = "Static IP for Grafana"
  type        = string
  default     = "172.18.255.103"
}

variable "alertmanager_ip" {
  description = "Static IP for Alertmanager"
  type        = string
  default     = "172.18.255.104"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin123"  # TODO: Use proper secret management
  sensitive   = true
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "5Gi"
}

variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager"
  type        = string
  default     = "2Gi"
}

variable "enable_monitoring" {
  description = "Enable the monitoring stack"
  type        = bool
  default     = true
}

# Providers configured at root level

# Install Kube Prometheus Stack
resource "helm_release" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "61.8.0"
  namespace  = "monitoring"

  create_namespace = true

  values = [
    yamlencode({
      # Prometheus configuration
      prometheus = {
        enabled = true

        serviceAccount = {
          create = true
          name   = "prometheus"
        }

        service = {
          type = "LoadBalancer"
          annotations = {
            "metallb.universe.tf/loadBalancerIPs" = var.prometheus_ip
          }
        }

        prometheusSpec = {
          replicas = 1
          retention = "6h"
          retentionSize = "1GB"

          resources = {
            requests = {
              cpu    = "200m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "500m"
              memory = "2Gi"
            }
          }

          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
        }
      }

      # Alertmanager configuration
      alertmanager = {
        enabled = true

        serviceAccount = {
          create = true
          name   = "alertmanager"
        }

        service = {
          type = "LoadBalancer"
          annotations = {
            "metallb.universe.tf/loadBalancerIPs" = var.alertmanager_ip
          }
        }

        alertmanagerSpec = {
          replicas = 1

          resources = {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "512Mi"
            }
          }

          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alertmanager_storage_size
                  }
                }
              }
            }
          }
        }
      }

      # Grafana configuration
      grafana = {
        enabled = true

        adminPassword = var.grafana_admin_password

        serviceAccount = {
          create = true
          name   = "grafana"
        }

        service = {
          type = "LoadBalancer"
          annotations = {
            "metallb.universe.tf/loadBalancerIPs" = var.grafana_ip
          }
        }

        persistence = {
          enabled = true
          size    = var.grafana_storage_size
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "512Mi"
          }
        }

        # Grafana dashboards will be added via ConfigMaps from GitOps
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name            = "default"
                type            = "file"
                disableDeletion = false
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }

        dashboardsConfigMaps = {
          default = "sealed-secrets-dashboard"
        }

        # Enable sidecar for dashboards
        sidecar = {
          dashboards = {
            enabled = true
            label   = "grafana_dashboard"
          }
        }
      }

      # Node Exporter
      nodeExporter = {
        enabled = true
      }

      # Kube State Metrics
      kubeStateMetrics = {
        enabled = true
      }

      # Disable components we don't need
      coreDns = {
        enabled = false
      }
    })
  ]
}

# Sealed Secrets ServiceMonitor moved to GitOps
# See: development/gitops-local/chat-gitops/infrastructure/monitoring/sealed-secrets-servicemonitor.yaml

# Sealed Secrets Prometheus Rules moved to GitOps
# See: development/gitops-local/chat-gitops/infrastructure/monitoring/sealed-secrets-prometheusrules.yaml

# Sealed Secrets Grafana Dashboard moved to GitOps
# See: development/gitops-local/chat-gitops/infrastructure/monitoring/sealed-secrets-dashboard.yaml

output "prometheus_url" {
  description = "Prometheus access URL"
  value       = "http://${var.prometheus_ip}:9090"
}

output "grafana_url" {
  description = "Grafana access URL"
  value       = "http://${var.grafana_ip}"
}

output "alertmanager_url" {
  description = "Alertmanager access URL"
  value       = "http://${var.alertmanager_ip}:9093"
}
