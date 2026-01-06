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
    terraform plan -out=tfplan

    # Apply infrastructure
    log_info "Applying infrastructure..."
    terraform apply tfplan

    # Wait for cluster to be ready
    log_info "Waiting for cluster to be fully ready..."
    sleep 30

    cd ../..

    log_success "✅ Infrastructure deployed successfully"
}

# Deploy platform configurations
deploy_platform() {
    log_info "⚙️ Deploying platform configurations with ArgoCD..."

    # Set kubeconfig
    export KUBECONFIG=./infrastructure/terraform/k3d-config

    # Deploy infrastructure applications
    log_info "Deploying MetalLB and monitoring configurations..."
    kubectl apply -f platform/argocd/applications/

    # Wait for applications to sync
    log_info "Waiting for ArgoCD applications to sync..."
    sleep 60

    log_success "✅ Platform configurations deployed"
}

# Deploy applications
deploy_applications() {
    log_info "📦 Deploying applications..."

    # Set kubeconfig
    export KUBECONFIG=./infrastructure/terraform/k3d-config

    # Deploy ApplicationSet for chat app
    log_info "Deploying chat application ApplicationSet..."
    kubectl apply -f platform/argocd/applicationsets/

    # Wait for applications to deploy
    log_info "Waiting for applications to deploy..."
    sleep 120

    log_success "✅ Applications deployed"
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

    echo "🌐 Service URLs:"
    echo "   ArgoCD:          https://172.18.255.101"
    echo "   Grafana:         http://172.18.255.103"
    echo "   Prometheus:      http://172.18.255.102"
    echo "   Alertmanager:    http://172.18.255.104"
    echo "   Chat App (Dev):  Via Ingress (check ArgoCD UI)"
    echo ""

    echo "🔧 Useful Commands:"
    echo "   # Set kubeconfig"
    echo "   export KUBECONFIG=./infrastructure/terraform/k3d-config"
    echo ""
    echo "   # Check cluster status"
    echo "   kubectl get nodes"
    echo "   kubectl get pods -A"
    echo ""
    echo "   # Access ArgoCD UI"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "   # Then open: https://localhost:8080"
    echo ""

    echo "📊 Monitoring:"
    echo "   - Prometheus: kubectl port-forward svc/prometheus-operated -n monitoring 9090:9090"
    echo "   - Grafana: kubectl port-forward svc/grafana -n monitoring 3000:3000"
    echo ""

    echo "🚀 Chat Application Scaling:"
    echo "   KEDA will automatically scale based on:"
    echo "   - Active WebSocket connections (primary)"
    echo "   - Message throughput rate (secondary)"
    echo "   - Memory usage (tertiary)"
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
