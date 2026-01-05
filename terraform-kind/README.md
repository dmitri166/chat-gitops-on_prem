# 🚀 Enterprise Terraform + Kind + MetalLB Setup

**Modular Infrastructure as Code** for deploying production-ready Kubernetes infrastructure with enterprise best practices.

## 📁 **Modular Architecture:**

```
terraform-kind/
├── 📄 main.tf                  # Entry point calling modules
├── 📄 variables.tf             # Global variables
├── 📄 terraform.tfvars         # Environment values
├── 📄 deploy.sh                # Deployment automation
├── 📁 modules/                 # Reusable modules
│   ├── 📁 kubernetes/         # Kind cluster setup
│   ├── 📁 networking/         # MetalLB + Ingress
│   ├── 📁 monitoring/         # Prometheus stack
│   └── 📁 security/           # ArgoCD + Sealed Secrets
└── 📄 README.md               # This documentation
```

## 🏗️ **What This Sets Up:**

### **Infrastructure:**
- ✅ **Kind Cluster** with 4 nodes (1 master + 3 workers)
- ✅ **MetalLB** LoadBalancer for external services
- ✅ **Local Path Provisioner** for persistent storage
- ✅ **NGINX Ingress Controller** with LoadBalancer IP

### **Platform Components:**
- ✅ **ArgoCD** GitOps with LoadBalancer IP
- ✅ **Prometheus Stack** (Prometheus, Grafana, Alertmanager)
- ✅ **Sealed Secrets** for encrypted secrets

### **Security & Policies:**
- ✅ **RBAC** role-based access control
- ✅ **Network Policies** zero-trust networking
- ✅ **Security Contexts** and resource limits
- ✅ **Pod Security Standards**

### **Environments:**
- ✅ **dev, staging, prod** namespaces
- ✅ **Persistent storage** for all components

## 🚀 **Quick Start:**

### **1. Prerequisites:**
```bash
# Install Terraform
choco install terraform  # Windows
# or download from https://terraform.io

# Install Kind
choco install kind
```

### **2. Initialize & Deploy:**
```bash
cd terraform-kind

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Deploy everything
terraform apply
```

### **3. Access Your Services:**

After deployment, you'll have **real LoadBalancer IPs**:

| Service | LoadBalancer IP | Port | Access |
|---------|-----------------|------|---------|
| **Chat App (Dev)** | `http://172.18.255.100` | 80/443 | Via Ingress |
| **ArgoCD** | `http://172.18.255.101` | 80 | Web UI |
| **Prometheus** | `http://172.18.255.102` | 9090 | Metrics |
| **Grafana** | `http://172.18.255.103` | 80 | Dashboards |
| **Alertmanager** | `http://172.18.255.104` | 9093 | Alerts |

**Credentials:**
- **ArgoCD:** admin / admin123
- **Grafana:** admin / admin123

## 🏗️ **Architecture:**

```
┌─────────────────────────────────────────────────────────────┐
│                    Host Machine                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                Kind Cluster                             │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │  Control Plane Node                                 │ │ │
│  │  │  - API Server, Scheduler, Controller                │ │ │
│  │  │  - Port mappings: 80,443,8082,3000,9090,9093       │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │  Worker Node 1 (env=nonprod)                        │ │ │
│  │  │  - Dev & Staging applications                       │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │  Worker Node 2 (env=prod)                           │ │ │
│  │  │  - Production applications                          │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │  Worker Node 3 (env=system)                         │ │ │
│  │  │  - Monitoring, ArgoCD, Ingress                      │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  MetalLB LoadBalancer IPs: 172.18.255.100-104          │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 **Key Features:**

### **Production-like Networking:**
```yaml
# Real LoadBalancer services (not NodePort)
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: LoadBalancer  # Gets real external IP!
  ports:
  - port: 80
    targetPort: 8080
```

### **GitOps Integration:**
```bash
# ArgoCD syncs automatically
kubectl get applications -n argocd

# Applications deploy to correct environments
kubectl get pods -n dev
kubectl get pods -n staging
kubectl get pods -n prod
```

### **Monitoring Stack:**
```bash
# Access Grafana dashboards
open http://172.18.255.103

# View Prometheus metrics
open http://172.18.255.102:9090

# Check alerts
open http://172.18.255.104:9093
```

## 🔧 **Customization:**

### **Modify Resources:**
```hcl
# In variables.tf or terraform.tfvars
master_cpu_limit    = "4000m"  # More CPU for master
worker_memory_limit = "4Gi"   # More memory for workers
```

### **Add More Services:**
```hcl
# Add service IPs to variables
variable "my_service_ip" {
  default = "172.18.255.105"
}
```

### **Scale Workers:**
```hcl
# Add more worker nodes in main.tf
node {
  role = "worker"
  kubeadm_config_patches = [
    yamlencode({
      kind = "JoinConfiguration"
      nodeRegistration = {
        kubeletExtraArgs = {
          "node-labels" = "env=extra,node-type=worker"
        }
      }
    })
  ]
}
```

## 🧹 **Cleanup:**

```bash
# Destroy everything
terraform destroy

# Clean up Kind cluster
kind delete cluster --name chat-local
```

## 🚀 **Next Steps:**

1. **Deploy your chat application:**
   ```bash
   # For development testing, use local gitops
   kubectl apply -f ../development/gitops-local/chat-gitops/applicationset.yaml

   # In production, ArgoCD syncs from remote GitHub repo
   kubectl get applications -n argocd
   ```

2. **Access via ingress:**
   ```bash
   # Add to /etc/hosts
   echo "172.18.255.100 chat-dev.local" >> /etc/hosts
   echo "172.18.255.100 chat-staging.local" >> /etc/hosts
   echo "172.18.255.100 chat-prod.local" >> /etc/hosts
   ```

3. **Monitor everything:**
   ```bash
   # Check cluster status
   kubectl get nodes
   kubectl get pods -A

   # View Grafana dashboards
   open http://172.18.255.103
   ```

## 💡 **Why This is Perfect:**

- ✅ **Development-first** - Kind's simplicity
- ✅ **Production networking** - MetalLB LoadBalancers
- ✅ **Infrastructure as Code** - Full Terraform management
- ✅ **Enterprise features** - Monitoring, security, GitOps
- ✅ **Easy cleanup** - Single `terraform destroy`

**This gives you the best of both worlds: Easy local development with production-like networking and management!** 🎯
