# Sealed Secrets Monitoring and Alerts (PRODUCTION BEST PRACTICE)

resource "kubectl_manifest" "sealed_secrets_servicemonitor" {
  count = var.enable_sealed_secrets ? 1 : 0

  depends_on = [helm_release.sealed_secrets]

  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "sealed-secrets"
      namespace = "monitoring"
      labels = {
        "app.kubernetes.io/name" = "sealed-secrets"
      }
    }

    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "sealed-secrets"
        }
      }

      endpoints = [
        {
          port        = "http"
          path        = "/metrics"
          interval    = "30s"
          scrapeTimeout = "10s"
        }
      ]

      namespaceSelector = {
        matchNames = ["sealed-secrets"]
      }
    }
  })
}

# Prometheus Rules for Sealed Secrets (PRODUCTION BEST PRACTICE)
resource "kubectl_manifest" "sealed_secrets_prometheus_rules" {
  count = var.enable_sealed_secrets ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"

    metadata = {
      name      = "sealed-secrets-alerts"
      namespace = "monitoring"
      labels = {
        "app.kubernetes.io/name" = "sealed-secrets"
        "prometheus" = "kube-prometheus"
        "role" = "alert-rules"
      }
    }

    spec = {
      groups = [
        {
          name = "sealed-secrets"
          rules = [
            # Critical: No encryption keys
            {
              alert = "SealedSecretsKeyMissing"
              expr  = "absent(sealed_secrets_secret_count{namespace=\"sealed-secrets\"}) == 1"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Sealed Secrets encryption key missing"
                description = "Sealed Secrets has no encryption keys. Secret decryption will fail."
              }
            },
            # Warning: Controller down
            {
              alert = "SealedSecretsControllerDown"
              expr  = "up{job=\"sealed-secrets\", namespace=\"sealed-secrets\"} == 0"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Sealed Secrets controller is down"
                description = "Sealed Secrets controller has been down for more than 5 minutes."
              }
            },
            # Info: Key rotation
            {
              alert = "SealedSecretsKeyRotation"
              expr  = "increase(sealed_secrets_key_rotation_total[1h]) > 0"
              labels = {
                severity = "info"
              }
              annotations = {
                summary     = "Sealed Secrets key rotated"
                description = "Sealed Secrets encryption key has been rotated."
              }
            }
          ]
        }
      ]
    }
  })
}

# Grafana Dashboard for Sealed Secrets (PRODUCTION BEST PRACTICE)
resource "kubectl_manifest" "sealed_secrets_grafana_dashboard" {
  count = var.enable_sealed_secrets ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"

    metadata = {
      name      = "sealed-secrets-dashboard"
      namespace = "monitoring"
      labels = {
        "grafana_dashboard" = "1"
      }
    }

    data = {
      "sealed-secrets-dashboard.json" = jsonencode({
        dashboard = {
          title = "Sealed Secrets Overview"
          tags  = ["sealed-secrets", "security", "secrets"]
          timezone = "browser"
          panels = [
            {
              title = "Sealed Secrets Status"
              type  = "stat"
              targets = [
                {
                  expr = "up{job=\"sealed-secrets\"}"
                  legendFormat = "Controller Status"
                }
              ]
            },
            {
              title = "Active Encryption Keys"
              type  = "stat"
              targets = [
                {
                  expr = "sealed_secrets_secret_count{namespace=\"sealed-secrets\"}"
                  legendFormat = "Keys"
                }
              ]
            },
            {
              title = "Sealed Secrets Processed"
              type  = "graph"
              targets = [
                {
                  expr = "rate(sealed_secrets_sealed_secret_created_total[5m])"
                  legendFormat = "Created/sec"
                },
                {
                  expr = "rate(sealed_secrets_sealed_secret_deleted_total[5m])"
                  legendFormat = "Deleted/sec"
                }
              ]
            }
          ]
          time = {
            from = "now-1h"
            to   = "now"
          }
          refresh = "30s"
        }
      })
    }
  })
}
