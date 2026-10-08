#!/bin/bash

# Build and Push Cell Ranger ARC Docker Image to Google Cloud
# Usage: ./build_and_push_arc.sh [GCP_PROJECT_ID] [REGION]
#
# Prerequisites: download cellranger-arc-2.2.0.tar.gz from 10X Genomics
# (https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads)
# into this docker/ directory before running.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
VERSION="2.2.0"
IMAGE_NAME="cellranger-arc"
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

echo -e "${GREEN}=== Cell Ranger ARC Docker Build and Push ===${NC}"
echo "Version: $VERSION"
echo "GCP Project: $GCP_PROJECT"
echo "Region: $GCP_REGION"
echo ""

# Artifact Registry (reuses the existing 'cellranger' repository)
REGISTRY_URL="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/cellranger"
FULL_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}"

echo ""
echo -e "${GREEN}Step 1: Configuring Docker authentication...${NC}"
gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev

echo ""
echo -e "${GREEN}Step 2: Building Docker image...${NC}"
docker build -f Dockerfile.cellranger-arc -t ${IMAGE_NAME}:${VERSION} .

echo ""
echo -e "${GREEN}Step 3: Testing the image...${NC}"
docker run --rm ${IMAGE_NAME}:${VERSION} cellranger-arc --version

echo ""
echo -e "${GREEN}Step 4: Tagging images...${NC}"
docker tag ${IMAGE_NAME}:${VERSION} ${FULL_IMAGE}:${VERSION}
docker tag ${IMAGE_NAME}:${VERSION} ${FULL_IMAGE}:latest
echo "Tagged: ${FULL_IMAGE}:${VERSION}"
echo "Tagged: ${FULL_IMAGE}:latest"

echo ""
echo -e "${GREEN}Step 5: Pushing to Google Cloud...${NC}"
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
echo "params {"
echo "    cellranger_arc_container = '${FULL_IMAGE}:${VERSION}'"
echo "}"
echo ""
