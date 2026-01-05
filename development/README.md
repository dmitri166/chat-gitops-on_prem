# 🛠️ Development Tools & Testing

This folder contains development tools, scripts, and local testing configurations that support the Terraform infrastructure deployment.

## 📁 Folder Structure

```
development/
├── 📁 gitops-local/           # 🧪 Local GitOps Development & Testing
│   └── 📁 chat-gitops/
│       ├── applicationset.yaml    # ArgoCD ApplicationSet (test locally)
│       ├── chat-app-helm/         # Helm chart development
│       │   ├── Chart.yaml
│       │   ├── templates/
│       │   └── values.yaml
│       └── values-*.yaml          # Environment-specific values (dev/staging/prod)
└── 📁 scripts/               # 🔧 Development Automation Scripts
    ├── build-and-push.sh         # Build & push container images
    ├── setup-local-registry.sh   # Setup local Docker registry
    ├── add-metrics-to-app.sh     # Add Prometheus metrics
    └── README.md
```

## 🎯 Purpose & Usage

### **GitOps Local (`gitops-local/`)**

**Purpose:** Test and develop GitOps configurations before deploying to production.

**When to use:**
- ✅ **Develop Helm charts** locally before pushing to remote repo
- ✅ **Test ArgoCD ApplicationSets** without affecting production
- ✅ **Validate environment configurations** (dev/staging/prod)
- ✅ **Debug GitOps issues** in isolation

**Workflow:**
```bash
# 1. Develop locally
cd development/gitops-local/chat-gitops
# Edit Helm charts, ApplicationSets, values files

# 2. Test with Terraform (points to remote GitHub repo)
cd ../../terraform-kind
./deploy.sh

# 3. Push changes to remote GitOps repo when ready
git add .
git commit -m "Updated chat application helm chart"
git push origin main
```

### **Scripts (`scripts/`)**

**Purpose:** Manual development tasks and utilities.

**When to use:**
- ✅ **Container Development:** Build and push images during development
- ✅ **Local Testing:** Setup local registry for testing
- ✅ **Application Enhancement:** Add metrics, monitoring, etc.
- ✅ **CI/CD Integration:** Scripts that can be called from CI pipelines

**Key Scripts:**
```bash
# Build and push container
./development/scripts/build-and-push.sh v1.2.0

# Setup local registry for testing
./development/scripts/setup-local-registry.sh

# Add Prometheus metrics to application
./development/scripts/add-metrics-to-app.sh
```

## 🔄 Development vs Production Workflow

### **Development (This Folder)**
```bash
# Local development and testing
├── Edit code in Flask-SocketIO-Chat/
├── Run scripts in development/scripts/
├── Test configurations in development/gitops-local/
├── Deploy with terraform-kind/ (uses remote GitOps repo)
```

### **Production (Terraform Infrastructure)**
```bash
# Production deployment
├── terraform-kind/ manages infrastructure
├── Remote GitHub repo (https://github.com/dmitri166/chat-gitops)
├── ArgoCD syncs from remote repo
├── Monitoring and security fully automated
```

## 🚀 Getting Started

### **For Application Development:**
```bash
# 1. Edit application code
cd Flask-SocketIO-Chat/
# Make changes...

# 2. Build and test container
cd ../development/scripts/
./build-and-push.sh v1.0.0

# 3. Test GitOps configurations
cd ../gitops-local/chat-gitops/
kubectl apply -f applicationset.yaml  # Local testing

# 4. Deploy infrastructure
cd ../../terraform-kind/
./deploy.sh
```

### **For Infrastructure Development:**
```bash
# Test Terraform changes
cd terraform-kind/
terraform plan
terraform apply

# Debug with local GitOps
kubectl apply -f ../development/gitops-local/chat-gitops/applicationset.yaml
```

## 📋 Best Practices

### **GitOps Development:**
1. **Develop locally** in `gitops-local/`
2. **Test changes** with local kubectl commands
3. **Push to remote** only when validated
4. **Use branches** for feature development

### **Script Usage:**
1. **Version control** your container images
2. **Test locally** before CI/CD integration
3. **Document usage** in script comments
4. **Handle errors** gracefully

## 🔗 Integration Points

### **With Terraform Infrastructure:**
- `terraform-kind/` deploys the cluster and points ArgoCD to remote GitOps repo
- `development/gitops-local/` provides local testing before remote deployment

### **With Application Code:**
- `Flask-SocketIO-Chat/` contains the actual application
- `development/scripts/` provides tools to build and enhance the application

### **With Remote GitOps:**
- `development/gitops-local/` is the local development version
- Remote GitHub repo is the production source of truth
- ArgoCD syncs from remote repo in production

## 🎯 Key Benefits

- ✅ **Separation of Concerns:** Development tools separate from production infra
- ✅ **Local Testing:** Test GitOps configurations without production impact
- ✅ **Iterative Development:** Build, test, deploy cycle with local tools
- ✅ **Production Ready:** Clean separation between dev and production assets

**This structure supports both rapid development iteration and production-grade deployment practices!** 🚀
