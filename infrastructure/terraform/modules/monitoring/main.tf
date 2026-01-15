# Monitoring Module
# Reusable module for monitoring stack configuration

terraform {
  required_version = ">= 1.5"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
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

variable "monitoring_stack" {
  description = "Monitoring stack to deploy"
  type = object({
    prometheus = optional(object({
      enabled    = bool
      version    = optional(string, "v2.45.0")
      retention  = optional(string, "15d")
    }), { enabled = true })
    grafana = optional(object({
      enabled    = bool
      version    = optional(string, "10.2.0")
      admin_user = optional(string, "admin")
    }), { enabled = true })
    alertmanager = optional(object({
      enabled    = bool
      version    = optional(string, "v0.27.0")
    }), { enabled = true })
    tempo = optional(object({
      enabled    = bool
      version    = optional(string, "latest")
    }), { enabled = true })
    loki = optional(object({
      enabled    = bool
      version    = optional(string, "latest")
    }), { enabled = true })
    opentelemetry = optional(object({
      enabled    = bool
      version    = optional(string, "latest")
    }), { enabled = true })
  })
  default = {
    prometheus = {
      enabled   = true
      version   = "v2.45.0"
      retention = "15d"
    }
    grafana = {
      enabled    = true
      version    = "10.2.0"
      admin_user = "admin"
    }
    alertmanager = {
      enabled = true
      version = "v0.27.0"
    }
    tempo = {
      enabled = true
      version = "latest"
    }
    loki = {
      enabled = true
      version = "latest"
    }
    opentelemetry = {
      enabled = true
      version = "latest"
    }
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values
locals {
  default_tags = merge(var.tags, {
    "component"   = "monitoring"
    "managed-by"  = "terraform"
  })
  
  prometheus_config = merge(var.monitoring_stack.prometheus, {
    enabled    = true
    version    = "v2.45.0"
    retention  = "15d"
  })
  
  grafana_config = merge(var.monitoring_stack.grafana, {
    enabled    = true
    version    = "10.2.0"
    admin_user = "admin"
  })
  
  alertmanager_config = merge(var.monitoring_stack.alertmanager, {
    enabled    = true
    version    = "v0.27.0"
  })
  
  tempo_config = merge(var.monitoring_stack.tempo, {
    enabled    = true
    version    = "latest"
  })
  
  loki_config = merge(var.monitoring_stack.loki, {
    enabled    = true
    version    = "latest"
  })
  
  opentelemetry_config = merge(var.monitoring_stack.opentelemetry, {
    enabled    = true
    version    = "latest"
  })
}

# Generate Prometheus configuration
resource "local_file" "prometheus_config" {
  content = local.prometheus_config.enabled ? yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind = "Application"
    metadata = {
      name = "prometheus"
      namespace = "argocd"
      labels = local.default_tags
    }
    spec = {
      project = "default"
      source = {
        repoURL = "https://prometheus-community.github.io/helm-charts"
        chart = "kube-prometheus-stack"
        targetRevision = local.prometheus_config.version
        helm = {
          releaseName = "monitoring"
          values = yamlencode({
            prometheus = {
              prometheusSpec = {
                retention = local.prometheus_config.retention
                storageSpec = {
                  volumeClaimTemplate = {
                    spec = {
                      accessModes = ["ReadWriteOnce"]
                      resources = {
                        requests = {
                          storage = "10Gi"
                        }
                      }
                    }
                  }
                }
              }
            }
            grafana = {
              enabled = local.grafana_config.enabled
              adminUser = local.grafana_config.admin_user
              adminPassword = "admin123"
              service = {
                type = "LoadBalancer"
              }
            }
            alertmanager = {
              enabled = local.alertmanager_config.enabled
              service = {
                type = "LoadBalancer"
              }
            }
          })
        }
      }
      destination = {
        server = "https://kubernetes.default.svc"
        namespace = "monitoring"
      }
      syncPolicy = {
        automated = {
          prune = true
          selfHeal = false
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }) : "# Prometheus disabled"
  
  filename = "${path.module}/prometheus.yaml"
}

# Generate Tempo configuration
resource "local_file" "tempo_config" {
  content = local.tempo_config.enabled ? yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind = "Application"
    metadata = {
      name = "tempo"
      namespace = "argocd"
      labels = local.default_tags
    }
    spec = {
      project = "default"
      source = {
        repoURL = "https://github.com/dmitri166/chat-gitops-on_prem"
        targetRevision = "master"
        path = "platform/manifests/monitoring"
        kustomize = {
          images = [
            {
              name = "tempo"
              newTag = local.tempo_config.version
            }
          ]
        }
      }
      destination = {
        server = "https://kubernetes.default.svc"
        namespace = "tempo"
      }
      syncPolicy = {
        automated = {
          prune = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }) : "# Tempo disabled"
  
  filename = "${path.module}/tempo.yaml"
}

# Generate Loki configuration
resource "local_file" "loki_config" {
  content = local.loki_config.enabled ? yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind = "Application"
    metadata = {
      name = "loki"
      namespace = "argocd"
      labels = local.default_tags
    }
    spec = {
      project = "default"
      source = {
        repoURL = "https://grafana.github.io/helm-charts"
        chart = "loki"
        targetRevision = local.loki_config.version
        helm = {
          releaseName = "loki"
          values = {
            loki = {
              auth_enabled = false
              common = {
                path_prefix = "/var/loki"
                storage = {
                  filesystem = {
                    chunks_directory = "/var/loki/chunks"
                    rules_directory = "/var/loki/rules"
                  }
                }
              }
              schema_config = {
                configs = [{
                  from = "2024-04-01"
                  store = "boltdb-shipper"
                  object_store = "filesystem"
                  schema = "v13"
                  index = {
                    prefix = "index_"
                    period = "24h"
                  }
                }]
              }
              ingester = {
                lifecycler = {
                  address = "127.0.0.1"
                  ring = {
                    kvstore = {
                      store = "inmemory"
                    }
                    replication_factor = 1
                  }
                }
              }
              limits_config = {
                enforce_metric_name = false
                reject_old_samples = true
                reject_old_samples_max_age = "168h"
              }
            }
          }
        }
      }
      destination = {
        server = "https://kubernetes.default.svc"
        namespace = "monitoring"
      }
      syncPolicy = {
        automated = {
          prune = true
          selfHeal = false
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }) : yamlencode({})
  
  filename = "${path.module}/loki.yaml"
}

# Generate OpenTelemetry Collector configuration
resource "local_file" "opentelemetry_config" {
  content = local.opentelemetry_config.enabled ? yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind = "Application"
    metadata = {
      name = "opentelemetry-collector"
      namespace = "argocd"
      labels = local.default_tags
    }
    spec = {
      project = "default"
      source = {
        repoURL = "https://open-telemetry.github.io/helm-charts"
        chart = "opentelemetry-collector"
        targetRevision = local.opentelemetry_config.version
        helm = {
          releaseName = "otel-collector"
          values = {
            mode = "deployment"
            config = {
              receivers = {
                otlp = {
                  protocols = {
                    grpc = {
                      endpoint = "0.0.0.0:4317"
                    }
                    http = {
                      endpoint = "0.0.0.0:4318"
                    }
                  }
                }
                prometheus = {
                  config = {
                    scrape_configs = [{
                      job_name = "kubernetes-pods"
                      kubernetes_sd_configs = [{
                        role = "pod"
                      }]
                      relabel_configs = [
                        {
                          source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
                          action = "keep"
                          regex = "true"
                        },
                        {
                          source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
                          action = "replace"
                          target_label = "__metrics_path__"
                          regex = "(.+)"
                        }
                      ]
                    }]
                  }
                }
              }
              processors = {
                batch = {}
                memory_limiter = {
                  limit_mib = 512
                }
                resource = {
                  attributes = [{
                    key = "environment"
                    value = var.environment
                  }]
                }
              }
              exporters = {
                prometheus = {
                  endpoint = "0.0.0.0:8889"
                }
                loki = {
                  endpoint = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
                }
                tempo = {
                  endpoint = "http://tempo.monitoring.svc.cluster.local:4317"
                }
              }
              service = {
                pipelines = {
                  traces = {
                    receivers = ["otlp"]
                    processors = ["memory_limiter", "batch"]
                    exporters = ["tempo"]
                  }
                  metrics = {
                    receivers = ["otlp", "prometheus"]
                    processors = ["memory_limiter", "batch"]
                    exporters = ["prometheus"]
                  }
                  logs = {
                    receivers = ["otlp"]
                    processors = ["memory_limiter", "batch"]
                    exporters = ["loki"]
                  }
                }
              }
            }
          }
        }
      }
      destination = {
        server = "https://kubernetes.default.svc"
        namespace = "monitoring"
      }
      syncPolicy = {
        automated = {
          prune = true
          selfHeal = false
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }) : yamlencode({})
  
  filename = "${path.module}/opentelemetry.yaml"
}

# Generate monitoring configuration
resource "local_file" "monitoring_config" {
  content = yamlencode({
    stack = {
      prometheus = local.prometheus_config
      grafana = local.grafana_config
      alertmanager = local.alertmanager_config
      tempo = local.tempo_config
      loki = local.loki_config
      opentelemetry = local.opentelemetry_config
    }
    created_at = timestamp()
    environment = var.environment
  })
  
  filename = "${path.module}/monitoring-config.yaml"
}

# Outputs
output "prometheus_config" {
  description = "Path to Prometheus configuration"
  value       = local_file.prometheus_config.filename
}

output "loki_config" {
  description = "Path to Loki configuration"
  value       = local_file.loki_config.filename
}

output "opentelemetry_config" {
  description = "Path to OpenTelemetry Collector configuration"
  value       = local_file.opentelemetry_config.filename
}

output "tempo_config" {
  description = "Path to Tempo configuration"
  value       = local_file.tempo_config.filename
}

output "monitoring_config" {
  description = "Path to monitoring configuration"
  value       = local_file.monitoring_config.filename
}
