#!/bin/bash

# Example: Running the pipeline with per-sample SoupOrCell cluster counts
# This script demonstrates how to use the souporcell_clusters_file parameter

nextflow run main.nf \
    -profile gcp \
    --data_type GEX \
    --samplesheet /home/lpantano/config-pipelines/20251129/final_samplesheet.csv \
    --reference gs://ghobrial-scrna-data/references/refdata-gex-GRCh38-2024-A \
    --run_souporcell true \
    --souporcell_fasta gs://ghobrial-scrna-data/references/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
    --souporcell_clusters_file /home/lpantano/config-pipelines/20251129/pool_analysis_summary.csv \
    --outdir gs://ghobrial-pipelines/results/20251129_variable_pooling

# Notes:
# - The pool_analysis_summary.csv must have columns: sample_id, sample_count
# - sample_id must match the sample_id in final_samplesheet.csv
# - sample_count is the number of donors/clusters for SoupOrCell
# - If souporcell_clusters_file is not provided, all samples will use the default
#   value from --souporcell_clusters (default: 2)
