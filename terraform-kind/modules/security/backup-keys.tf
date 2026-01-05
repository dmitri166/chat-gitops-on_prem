# Sealed Secrets Key Backup and Recovery
# Critical for production - backup your encryption keys!

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Backup Sealed Secrets encryption keys
resource "kubectl_manifest" "backup_sealed_secrets_keys" {
  depends_on = [helm_release.sealed_secrets]

  yaml_body = yamlencode({
    apiVersion = "batch/v1"
    kind       = "Job"

    metadata = {
      name      = "backup-sealed-secrets-keys"
      namespace = "sealed-secrets"
    }

    spec = {
      template = {
        spec = {
          serviceAccountName = "sealed-secrets-controller"
          restartPolicy      = "Never"

          containers = [
            {
              name  = "backup-keys"
              image = "bitnami/kubectl:latest"

              command = [
                "sh",
                "-c",
                <<-EOF
                # Backup encryption keys to ConfigMap
                kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > /tmp/keys-backup.yaml

                # Create backup ConfigMap
                kubectl create configmap sealed-secrets-key-backup \
                  --from-file=keys.yaml=/tmp/keys-backup.yaml \
                  --dry-run=client -o yaml | kubectl apply -f -

                echo "Sealed Secrets keys backed up successfully"
                EOF
              ]
            }
          ]
        }
      }
    }
  })
}

# Example: Store backup in external location (AWS S3)
resource "aws_s3_object" "sealed_secrets_backup" {
  count = var.enable_backup_to_s3 ? 1 : 0

  bucket = var.backup_bucket
  key    = "sealed-secrets/keys-${timestamp()}.yaml"
  source = "/tmp/sealed-secrets-keys-backup.yaml"

  # In real implementation, you'd need to:
  # 1. Run the backup job
  # 2. Extract the keys
  # 3. Upload to S3
}

variable "enable_backup_to_s3" {
  description = "Enable backup to AWS S3"
  type        = bool
  default     = false
}

variable "backup_bucket" {
  description = "S3 bucket for backups"
  type        = string
  default     = ""
}
