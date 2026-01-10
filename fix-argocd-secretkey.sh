#!/bin/bash

# 🔧 Fix ArgoCD Missing server.secretkey
# This adds the missing secretkey to the existing ArgoCD secret

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

KUBECONFIG="infrastructure/terraform/k3d-config"

log_info "🔧 Fixing ArgoCD server.secretkey..."

# Generate a random 32-byte secretkey and base64 encode it
SECRETKEY=$(openssl rand -base64 32 | tr -d '\n')
ENCODED=$(echo -n "$SECRETKEY" | base64 -w 0)

log_info "Generated secretkey, adding to ArgoCD secret..."

# Patch the secret
kubectl patch secret argocd-secret -n argocd \
  --type='json' \
  -p="[{\"op\": \"add\", \"path\": \"/data/server.secretkey\", \"value\": \"${ENCODED}\"}]" \
  --kubeconfig "$KUBECONFIG"

log_success "✅ server.secretkey added to ArgoCD secret"

log_info "Restarting ArgoCD server to pick up the change..."
kubectl rollout restart deployment argocd-server -n argocd --kubeconfig "$KUBECONFIG"

log_success "✅ ArgoCD server restarting..."
log_info "Wait 30 seconds, then refresh the ArgoCD UI"




