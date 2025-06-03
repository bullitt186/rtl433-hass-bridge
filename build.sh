#!/bin/bash
set -e

# Build script for RTL_433 MQTT Home Assistant Bridge Docker image

# Default values
IMAGE_NAME="rtl433-hass-bridge"
IMAGE_TAG="latest"
PUSH_TO_REGISTRY=false
REGISTRY=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_TO_REGISTRY=true
            shift
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -n, --name NAME       Docker image name (default: rtl433-hass-bridge)"
            echo "  -t, --tag TAG         Docker image tag (default: latest)"
            echo "  -p, --push            Push image to registry after build"
            echo "  -r, --registry REG    Registry to push to (e.g., ghcr.io/user)"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set full image name
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
else
    FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
fi

echo "Building Docker image: $FULL_IMAGE_NAME"

# Build arguments
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Build the image
docker build \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VCS_REF="$VCS_REF" \
    --tag "$FULL_IMAGE_NAME" \
    --tag "${IMAGE_NAME}:latest" \
    .

echo "Build completed successfully!"
echo "Image: $FULL_IMAGE_NAME"

# Push to registry if requested
if [ "$PUSH_TO_REGISTRY" = true ]; then
    if [ -z "$REGISTRY" ]; then
        echo "Error: Registry not specified for push operation"
        exit 1
    fi
    
    echo "Pushing image to registry..."
    docker push "$FULL_IMAGE_NAME"
    echo "Push completed successfully!"
fi

echo "Done!"