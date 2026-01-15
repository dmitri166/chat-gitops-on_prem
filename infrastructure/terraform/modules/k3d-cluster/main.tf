# K3D Cluster Module
# Reusable module for k3d cluster creation using local commands

terraform {
  required_version = ">= 1.5"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Input variables
variable "cluster_name" {
  description = "Name of k3d cluster"
  type        = string
}

variable "k3s_image" {
  description = "k3s image to use"
  type        = string
  default     = "rancher/k3s:v1.29.2-k3s1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "servers" {
  description = "Number of server nodes"
  type        = number
  default     = 1
}

variable "agents" {
  description = "Number of agent nodes"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values
locals {
  cluster_network = "${var.cluster_name}-network"
  storage_path   = "/tmp/k3d-${var.cluster_name}-storage"
  
  default_tags = merge(var.tags, {
    "component"   = "k3d-cluster"
    "environment" = var.environment
    "managed-by"  = "terraform"
  })
}

# Create k3d cluster using local command
resource "null_resource" "create_cluster" {
  provisioner "local-exec" {
    command = "k3d cluster create ${var.cluster_name} --image ${var.k3s_image} --servers ${var.servers} --agents ${var.agents} --network ${local.cluster_network} --volume ${local.storage_path}:/tmp/k3d-${var.cluster_name}-storage"
  }
}

# Generate kubeconfig
resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.create_cluster]
  
  provisioner "local-exec" {
    command = "k3d kubeconfig get ${var.cluster_name} > ${path.module}/kubeconfig-${var.cluster_name}"
  }
}

# Generate cluster configuration
resource "local_file" "cluster_config" {
  content = yamlencode({
    name        = var.cluster_name
    image       = var.k3s_image
    servers     = var.servers
    agents      = var.agents
    network     = local.cluster_network
    storage_path = local.storage_path
    created_at   = timestamp()
    environment  = var.environment
  })
  
  filename = "${path.module}/cluster-config.yaml"
}

# Outputs
output "cluster_name" {
  description = "Name of k3d cluster"
  value       = var.cluster_name
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = "${path.module}/kubeconfig-${var.cluster_name}"
}

output "network_name" {
  description = "Name of cluster network"
  value       = local.cluster_network
}

output "storage_path" {
  description = "Path to cluster storage"
  value       = local.storage_path
}

output "cluster_config" {
  description = "Path to cluster configuration file"
  value       = local_file.cluster_config.filename
}
