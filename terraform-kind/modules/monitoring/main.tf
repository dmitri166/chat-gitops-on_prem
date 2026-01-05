# Monitoring Module
# Handles Prometheus, Grafana, Alertmanager stack
# Note: Providers are inherited from root configuration

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
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
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

          securityContext = {
            fsGroup = 65534
            runAsGroup = 65534
            runAsNonRoot = true
            runAsUser = 65534
          }

          ruleSelectorNilUsesHelmValues = false
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues = false
          probeSelectorNilUsesHelmValues = false

          scrapeInterval = "15s"
          evaluationInterval = "15s"
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
          enabled     = true
          accessMode  = "ReadWriteOnce"
          size        = var.grafana_storage_size
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

        securityContext = {
          fsGroup = 472
          runAsGroup = 472
          runAsNonRoot = true
          runAsUser = 472
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

        # Pre-configured dashboards
        dashboards = {
          default = {
            "kubernetes-cluster-monitoring" = {
              gnetId = 3119
              revision = 23
              datasource = "Prometheus"
            }
            "kubernetes-pod-monitoring" = {
              gnetId = 6417
              revision = 1
              datasource = "Prometheus"
            }
            "chat-application-monitoring" = {
              json = yamlencode({
                dashboard = {
                  title = "Chat Application Monitoring"
                  tags = ["chat", "application"]
                  timezone = "browser"
                  panels = [
                    {
                      title = "Application Status"
                      type = "stat"
                      targets = [
                        {
                          expr = "up{job=\"chat-app\"}"
                          legendFormat = "Instances Up"
                        }
                      ]
                    }
                  ]
                  time = {
                    from = "now-1h"
                    to = "now"
                  }
                  refresh = "30s"
                }
              })
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
          forceEnableClusterMode = false

          securityContext = {
            fsGroup = 65534
            runAsGroup = 65534
            runAsNonRoot = true
            runAsUser = 65534
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

      # Additional components
      prometheus-node-exporter = {
        enabled = true

        resources = {
          requests = {
            cpu    = "10m"
            memory = "32Mi"
          }
          limits = {
            cpu    = "50m"
            memory = "64Mi"
          }
        }
      }

      kube-state-metrics = {
        enabled = true

        resources = {
          requests = {
            cpu    = "10m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "50m"
            memory = "128Mi"
          }
        }
      }

      prometheusOperator = {
        enabled = true

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

        securityContext = {
          fsGroup = 65534
          runAsGroup = 65534
          runAsNonRoot = true
          runAsUser = 65534
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

      # Default rules
      defaultRules = {
        create = true
        rules = {
          alertmanager = true
          etcd = false
          configReloaders = true
          general = true
          k8s = true
          kubeApiserver = true
          kubeApiserverAvailability = true
          kubeApiserverBurnrate = true
          kubeApiserverHistogram = true
          kubeApiserverSlos = true
          kubelet = true
          kubePrometheusGeneral = true
          kubePrometheusNodeRecording = true
          kubernetesApps = true
          kubernetesResources = true
          kubernetesStorage = true
          kubernetesSystem = true
          kubeScheduler = true
          kubeStateMetrics = true
          network = true
          node = true
          prometheus = true
          prometheusOperator = true
        }
      }

      # Disable components not needed
      kubeEtcd = {
        enabled = false
      }

      kubeScheduler = {
        enabled = false
      }

      kubeControllerManager = {
        enabled = false
      }

      coreDns = {
        enabled = false
      }
    })
  ]
}

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
