#!/bin/bash
set -e

# -----------------------------
# 🚀 k3d Cluster + Registry Setup + Image Push
# -----------------------------

CLUSTER_NAME="chat-k3d"
REGISTRY_NAME="k3d-registry"
REGISTRY_PORT="5002"
IMAGE_NAME="chat-app"
IMAGE_TAG="latest"
SOURCE_DIR="./applications/chat-app/source"

echo "🟢 Setting up k3d cluster and registry..."

# -----------------------------
# Step 1: Clean existing cluster and registry
# -----------------------------
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo "⚠️  Deleting existing cluster $CLUSTER_NAME..."
  k3d cluster delete "$CLUSTER_NAME"
fi

if k3d registry list | grep -q "$REGISTRY_NAME"; then
  echo "⚠️  Deleting existing registry $REGISTRY_NAME..."
  k3d registry delete "$REGISTRY_NAME"
fi

# -----------------------------
# Step 2: Create registry
# -----------------------------
echo "📦 Creating registry $REGISTRY_NAME:$REGISTRY_PORT..."
k3d registry create "$REGISTRY_NAME" --port "$REGISTRY_PORT"

# -----------------------------
# Step 3: Create cluster with registry attached
# -----------------------------
echo "⚙️  Creating cluster $CLUSTER_NAME with attached registry..."
k3d cluster create "$CLUSTER_NAME" \
  --agents 2 \
  --registry-use "${REGISTRY_NAME}:${REGISTRY_PORT}" \
  --k3s-arg "--disable=traefik@server:0"

# -----------------------------
# Step 4: Save kubeconfig
# -----------------------------
KUBECONFIG_FILE="infrastructure/terraform/k3d-config"
mkdir -p $(dirname "$KUBECONFIG_FILE")
k3d kubeconfig get "$CLUSTER_NAME" > "$KUBECONFIG_FILE"
echo "✅ Kubeconfig saved to $KUBECONFIG_FILE"

# -----------------------------
# Step 5: Build and push Docker image
# -----------------------------
LOCAL_REGISTRY="localhost:$REGISTRY_PORT"
IMAGE_FULL="${LOCAL_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "📦 Building Docker image $IMAGE_FULL..."
docker build -t "$IMAGE_FULL" "$SOURCE_DIR"

echo "📤 Pushing image to registry..."
docker push "$IMAGE_FULL"

# -----------------------------
# Step 6: Verify cluster
# -----------------------------
echo "🔍 Verifying cluster nodes..."
kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes

echo "🎉 Setup complete!"
echo "📌 Next steps:"
echo "1. Update Helm values.yaml to use image repository: $LOCAL_REGISTRY/$IMAGE_NAME"
echo "2. Deploy your app with:"
echo "   helm upgrade --install chat-app-dev ./helm -f values.yaml -f values-dev.yaml -n dev --create-namespace"
