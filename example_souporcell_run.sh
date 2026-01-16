#!/bin/bash

# Example script for running the pipeline with SoupOrCell
# This demonstrates demultiplexing a pooled 2-donor experiment

nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet samplesheet_gex.csv \
    --reference /path/to/refdata-gex-GRCh38-2024-A \
    --run_souporcell true \
    --souporcell_fasta /path/to/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
    --souporcell_clusters 2 \
    --outdir results_with_souporcell
