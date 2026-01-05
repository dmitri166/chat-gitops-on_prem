# Makefile for Chat Application Development Workflow
# Alternative to bash scripts - more structured approach

.PHONY: help build push registry metrics deploy clean test

# Default target
help:
	@echo "Chat Application Development Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  build     - Build Docker image"
	@echo "  push      - Push image to registry"
	@echo "  registry  - Setup local registry"
	@echo "  metrics   - Add metrics to application"
	@echo "  deploy    - Deploy with Terraform"
	@echo "  test      - Run tests"
	@echo "  clean     - Clean up resources"
	@echo ""
	@echo "Usage: make <target> [VERSION=v1.0.0]"

# Variables
VERSION ?= latest
IMAGE_NAME := localhost:5001/chat-app
FULL_IMAGE := $(IMAGE_NAME):$(VERSION)

# Build container
build:
	@echo "🔨 Building container: $(FULL_IMAGE)"
	docker build -t $(FULL_IMAGE) ../../Flask-SocketIO-Chat
	@echo "✅ Build complete"

# Push container
push: build
	@echo "📤 Pushing container: $(FULL_IMAGE)"
	docker push $(FULL_IMAGE)
	@echo "✅ Push complete"

# Setup registry
registry:
	@echo "🐳 Setting up local registry"
	@./setup-local-registry.sh

# Add metrics
metrics:
	@echo "📊 Adding Prometheus metrics"
	@./add-metrics-to-app.sh

# Deploy infrastructure
deploy:
	@echo "🚀 Deploying infrastructure"
	cd ../../terraform-kind && ./deploy.sh

# Run tests
test:
	@echo "🧪 Running tests"
	# Add your test commands here
	@echo "✅ Tests passed"

# Clean up
clean:
	@echo "🧹 Cleaning up"
	docker system prune -f
	kind delete cluster --name chat-local || true
	@echo "✅ Cleanup complete"

# Combined workflow
all: registry build push metrics deploy
	@echo "🎉 Full deployment complete!"

# Development workflow
dev: build push deploy
	@echo "💻 Development deployment ready"

# Production workflow
prod: test build push deploy
	@echo "🏭 Production deployment complete"
