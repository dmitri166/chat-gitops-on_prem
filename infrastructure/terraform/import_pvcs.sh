#!/usr/bin/env bash
set -euo pipefail

# Import existing namespaces and PVCs into Terraform module.storage state.
# Run this from a shell with terraform installed and KUBECONFIG set (if needed).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Initializing Terraform..."
terraform init

echo "Importing namespaces..."
terraform import 'module.storage.kubernetes_namespace.env["dev"]' dev || true
terraform import 'module.storage.kubernetes_namespace.env["staging"]' staging || true
terraform import 'module.storage.kubernetes_namespace.env["prod"]' prod || true

echo "Importing PVCs..."
terraform import 'module.storage.kubernetes_persistent_volume_claim.chat_logs["dev"]' dev/chat-logs-dev || true
terraform import 'module.storage.kubernetes_persistent_volume_claim.chat_logs["staging"]' staging/chat-logs-staging || true
terraform import 'module.storage.kubernetes_persistent_volume_claim.chat_logs["prod"]' prod/chat-logs-prod || true

echo "Import complete. Run 'terraform plan' to verify." 
