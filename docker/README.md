# Cell Ranger Docker Image

This directory contains the Dockerfile and build instructions for creating a custom Cell Ranger 10.0.0 Docker image.

## Prerequisites

- Docker installed locally
- Google Cloud SDK installed and configured (`gcloud`)
- Access to download Cell Ranger from 10X Genomics
- Permissions to push to your Google Cloud Container Registry

## Building the Docker Image

### Option 1: Using the Build Script (Recommended)

```bash
# Make the script executable
chmod +x build_and_push.sh

# Build and push to Google Cloud
./build_and_push.sh
```

### Option 2: Manual Build

#### 1. Get Fresh Download URL from 10X Genomics

The download URL in the Dockerfile expires. Get a fresh one:

1. Go to https://www.10xgenomics.com/support/software/cell-ranger/downloads
2. Download Cell Ranger 10.0.0
3. Copy the download URL
4. Update the `CELLRANGER_URL` in the Dockerfile or pass it as a build argument

#### 2. Build the Image Locally

```bash
cd docker

# Build with default URL (if not expired)
docker build -t cellranger:10.0.0 .

# OR build with fresh download URL
docker build \
  --build-arg CELLRANGER_URL="YOUR_FRESH_DOWNLOAD_URL" \
  -t cellranger:10.0.0 .
```

#### 3. Test the Image

```bash
# Test that cellranger works
docker run --rm cellranger:10.0.0 cellranger --version

# Expected output: cellranger cellranger-10.0.0
```

## Pushing to Google Cloud Container Registry

### 1. Configure Docker for Google Cloud

```bash
# Configure Docker to use gcloud as credential helper
gcloud auth configure-docker
```

### 2. Set Your Project Variables

```bash
# Set your GCP project ID
export GCP_PROJECT="your-gcp-project-id"

# Set the region (optional, default is us)
export GCP_REGION="us"
```

### 3. Tag the Image for Google Cloud

```bash
# Tag for Google Container Registry (gcr.io)
docker tag cellranger:10.0.0 gcr.io/${GCP_PROJECT}/cellranger:10.0.0
docker tag cellranger:10.0.0 gcr.io/${GCP_PROJECT}/cellranger:latest

# OR tag for Artifact Registry (recommended for new projects)
docker tag cellranger:10.0.0 ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/cellranger/cellranger:10.0.0
docker tag cellranger:10.0.0 ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/cellranger/cellranger:latest
```

### 4. Push to Google Cloud

```bash
# Push to Container Registry (gcr.io)
docker push gcr.io/${GCP_PROJECT}/cellranger:10.0.0
docker push gcr.io/${GCP_PROJECT}/cellranger:latest

# OR push to Artifact Registry
docker push ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/cellranger/cellranger:10.0.0
docker push ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/cellranger/cellranger:latest
```

### 5. Verify the Push

```bash
# List images in Container Registry
gcloud container images list --repository=gcr.io/${GCP_PROJECT}

# OR list in Artifact Registry
gcloud artifacts docker images list ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/cellranger
```

## Using the Custom Image in the Pipeline

### Update nextflow.config

Edit the `nextflow.config` file to use your custom image:

```groovy
process {
    // Use your custom image
    container = 'gcr.io/your-gcp-project-id/cellranger:10.0.0'

    // OR for Artifact Registry
    container = 'us-docker.pkg.dev/your-gcp-project-id/cellranger/cellranger:10.0.0'
}
```

### Or Update conf/modules.config

For module-specific configuration:

```groovy
process {
    withName: 'CELLRANGER_COUNT' {
        container = 'gcr.io/your-gcp-project-id/cellranger:10.0.0'
    }

    withName: 'CELLRANGER_MULTI' {
        container = 'gcr.io/your-gcp-project-id/cellranger:10.0.0'
    }
}
```

## Artifact Registry Setup (Recommended for New Projects)

If using Artifact Registry instead of Container Registry:

### 1. Create Repository

```bash
gcloud artifacts repositories create cellranger \
    --repository-format=docker \
    --location=${GCP_REGION} \
    --description="Cell Ranger Docker images"
```

### 2. Configure Docker Authentication

```bash
gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev
```

### 3. Follow Steps 3-4 Above

Use the Artifact Registry URLs as shown in the tagging and pushing examples.

## Troubleshooting

### Download URL Expired

If you get a 403 error when building:
1. Get a fresh download URL from 10X Genomics
2. Pass it as a build argument: `--build-arg CELLRANGER_URL="new_url"`

### Permission Denied

If you can't push to GCP:
```bash
# Re-authenticate
gcloud auth login

# Configure docker again
gcloud auth configure-docker
```

### Image Too Large

The Cell Ranger image is ~2-3 GB. Ensure you have:
- Sufficient local disk space
- Good internet connection for pushing
- Consider pushing during off-peak hours

## Image Details

- **Base Image**: Ubuntu 22.04
- **Cell Ranger Version**: 10.0.0
- **Size**: ~2-3 GB
- **Architecture**: x86_64

## Updating Cell Ranger Version

To update to a newer version:
1. Download the new version URL from 10X Genomics
2. Update the `CELLRANGER_URL` and version numbers in the Dockerfile
3. Rebuild and push with the new version tag

## Cell Ranger ARC (Multiome) Image

Multiome (ATAC + Gene Expression) data requires a separate tool, `cellranger-arc`, which is not compatible with the standard `cellranger` binary/container above. See [Dockerfile.cellranger-arc](Dockerfile.cellranger-arc) and [build_and_push_arc.sh](build_and_push_arc.sh), which follow the same download-under-license-and-build pattern:

```bash
# 1. Download cellranger-arc-2.2.0.tar.gz from 10X Genomics into this directory
#    https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads

# 2. Build and push
./build_and_push_arc.sh
```

This pushes to the same Artifact Registry repository (`cellranger`) under a distinct image name (`cellranger-arc`), configured via `params.cellranger_arc_container` in [nextflow.config](../nextflow.config).
