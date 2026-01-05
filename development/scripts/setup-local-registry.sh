#!/bin/bash

# Setup local Docker registry for Kind cluster
# This script creates and configures a local registry accessible by Kind

set -e

REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"

echo "Setting up local Docker registry for Kind..."

# Create registry container if it doesn't exist
if ! docker ps -a --format 'table {{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
    echo "Creating registry container..."
    docker run -d \
        --name "${REGISTRY_NAME}" \
        --restart always \
        -p "127.0.0.1:${REGISTRY_PORT}:5000" \
        -e REGISTRY_STORAGE_DELETE_ENABLED=true \
        registry:2.8
else
    echo "Registry container already exists. Starting if not running..."
    docker start "${REGISTRY_NAME}" 2>/dev/null || echo "Registry already running"
fi

# Wait for registry to be ready
echo "Waiting for registry to be ready..."
for i in {1..30}; do
    if curl -s "http://localhost:${REGISTRY_PORT}/v2/" > /dev/null; then
        break
    fi
    echo "Waiting for registry... ($i/30)"
    sleep 2
done

# Verify registry is working
if curl -s "http://localhost:${REGISTRY_PORT}/v2/" > /dev/null; then
    echo "✅ Local registry is running at localhost:${REGISTRY_PORT}"
    echo "Registry URL for Kind: localhost:${REGISTRY_PORT}"
else
    echo "❌ Failed to start registry"
    exit 1
fi

# Add registry to insecure registries in Docker (for local development)
echo "Configuring Docker to allow insecure registry..."
if command -v docker &> /dev/null; then
    # Check if registry is already in insecure registries
    if ! docker info 2>/dev/null | grep -A 10 "Insecure Registries" | grep -q "localhost:${REGISTRY_PORT}"; then
        echo "Please add the following to your Docker daemon configuration:"
        echo "  \"insecure-registries\": [\"localhost:${REGISTRY_PORT}\"]"
        echo ""
        echo "On Linux, edit /etc/docker/daemon.json"
        echo "On macOS, go to Docker Desktop > Settings > Docker Engine"
        echo "On Windows, go to Docker Desktop > Settings > Docker Engine"
    else
        echo "✅ Registry already configured as insecure"
    fi
fi

echo ""
echo "Registry setup complete!"
echo "You can now build and push images to: localhost:${REGISTRY_PORT}"
echo ""
echo "Example usage:"
echo "  docker build -t localhost:${REGISTRY_PORT}/my-app:latest ."
echo "  docker push localhost:${REGISTRY_PORT}/my-app:latest"
