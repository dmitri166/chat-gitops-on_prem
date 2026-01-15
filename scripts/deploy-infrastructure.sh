#!/bin/bash

# Enhanced Infrastructure Deployment Script
# Uses Terraform best practices with modules

set -e

echo "🏗️ Enhanced Infrastructure Deployment"
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
    
    # Get script directory and navigate to Terraform directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/infrastructure/terraform"
    
    # Change to Terraform directory first
    cd "$TERRAFORM_DIR"
    
    # Verify we're in the right directory
    if [ ! -f "main.tf" ]; then
        print_error "Terraform configuration files not found in $TERRAFORM_DIR"
        exit 1
    fi
    
    print_status "Working directory: $(pwd)"
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform >= 1.5."
        exit 1
    fi
    
    # Check Terraform version
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    REQUIRED_VERSION="1.5.0"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$TERRAFORM_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        print_error "Terraform version $TERRAFORM_VERSION is too old. Required: >= $REQUIRED_VERSION"
        exit 1
    fi
    
    # Check if k3d provider is available (after terraform init)
    print_status "Terraform files found, will check provider after init"
    
    print_status "Prerequisites check passed ✓"
}

# Initialize Terraform
initialize_terraform() {
    print_status "Initializing Terraform..."
    
    # Already in Terraform directory from check_prerequisites()
    
    # Clean any existing state
    if [ -d ".terraform" ]; then
        rm -rf .terraform
    fi
    
    # Initialize with backend
    terraform init -upgrade
    
    # Now check for k3d provider
    if ! terraform providers | grep -q "k3d"; then
        print_error "k3d provider not found. Please check Terraform configuration."
        exit 1
    fi
    
    print_status "Terraform initialized ✓"
}

# Plan infrastructure
plan_infrastructure() {
    print_status "Planning infrastructure deployment..."
    
    # Check for environment-specific variables
    ENVIRONMENT=${1:-dev}
    VAR_FILE=""
    
    case $ENVIRONMENT in
        "dev")
            VAR_FILE="dev.tfvars"
            ;;
        "staging")
            VAR_FILE="staging.tfvars"
            ;;
        "prod")
            VAR_FILE="prod.tfvars"
            ;;
        *)
            print_warning "Unknown environment: $ENVIRONMENT. Using dev."
            VAR_FILE="dev.tfvars"
            ;;
    esac
    
    # Create variables file if it doesn't exist
    if [ ! -f "$VAR_FILE" ]; then
        print_status "Creating $VAR_FILE with default values..."
        
        case $ENVIRONMENT in
            "dev")
                cat > "$VAR_FILE" << 'EOF'
environment = "dev"
cluster_name = "k3d-dev"
k3s_image = "rancher/k3s:v1.28.3-k3s1"
enable_monitoring = true
enable_security = true
enable_networking = true
enable_storage = true
cluster_memory_limit = "4Gi"
cluster_cpu_limit = "2"
tags = {
  environment = "dev"
  project = "chat-app"
  managed_by = "terraform"
}
EOF
                ;;
            "staging")
                cat > "$VAR_FILE" << 'EOF'
environment = "staging"
cluster_name = "k3d-staging"
k3s_image = "rancher/k3s:v1.28.3-k3s1"
enable_monitoring = true
enable_security = true
enable_networking = true
enable_storage = true
cluster_memory_limit = "6Gi"
cluster_cpu_limit = "3"
tags = {
  environment = "staging"
  project = "chat-app"
  managed_by = "terraform"
}
EOF
                ;;
            "prod")
                cat > "$VAR_FILE" << 'EOF'
environment = "prod"
cluster_name = "k3d-prod"
k3s_image = "rancher/k3s:v1.28.3-k3s1"
enable_monitoring = true
enable_security = true
enable_networking = true
enable_storage = true
cluster_memory_limit = "8Gi"
cluster_cpu_limit = "4"
tags = {
  environment = "prod"
  project = "chat-app"
  managed_by = "terraform"
}
EOF
                ;;
        esac
        
        print_status "Created $VAR_FILE ✓"
    fi
    
    # Run terraform plan
    if [ -f "$VAR_FILE" ]; then
        terraform plan -var-file="$VAR_FILE" -out=tfplan
    else
        terraform plan -out=tfplan
    fi
    
    print_status "Infrastructure plan created ✓"
}

# Apply infrastructure
apply_infrastructure() {
    print_status "Applying infrastructure deployment..."
    
    # Apply the plan
    terraform apply tfplan
    
    print_status "Infrastructure deployment completed ✓"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying infrastructure deployment..."
    
    # Check if cluster exists
    if ! k3d cluster list | grep -q "chat-k3d"; then
        print_error "k3d cluster not found"
        exit 1
    fi
    
    # Check kubeconfig
    if [ ! -f "k3d-config" ]; then
        print_error "kubeconfig file not found"
        exit 1
    fi
    
    # Test cluster connectivity
    export KUBECONFIG="$(pwd)/k3d-config"
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to cluster"
        exit 1
    fi
    
    print_status "Infrastructure verification passed ✓"
}

# Setup environment
setup_environment() {
    print_status "Setting up environment..."
    
    # Set kubeconfig
    export KUBECONFIG="$(pwd)/k3d-config"
    
    # Create namespaces
    kubectl apply -f modules/storage/storage-class-*.yaml || true
    kubectl apply -f modules/networking/*.yaml || true
    
    print_status "Environment setup completed ✓"
}

# Show outputs
show_outputs() {
    print_status "Infrastructure Outputs:"
    echo ""
    
    # Get outputs from Terraform
    terraform output -json > outputs.json
    
    # Display key outputs
    CLUSTER_NAME=$(jq -r '.cluster_name.value' outputs.json)
    REGISTRY_ENDPOINT=$(jq -r '.registry_endpoint.value' outputs.json)
    
    echo "🏗️ Cluster Information:"
    echo "   Name: $CLUSTER_NAME"
    echo "   Kubeconfig: $(pwd)/k3d-config"
    echo "   Registry: $REGISTRY_ENDPOINT"
    echo ""
    
    # Show secrets (if available)
    if jq -e '.argocd_password.value' outputs.json &> /dev/null; then
        ARGOCD_PASSWORD=$(jq -r '.argocd_password.value' outputs.json)
        echo "🔐 Secrets:"
        echo "   ArgoCD Password: $ARGOCD_PASSWORD"
        echo ""
    fi
    
    if jq -e '.grafana_password.value' outputs.json &> /dev/null; then
        GRAFANA_PASSWORD=$(jq -r '.grafana_password.value' outputs.json)
        echo "🔐 Grafana Password: $GRAFANA_PASSWORD"
        echo ""
    fi
    
    echo "📋 Next Steps:"
    echo "1. Set KUBECONFIG: export KUBECONFIG=\"$(pwd)/k3d-config\""
    echo "2. Deploy platform services: cd ../platform/argocd && kubectl apply -f ."
    echo "3. Access cluster: kubectl get nodes"
    echo ""
    
    print_status "Enhanced infrastructure deployment completed! 🎉"
}

# Clean up
cleanup() {
    print_status "Cleaning up..."
    
    # Remove temporary files
    rm -f tfplan
    rm -f outputs.json
    
    print_status "Cleanup completed ✓"
}

# Main deployment flow
main() {
    ENVIRONMENT=${1:-dev}
    
    print_status "Starting enhanced infrastructure deployment for environment: $ENVIRONMENT"
    
    check_prerequisites
    initialize_terraform
    plan_infrastructure $ENVIRONMENT
    apply_infrastructure
    verify_deployment
    setup_environment
    show_outputs
    cleanup
}

# Handle script arguments
case "${1:-}" in
    "dev")
        main "dev"
        ;;
    "staging")
        main "staging"
        ;;
    "prod")
        main "prod"
        ;;
    "plan")
        check_prerequisites
        initialize_terraform
        plan_infrastructure ${2:-dev}
        ;;
    "apply")
        check_prerequisites
        initialize_terraform
        apply_infrastructure
        ;;
    "destroy")
        print_warning "Destroying infrastructure..."
        cd infrastructure/terraform
        terraform destroy
        ;;
    "clean")
        cleanup
        ;;
    *)
        echo "Usage: $0 {dev|staging|prod|plan|apply|destroy|clean}"
        echo ""
        echo "Examples:"
        echo "  $0 dev          # Deploy development environment"
        echo "  $0 staging       # Deploy staging environment"
        echo "  $0 prod          # Deploy production environment"
        echo "  $0 plan staging  # Plan staging deployment"
        echo "  $0 apply         # Apply planned changes"
        echo "  $0 destroy       # Destroy infrastructure"
        echo "  $0 clean         # Clean temporary files"
        exit 1
        ;;
esac
