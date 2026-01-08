# 🚀 KUBERNETES PLATFORM - QUICK START

## 🎯 STEP 1: START ALL SERVICES
**Double-click:** `start-all-services.bat`

This opens 4 Command Prompt windows with port forwarding:
- 🌐 **ArgoCD**: http://localhost:8082 (GitOps Platform)
- 📊 **Grafana**: http://localhost:3000 (Monitoring Dashboards)
- 📈 **Prometheus**: http://localhost:9092 (Metrics Collection)
- 🚨 **Alertmanager**: http://localhost:9094 (Alert Management)

## 🔐 STEP 2: GET CREDENTIALS

**ArgoCD Password:**
```bash
cd infrastructure/terraform
terraform output argocd_admin_password
```

**Grafana Password:**
```bash
cd infrastructure/terraform
terraform output grafana_admin_password
```

**Default Login:** `admin` / `[password from above]`

## 🎯 STEP 3: ACCESS YOUR PLATFORM

1. **Keep all 4 Command Prompt windows open**
2. **Open URLs in your browser**
3. **Login with admin credentials**

## 📋 STEP 4: CHECK YOUR DEPLOYMENTS

**In ArgoCD (http://localhost:8082):**
- Look for: `chat-app-dev`, `chat-app-staging`, `chat-app-prod`
- They should show as "Healthy" and "Synced"

**Your chat application is automatically deployed!**

## 🔧 TROUBLESHOOTING

**If ArgoCD password doesn't work:**
```bash
# Get the correct password from Terraform
cd infrastructure/terraform
terraform output argocd_admin_password

# Or reset using the proper method:
kubectl --kubeconfig infrastructure/terraform/k3d-config exec -n argocd deploy/argocd-server -- argocd admin initial-password reset

# Use the password shown above to login
```

## 🎉 SUCCESS!

**Your enterprise Kubernetes platform is now running with:**
- GitOps deployment (ArgoCD)
- Monitoring stack (Prometheus + Grafana)
- Automatic chat app deployment
- Production-ready infrastructure
