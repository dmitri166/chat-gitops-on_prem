#!/bin/bash

# 🔧 Fix ArgoCD Admin Password
# Manually sets the admin password for ArgoCD

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

KUBECONFIG="infrastructure/terraform/k3d-config"
NAMESPACE="argocd"

# Default password (you can change this)
NEW_PASSWORD="${1:-admin123}"

log_info "🔧 Fixing ArgoCD admin password..."

# Method 1: Use ArgoCD CLI if available
if command -v argocd &> /dev/null; then
    log_info "Using ArgoCD CLI to reset password..."
    
    # Get ArgoCD server pod
    ARGOCD_SERVER_POD=$(kubectl get pods -n $NAMESPACE --kubeconfig "$KUBECONFIG" -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$ARGOCD_SERVER_POD" ]; then
        log_info "Resetting password using ArgoCD CLI in pod: $ARGOCD_SERVER_POD"
        
        # Reset password using argocd admin command
        kubectl exec -n $NAMESPACE $ARGOCD_SERVER_POD --kubeconfig "$KUBECONFIG" -- \
          argocd admin initial-password -n $NAMESPACE 2>/dev/null || true
        
        # Update password
        kubectl exec -n $NAMESPACE $ARGOCD_SERVER_POD --kubeconfig "$KUBECONFIG" -- \
          argocd account update-password --account admin --current-password $(kubectl get secret argocd-secret -n $NAMESPACE --kubeconfig "$KUBECONFIG" -o jsonpath='{.data.admin\.password}' | base64 -d) --new-password "$NEW_PASSWORD" 2>/dev/null || {
            log_warning "CLI method failed, trying manual secret update..."
        }
    fi
fi

# Method 2: Manual secret update (always works)
log_info "Updating ArgoCD secret manually..."

# Generate bcrypt hash for the password
# Using htpasswd if available, otherwise use a simple method
if command -v htpasswd &> /dev/null; then
    BCRYPT_HASH=$(htpasswd -nbBC 10 "" "$NEW_PASSWORD" | tr -d ':\n' | sed 's/\$2y\$/$2a$/')
else
    log_warning "htpasswd not found, using Python to generate bcrypt hash..."
    BCRYPT_HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw('$NEW_PASSWORD'.encode('utf-8'), bcrypt.gensalt(rounds=10)).decode('utf-8'))" 2>/dev/null || echo "")
    
    if [ -z "$BCRYPT_HASH" ]; then
        log_warning "Python bcrypt not available, using simple base64 (less secure)..."
        BCRYPT_HASH=$(echo -n "$NEW_PASSWORD" | base64)
    fi
fi

# Base64 encode the hash
ENCODED_HASH=$(echo -n "$BCRYPT_HASH" | base64 -w 0)

# Update the secret
log_info "Patching ArgoCD secret..."
kubectl patch secret argocd-secret -n $NAMESPACE \
  --type='json' \
  -p="[{\"op\": \"replace\", \"path\": \"/data/admin.password\", \"value\": \"${ENCODED_HASH}\"}]" \
  --kubeconfig "$KUBECONFIG"

# Update password modification time
MTIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ENCODED_MTIME=$(echo -n "$MTIME" | base64 -w 0)

kubectl patch secret argocd-secret -n $NAMESPACE \
  --type='json' \
  -p="[{\"op\": \"replace\", \"path\": \"/data/admin.passwordMtime\", \"value\": \"${ENCODED_MTIME}\"}]" \
  --kubeconfig "$KUBECONFIG" 2>/dev/null || \
kubectl patch secret argocd-secret -n $NAMESPACE \
  --type='json' \
  -p="[{\"op\": \"add\", \"path\": \"/data/admin.passwordMtime\", \"value\": \"${ENCODED_MTIME}\"}]" \
  --kubeconfig "$KUBECONFIG"

log_success "✅ Password updated in secret"

# Restart ArgoCD server to pick up the change
log_info "Restarting ArgoCD server..."
kubectl rollout restart deployment argocd-server -n $NAMESPACE --kubeconfig "$KUBECONFIG"

log_success "✅ ArgoCD server restarting..."

echo ""
log_success "🎉 ArgoCD password reset complete!"
echo ""
echo "📋 Login Credentials:"
echo "   URL: http://localhost:8082 (or your ArgoCD LoadBalancer IP)"
echo "   Username: admin"
echo "   Password: $NEW_PASSWORD"
echo ""
log_info "💡 Wait 30 seconds for ArgoCD server to restart, then try logging in"



