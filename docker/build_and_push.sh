#!/bin/bash

# Build and Push Cell Ranger Docker Image to Google Cloud
# Usage: ./build_and_push.sh [GCP_PROJECT_ID] [REGION]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
VERSION="10.0.0"
IMAGE_NAME="cellranger"
DEFAULT_REGION="us"

# Get GCP project from argument or prompt
if [ -z "$1" ]; then
    read -p "Enter your GCP Project ID: " GCP_PROJECT
else
    GCP_PROJECT="$1"
fi

# Get region from argument or use default
if [ -z "$2" ]; then
    GCP_REGION="$DEFAULT_REGION"
else
    GCP_REGION="$2"
fi

echo -e "${GREEN}=== Cell Ranger Docker Build and Push ===${NC}"
echo "Version: $VERSION"
echo "GCP Project: $GCP_PROJECT"
echo "Region: $GCP_REGION"
echo ""

# Ask for fresh download URL
echo -e "${YELLOW}NOTE: The Cell Ranger download URL in the Dockerfile may have expired.${NC}"
read -p "Do you have a fresh download URL from 10X Genomics? (y/n): " HAS_URL

if [ "$HAS_URL" = "y" ]; then
    read -p "Enter the Cell Ranger download URL: " CELLRANGER_URL
    BUILD_ARGS="--build-arg CELLRANGER_URL=\"$CELLRANGER_URL\""
else
    echo -e "${YELLOW}Using URL from Dockerfile (may fail if expired)${NC}"
    BUILD_ARGS=""
fi

# Choose registry type
echo ""
echo "Select container registry:"
echo "1) Container Registry (gcr.io) - Legacy"
echo "2) Artifact Registry (Artifact Registry) - Recommended"
read -p "Choice (1 or 2): " REGISTRY_CHOICE

if [ "$REGISTRY_CHOICE" = "2" ]; then
    # Artifact Registry
    REGISTRY_URL="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${IMAGE_NAME}"
    FULL_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}"

    echo ""
    echo -e "${GREEN}Step 1: Creating Artifact Registry repository...${NC}"
    gcloud artifacts repositories create ${IMAGE_NAME} \
        --repository-format=docker \
        --location=${GCP_REGION} \
        --description="Cell Ranger Docker images" \
        --project=${GCP_PROJECT} 2>/dev/null || echo "Repository may already exist"

    echo ""
    echo -e "${GREEN}Step 2: Configuring Docker authentication...${NC}"
    gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev
else
    # Container Registry
    FULL_IMAGE="gcr.io/${GCP_PROJECT}/${IMAGE_NAME}"

    echo ""
    echo -e "${GREEN}Step 1: Configuring Docker authentication...${NC}"
    gcloud auth configure-docker
fi

echo ""
echo -e "${GREEN}Step 3: Building Docker image...${NC}"
if [ -n "$BUILD_ARGS" ]; then
    eval docker build $BUILD_ARGS -t ${IMAGE_NAME}:${VERSION} .
else
    docker build -t ${IMAGE_NAME}:${VERSION} .
fi

echo ""
echo -e "${GREEN}Step 4: Testing the image...${NC}"
docker run --rm ${IMAGE_NAME}:${VERSION} cellranger --version

echo ""
echo -e "${GREEN}Step 5: Tagging images...${NC}"
docker tag ${IMAGE_NAME}:${VERSION} ${FULL_IMAGE}:${VERSION}
docker tag ${IMAGE_NAME}:${VERSION} ${FULL_IMAGE}:latest
echo "Tagged: ${FULL_IMAGE}:${VERSION}"
echo "Tagged: ${FULL_IMAGE}:latest"

echo ""
echo -e "${GREEN}Step 6: Pushing to Google Cloud...${NC}"
docker push ${FULL_IMAGE}:${VERSION}
docker push ${FULL_IMAGE}:latest

echo ""
echo -e "${GREEN}=== Build and Push Complete! ===${NC}"
echo ""
echo "Your Docker image is available at:"
echo "  ${FULL_IMAGE}:${VERSION}"
echo "  ${FULL_IMAGE}:latest"
echo ""
echo "To use in your pipeline, update nextflow.config:"
echo ""
echo "process {"
echo "    container = '${FULL_IMAGE}:${VERSION}'"
echo "}"
echo ""
