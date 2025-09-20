# FreePBX Docker Makefile
.PHONY: help build-dev build-prod build-all push-dev push-prod push-all up-dev up-prod down-dev down-prod clean logs

# Default target
help: ## Show this help message
	@echo "FreePBX Docker Build & Management"
	@echo "================================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Build targets
build-dev: ## Build development image (lnxr-freepbx:dev)
	./build.sh dev

build-prod: ## Build production image (lnxr-freepbx:17)
	./build.sh prod

build-all: ## Build both dev and prod images
	./build.sh all

# Push targets  
push-dev: ## Build and push development image to Docker Hub
	./build.sh dev --push

push-prod: ## Build and push production image to Docker Hub
	./build.sh prod --push

push-all: ## Build and push both images to Docker Hub
	./build.sh all --push

# Container management
up-dev: ## Start development container
	docker-compose up -d

up-prod: ## Start production container (requires .env.prod)
	docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

down-dev: ## Stop development container
	docker-compose down

down-prod: ## Stop production container
	docker-compose -f docker-compose.prod.yml down

# Utility targets
logs: ## Show logs for running containers
	@echo "=== Development Logs ==="
	@docker-compose logs --tail=50 -f || echo "Development container not running"

logs-prod: ## Show production logs
	@echo "=== Production Logs ==="
	@docker-compose -f docker-compose.prod.yml logs --tail=50 -f || echo "Production container not running"

shell-dev: ## Open shell in development container
	docker exec -it lnxr-freepbx-dev /bin/bash

shell-prod: ## Open shell in production container
	docker exec -it lnxr-freepbx-prod /bin/bash

asterisk-cli: ## Open Asterisk CLI (development)
	docker exec -it lnxr-freepbx-dev asterisk -r

asterisk-cli-prod: ## Open Asterisk CLI (production)
	docker exec -it lnxr-freepbx-prod asterisk -r

clean: ## Remove all FreePBX images and containers
	@echo "Cleaning up FreePBX containers and images..."
	@docker ps -a | grep lnxr-freepbx | awk '{print $$1}' | xargs -r docker rm -f
	@docker images lnxr-freepbx | grep -v REPOSITORY | awk '{print $$3}' | xargs -r docker rmi -f
	@echo "Cleanup completed"

status: ## Show status of all FreePBX containers
	@echo "=== Container Status ==="
	@docker ps -a --filter "name=lnxr-freepbx" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "=== Available Images ==="
	@docker images lnxr-freepbx --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Setup targets
setup-env: ## Create .env.prod from .env.example
	@if [ ! -f .env.prod ]; then \
		cp .env.example .env.prod; \
		echo "Created .env.prod from .env.example"; \
		echo "Please edit .env.prod with your configuration"; \
	else \
		echo ".env.prod already exists"; \
	fi

# Complete workflow
dev-deploy: build-dev up-dev ## Build and start development environment

prod-deploy: build-prod setup-env up-prod ## Build and start production environment