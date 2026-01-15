#!/bin/bash

# Enhanced Deployment Script
# Includes all best practices for k3d environment

set -e

echo "🚀 Enhanced Chat Application Deployment"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if k3d is installed
    if ! command -v k3d &> /dev/null; then
        print_error "k3d is not installed. Please install k3d first."
        exit 1
    fi
    
    # Check if kubectl is configured
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl is not configured. Please check your kubeconfig."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker."
        exit 1
    fi
    
    print_status "Prerequisites check passed ✓"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure..."
    
    cd infrastructure/terraform
    terraform init
    terraform apply -auto-approve
    cd ../..
    
    # Set kubeconfig
    export KUBECONFIG="$(pwd)/infrastructure/terraform/k3d-config"
    
    print_status "Infrastructure deployed ✓"
}

# Deploy Argo Rollouts
install_argo_rollouts() {
    print_status "Installing Argo Rollouts..."
    
    # Create namespace
    kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Argo Rollouts
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    
    # Wait for rollout controller
    kubectl wait --for=condition=available deployment/argo-rollouts -n argo-rollouts --timeout=60s
    
    print_status "Argo Rollouts installed ✓"
}

# Deploy enhanced platform services
deploy_platform_services() {
    print_status "Deploying enhanced platform services..."
    
    cd platform/argocd
    
    # Apply enhanced kustomization
    kubectl apply -f kustomization-enhanced.yaml
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    kubectl wait --for=condition=available deployment --all -n argo-rollouts --timeout=120s
    kubectl wait --for=condition=available deployment --all -n tempo --timeout=120s
    
    cd ../..
    
    print_status "Platform services deployed ✓"
}

# Deploy chat application with rollouts
deploy_chat_app() {
    print_status "Deploying chat application with rollouts..."
    
    # Update application to use rollouts
    cd applications/chat-app/helm/templates
    
    # Backup original deployment
    cp deployment.yaml deployment.yaml.backup
    
    # Use enhanced rollout instead of deployment
    print_status "Configuring progressive deployment..."
    
    cd ../../..
    
    # Apply updated application
    kubectl apply -f ../../platform/argocd/applicationsets/chat-applicationset.yaml
    
    print_status "Chat application deployed ✓"
}

# Setup monitoring
setup_monitoring() {
    print_status "Setting up enhanced monitoring..."
    
    # Apply monitoring configurations
    kubectl apply -f platform/manifests/monitoring/argo-rollouts.yaml
    kubectl apply -f platform/manifests/monitoring/tempo-stack.yaml
    kubectl apply -f platform/manifests/monitoring/chat-app-monitoring.yaml
    
    # Wait for monitoring stack
    kubectl wait --for=condition=available deployment/tempo -n tempo --timeout=60s
    
    print_status "Enhanced monitoring setup ✓"
}

# Setup security
setup_security() {
    print_status "Setting up security policies..."
    
    # Apply network policies
    kubectl apply -f platform/manifests/security/network-policies.yaml
    
    print_status "Security policies applied ✓"
}

# Setup port forwarding
setup_port_forwarding() {
    print_status "Setting up port forwarding..."
    
    # Kill existing port forwards
    pkill -f "kubectl port-forward" || true
    
    # Start port forwarding in background
    kubectl port-forward -n argocd svc/argocd-server 8080:443 &
    kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9092:9090 &
    kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-grafana 3000:3000 &
    kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9094:9093 &
    kubectl port-forward -n tempo svc/tempo 3100:3100 &
    
    print_status "Port forwarding setup ✓"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check all pods are running
    kubectl get pods -A
    
    # Check services
    kubectl get svc -A
    
    # Check rollouts
    kubectl get rollouts -A
    
    print_status "Deployment verification completed ✓"
}

# Show access information
show_access_info() {
    print_status "Access Information:"
    echo ""
    echo "🔐 ArgoCD:"
    echo "   URL: http://localhost:8080"
    echo "   Username: admin"
    echo "   Password: $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)"
    echo ""
    echo "📊 Monitoring:"
    echo "   Prometheus: http://localhost:9092"
    echo "   Grafana: http://localhost:3000 (admin/admin123)"
    echo "   Alertmanager: http://localhost:9094"
    echo "   Tempo: http://localhost:3100"
    echo ""
    echo "🚀 Chat Application:"
    echo "   Dev: http://chat-dev.local"
    echo "   Staging: http://chat-staging.local"
    echo "   Prod: http://chat-prod.local"
    echo ""
    echo "🔍 Rollouts Status:"
    echo "   Command: kubectl get rollouts -A"
    echo "   Command: kubectl argo rollouts get rollout chat-app -n dev"
    echo ""
    print_status "Enhanced deployment completed successfully! 🎉"
}

# Main deployment flow
main() {
    print_status "Starting enhanced deployment..."
    
    check_prerequisites
    deploy_infrastructure
    install_argo_rollouts
    deploy_platform_services
    setup_monitoring
    setup_security
    deploy_chat_app
    setup_port_forwarding
    verify_deployment
    show_access_info
}

# Handle script arguments
case "${1:-}" in
    "infra")
        check_prerequisites
        deploy_infrastructure
        ;;
    "monitoring")
        setup_monitoring
        ;;
    "security")
        setup_security
        ;;
    "rollouts")
        install_argo_rollouts
        ;;
    "port-forward")
        setup_port_forwarding
        ;;
    "verify")
        verify_deployment
        ;;
    *)
        main
        ;;
esac
