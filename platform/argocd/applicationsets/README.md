# ArgoCD ApplicationSets - Professional Naming Convention

## 📁 File Naming Convention

### 🏗️ STRUCTURE
```
platform/argocd/applicationsets/
├── README.md                    # This documentation
├── ghost-platform.yaml          # Main Ghost platform deployment
├── infrastructure.yaml          # Infrastructure components
├── backup/                     # Backup old files
│   ├── ghost-simple.yaml.bak
│   └── ghost-applications.yaml.bak
└── templates/                   # Template files for reference
    ├── application-template.yaml
    └── applicationset-template.yaml
```

## 🎯 Naming Rules

### ✅ ACCEPTABLE NAMES
- `ghost-platform.yaml` - Platform-wide deployment
- `ghost-environments.yaml` - Multi-environment setup
- `infrastructure.yaml` - Infrastructure components
- `applications.yaml` - Application deployments

### ❌ UNACCEPTABLE NAMES
- `ghost-simple.yaml` - Too vague
- `ghost-correct.yaml` - Unprofessional
- `ghost-temp.yaml` - Temporary naming
- `test-ghost.yaml` - Testing naming

## 🚀 Deployment Strategy

### 📊 Environment-Based
```yaml
# ghost-platform.yaml - Multi-environment deployment
- ghost-dev → ghost-dev namespace
- ghost-staging → ghost-staging namespace  
- ghost-prod → ghost-prod namespace
- mysql → ghost namespace (shared)
```

### 🔄 GitOps Workflow
```bash
# 1. Update values files
vim applications/ghost-app/helm/values-dev.yaml

# 2. Commit changes
git add applications/ghost-app/helm/values-dev.yaml
git commit -m "Update development configuration"

# 3. Push changes
git push origin main

# 4. ArgoCD auto-deploys
# No manual intervention needed
```

## 🛡️ Best Practices

### 📋 File Organization
- ✅ Use descriptive, professional names
- ✅ One ApplicationSet per logical group
- ✅ Clear separation of concerns
- ✅ Version control all changes

### 🔧 Configuration Management
- ✅ Environment-specific values files
- ✅ Shared infrastructure components
- ✅ Automated sync policies
- ✅ Proper labeling and annotations

### 🏢 Production Readiness
- ✅ Resource quotas per namespace
- ✅ Network policies for isolation
- ✅ RBAC for access control
- ✅ Monitoring and alerting

## 📝 Maintenance

### 🔄 Updates
```bash
# Update ApplicationSet
kubectl apply -f platform/argocd/applicationsets/ghost-platform.yaml

# Check status
kubectl get applications -n argocd
kubectl describe application ghost-dev -n argocd
```

### 🧹 Cleanup
```bash
# Remove old ApplicationSets
kubectl delete applicationset ghost-simple -n argocd
kubectl delete applicationset ghost-applications -n argocd

# Backup old files
mkdir -p platform/argocd/applicationsets/backup
mv *.bak backup/
```
