#!/bin/bash

# 🔧 Fix ArgoCD Terraform State
# This script fixes the Terraform state when ArgoCD is already deployed

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

cd infrastructure/terraform

log_info "🔧 Fixing ArgoCD Terraform state..."

# Option 1: Remove from state and re-import
log_info "Removing ArgoCD from Terraform state..."
terraform state rm 'module.security.helm_release.argocd[0]' 2>/dev/null || log_warning "Resource not in state or already removed"

log_info "Importing existing ArgoCD Helm release..."
terraform import 'module.security.helm_release.argocd[0]' argocd/argocd

log_success "✅ ArgoCD state fixed!"

log_info "Running terraform plan to verify..."
terraform plan

log_info "If plan shows no changes, run: terraform apply -auto-approve"

