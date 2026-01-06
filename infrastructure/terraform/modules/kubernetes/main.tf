# Kubernetes Cluster Module
# Handles k3d cluster setup and configuration

terraform {
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

variable "cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
  default     = "chat-k3d"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28.0"
}

variable "server_ip" {
  description = "Not used in k3d - cluster runs locally"
  type        = string
  default     = ""
}

variable "agent_ips" {
  description = "Not used in k3d - agents are containers"
  type        = list(string)
  default     = []
}

variable "k3s_token" {
  description = "Not used in k3d"
  type        = string
  sensitive   = true
  default     = ""
}

# k3d cluster configuration
resource "null_resource" "k3d_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      # Delete existing cluster if it exists
      k3d cluster delete ${var.cluster_name} || true

      # Create k3d cluster with proper networking
      k3d cluster create ${var.cluster_name} \
        --image rancher/k3s:${var.kubernetes_version} \
        --servers 1 \
        --agents 2 \
        --port "80:80@loadbalancer" \
        --port "443:443@loadbalancer" \
        --port "30000-30010:30000-30010@server:0" \
        --k3s-arg "--disable=traefik@server:0" \
        --wait

      # Wait for cluster to be ready
      kubectl wait --for=condition=Ready nodes --all --timeout=300s

      # Create kubeconfig for terraform
      k3d kubeconfig get ${var.cluster_name} > ./k3d-config
    EOT
  }
}

# Wait for cluster to be fully ready
resource "time_sleep" "wait_for_cluster" {
  depends_on = [null_resource.k3d_cluster]
  create_duration = "30s"
}

# Install essential addons
resource "null_resource" "install_addons" {
  depends_on = [time_sleep.wait_for_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=./k3d-config

      # Install metrics server
      kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

      # Install local path provisioner for storage
      kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

      # Wait for addons to be ready
      kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system
    EOT
  }
}

output "cluster_name" {
  description = "Name of the created k3d cluster"
  value       = var.cluster_name
}

output "server_ip" {
  description = "k3d cluster runs locally"
  value       = "localhost"
}

output "agent_ips" {
  description = "k3d agents are containers"
  value       = ["agent-0", "agent-1"]
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = "./k3d-config"
}

output "cluster_info" {
  description = "k3d cluster information"
  value       = <<-EOT
    k3d cluster setup complete!
    - Cluster: ${var.cluster_name}
    - Kubeconfig: ./k3d-config
    - Nodes: 3 total (1 server, 2 agents)

    Next steps:
    1. Set kubeconfig: export KUBECONFIG=./k3d-config
    2. Verify: kubectl get nodes
    3. Deploy infrastructure: terraform apply (next phase)
  EOT
}
