#!/bin/bash

# Example run script for SOUPORCELL mode
# This runs souporcell on existing BAM files from previous cellranger runs

nextflow run main.nf \
    -profile gcp \
    --data_type SOUPORCELL \
    --samplesheet samplesheet_souporcell.csv \
    --souporcell_fasta gs://path/to/reference/genome.fa \
    --outdir gs://ghobrial-pipelines/results/souporcell_only \
    -resume
