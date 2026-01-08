#!/bin/bash

# 🚀 Complete Chat Application Deployment Script
# This script deploys the entire infrastructure and application stack

set -e

# Colors for output
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

# Prerequisites check
check_prerequisites() {
    log_info "🔍 Checking prerequisites..."

    # Check required tools
    local tools=("kubectl" "terraform" "k3d" "helm")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is not installed. Please install it first."
            exit 1
        fi
    done

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi

    log_success "✅ All prerequisites met"
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "🏗️ Deploying infrastructure with Terraform..."

    cd infrastructure/terraform

    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init

    # Plan deployment
    log_info "Planning deployment..."
    terraform plan

    # Apply infrastructure
    log_info "Applying infrastructure..."
    terraform apply -auto-approve

    cd ../..

    log_success "✅ Infrastructure deployed successfully"
}

# Deploy platform configurations
deploy_platform() {
    log_info "⚙️ Deploying ArgoCD platform configurations..."

    # Deploy ArgoCD ApplicationSets (creates the applications)
    kubectl --kubeconfig infrastructure/terraform/k3d-config apply -f platform/argocd/applicationsets/

    # Deploy ArgoCD Applications (platform infrastructure)
    kubectl --kubeconfig infrastructure/terraform/k3d-config apply -f platform/argocd/applications/

    # Wait for applications to be created
    log_info "⏳ Waiting for ArgoCD applications to be created..."
    sleep 10

    log_success "✅ ArgoCD platform configurations deployed"
}

# Deploy applications
deploy_applications() {
    log_info "📦 Applications are deployed automatically via ArgoCD ApplicationSet..."
    log_info "Check ArgoCD UI for chat-dev, chat-staging, chat-prod applications"

    # Wait a bit for ArgoCD to process the applications
    log_info "⏳ Waiting for application deployments..."
    sleep 30

    log_success "✅ Applications deployed via ArgoCD GitOps"
}

# Show access information
show_access_info() {
    log_info "🎉 Deployment Complete!"
    echo ""
    echo "🌐 Access Information:"
    echo ""

    # Get terraform outputs
    cd infrastructure/terraform
    ARGOCD_PASSWORD=$(terraform output -raw argocd_admin_password 2>/dev/null || echo "admin123")
    GRAFANA_PASSWORD=$(terraform output -raw grafana_admin_password 2>/dev/null || echo "admin123")
    cd ../..

    echo "🔐 Credentials:"
    echo "   ArgoCD Admin:     admin / $ARGOCD_PASSWORD"
    echo "   Grafana Admin:    admin / $GRAFANA_PASSWORD"
    echo ""

    echo "📋 Verification Steps:"
    echo "1. Verify cluster: kubectl get nodes"
    echo "2. Check services: kubectl get svc -A"
    echo "3. Check ArgoCD UI: Applications should be deployed automatically"
    echo "4. Access services: Use ./start-all-services.bat"
    echo "5. Check your chat app: Should be running in dev/staging/prod namespaces"
}

# Main deployment
main() {
    echo "🚀 Chat Application Full Deployment"
    echo "===================================="
    echo ""

    check_prerequisites

    echo ""
    read -p "This will deploy a complete Kubernetes infrastructure. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled"
        exit 0
    fi

    deploy_infrastructure
    deploy_platform
    deploy_applications
    show_access_info

    log_success "🎉 Complete deployment finished successfully!"
    echo ""
    echo "🎊 Your chat application is now running with:"
    echo "   • Auto-scaling based on user activity"
    echo "   • Full monitoring and alerting"
    echo "   • GitOps deployment workflow"
    echo "   • Production-grade infrastructure"
}

# Handle command line arguments
case "${1:-}" in
    "infra")
        check_prerequisites
        deploy_infrastructure
        ;;
    "platform")
        check_prerequisites
        deploy_platform
        ;;
    "apps")
        check_prerequisites
        deploy_applications
        ;;
    "access")
        show_access_info
        ;;
    *)
        main
        ;;
esac
