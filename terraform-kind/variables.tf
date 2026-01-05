variable "kind_cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "chat-local"
}

variable "metallb_ip_range" {
  description = "IP range for MetalLB LoadBalancer services"
  type        = string
  default     = "172.18.255.1-172.18.255.250"
}

variable "ingress_nginx_ip" {
  description = "Static IP for NGINX Ingress"
  type        = string
  default     = "172.18.255.100"
}

variable "argocd_ip" {
  description = "Static IP for ArgoCD"
  type        = string
  default     = "172.18.255.101"
}

variable "prometheus_ip" {
  description = "Static IP for Prometheus"
  type        = string
  default     = "172.18.255.102"
}

variable "grafana_ip" {
  description = "Static IP for Grafana"
  type        = string
  default     = "172.18.255.103"
}

variable "alertmanager_ip" {
  description = "Static IP for Alertmanager"
  type        = string
  default     = "172.18.255.104"
}

variable "master_cpu_request" {
  description = "CPU request for master node"
  type        = string
  default     = "1000m"
}

variable "master_memory_request" {
  description = "Memory request for master node"
  type        = string
  default     = "2Gi"
}

variable "master_cpu_limit" {
  description = "CPU limit for master node"
  type        = string
  default     = "2000m"
}

variable "master_memory_limit" {
  description = "Memory limit for master node"
  type        = string
  default     = "4Gi"
}

variable "worker_cpu_request" {
  description = "CPU request for worker nodes"
  type        = string
  default     = "500m"
}

variable "worker_memory_request" {
  description = "Memory request for worker nodes"
  type        = string
  default     = "1Gi"
}

variable "worker_cpu_limit" {
  description = "CPU limit for worker nodes"
  type        = string
  default     = "1000m"
}

variable "worker_memory_limit" {
  description = "Memory limit for worker nodes"
  type        = string
  default     = "2Gi"
}

# Security variables (PRODUCTION BEST PRACTICES)
variable "sealed_secrets_key_rotation" {
  description = "Enable automatic key rotation for Sealed Secrets"
  type        = bool
  default     = true
}

variable "sealed_secrets_key_rotation_interval" {
  description = "Key rotation interval (e.g., '720h' for 30 days)"
  type        = string
  default     = "720h"
}

variable "sealed_secrets_backup_enabled" {
  description = "Enable automatic key backup for Sealed Secrets"
  type        = bool
  default     = true
}

variable "argocd_admin_password" {
  description = "Admin password for ArgoCD"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"
  sensitive   = true
}
