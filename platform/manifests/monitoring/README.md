# Monitoring Configuration

This directory contains monitoring resources for the chat application.

## Files

- `sealed-secrets-dashboard.yaml` - Grafana dashboard for Sealed Secrets
- `sealed-secrets-prometheusrules.yaml` - Alert rules for Sealed Secrets
- `sealed-secrets-servicemonitor.yaml` - ServiceMonitor for Sealed Secrets metrics

## Access URLs

- Prometheus: http://172.18.255.102:9090
- Grafana: http://172.18.255.103:3000 (admin/admin123)
- Alertmanager: http://172.18.255.104:9093

## Current Status

Basic monitoring is configured with:
- Prometheus for metrics collection
- Grafana for dashboards
- Alertmanager for alert management
- Sealed Secrets monitoring

Alert notifications are not configured. To set up alerts, you'll need to:
1. Configure Alertmanager with your preferred notification method
2. Create PrometheusRule resources for your applications
3. Test alert delivery
