# Enhanced Infrastructure with Terraform Best Practices
# Implements modules, state management, security, and proper IaC patterns

terraform {
  required_version = ">= 1.5"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  # Backend configuration for state management
  backend "local" {
    path = "./terraform.tfstate"
  }
}

# Input variables with validation
variable "cluster_name" {
  description = "Name of k3d cluster"
  type        = string
  default     = "ghost-k3d"
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

variable "enable_kedacore" {
  description = "Enable KEDA autoscaling"
  type        = bool
  default     = true
}

variable "ghost_namespace" {
  description = "Ghost application namespace"
  type        = string
  default     = "ghost"
}

variable "cluster_cpu_limit" {
  description = "CPU limit for cluster nodes"
  type        = string
  default     = "2"
}

variable "cluster_memory_limit" {
  description = "Memory limit for cluster nodes"
  type        = string
  default     = "4Gi"
}

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Enable security policies"
  type        = bool
  default     = true
}

variable "enable_networking" {
  description = "Enable networking components"
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Enable storage classes"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values for security
locals {
  cluster_network = "${var.cluster_name}-network"
  storage_path   = "/tmp/k3d-${var.cluster_name}-storage"
  
  # Security labels
  security_labels = {
    "security.company"      = "chat-app"
    "security.environment" = var.environment
    "security.managed-by"  = "terraform"
    "security.version"     = "1.0.0"
  }
  
  # Common tags
  common_tags = merge(local.security_labels, {
    "project"     = "chat-app"
    "component"   = "infrastructure"
    "terraform"   = "true"
  })
}

# Module for k3d cluster
module "k3d_cluster" {
  source = "./modules/k3d-cluster"
  
  cluster_name = var.cluster_name
  k3s_image   = var.k3s_image
  environment  = var.environment
  
  tags = local.common_tags
}

# Module for container registry
module "container_registry" {
  source = "./modules/container-registry"
  
  cluster_name = var.cluster_name
  registry_name = "${var.cluster_name}-registry"
  
  tags = local.common_tags
}

# Module for storage
module "storage" {
  source = "./modules/storage"
  
  cluster_name = module.k3d_cluster.cluster_name
  environment  = var.environment
  
  tags = local.common_tags
}

# Module for networking
module "networking" {
  source = "./modules/networking"
  
  cluster_name = module.k3d_cluster.cluster_name
  network_name = local.cluster_network
  
  tags = local.common_tags
}

# Module for ArgoCD GitOps
module "argocd" {
  source = "./modules/argocd"
  
  cluster_name = module.k3d_cluster.cluster_name
  environment  = var.environment
  namespace    = "argocd"
  admin_password = random_password.argocd_admin.result
  
  tags = local.common_tags
}

# Module for KEDA autoscaling
module "kedacore" {
  source = "./modules/kedacore"
  
  cluster_name = module.k3d_cluster.cluster_name
  environment  = var.environment
  namespace    = "ghost"
  ghost_namespace = var.ghost_namespace
  
  tags = local.common_tags
}

# Module for monitoring (optional)
module "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"
  
  cluster_name = module.k3d_cluster.cluster_name
  environment  = var.environment
  
  tags = local.common_tags
}

# Module for security (optional)
module "security" {
  count = var.enable_security ? 1 : 0
  source = "./modules/security"
  
  cluster_name = module.k3d_cluster.cluster_name
  environment  = var.environment
  
  tags = local.common_tags
}

# Generate kubeconfig
resource "local_file" "kubeconfig" {
  content  = "# Kubeconfig will be generated by k3d cluster"
  filename = "${path.module}/k3d-config"
  
  depends_on = [
    module.k3d_cluster,
    module.container_registry,
    module.storage,
    module.networking
  ]
}

# Generate cluster information
resource "local_file" "cluster_info" {
  content = jsonencode({
    cluster_name = module.k3d_cluster.cluster_name
    environment  = var.environment
    kubeconfig   = local_file.kubeconfig.filename
    registry     = module.container_registry.endpoint
    storage_path = local.storage_path
    network_name = local.cluster_network
    created_at   = timestamp()
    version      = "1.0.0"
  })
  
  filename = "${path.module}/cluster-info.json"
}

# Security: Generate random passwords
resource "random_password" "argocd_admin" {
  length  = 32
  special  = true
}

resource "random_password" "grafana_admin" {
  length  = 32
  special  = true
}

# Store secrets securely
resource "local_file" "secrets" {
  content = jsonencode({
    argocd = {
      username = "admin"
      password = random_password.argocd_admin.result
    }
    grafana = {
      username = "admin"
      password = random_password.grafana_admin.result
    }
  })
  
  filename = "${path.module}/secrets.json"
  file_permission = "0600"
}

# Outputs with sensitive data handling
output "cluster_name" {
  description = "Name of the k3d cluster"
  value       = module.k3d_cluster.cluster_name
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = local_file.kubeconfig.filename
  sensitive   = true
}

output "registry_endpoint" {
  description = "Container registry endpoint"
  value       = module.container_registry.endpoint
}

output "cluster_info" {
  description = "Cluster information"
  value       = local_file.cluster_info.filename
}

output "secrets_file" {
  description = "Path to secrets file"
  value       = local_file.secrets.filename
  sensitive   = true
}

output "argocd_password" {
  description = "ArgoCD admin password"
  value       = random_password.argocd_admin.result
  sensitive   = true
}

output "grafana_password" {
  description = "Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}
