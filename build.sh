#!/bin/bash

# FreePBX Docker Build & Push Script
# Usage: ./build.sh [dev|prod|all] [--push]

set -e

# Configuration
IMAGE_NAME="lnxr-freepbx"
DEV_TAG="dev"
PROD_TAG="17"
DOCKER_HUB_USER="${DOCKER_HUB_USER:-mleem97}"  # Change to your Docker Hub username
REGISTRY="${DOCKER_REGISTRY:-docker.io}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
show_usage() {
    echo "Usage: $0 [dev|prod|all] [--push]"
    echo ""
    echo "Commands:"
    echo "  dev     Build development image ($IMAGE_NAME:$DEV_TAG)"
    echo "  prod    Build production image ($IMAGE_NAME:$PROD_TAG)"
    echo "  all     Build both dev and prod images"
    echo ""
    echo "Options:"
    echo "  --push  Push images to Docker Hub after build"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKER_HUB_USER    Docker Hub username (default: mleem97)"
    echo "  DOCKER_REGISTRY    Registry URL (default: docker.io)"
    echo ""
    echo "Examples:"
    echo "  $0 dev              # Build dev image only"
    echo "  $0 prod --push      # Build prod image and push to Docker Hub"
    echo "  $0 all --push       # Build both images and push to Docker Hub"
}

# Check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        log_error "Docker is not running or not accessible"
        exit 1
    fi
}

# Build development image
build_dev() {
    log_info "Building development image: $IMAGE_NAME:$DEV_TAG"
    
    # Check if optimized dockerfile exists
    if [[ -f "dockerfile.optimized" ]]; then
        log_info "Using optimized multi-stage Dockerfile"
        docker build -f dockerfile.optimized -t "$IMAGE_NAME:$DEV_TAG" .
    else
        docker build -t "$IMAGE_NAME:$DEV_TAG" .
    fi
    
    log_success "Development image built: $IMAGE_NAME:$DEV_TAG"
    
    # Show image size
    local size=$(docker images "$IMAGE_NAME:$DEV_TAG" --format "{{.Size}}")
    log_info "Image size: $size"
}

# Build production image (tag from dev)
build_prod() {
    log_info "Tagging production image: $IMAGE_NAME:$PROD_TAG"
    
    # Check if dev image exists
    if ! docker image inspect "$IMAGE_NAME:$DEV_TAG" &> /dev/null; then
        log_warning "Development image not found, building it first..."
        build_dev
    fi
    
    # Tag dev image as prod
    docker tag "$IMAGE_NAME:$DEV_TAG" "$IMAGE_NAME:$PROD_TAG"
    log_success "Production image tagged: $IMAGE_NAME:$PROD_TAG"
}

# Push images to Docker Hub
push_images() {
    local images=("$@")
    
    # Check if logged in to Docker Hub
    if ! docker info 2>/dev/null | grep -q "Username"; then
        log_warning "Not logged in to Docker Hub. Attempting login..."
        docker login
    fi
    
    for tag in "${images[@]}"; do
        local hub_image="$DOCKER_HUB_USER/$IMAGE_NAME:$tag"
        
        log_info "Tagging for Docker Hub: $hub_image"
        docker tag "$IMAGE_NAME:$tag" "$hub_image"
        
        log_info "Pushing to Docker Hub: $hub_image"
        docker push "$hub_image"
        log_success "Pushed: $hub_image"
    done
}

# Update docker-compose files
update_compose_files() {
    log_info "Updating docker-compose files..."
    
    # Update dev compose file
    if [[ -f "docker-compose.yml" ]]; then
        log_info "Updating docker-compose.yml for development"
        # Already configured correctly
    fi
    
    # Update prod compose file
    if [[ -f "docker-compose.prod.yml" ]]; then
        log_info "Updating docker-compose.prod.yml for production"
        # Update the image reference to use our naming convention
        sed -i.bak "s|image: \${IMAGE_REGISTRY:-ghcr.io}/\${IMAGE_REPO:-your-username/freepbx-docker}:\${IMAGE_TAG:-latest}|image: \${IMAGE_REGISTRY:-$DOCKER_HUB_USER}/$IMAGE_NAME:\${IMAGE_TAG:-$PROD_TAG}|g" docker-compose.prod.yml
        rm -f docker-compose.prod.yml.bak
    fi
}

# Main execution
main() {
    local command="${1:-dev}"
    local push_flag="$2"
    local images_to_push=()
    
    # Check arguments
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    if [[ "$2" == "--push" || "$1" == "--push" ]]; then
        push_flag="--push"
        if [[ "$1" == "--push" ]]; then
            command="all"
        fi
    fi
    
    # Check Docker
    check_docker
    
    # Update compose files
    update_compose_files
    
    log_info "Starting FreePBX Docker build process..."
    log_info "Target: $command"
    
    case "$command" in
        "dev")
            build_dev
            if [[ "$push_flag" == "--push" ]]; then
                images_to_push=("$DEV_TAG")
            fi
            ;;
        "prod")
            build_prod
            if [[ "$push_flag" == "--push" ]]; then
                images_to_push=("$PROD_TAG")
            fi
            ;;
        "all")
            build_dev
            build_prod
            if [[ "$push_flag" == "--push" ]]; then
                images_to_push=("$DEV_TAG" "$PROD_TAG")
            fi
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
    
    # Push images if requested
    if [[ "$push_flag" == "--push" && ${#images_to_push[@]} -gt 0 ]]; then
        push_images "${images_to_push[@]}"
    fi
    
    log_success "Build process completed!"
    
    # Show available images
    log_info "Available images:"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    if [[ "$push_flag" == "--push" ]]; then
        log_info "Docker Hub images:"
        for tag in "${images_to_push[@]}"; do
            echo "  docker pull $DOCKER_HUB_USER/$IMAGE_NAME:$tag"
        done
    fi
}

# Run main function with all arguments
main "$@"