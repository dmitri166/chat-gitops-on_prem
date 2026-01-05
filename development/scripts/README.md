# Containerization Scripts

This directory contains scripts for building and managing the chat application container for the on-premises deployment.

## Scripts Overview

### `setup-local-registry.sh`
Sets up a local Docker registry that can be accessed by the Kind cluster.

**Usage:**
```bash
./setup-local-registry.sh
```

**What it does:**
- Creates a Docker registry container on port 5001
- Configures it for local development
- Provides instructions for Docker insecure registry configuration

### `build-and-push.sh`
Builds the chat application container and pushes it to the local registry.

**Usage:**
```bash
./build-and-push.sh [tag]
```

**Examples:**
```bash
# Build with default 'latest' tag
./build-and-push.sh

# Build with specific tag
./build-and-push.sh v1.0.0
```

**What it does:**
- Builds the container from the Flask-SocketIO-Chat directory
- Tags it with the specified tag (or 'latest')
- Pushes to localhost:5001 registry
- Also tags as 'latest' if a different tag was specified

### `add-metrics-to-app.sh`
Adds Prometheus metrics support to the Flask application.

**Usage:**
```bash
./add-metrics-to-app.sh
```

**What it does:**
- Adds prometheus-flask-exporter to requirements.txt
- Modifies chat.py to include metrics instrumentation
- Enables /metrics endpoint for Prometheus scraping

## Workflow

1. **Setup Registry:**
   ```bash
   ./setup-local-registry.sh
   ```

2. **Add Metrics (optional but recommended):**
   ```bash
   ./add-metrics-to-app.sh
   ```

3. **Build and Push:**
   ```bash
   ./build-and-push.sh v1.0.0
   ```

4. **Update Helm Values:**
   Update the image tag in `chat-gitops/chat-gitops/chat-app-helm/values.yaml` if needed

5. **Deploy via ArgoCD:**
   The ApplicationSet will automatically pick up the new image

## Local Registry Details

- **Registry URL:** localhost:5001
- **Container Name:** kind-registry
- **Data Volume:** Mounted to /tmp/kind-registry (configured in kind-config.yaml)
- **Insecure:** Configured for local development only

## Security Notes

- The local registry is configured as insecure for development
- In production, use a secure registry with proper TLS certificates
- Store registry credentials using Sealed Secrets

## Troubleshooting

### Registry Connection Issues:
```bash
# Check if registry is running
docker ps | grep kind-registry

# Test registry connectivity
curl http://localhost:5001/v2/

# Check Kind cluster can reach registry
kubectl run test --image=busybox --rm -it -- wget -O- http://kind-registry:5000/v2/
```

### Build Issues:
```bash
# Clean build
docker system prune -f
./build-and-push.sh

# Check build logs
docker build --no-cache -t localhost:5001/chat-app:test ./Flask-SocketIO-Chat
```

### Push Issues:
```bash
# Check registry permissions
docker logs kind-registry

# Verify insecure registry configuration
docker info | grep -A 10 "Insecure Registries"
```
