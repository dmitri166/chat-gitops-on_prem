# ⚡ Quick Start - Best Practices Setup

## **Essential Steps (Copy & Paste)**

### **1. Setup Cluster**
```bash
chmod +x setup-k3d-cluster.sh
./setup-k3d-cluster.sh
```

### **2. Build & Push Image**
```bash
cd applications/chat-app/source
docker build -t k3d-registry:5000/chat-app:latest .
docker push k3d-registry:5000/chat-app:latest
cd ../../..
```

### **3. Deploy Infrastructure**
```bash
cd infrastructure/terraform
terraform apply -auto-approve
cd ../..
```

### **4. Deploy Applications**
```bash
kubectl --kubeconfig infrastructure/terraform/k3d-config apply -f platform/argocd/applicationsets/
```

### **5. Verify**
```bash
kubectl get pods -A --kubeconfig infrastructure/terraform/k3d-config | grep chat-app
```

### **6. Access Services**
```bash
.\start-all-services.bat
```

---

## **✅ Key Points**

- **Registry:** `k3d-registry:5000` (standard name)
- **Image:** `k3d-registry:5000/chat-app:latest`
- **Pull Policy:** `Always`
- **Cluster:** `chat-k3d` with registry attached

---

**See SETUP-GUIDE.md for detailed instructions and troubleshooting.**

