FROM ubuntu:22.04

LABEL maintainer="your-email@example.com"
LABEL description="Docker image for Cell Ranger 10.0.0"
LABEL version="10.0.0"

# Install dependencies
RUN apt-get update && apt-get install -y \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt

# Copy and install Cell Ranger 10.0.0
# Note: User should download cellranger-10.0.0.tar.gz from 10X Genomics first
COPY cellranger-10.0.0.tar.gz .

RUN tar -xzvf cellranger-10.0.0.tar.gz \
    && rm cellranger-10.0.0.tar.gz

# Add Cell Ranger to PATH
ENV PATH="/opt/cellranger-10.0.0:${PATH}"

# Verify installation
RUN cellranger --version

# Set default command
CMD ["/bin/bash"]
