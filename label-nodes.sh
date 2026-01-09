#!/bin/bash

# 🏷️ Label k3d Nodes for Chat App Scheduling
# Adds environment labels to nodes for pod scheduling

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

log_info "🏷️ Labeling k3d nodes for chat app scheduling..."

# Label agent nodes as nonprod (for dev/staging)
log_info "Labeling agent nodes with env=nonprod..."
kubectl label nodes k3d-chat-k3d-agent-0 env=nonprod --overwrite --kubeconfig "$KUBECONFIG"
kubectl label nodes k3d-chat-k3d-agent-1 env=nonprod --overwrite --kubeconfig "$KUBECONFIG"

# Label one agent node as prod (for production)
log_info "Labeling agent-0 with env=prod (can schedule both nonprod and prod)..."
kubectl label nodes k3d-chat-k3d-agent-0 env=prod --overwrite --kubeconfig "$KUBECONFIG"

# Add taints to match tolerations (optional - for strict separation)
log_info "Adding taints to nodes..."
kubectl taint nodes k3d-chat-k3d-agent-0 env=nonprod:NoSchedule --overwrite --kubeconfig "$KUBECONFIG" || true
kubectl taint nodes k3d-chat-k3d-agent-1 env=nonprod:NoSchedule --overwrite --kubeconfig "$KUBECONFIG" || true
kubectl taint nodes k3d-chat-k3d-agent-0 env=prod:NoSchedule --overwrite --kubeconfig "$KUBECONFIG" || true

log_success "✅ Nodes labeled successfully!"

echo ""
log_info "📋 Node labels:"
kubectl get nodes --show-labels --kubeconfig "$KUBECONFIG" | grep -E "(NAME|chat-k3d)"

echo ""
log_success "🎉 Pods should now be able to schedule!"
log_info "💡 Check pods: kubectl get pods -A --kubeconfig $KUBECONFIG | grep chat-app"



