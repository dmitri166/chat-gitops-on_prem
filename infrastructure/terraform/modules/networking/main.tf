# Networking Module
# Reusable module for Kubernetes networking configuration

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

variable "network_name" {
  description = "Name of the network"
  type        = string
}

variable "ip_ranges" {
  description = "IP address ranges for services"
  type        = object({
    metallb = optional(list(string), ["172.18.255.200-172.18.255.250"])
    services = optional(list(string), ["172.18.255.100-172.18.255.199"])
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
    "component"   = "networking"
    "managed-by"  = "terraform"
  })
  
  metallb_range = length(var.ip_ranges.metallb) > 0 ? var.ip_ranges.metallb : ["172.18.255.200-172.18.255.250"]
  services_range = length(var.ip_ranges.services) > 0 ? var.ip_ranges.services : ["172.18.255.100-172.18.255.199"]
}

# Generate MetalLB configuration
resource "local_file" "metallb_config" {
  content = yamlencode({
    apiVersion = "v1"
    kind = "ConfigMap"
    metadata = {
      name = "metallb-config"
      namespace = "metallb-system"
      labels = local.default_tags
    }
    data = {
      config = yamlencode({
        address_pools = [
          {
            name = "default"
            protocol = "layer2"
            addresses = local.metallb_range
          }
        ]
      })
    }
  })
  
  filename = "${path.module}/metallb-config.yaml"
}

# Generate Ingress configuration
resource "local_file" "ingress_config" {
  content = yamlencode({
    apiVersion = "networking.k8s.io/v1"
    kind = "IngressClass"
    metadata = {
      name = "nginx"
      annotations = {
        "ingressclass.kubernetes.io/is-default-class" = "true"
      }
      labels = local.default_tags
    }
    spec = {
      controller = "k8s.io/ingress-nginx"
    }
  })
  
  filename = "${path.module}/ingress-class.yaml"
}

# Generate service IP assignments
resource "local_file" "service_ips" {
  content = yamlencode({
    service_assignments = {
      "argocd"       = "172.18.255.100"
      "prometheus"    = "172.18.255.101"
      "grafana"       = "172.18.255.102"
      "alertmanager"  = "172.18.255.103"
      "tempo"        = "172.18.255.104"
      "chat-dev"     = "172.18.255.105"
      "chat-staging" = "172.18.255.106"
      "chat-prod"    = "172.18.255.107"
    }
    ip_ranges = {
      metallb = local.metallb_range
      services = local.services_range
    }
    created_at = timestamp()
  })
  
  filename = "${path.module}/service-ips.yaml"
}

# Generate network configuration
resource "local_file" "network_config" {
  content = yamlencode({
    cluster_name = var.cluster_name
    network_name = var.network_name
    metallb_config = local_file.metallb_config.filename
    ingress_class = local_file.ingress_config.filename
    service_ips = local_file.service_ips.filename
    ip_ranges = {
      metallb = local.metallb_range
      services = local.services_range
    }
    created_at = timestamp()
  })
  
  filename = "${path.module}/network-config.yaml"
}

# Outputs
output "metallb_config" {
  description = "Path to MetalLB configuration"
  value       = local_file.metallb_config.filename
}

output "ingress_class" {
  description = "Path to Ingress class configuration"
  value       = local_file.ingress_config.filename
}

output "service_ips" {
  description = "Path to service IP assignments"
  value       = local_file.service_ips.filename
}

output "network_config" {
  description = "Path to network configuration"
  value       = local_file.network_config.filename
}
