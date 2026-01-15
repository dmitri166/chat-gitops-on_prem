# Security Module
# Reusable module for Kubernetes security configuration

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

variable "security_policies" {
  description = "Security policies to apply"
  type        = object({
    network_policies = optional(bool, true)
    pod_security = optional(bool, true)
    rbac = optional(bool, true)
  })
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values
locals {
  default_tags = merge(var.tags, {
    "component"   = "security"
    "managed-by"  = "terraform"
  })
  
  security_config = merge(var.security_policies, {
    network_policies = true
    pod_security = true
    rbac = true
  })
}

# Generate network policies
resource "local_file" "network_policies" {
  content = local.security_config.network_policies ? yamlencode({
    apiVersion = "v1"
    kind = "NetworkPolicy"
    metadata = {
      name = "default-deny-all"
      namespace = "default"
      labels = local.default_tags
    }
    spec = {
      podSelector = {}
      policyTypes = ["Ingress", "Egress"]
    }
  }) : "# Network policies disabled"
  
  filename = "${path.module}/network-policies.yaml"
}

# Generate Pod Security Policy
resource "local_file" "pod_security" {
  content = local.security_config.pod_security ? yamlencode({
    apiVersion = "policy/v1beta1"
    kind = "PodSecurityPolicy"
    metadata = {
      name = "restricted"
      labels = local.default_tags
    }
    spec = {
      privileged = false
      allowPrivilegeEscalation = false
      requiredDropCapabilities = ["ALL"]
      volumes = {
        configMap = {
          allowed = true
        }
        emptyDir = {
          allowed = true
        }
        projected = {
          allowed = true
        }
        secret = {
          allowed = true
        }
        downwardAPI = {
          allowed = true
        }
        persistentVolumeClaim = {
          allowed = true
        }
      }
      runAsUser = {
        rule = "MustRunAsNonRoot"
      }
      seLinux = {
        rule = "RunAsAny"
      }
      fsGroup = {
        rule = "RunAsAny"
      }
    }
  }) : "# Pod security policies disabled"
  
  filename = "${path.module}/pod-security.yaml"
}

# Generate RBAC configuration
resource "local_file" "rbac_config" {
  content = local.security_config.rbac ? yamlencode({
    apiVersion = "v1"
    kind = "Namespace"
    metadata = {
      name = "security"
      labels = local.default_tags
    }
  }) : "# RBAC disabled"
  
  filename = "${path.module}/rbac.yaml"
}

# Generate security configuration
resource "local_file" "security_config" {
  content = yamlencode({
    cluster_name = var.cluster_name
    environment = var.environment
    security = local.security_config
    network_policies = local_file.network_policies.filename
    pod_security = local_file.pod_security.filename
    rbac = local_file.rbac_config.filename
    created_at = timestamp()
  })
  
  filename = "${path.module}/security-config.yaml"
}

# Outputs
output "network_policies" {
  description = "Path to network policies"
  value       = local_file.network_policies.filename
}

output "pod_security" {
  description = "Path to pod security policies"
  value       = local_file.pod_security.filename
}

output "rbac_config" {
  description = "Path to RBAC configuration"
  value       = local_file.rbac_config.filename
}

output "security_config" {
  description = "Path to security configuration"
  value       = local_file.security_config.filename
}
