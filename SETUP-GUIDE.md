# 🚀 Complete Setup Guide - Best Practices

## **Step-by-Step Instructions**

Follow these steps in order to set up your k3d cluster with best practices.

---

## **Phase 1: Clean Cluster Setup**

### **Step 1: Run Setup Script (Automated)**
```bash
chmod +x setup-k3d-cluster.sh
./setup-k3d-cluster.sh
```

**OR manually:**

### **Step 1 (Manual): Delete Existing Cluster**
```bash
k3d cluster delete chat-k3d
```

### **Step 2 (Manual): Delete Existing Registries**
```bash
# List registries
k3d registry list

# Delete each one found
k3d registry delete myregistry.localhost  # or whatever name you see
```

### **Step 3 (Manual): Create Standard Registry**
```bash
# Using port 5002 to avoid conflicts (registry is accessible on port 5000 inside cluster)
k3d registry create k3d-registry --port 5002
```

### **Step 4 (Manual): Create Cluster with Registry**
```bash
k3d cluster create chat-k3d \
  --registry-use k3d-registry:5000 \
  --agents 2 \
  --k3s-arg "--disable=traefik@server:0"
```

### **Step 5 (Manual): Get Kubeconfig**
```bash
k3d kubeconfig get chat-k3d > infrastructure/terraform/k3d-config
```

### **Step 6 (Manual): Verify Cluster**
```bash
kubectl --kubeconfig infrastructure/terraform/k3d-config get nodes
```

**Expected output:** 3 nodes (1 server, 2 agents) all in Ready state

---

## **Phase 2: Build & Push Docker Image**

### **Step 7: Build Image with Correct Registry Name**
```bash
cd applications/chat-app/source
docker build -t k3d-registry:5000/chat-app:latest .
cd ../../..
```

### **Step 8: Push Image to Registry**
```bash
docker push k3d-registry:5000/chat-app:latest
```

### **Step 9: Verify Image is in Registry**
```bash
# From your host machine
curl http://localhost:5000/v2/chat-app/tags/list

# Expected output:
# {"name":"chat-app","tags":["latest"]}
```

---

## **Phase 3: Deploy Infrastructure**

### **Step 10: Initialize Terraform (if needed)**
```bash
cd infrastructure/terraform
terraform init
cd ../..
```

### **Step 11: Deploy Infrastructure**
```bash
cd infrastructure/terraform
terraform apply -auto-approve
cd ../..
```

**This will deploy:**
- ✅ MetalLB (LoadBalancer)
- ✅ NGINX Ingress
- ✅ ArgoCD (GitOps)
- ✅ Sealed Secrets
- ✅ KEDA (Autoscaling)
- ✅ Monitoring (if enabled)

**Wait for:** All resources to be created (may take 5-10 minutes)

---

## **Phase 4: Deploy Applications**

### **Step 12: Deploy ArgoCD Applications**
```bash
kubectl --kubeconfig infrastructure/terraform/k3d-config apply -f platform/argocd/applicationsets/
```

### **Step 13: Wait for ArgoCD Sync**
```bash
# Check ArgoCD applications
kubectl get applications -n argocd --kubeconfig infrastructure/terraform/k3d-config

# Wait until all show "Synced" and "Healthy"
```

### **Step 14: Verify Chat Apps Are Running**
```bash
kubectl get pods -A --kubeconfig infrastructure/terraform/k3d-config | grep chat-app
```

**Expected:** All pods in `Running` state (not ImagePullBackOff)

---

## **Phase 5: Access Services**

### **Step 15: Start Port Forwarding**
```bash
# Windows
.\start-all-services.bat

# Or manually:
kubectl port-forward -n argocd svc/argocd-server 8082:80 --kubeconfig infrastructure/terraform/k3d-config
```

### **Step 16: Access Chat Apps**
```bash
# Get LoadBalancer IPs
kubectl get services -A --kubeconfig infrastructure/terraform/k3d-config | grep chat-app

# Access via browser:
# Dev: http://[DEV_LOADBALANCER_IP]
# Staging: http://[STAGING_LOADBALANCER_IP]
# Prod: http://[PROD_LOADBALANCER_IP]
```

---

## **✅ Verification Checklist**

After completing all steps, verify:

- [ ] Cluster has 3 nodes (1 server, 2 agents)
- [ ] Registry is running: `docker ps | grep k3d-registry`
- [ ] Image is in registry: `curl http://localhost:5000/v2/chat-app/tags/list`
- [ ] Terraform apply completed successfully
- [ ] ArgoCD is running: `kubectl get pods -n argocd`
- [ ] Chat apps are running: `kubectl get pods -A | grep chat-app`
- [ ] All pods show `Running` status (not ImagePullBackOff)
- [ ] Services have LoadBalancer IPs assigned

---

## **🔧 Troubleshooting**

### **Issue: ImagePullBackOff**
**Solution:** 
1. Verify image exists: `curl http://localhost:5000/v2/chat-app/tags/list`
2. Check image name matches: `k3d-registry:5000/chat-app:latest`
3. Rebuild and push: `docker build -t k3d-registry:5000/chat-app:latest . && docker push k3d-registry:5000/chat-app:latest`

### **Issue: Cluster not accessible**
**Solution:**
```bash
k3d cluster start chat-k3d
k3d kubeconfig get chat-k3d > infrastructure/terraform/k3d-config
```

### **Issue: Registry not accessible**
**Solution:**
```bash
# Check registry is running
docker ps | grep k3d-registry

# Restart if needed
k3d registry delete k3d-registry
k3d registry create k3d-registry --port 5000
```

### **Issue: Terraform fails**
**Solution:**
1. Check kubeconfig: `kubectl --kubeconfig infrastructure/terraform/k3d-config get nodes`
2. Check cluster is running: `k3d cluster list`
3. Re-run: `terraform apply -auto-approve`

---

## **📋 Quick Reference**

### **Registry Name:**
- ✅ **Correct:** `k3d-registry:5000/chat-app:latest`
- ❌ **Wrong:** `k3d-k3d-registry:5000` (doesn't exist)
- ❌ **Wrong:** `localhost:5002` (not accessible from pods)
- ❌ **Wrong:** `k3d-myregistry.localhost:5000` (old name)

### **Key Commands:**
```bash
# Cluster management
k3d cluster list
k3d cluster delete chat-k3d
k3d cluster create chat-k3d --registry-use k3d-registry:5000

# Registry management
k3d registry list
k3d registry create k3d-registry --port 5000

# Image management
docker build -t k3d-registry:5000/chat-app:latest .
docker push k3d-registry:5000/chat-app:latest

# Kubernetes access
kubectl --kubeconfig infrastructure/terraform/k3d-config get pods -A
```

---

## **🎯 Best Practices Applied**

1. ✅ **Standard Registry Name:** `k3d-registry` (matches k3d conventions)
2. ✅ **Registry Attached:** Cluster created with `--registry-use`
3. ✅ **Image Pull Policy:** `Always` (ensures fresh images)
4. ✅ **Clean Setup:** No leftover configurations
5. ✅ **Proper Naming:** Consistent naming throughout

---

**🎉 After completing all steps, your chat application will be running with best practices!**

