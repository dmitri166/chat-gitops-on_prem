# 📦 Applications Layer

This directory contains **application source code** and **deployment configurations** managed by ArgoCD GitOps.

## 📁 Structure

```
applications/
└── chat-app/              # Your chat application
    ├── source/           # Application source code
    │   ├── app/         # Flask application
    │   ├── Dockerfile   # Container definition
    │   └── requirements.txt
    ├── helm/            # Helm chart for deployment
    │   ├── Chart.yaml
    │   ├── values.yaml
    │   └── templates/
    ├── manifests/       # Additional Kubernetes manifests
    └── README.md        # Application documentation
```

## 🎯 What Goes Here

### **Application Source Code**
- ✅ **Your chat application** (Flask + SocketIO)
- ✅ **Dockerfiles** and build configurations
- ✅ **Dependencies** (requirements.txt, package.json)
- ✅ **Documentation** and runbooks

### **Deployment Configurations**
- ✅ **Helm charts** for your applications
- ✅ **Kubernetes manifests** (ConfigMaps, Secrets)
- ✅ **Environment-specific** configurations
- ✅ **CI/CD pipelines** (GitHub Actions, etc.)

## 🚫 What Does NOT Go Here

### **Infrastructure Code**
- ❌ Terraform configurations → `infrastructure/terraform/`
- ❌ MetalLB configurations → `platform/manifests/`
- ❌ ArgoCD applications → `platform/argocd/`

## 🔄 Deployment Flow

```
Application Code (Git) → ArgoCD → Kubernetes
       ↓
   Helm Chart → Container Registry → Deployments
```

### **Multi-Environment Support**

Your application supports **dev/staging/prod** environments:

```yaml
# ArgoCD ApplicationSet automatically creates:
# - chat-dev (development environment)
# - chat-staging (staging environment)  
# - chat-prod (production environment)
```

## 🚀 Development Workflow

```bash
# 1. Develop locally
cd applications/chat-app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python chat.py

# 2. Build and test container
docker build -t chat-app:latest .

# 3. Push changes to Git
git add .
git commit -m "feat: add new chat feature"
git push

# 4. ArgoCD deploys automatically
# Check status in ArgoCD UI
```

## 📋 Environment Configurations

### **Development**
- **Namespace**: `dev`
- **Resources**: Minimal (for development)
- **Access**: Local development access

### **Staging**
- **Namespace**: `staging`
- **Resources**: Production-like sizing
- **Access**: Team testing access

### **Production**
- **Namespace**: `prod`
- **Resources**: Full production sizing
- **Access**: Customer-facing

## 🔧 Application Management

### **Scaling**
```bash
# Via ArgoCD (recommended)
kubectl scale deployment chat-app -n prod --replicas=5

# Or update Helm values and push to Git
```

### **Rollbacks**
```bash
# Git-based rollback
git revert HEAD~1
git push

# ArgoCD automatically rolls back
```

### **Monitoring**
- **Metrics**: Prometheus scrapes application metrics
- **Logs**: Centralized logging (if configured)
- **Alerts**: Application-specific alerts

## 🎯 Best Practices

- **GitOps First**: All changes go through Git
- **Immutable Deployments**: New containers for each change
- **Health Checks**: Proper readiness/liveness probes
- **Resource Limits**: Set appropriate CPU/memory limits
- **Secrets Management**: Use Sealed Secrets for sensitive data

## 📊 Application Metrics

Your chat application should expose:
- **User connections** (WebSocket connections)
- **Message throughput** (messages per second)
- **Error rates** (failed connections/messages)
- **Performance** (response times, latency)

See [main README](../README.md) for complete setup instructions.
