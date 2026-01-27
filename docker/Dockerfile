FROM ubuntu:22.04

LABEL maintainer="your-email@example.com"
LABEL description="Docker image for Cell Ranger 8.0.1"
LABEL version="8.0.1"

# Install dependencies
RUN apt-get update && apt-get install -y \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt

# Copy and install Cell Ranger 8.0.1
# Note: User should download cellranger-8.0.1.tar.gz from 10X Genomics first
COPY cellranger-8.0.1.tar.gz .

RUN tar -xzvf cellranger-8.0.1.tar.gz \
    && rm cellranger-8.0.1.tar.gz

# Add Cell Ranger to PATH
ENV PATH="/opt/cellranger-8.0.1:${PATH}"

# Verify installation
RUN cellranger --version

# Set default command
CMD ["/bin/bash"]
