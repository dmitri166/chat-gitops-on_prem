# Storage Module
# Reusable module for Kubernetes storage configuration

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

variable "storage_classes" {
  description = "Storage classes to create"
  type        = list(object({
    name         = string
    provisioner  = string
    parameters   = optional(map(string), {})
    reclaim_policy = optional(string, "Delete")
    volume_binding_mode = optional(string, "WaitForFirstConsumer")
    is_default_class = optional(bool, false)
  }))
  default = [
    {
      name         = "local-path"
      provisioner  = "rancher.io/local-path"
      reclaim_policy = "Delete"
      volume_binding_mode = "WaitForFirstConsumer"
      is_default_class = true
    },
    {
      name         = "fast-ssd"
      provisioner  = "rancher.io/local-path"
      reclaim_policy = "Delete"
      volume_binding_mode = "Immediate"
      is_default_class = false
    }
  ]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values
locals {
  default_tags = merge(var.tags, {
    "component"   = "storage"
    "managed-by"  = "terraform"
  })
}

# Create storage class manifests
resource "local_file" "storage_classes" {
  for_each = { for sc in var.storage_classes : sc.name => sc }
  
  content = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = each.value.name
      annotations = each.value.is_default_class ? {
        "storageclass.kubernetes.io/is-default-class" = "true"
      } : {}
      labels = local.default_tags
    }
    provisioner = each.value.provisioner
    reclaimPolicy = each.value.reclaim_policy
    volumeBindingMode = each.value.volume_binding_mode
    parameters = each.value.parameters
  })
  
  filename = "${path.module}/storage-class-${each.key}.yaml"
}

# Generate storage configuration
resource "local_file" "storage_config" {
  content = yamlencode({
    storage_classes = [
      for sc in var.storage_classes : {
        name         = sc.name
        provisioner  = sc.provisioner
        reclaim_policy = sc.reclaim_policy
        volume_binding_mode = sc.volume_binding_mode
        is_default_class = sc.is_default_class
        parameters   = sc.parameters
      }
    ]
    created_at = timestamp()
    environment = var.environment
  })
  
  filename = "${path.module}/storage-config.yaml"
}

# Outputs
output "storage_classes" {
  description = "List of storage class files"
  value       = [for f in local_file.storage_classes : f.filename]
}

output "storage_config" {
  description = "Path to storage configuration file"
  value       = local_file.storage_config.filename
}
