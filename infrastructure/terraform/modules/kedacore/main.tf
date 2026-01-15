# KEDA Module - Simplified Approach
# Kubernetes Event-Driven Autoscaling for Ghost

terraform {
  required_version = ">= 1.5"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Input variables
variable "cluster_name" {
  description = "Name of k3d cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "namespace" {
  description = "Kubernetes namespace for KEDA"
  type        = string
  default     = "ghost"
}

variable "ghost_namespace" {
  description = "Ghost application namespace"
  type        = string
  default     = "ghost"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values
locals {
  common_tags = merge(var.tags, {
    "component"   = "autoscaling"
    "managed-by"  = "terraform"
    "environment"  = var.environment
  })
}

# Install KEDA using local-exec
resource "null_resource" "install_keda" {
  provisioner "local-exec" {
    command = "helm repo add kedacore https://kedacore.github.io/charts && helm upgrade --install keda kedacore/keda --namespace ${var.namespace} --create-namespace"
  }

  depends_on = [
    null_resource.wait_for_cluster
  ]
}

# Wait for cluster to be ready
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = "kubectl cluster-info"
  }
  
  depends_on = [
    time_sleep.wait_for_kubeconfig
  ]
}

# Wait for kubeconfig to be created
resource "time_sleep" "wait_for_kubeconfig" {
  create_duration = "10s"
}

# Outputs
output "kedacore_namespace" {
  description = "KEDA namespace"
  value       = var.namespace
}
