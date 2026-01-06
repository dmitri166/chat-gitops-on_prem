# 🏗️ Infrastructure Layer

This directory contains **infrastructure provisioning** code managed by Terraform. Infrastructure is the foundation that applications run on top of.

## 📁 Structure

```
infrastructure/
├── terraform/              # Terraform configurations
│   ├── main.tf            # Main infrastructure setup
│   ├── variables.tf       # Infrastructure variables
│   ├── modules/           # Reusable Terraform modules
│   └── README.md          # Infrastructure docs
└── scripts/               # Infrastructure scripts
    ├── setup-registry.sh # Local registry setup
    └── deploy-infra.sh   # Infrastructure deployment
```

## 🎯 What Terraform Manages

### **Cluster & Runtime**
- ✅ **k3d cluster creation** (1 server, 2 agents in Docker)
- ✅ **Kubernetes version management**
- ✅ **Local storage provisioner**

### **Network & Load Balancing**
- ✅ **MetalLB Helm release** (basic installation)
- ✅ **NGINX Ingress Controller** (basic installation)
- ✅ **Network policies** (foundation)

### **Security Foundation**
- ✅ **Sealed Secrets Helm release**
- ✅ **Sealed Secrets backup CronJob** (infrastructure security)
- ✅ **RBAC foundations**

### **Monitoring Foundation**
- ✅ **Kube Prometheus Stack Helm release** (Prometheus, Grafana, Alertmanager)
- ✅ **Basic monitoring setup**

### **GitOps Foundation**
- ✅ **ArgoCD Helm release**
- ✅ **ArgoCD basic configuration**

## 🚫 What Terraform Does NOT Manage

### **Application Configurations**
- ❌ MetalLB IPAddressPool/L2Advertisement → **ArgoCD**
- ❌ Monitoring ServiceMonitors/Rules → **ArgoCD**
- ❌ Grafana dashboards → **ArgoCD**
- ❌ Your chat application → **ArgoCD**

**Why?** These are application-level configurations that need GitOps for versioning, rollbacks, and multi-environment support.

## 🚀 Usage

```bash
cd infrastructure/terraform

# Initialize
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

## 📋 Dependencies

This layer provides the foundation for the **Platform** and **Applications** layers:

```
Infrastructure (Terraform)
    ↓
Platform (ArgoCD)
    ↓
Applications (ArgoCD)
```

## 🎯 Best Practices

- **Infrastructure is foundational** - Changes here affect everything
- **Keep it minimal** - Only essential cluster services
- **Version control** - All infrastructure changes tracked
- **Test changes** - Infrastructure changes need careful testing
- **Documentation** - Keep runbooks for infrastructure changes

## 🔧 Troubleshooting

- **Cluster issues**: Check k3d cluster status
- **Helm releases**: `helm list -A`
- **Resource conflicts**: Check existing resources before applying
- **Network issues**: Verify MetalLB IP ranges

See [main README](../../README.md) for complete setup instructions.
