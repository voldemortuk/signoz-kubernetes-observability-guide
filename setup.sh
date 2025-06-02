#!/bin/bash

# SigNoz Kubernetes Observability Setup Script
# This script automates the setup of SigNoz with OpenTelemetry on Kind

set -e

echo "🚀 Starting SigNoz Kubernetes Observability Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if required tools are installed
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop first."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm first."
        exit 1
    fi
    
    if ! command -v kind &> /dev/null; then
        print_error "Kind is not installed. Please install Kind first."
        exit 1
    fi
    
    print_step "All prerequisites are installed!"
}

# Create Kind cluster
create_cluster() {
    print_step "Creating Kind cluster..."
    
    if kind get clusters | grep -q "signoz-cluster"; then
        print_warning "Cluster 'signoz-cluster' already exists. Skipping creation."
    else
        kind create cluster --name signoz-cluster
        print_step "Kind cluster created successfully!"
    fi
}

# Add SigNoz Helm repository
add_helm_repo() {
    print_step "Adding SigNoz Helm repository..."
    
    helm repo add signoz https://charts.signoz.io
    helm repo update
    
    print_step "SigNoz Helm repository added!"
}

# Create namespace
create_namespace() {
    print_step "Creating signoz namespace..."
    
    if kubectl get namespace signoz &> /dev/null; then
        print_warning "Namespace 'signoz' already exists. Skipping creation."
    else
        kubectl create namespace signoz
        print_step "Namespace created successfully!"
    fi
}

# Deploy SigNoz core
deploy_signoz() {
    print_step "Deploying SigNoz core components..."
    
    if helm list -n signoz | grep -q "signoz"; then
        print_warning "SigNoz is already deployed. Skipping deployment."
    else
        helm install signoz signoz/signoz -n signoz
        print_step "SigNoz core deployed successfully!"
    fi
}

# Check if override-values.yaml exists
check_config() {
    if [ ! -f "override-values.yaml" ]; then
        print_error "override-values.yaml not found!"
        print_error "Please copy override-values.example.yaml to override-values.yaml and update with your values."
        exit 1
    fi
    
    # Check if placeholders are still present
    if grep -q "<SIGNOZ_INGESTION_KEY>" override-values.yaml; then
        print_error "Please update override-values.yaml with your actual SigNoz ingestion key!"
        exit 1
    fi
    
    print_step "Configuration file validated!"
}

# Deploy k8s-infra
deploy_k8s_infra() {
    print_step "Deploying k8s-infra with log collection..."
    
    if helm list -n signoz | grep -q "k8s-infra"; then
        print_warning "k8s-infra is already deployed. Upgrading with new configuration..."
        helm upgrade k8s-infra signoz/k8s-infra -f override-values.yaml -n signoz
    else
        helm install k8s-infra signoz/k8s-infra -f override-values.yaml -n signoz
    fi
    
    print_step "k8s-infra deployed successfully!"
}

# Wait for pods to be ready
wait_for_pods() {
    print_step "Waiting for pods to be ready..."
    
    kubectl wait --for=condition=ready pod --all -n signoz --timeout=300s
    
    print_step "All pods are ready!"
}

# Display status
show_status() {
    print_step "Deployment Status:"
    echo ""
    echo "Helm Releases:"
    helm list -n signoz
    echo ""
    echo "Running Pods:"
    kubectl get pods -n signoz
    echo ""
    echo "DaemonSets (Log Collectors):"
    kubectl get daemonsets -n signoz
    echo ""
    print_step "Setup completed successfully!"
    echo ""
    print_step "Next steps:"
    echo "1. Log in to your SigNoz Cloud account"
    echo "2. Go to Logs Explorer"
    echo "3. Filter by service.name to see your Kubernetes logs"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    create_cluster
    add_helm_repo
    create_namespace
    deploy_signoz
    check_config
    deploy_k8s_infra
    wait_for_pods
    show_status
}

# Run main function
main
