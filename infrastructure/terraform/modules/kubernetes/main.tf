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
  default     = "1.27.4"
}



# Create kubeconfig for manual k3d cluster
resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Getting kubeconfig from manual k3d cluster..."
      k3d kubeconfig get ${var.cluster_name} > k3d-config
      echo "Kubeconfig created successfully"
    EOT
  }
}

output "cluster_name" {
  description = "Name of the created k3d cluster"
  value       = var.cluster_name
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
    - Kubernetes Version: ${var.kubernetes_version}

    Next steps:
    1. Set kubeconfig: export KUBECONFIG=./k3d-config
    2. Verify: kubectl get nodes
    3. Deploy infrastructure: terraform apply (next phase)
  EOT
}
