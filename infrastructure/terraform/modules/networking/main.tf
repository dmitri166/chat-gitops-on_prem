# Networking Module
# Handles MetalLB, NGINX Ingress, and network policies

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Providers configured at root level

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

variable "enable_ingress" {
  description = "Enable NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "ingress_replicas" {
  description = "Number of NGINX Ingress replicas"
  type        = number
  default     = 1
}

# Install MetalLB for LoadBalancer services
resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.13.12"
  namespace  = "metallb-system"

  create_namespace = true

  # configInline removed - now using separate ConfigMap
  values = [
    yamlencode({
      # MetalLB configuration moved to separate ConfigMap
      speaker = {
        tolerateMaster = true
      }
    })
  ]
}

# MetalLB Configuration moved to GitOps
# See: development/gitops-local/chat-gitops/infrastructure/metallb/
# - IPAddressPool and L2Advertisement are now deployed via ArgoCD

# Install NGINX Ingress Controller
resource "helm_release" "ingress_nginx" {
  count = var.enable_ingress ? 1 : 0

  depends_on = [helm_release.metallb]

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.9.0"
  namespace  = "ingress-nginx"

  create_namespace = true

  # Increase timeout for slow chart deployments
  timeout = 600  # 10 minutes

  values = [
    yamlencode({
      controller = {
        replicaCount = var.ingress_replicas

        service = {
          type = "LoadBalancer"
          annotations = {
            "metallb.universe.tf/loadBalancerIPs" = var.ingress_nginx_ip
          }
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }

        # Removed node selector and tolerations for k3d compatibility
        # nodeSelector = {
        #   "env" = "system"
        # }

        # tolerations = [
        #   {
        #     key      = "env"
        #     operator = "Equal"
        #     value    = "system"
        #     effect   = "NoSchedule"
        #   }
        # ]

        config = {
          "use-forwarded-headers" = "true"
          "proxy-real-ip-cidr"    = "0.0.0.0/0"
          "proxy-body-size"       = "50m"
          "server-tokens"         = "false"
        }

        # Metrics enabled, ServiceMonitor will be created via ArgoCD/GitOps
        # after monitoring stack is deployed
        metrics = {
          enabled = true
          # serviceMonitor disabled here, will be created via GitOps
          # serviceMonitor = {
          #   enabled = true
          #   namespace = "monitoring"
          # }
        }
      }

      # Disable default backend to avoid image pull issues
      # Will be handled by application-specific backends
      defaultBackend = {
        enabled = false
      }

      admissionWebhooks = {
        enabled = false
      }
    })
  ]
}

output "metallb_ip_range" {
  description = "IP range used by MetalLB"
  value       = var.metallb_ip_range
}

# Storage setup - Minikube has built-in storage provisioner
# No need for additional storage class configuration

# Persistent volume claims will be created by individual services
# Minikube's default storage class handles PVC provisioning automatically

output "ingress_nginx_ip" {
  description = "IP address assigned to NGINX Ingress"
  value       = var.ingress_nginx_ip
}
