# 🚀 Enterprise Kubernetes Infrastructure

**Production-Ready Platform** - Terraform + ArgoCD + Helm for reliable Kubernetes deployments.

## 📁 Project Structure

This repository follows **production best practices** with clear separation of concerns:

```
├── infrastructure/          # 🏗️ Infrastructure as Code
│   ├── terraform/          # Terraform configurations (cluster, security)
│   └── scripts/            # Infrastructure deployment scripts
├── platform/               # ⚙️ Platform configurations
│   ├── argocd/            # ArgoCD applications and configurations
│   └── manifests/         # Infrastructure manifests (MetalLB, monitoring)
├── applications/           # 📦 Application deployments
│   └── chat-app/          # Your chat application source code
└── docs/                  # 📚 Documentation
```

### **🗂️ Directory Purposes:**

| Directory | Purpose | Managed By | Example Contents |
|-----------|---------|------------|------------------|
| `infrastructure/` | **Infrastructure provisioning** | Terraform | Cluster creation, Helm releases |
| `platform/` | **Platform configurations** | ArgoCD | MetalLB config, monitoring rules |
| `applications/` | **Application code** | ArgoCD | Your chat app, microservices |

## 🎯 **Responsibilities Breakdown**

### **🏗️ Terraform (Infrastructure Layer)**
**Manages:** Cluster lifecycle, network, security foundations
- ✅ k3d cluster creation (1 server, 2 agents)
- ✅ Helm releases (MetalLB, Ingress, Monitoring, ArgoCD, Sealed Secrets)
- ✅ Security policies (Sealed Secrets backup)
- ✅ Network configuration basics

**Why Terraform?** Infrastructure is stateful and needs declarative provisioning.

### **⚙️ ArgoCD (Application Layer)**
**Manages:** Application deployments, configurations, GitOps
- ✅ MetalLB IPAddressPool and L2Advertisement
- ✅ Monitoring ServiceMonitors, PrometheusRules, Grafana dashboards
- ✅ Your chat application (via ApplicationSet)
- ✅ Configuration drift detection and auto-healing

**Why ArgoCD?** Applications need GitOps, rollbacks, and multi-environment support.

### **📦 Helm (Packaging Layer)**
**Manages:** Application packaging and templating
- ✅ Base application charts (Prometheus, Grafana, ArgoCD)
- ✅ Your chat app Helm chart
- ✅ Reusable component packaging

**Why Helm?** Standard packaging format for Kubernetes applications.

## 🚀 **Quick Start**

```bash
# 1. Deploy infrastructure (Terraform)
cd infrastructure/terraform
terraform init
terraform apply

# 2. Deploy platform configurations (ArgoCD)
cd ../../platform/argocd
kubectl apply -f applications/

# 3. Your applications deploy automatically via ArgoCD
```

## 📋 **Architecture Overview**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Terraform     │    │     ArgoCD      │    │     Helm        │
│                 │    │                 │    │                 │
│ • k3d cluster   │    │ • Applications  │    │ • App charts    │
│ • Helm releases │    │ • MetalLB config│    │ • Dependencies  │
│ • Security      │    │ • Monitoring    │    │ • Templates     │
│ • Networking    │    │ • Auto-healing  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
       │                        │                        │
       └───────── Git ──────────┼───────── Git ──────────┘
                              GitOps
```

## 🎯 **Key Benefits**

- **🔧 No kubectl provider issues** - ArgoCD handles complex deployments
- **📊 Production observability** - Full monitoring and alerting
- **🔄 GitOps workflow** - Everything version controlled
- **🏢 Enterprise ready** - Matches Fortune 500 practices
- **🚀 Developer friendly** - Clear separation of concerns

## 📚 **Documentation**

- [Infrastructure Setup](./infrastructure/terraform/README.md)
- [Platform Configuration](./platform/README.md)
- [Application Deployment](./applications/README.md)
- [Troubleshooting](./docs/troubleshooting.md)

## 🏆 **Production Best Practices Implemented**

- ✅ **GitOps Deployment** (ArgoCD)
- ✅ **Infrastructure as Code** (Terraform)
- ✅ **Application GitOps** (ArgoCD)
- ✅ **Security First** (Sealed Secrets, RBAC)
- ✅ **Monitoring & Alerting** (Prometheus, Grafana)
- ✅ **Load Balancing** (MetalLB)
- ✅ **Git Workflow** (Everything in Git)

---

**Ready for production?** This setup matches industry standards used by Netflix, Spotify, and other tech giants! 🚀