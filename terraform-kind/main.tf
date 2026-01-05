# Main Terraform Configuration (Modular)
# This replaces the monolithic main.tf with clean module calls

terraform {
  required_version = ">= 1.0"
}

# Include shared providers
module "providers" {
  source = "./shared/providers"
}

# Create Kubernetes cluster
module "kubernetes" {
  source = "./modules/kubernetes"

  cluster_name       = var.kind_cluster_name
  kubernetes_version = "1.28.0"
  enable_registry    = true
  registry_port      = 5001
}

# Setup networking (MetalLB + Ingress)
module "networking" {
  source = "./modules/networking"

  depends_on = [module.kubernetes]

  metallb_ip_range    = var.metallb_ip_range
  ingress_nginx_ip    = var.ingress_nginx_ip
  enable_ingress      = true
  ingress_replicas    = 1
}

# Install monitoring stack
module "monitoring" {
  source = "./modules/monitoring"

  depends_on = [module.networking]

  prometheus_ip             = var.prometheus_ip
  grafana_ip               = var.grafana_ip
  alertmanager_ip          = var.alertmanager_ip
  grafana_admin_password   = var.grafana_admin_password
  prometheus_storage_size  = "10Gi"
  grafana_storage_size     = "5Gi"
  alertmanager_storage_size = "2Gi"
  enable_monitoring        = true
}

# Install security components
module "security" {
  source = "./modules/security"

  depends_on = [module.networking]

  # ArgoCD settings
  argocd_ip             = var.argocd_ip
  argocd_admin_password = var.argocd_admin_password
  enable_argocd        = true

  # Sealed Secrets with production best practices
  enable_sealed_secrets = true
  sealed_secrets_key_rotation = var.sealed_secrets_key_rotation
  sealed_secrets_key_rotation_interval = var.sealed_secrets_key_rotation_interval
  sealed_secrets_backup_enabled = var.sealed_secrets_backup_enabled
}

# Apply Kubernetes manifests (RBAC, network policies, etc.)
resource "kubectl_manifest" "rbac_policies" {
  depends_on = [module.kubernetes]

  yaml_body = file("${path.module}/../k8s-manifests/security/rbac-policies.yaml")
}

resource "kubectl_manifest" "security_contexts" {
  depends_on = [module.kubernetes]

  yaml_body = file("${path.module}/../k8s-manifests/security/security-contexts.yaml")
}

# Apply network policies
resource "kubectl_manifest" "network_policies" {
  depends_on = [module.kubernetes]

  yaml_body = file("${path.module}/../k8s-manifests/networking/network-policies.yaml")
}

# Storage setup
resource "helm_release" "local_path_provisioner" {
  depends_on = [module.kubernetes]

  name       = "local-path-provisioner"
  repository = "https://charts.rancher.io"
  chart      = "local-path-provisioner"
  version    = "0.0.24"
  namespace  = "local-path-storage"

  create_namespace = true

  values = [
    yamlencode({
      storageClass = {
        create = true
        name   = "local-path"
        defaultClass = true
        reclaimPolicy = "Delete"
        volumeBindingMode = "WaitForFirstConsumer"
        fsType = "ext4"
      }

      configMap = {
        setup = yamlencode({
          nodePathMap = [
            {
              node = "DEFAULT_PATH_FOR_NON_LISTED_NODES"
              paths = ["/var/local-path-provisioner"]
            }
          ]
        })

        teardown = yamlencode({
          nodePathMap = [
            {
              node = "DEFAULT_PATH_FOR_NON_LISTED_NODES"
              paths = ["/var/local-path-provisioner"]
            }
          ]
        })
      }
    })
  ]
}

# Persistent volume claims
resource "kubectl_manifest" "pvcs" {
  depends_on = [helm_release.local_path_provisioner]

  for_each = {
    "grafana-pvc" = {
      namespace = "monitoring"
      size      = "5Gi"
      labels    = { app = "grafana" }
    }
    "prometheus-pvc" = {
      namespace = "monitoring"
      size      = "10Gi"
      labels    = { app = "prometheus" }
    }
    "alertmanager-pvc" = {
      namespace = "monitoring"
      size      = "2Gi"
      labels    = { app = "alertmanager" }
    }
    "argocd-pvc" = {
      namespace = "argocd"
      size      = "5Gi"
      labels    = { app = "argocd" }
    }
  }

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"

    metadata = {
      name      = each.key
      namespace = each.value.namespace
      labels    = each.value.labels
    }

    spec = {
      accessModes = ["ReadWriteOnce"]
      storageClassName = "local-path"
      resources = {
        requests = {
          storage = each.value.size
        }
      }
    }
  })
}

# Outputs
output "cluster_name" {
  description = "Name of the created Kind cluster"
  value       = module.kubernetes.cluster_name
}

output "ingress_ip" {
  description = "NGINX Ingress LoadBalancer IP"
  value       = module.networking.ingress_nginx_ip
}

output "argocd_url" {
  description = "ArgoCD access URL"
  value       = module.security.argocd_url
}

output "grafana_url" {
  description = "Grafana access URL"
  value       = module.monitoring.grafana_url
}

output "prometheus_url" {
  description = "Prometheus access URL"
  value       = module.monitoring.prometheus_url
}

output "alertmanager_url" {
  description = "Alertmanager access URL"
  value       = module.monitoring.alertmanager_url
}
