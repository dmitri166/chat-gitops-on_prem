#!/bin/bash

# Build and push chat application to local registry
# Usage: ./build-and-push.sh [tag]

set -e

# Default tag
TAG=${1:-latest}
REGISTRY="localhost:5001"
IMAGE_NAME="chat-app"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "Building chat application container..."
echo "Image: ${FULL_IMAGE}"

# Build the container
docker build -t "${FULL_IMAGE}" ./Flask-SocketIO-Chat

# Push to local registry
echo "Pushing to local registry..."
docker push "${FULL_IMAGE}"

echo "Successfully built and pushed: ${FULL_IMAGE}"

# Also tag as latest if not already
if [ "$TAG" != "latest" ]; then
    LATEST_IMAGE="${REGISTRY}/${IMAGE_NAME}:latest"
    docker tag "${FULL_IMAGE}" "${LATEST_IMAGE}"
    docker push "${LATEST_IMAGE}"
    echo "Also tagged and pushed as: ${LATEST_IMAGE}"
fi

echo "Container is ready for deployment!"
