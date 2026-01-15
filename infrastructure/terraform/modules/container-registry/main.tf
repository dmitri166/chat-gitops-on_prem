# Container Registry Module
# Reusable module for k3d container registry using local commands

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

variable "registry_name" {
  description = "Name of container registry"
  type        = string
  default     = "ghost-k3d-registry-new"
}

variable "registry_port" {
  description = "Port for registry"
  type        = number
  default     = 5001
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values
locals {
  default_tags = merge(var.tags, {
    "component"   = "container-registry"
    "managed-by"  = "terraform"
  })
}

# Create container registry using local command
resource "null_resource" "create_registry" {
  provisioner "local-exec" {
    command = "k3d registry create ${var.registry_name} --port ${var.registry_port} --cluster ${var.cluster_name}"
  }
}

# Generate registry configuration
resource "local_file" "registry_config" {
  content = yamlencode({
    name        = var.registry_name
    port        = var.registry_port
    cluster     = var.cluster_name
    endpoint    = "localhost:${var.registry_port}"
    created_at   = timestamp()
  })
  
  filename = "${path.module}/registry-config.yaml"
}

# Outputs
output "registry_name" {
  description = "Name of container registry"
  value       = var.registry_name
}

output "endpoint" {
  description = "Registry endpoint"
  value       = "localhost:${var.registry_port}"
}

output "port" {
  description = "Registry port"
  value       = var.registry_port
}

output "registry_config" {
  description = "Path to registry configuration file"
  value       = local_file.registry_config.filename
}
