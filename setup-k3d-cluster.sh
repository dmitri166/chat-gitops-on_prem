#!/bin/bash

# 🚀 k3d Cluster Setup with Best Practices
# Creates a clean k3d cluster with standard registry configuration

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

CLUSTER_NAME="chat-k3d"
REGISTRY_NAME="k3d-registry"
REGISTRY_PORT="5002"  # Using 5002 to avoid conflicts with port 5000

log_info "🚀 Setting up k3d cluster with best practices..."

# Step 1: Delete existing cluster (if exists)
log_info "Step 1: Cleaning up existing cluster..."
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    log_info "Deleting existing cluster: $CLUSTER_NAME"
    k3d cluster delete "$CLUSTER_NAME"
    log_success "✅ Cluster deleted"
else
    log_info "No existing cluster found, proceeding..."
fi

# Step 2: Delete existing registries (cleanup)
log_info "Step 2: Cleaning up existing registries..."
# Get all registry names and delete them
k3d registry list -o json 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read registry; do
    if [ -n "$registry" ]; then
        log_info "Deleting registry: $registry"
        k3d registry delete "$registry" 2>/dev/null || true
    fi
done
# Also try to delete by common names
for reg_name in "k3d-registry" "k3d-k3d-registry" "myregistry.localhost"; do
    k3d registry delete "$reg_name" 2>/dev/null || true
done
log_success "✅ Registries cleaned up"

# Step 3: Create registry with standard name
log_info "Step 3: Creating registry: ${REGISTRY_NAME}:${REGISTRY_PORT}..."
k3d registry create "$REGISTRY_NAME" --port "$REGISTRY_PORT"
log_success "✅ Registry created: ${REGISTRY_NAME}:${REGISTRY_PORT}"

# Step 4: Create cluster with registry attached
log_info "Step 4: Creating cluster with registry attached..."
k3d cluster create "$CLUSTER_NAME" \
  --registry-use "${REGISTRY_NAME}:${REGISTRY_PORT}" \
  --agents 2 \
  --k3s-arg "--disable=traefik@server:0"
log_success "✅ Cluster created with registry attached"

# Step 5: Get kubeconfig
log_info "Step 5: Getting kubeconfig..."
mkdir -p infrastructure/terraform
k3d kubeconfig get "$CLUSTER_NAME" > infrastructure/terraform/k3d-config
log_success "✅ Kubeconfig saved to infrastructure/terraform/k3d-config"

# Step 6: Verify cluster
log_info "Step 6: Verifying cluster..."
kubectl --kubeconfig infrastructure/terraform/k3d-config get nodes
log_success "✅ Cluster is ready"

echo ""
log_success "🎉 k3d cluster setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Build image: docker build -t ${REGISTRY_NAME}:${REGISTRY_PORT}/chat-app:latest applications/chat-app/source/"
echo "2. Push image: docker push ${REGISTRY_NAME}:${REGISTRY_PORT}/chat-app:latest"
echo "3. Deploy infrastructure: cd infrastructure/terraform && terraform apply -auto-approve"
echo ""
log_info "💡 Registry name: ${REGISTRY_NAME}:${REGISTRY_PORT} (standard k3d naming)"

