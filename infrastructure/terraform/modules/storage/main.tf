

resource "kubernetes_namespace" "env" {
  for_each = toset(var.envs)
  metadata {
    name = each.key
  }
}

resource "kubernetes_persistent_volume_claim" "chat_logs" {
  for_each = toset(var.envs)

  metadata {
    name      = "chat-logs-${each.key}"
    namespace = each.key
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.pvc_size
      }
    }

    storage_class_name = "local-path"
  }
}

output "namespaces" {
  value = [for n in kubernetes_namespace.env : n.metadata[0].name]
}
