#!/bin/bash

# Terraform + Kind + MetalLB deployment script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it from https://terraform.io"
        exit 1
    fi

    if ! command -v kind &> /dev/null; then
        log_error "Kind is not installed. Please install it from https://kind.sigs.k8s.io"
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install it."
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    terraform init
    log_success "Terraform initialized"
}

# Plan deployment
plan_deployment() {
    log_info "Planning deployment..."
    terraform plan -out=tfplan
    log_success "Deployment planned"
}

# Apply deployment
apply_deployment() {
    log_info "Applying deployment..."
    terraform apply tfplan
    log_success "Deployment completed!"
}

# Show access information
show_access_info() {
    log_info "🚀 Deployment completed! Access information:"
    echo ""
    echo "🌐 LoadBalancer Services:"
    echo "  NGINX Ingress:    http://172.18.255.100"
    echo "  ArgoCD:           http://172.18.255.101"
    echo "  Prometheus:       http://172.18.255.102:9090"
    echo "  Grafana:          http://172.18.255.103"
    echo "  Alertmanager:     http://172.18.255.104:9093"
    echo ""
    echo "🔐 Credentials:"
    echo "  ArgoCD:           admin / admin123"
    echo "  Grafana:          admin / admin123"
    echo ""
    echo "📱 Chat Application (via Ingress):"
    echo "  Dev:              http://172.18.255.100 (add to /etc/hosts)"
    echo "  Staging:          http://172.18.255.100"
    echo "  Prod:             http://172.18.255.100"
    echo ""
    echo "🔧 Management:"
    echo "  kubectl:          kubectl config use-context kind-chat-local"
    echo "  Terraform:        terraform destroy (to cleanup)"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Add hosts entries: echo '172.18.255.100 chat-dev.local chat-staging.local chat-prod.local' >> /etc/hosts"
    echo "  2. Access ArgoCD at http://172.18.255.101"
    echo "  3. Deploy your chat application via ArgoCD"
    echo "  4. Monitor via Grafana at http://172.18.255.103"
}

# Cleanup function
cleanup() {
    log_warning "Cleaning up..."
    terraform destroy -auto-approve 2>/dev/null || true
    kind delete cluster --name chat-local 2>/dev/null || true
    log_success "Cleanup completed"
}

# Main deployment
main() {
    echo "🚀 Terraform + Kind + MetalLB Deployment"
    echo "========================================"

    # Set trap for cleanup on error
    trap cleanup ERR

    check_prerequisites
    init_terraform
    plan_deployment

    echo ""
    log_warning "This will create a complete Kubernetes infrastructure."
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled"
        exit 0
    fi

    apply_deployment
    show_access_info

    log_success "🎉 Deployment successful! Your enterprise-grade Kubernetes cluster is ready!"
}

# Handle command line arguments
case "${1:-}" in
    "plan")
        check_prerequisites
        init_terraform
        plan_deployment
        ;;
    "apply")
        check_prerequisites
        init_terraform
        apply_deployment
        show_access_info
        ;;
    "destroy")
        cleanup
        ;;
    "status")
        echo "Cluster status:"
        kubectl get nodes 2>/dev/null || echo "No cluster found"
        echo ""
        echo "Services:"
        kubectl get svc -A 2>/dev/null || echo "No services found"
        ;;
    *)
        main
        ;;
esac
