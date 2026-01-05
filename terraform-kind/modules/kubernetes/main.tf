# Kubernetes Cluster Module
# Handles Kind cluster creation and basic setup

terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4"
    }
  }
}

variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "chat-local"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28.0"
}

variable "enable_registry" {
  description = "Enable local Docker registry"
  type        = bool
  default     = true
}

variable "registry_port" {
  description = "Local registry port"
  type        = number
  default     = 5001
}

# Create Kind cluster
resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # Control plane node
    node {
      role = "control-plane"

      # Kubernetes version
      image = "kindest/node:v${var.kubernetes_version}"

      # Extra port mappings for services
      extra_port_mappings {
        container_port = 30080
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30443
        host_port      = 443
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30082
        host_port      = 8082
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30000
        host_port      = 3000
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30900
        host_port      = 9090
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30903
        host_port      = 9093
        protocol       = "TCP"
      }

      # Node labels
      kubeadm_config_patches = [
        yamlencode({
          kind = "InitConfiguration"
          nodeRegistration = {
            kubeletExtraArgs = {
              "node-labels" = "node-role.kubernetes.io/control-plane=true"
            }
          }
        })
      ]

      # Mounts for persistent storage simulation
      extra_mounts {
        host_path      = "/tmp/kind-persistent"
        container_path = "/var/local-path-provisioner"
      }

      extra_mounts {
        host_path      = "/tmp/kind-registry"
        container_path = "/var/lib/registry"
      }
    }

    # Worker nodes for different environments
    node {
      role          = "worker"
      image         = "kindest/node:v${var.kubernetes_version}"

      kubeadm_config_patches = [
        yamlencode({
          kind = "JoinConfiguration"
          nodeRegistration = {
            kubeletExtraArgs = {
              "node-labels" = "env=nonprod,node-type=worker"
            }
          }
        })
      ]

      extra_mounts {
        host_path      = "/tmp/kind-worker1-persistent"
        container_path = "/var/local-path-provisioner"
      }
    }

    node {
      role          = "worker"
      image         = "kindest/node:v${var.kubernetes_version}"

      kubeadm_config_patches = [
        yamlencode({
          kind = "JoinConfiguration"
          nodeRegistration = {
            kubeletExtraArgs = {
              "node-labels" = "env=prod,node-type=worker"
            }
          }
        })
      ]

      extra_mounts {
        host_path      = "/tmp/kind-worker2-persistent"
        container_path = "/var/local-path-provisioner"
      }
    }

    node {
      role          = "worker"
      image         = "kindest/node:v${var.kubernetes_version}"

      kubeadm_config_patches = [
        yamlencode({
          kind = "JoinConfiguration"
          nodeRegistration = {
            kubeletExtraArgs = {
              "node-labels" = "env=system,node-type=monitoring"
            }
          }
        })
      ]

      extra_mounts {
        host_path      = "/tmp/kind-monitoring-persistent"
        container_path = "/var/local-path-provisioner"
      }
    }

    # Containerd registry config for local registry
    dynamic "containerd_config_patches" {
      for_each = var.enable_registry ? [1] : []

      content {
        yamlencode({
          plugins = {
            "io.containerd.grpc.v1.cri" = {
              registry = {
                mirrors = {
                  "localhost:${var.registry_port}" = {
                    endpoint = ["http://kind-registry:${var.registry_port}"]
                  }
                  "registry.local:${var.registry_port}" = {
                    endpoint = ["http://kind-registry:${var.registry_port}"]
                  }
                }
              }
            }
          }
        })
      }
    }

    # Feature gates for production-like features
    feature_gates {
      EphemeralContainers    = true
      ServerSideFieldValidation = true
    }

    # Runtime configuration
    runtime_config = ["api/all=true"]
  }
}

# Wait for cluster to be ready
resource "time_sleep" "wait_for_cluster" {
  depends_on = [kind_cluster.this]

  create_duration = "30s"
}

output "cluster_name" {
  description = "Name of the created Kind cluster"
  value       = kind_cluster.this.name
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = kind_cluster.this.kubeconfig
  sensitive   = true
}
