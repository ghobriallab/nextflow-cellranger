FROM ubuntu:22.04

LABEL maintainer="your-email@example.com"
LABEL description="Docker image for Cell Ranger 10.0.0"
LABEL version="10.0.0"

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt

# Download and install Cell Ranger 10.0.0
# Note: This URL contains authentication and will expire - replace with your own download URL from 10X Genomics
ARG CELLRANGER_URL="https://cf.10xgenomics.com/releases/cell-exp/cellranger-10.0.0.tar.gz?Expires=1765959513&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=jlqGr4EE5hvAY5Hm5z8RlfK9gyxY75Ee9vQQtG6MSlJwRbi29HxAzkHvWf72Wh02PkA2kciwd5IMjLErQvuRxGLfVnr-Bi6vNLkPLTPzg7O3JjgE7cX9zzuk8~eNBiClMi6EGpRmOz608b0th1dUnJ7q8J1SA52dn1KyoDiVVOX52an8ZNWRUkn9pczvJCWuVDpOmhMhnEqjDTJf-2dXcMk5EqUjZ0KhTWV-Zq7HxXFdNlxP6BeLP6TjRC5NFGc8B5IqpMdWdcGPQQ4ez0xt6z8YAeaEEplPrleAx-j3-mY2SPmGRARjgOy9WM6XrVd-3JwTdyJXFp4gT7mrEVYOfQ__"

RUN curl -o cellranger-10.0.0.tar.gz "${CELLRANGER_URL}" \
    && tar -xzvf cellranger-10.0.0.tar.gz \
    && rm cellranger-10.0.0.tar.gz

# Add Cell Ranger to PATH
ENV PATH="/opt/cellranger-10.0.0:${PATH}"

# Verify installation
RUN cellranger --version

# Set default command
CMD ["/bin/bash"]
