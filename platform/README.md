# ⚙️ Platform Layer

This directory contains **platform configurations** managed by ArgoCD GitOps. Platform configurations are the "glue" between infrastructure and applications.

## 📁 Structure

```
platform/
├── argocd/                # ArgoCD applications
│   ├── applications/     # ArgoCD Application manifests
│   └── applicationsets/  # ArgoCD ApplicationSet manifests
└── manifests/            # Kubernetes manifests
    ├── metallb/         # MetalLB configurations
    └── monitoring/      # Monitoring configurations
```

## 🎯 What ArgoCD Manages

### **Infrastructure Configurations**
- ✅ **MetalLB IPAddressPool** (defines IP ranges for LoadBalancer services)
- ✅ **MetalLB L2Advertisement** (Layer 2 network advertisement)
- ✅ **Monitoring ServiceMonitors** (scrapes metrics from services)
- ✅ **PrometheusRules** (alerting rules)
- ✅ **Grafana Dashboards** (visualization configurations)

### **Application Deployments**
- ✅ **Your chat application** (via ApplicationSet)
- ✅ **Multi-environment deployments** (dev/staging/prod)
- ✅ **Application configurations**
- ✅ **Secrets management** (via Sealed Secrets)

## 🚫 What ArgoCD Does NOT Manage

### **Infrastructure Foundations**
- ❌ k3d cluster creation → **Terraform**
- ❌ Helm releases installation → **Terraform**
- ❌ Sealed Secrets backup → **Terraform** (infrastructure security)

**Why?** These are foundational infrastructure components that need Terraform's state management and dependency handling.

## 🔄 GitOps Workflow

ArgoCD provides **continuous deployment** from Git:

```yaml
# Application manifest (GitOps)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: metallb-config
spec:
  source:
    repoURL: https://github.com/your-org/platform
    path: manifests/metallb
  destination:
    server: https://kubernetes.default.svc
    namespace: metallb-system
  syncPolicy:
    automated:
      prune: true      # Remove deleted resources
      selfHeal: true   # Fix configuration drift
```

## 🚀 Benefits

### **Reliability**
- **Automatic retries** - Failed deployments retry automatically
- **Dependency waiting** - ArgoCD waits for CRDs and dependencies
- **Self-healing** - Detects and fixes configuration drift

### **Developer Experience**
- **Git workflow** - All changes go through Git
- **Audit trail** - Complete history of deployments
- **Rollback** - Git revert for instant rollbacks
- **Multi-environment** - Same manifests across environments

### **Operations**
- **Centralized view** - ArgoCD UI shows all deployments
- **Health monitoring** - Real-time deployment status
- **Sync waves** - Controlled rollout ordering

## 📋 Deployment

```bash
# After infrastructure is deployed
cd platform/argocd

# Deploy platform configurations
kubectl apply -f applications/

# Check status in ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## 🎯 Platform vs Infrastructure

| Concern | Infrastructure (Terraform) | Platform (ArgoCD) |
|---------|----------------------------|-------------------|
| **Purpose** | Cluster creation & foundations | Application configurations |
| **Change Frequency** | Rare (infrastructure changes) | Frequent (app updates) |
| **Rollback** | Complex (infrastructure state) | Simple (Git revert) |
| **Testing** | Extensive (affects everything) | Focused (app-specific) |
| **Ownership** | Platform/SRE team | Application teams |

## 🔧 Troubleshooting

- **Sync issues**: Check ArgoCD application status
- **Resource conflicts**: Review existing resources
- **CRD dependencies**: Ensure Helm releases are complete
- **Network policies**: Verify MetalLB configurations

See [main README](../README.md) for complete setup instructions.
