# SoupOrCell Integration

SoupOrCell is a tool for demultiplexing pooled single-cell RNA-seq experiments and detecting doublets. This pipeline integrates SoupOrCell as an optional post-processing step after CellRanger count.

## What is SoupOrCell?

SoupOrCell clusters cells by their genotypes and identifies doublets in droplet-based single-cell RNA-seq data. It's particularly useful for:

- **Pooled experiments**: When multiple donors/samples are pooled into a single 10X channel
- **Doublet detection**: Identifying droplets containing cells from multiple individuals
- **Cost reduction**: Pool multiple samples per lane without cell hashing

## Usage

To enable SoupOrCell in your pipeline run, add the following parameters:

```bash
nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet samplesheet_gex.csv \
    --reference /path/to/refdata-gex-GRCh38-2024-A \
    --run_souporcell true \
    --souporcell_fasta /path/to/genome.fasta \
    --souporcell_clusters 2 \
    --outdir results
```

## Required Files

### Reference Genome FASTA

SoupOrCell requires a reference genome FASTA file (typically the same genome used for the CellRanger reference):

```bash
# Download from NCBI, Ensembl, or use the FASTA from your CellRanger reference
# Example: GRCh38 human genome
wget http://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
```

### Number of Clusters

Set `--souporcell_clusters` to the number of genotypes/donors expected in your pooled sample:

- `2` for 2 donors
- `3` for 3 donors
- etc.

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `--run_souporcell` | Enable SoupOrCell | `false` | No |
| `--souporcell_fasta` | Reference genome FASTA | `null` | Yes (if enabled) |
| `--souporcell_clusters` | Number of expected clusters/genotypes (default for all samples) | `2` | No |
| `--souporcell_clusters_file` | CSV file with per-sample cluster counts | `null` | No |

## Cluster Count Options

You have two options for specifying the number of clusters/donors for SoupOrCell:

### Option 1: Single Value for All Samples (Default)

Use `--souporcell_clusters` to apply the same cluster count to all samples:

```bash
nextflow run main.nf \
    --run_souporcell true \
    --souporcell_fasta /path/to/genome.fasta \
    --souporcell_clusters 2
```

### Option 2: Per-Sample Cluster Counts

For experiments where different samples have different numbers of pooled donors, provide a CSV file with per-sample cluster counts using `--souporcell_clusters_file`:

```bash
nextflow run main.nf \
    --run_souporcell true \
    --souporcell_fasta /path/to/genome.fasta \
    --souporcell_clusters_file pool_analysis_summary.csv
```

The CSV file must contain at least two columns:
- `sample_id`: Must match the sample_id from your samplesheet
- `sample_count`: Number of clusters/donors for this sample

Example `pool_analysis_summary.csv`:
```csv
sample_id,sample_count,Demux_Sample_IDs
B100_1_1_GEX_5,4,IP2330PB_1_PB_CD138neg_GEX_5; IP1818PB_1_PB_CD138neg_GEX_5; IP2541PB_1_PB_CD138neg_GEX_5; CP1278PB_1_PB_CD138neg_GEX_5
B101_1_1_GEX_5,4,IP3078PB_1_PB_CD138neg_GEX_5; IP2457PB_1_PB_CD138neg_GEX_5; IP2085PB_1_PB_CD138neg_GEX_5; CP1133PB_1_PB_CD138neg_GEX_5
B99_1_1_GEX_5,3,pM1717_1_PB_CD138neg_GEX_5; pM10182PB_1_PB_CD138neg_GEX_5; pM7771PB_1_PB_CD138neg_GEX_5
pM10113PB_1_1_1_PB_CD138neg_GEX_5,1,pM10113PB_1_PB_CD138neg_GEX_5
```

**Note**: Additional columns (like `Demux_Sample_IDs` in the example) are allowed and will be ignored. Only `sample_id` and `sample_count` are used by the pipeline.

## Output Files

SoupOrCell creates a subdirectory `souporcell/` within each sample's output directory:

```
results/
└── sample1/
    ├── outs/
    │   └── (CellRanger outputs)
    └── souporcell/
        └── sample1/
            ├── clusters.tsv
            ├── cluster_genotypes.vcf
            └── ambient_rna.txt
```

### Output File Descriptions

#### clusters.tsv

Tab-separated file with cell barcode assignments:

| Column | Description |
|--------|-------------|
| barcode | Cell barcode |
| status | singlet/doublet/unassigned |
| assignment | Cluster assignment (0, 1, 2, ...) |
| log_prob_singleton | Log probability of being a singlet |
| log_prob_doublet | Log probability of being a doublet |

Example:
```
barcode	status	assignment	log_prob_singleton	log_prob_doublet
AAACCTGAGAAACCAT-1	singlet	0	-0.01	-5.34
AAACCTGAGACAGACC-1	singlet	1	-0.02	-6.12
AAACCTGCATAGTCAG-1	doublet	0,1	-4.23	-0.05
```

#### cluster_genotypes.vcf

VCF file containing the called genotypes for each cluster at informative SNPs.

#### ambient_rna.txt

Profile of ambient RNA contamination detected in the sample.

## Resource Requirements

SoupOrCell is configured with the following default resources (see `conf/modules.config`):

- **CPUs**: 8
- **Memory**: 32 GB
- **Time**: 12 hours

These can be adjusted in `conf/modules.config` if needed.

## Example: Pooled 2-Donor Experiment

```bash
# Run pipeline with 2 pooled donors (same for all samples)
nextflow run main.nf \
    -profile gcp \
    --data_type GEX \
    --samplesheet pooled_samples.csv \
    --reference gs://bucket/refdata-gex-GRCh38-2024-A \
    --run_souporcell true \
    --souporcell_fasta gs://bucket/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
    --souporcell_clusters 2 \
    --outdir gs://bucket/results
```

## Example: Variable Pooling Per Sample

```bash
# Run pipeline with different number of donors per sample
nextflow run main.nf \
    -profile gcp \
    --data_type GEX \
    --samplesheet pooled_samples.csv \
    --reference gs://bucket/refdata-gex-GRCh38-2024-A \
    --run_souporcell true \
    --souporcell_fasta gs://bucket/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
    --souporcell_clusters_file gs://bucket/pool_analysis_summary.csv \
    --outdir gs://bucket/results
```

## Downstream Analysis

After SoupOrCell completes, you can:

1. **Filter doublets**: Remove cells marked as "doublet" in `clusters.tsv`
2. **Demultiplex samples**: Split your data by cluster assignment
3. **Compare genotypes**: Use the VCF file to validate expected donor genotypes

Example R code for filtering:

```r
library(Seurat)
library(tidyverse)

# Read CellRanger output
seurat_obj <- Read10X("results/sample1/outs/filtered_feature_bc_matrix")

# Read SoupOrCell clusters
clusters <- read_tsv("results/sample1/souporcell/sample1/clusters.tsv")

# Filter singlets only
singlets <- clusters %>% filter(status == "singlet")
seurat_obj <- seurat_obj[, singlets$barcode]

# Add donor assignment as metadata
seurat_obj$donor <- clusters$assignment[match(colnames(seurat_obj), clusters$barcode)]
```

## Troubleshooting

### Common Issues

**Issue**: SoupOrCell fails with memory error
- **Solution**: Increase memory allocation in `conf/modules.config`

**Issue**: Too many unassigned cells
- **Solution**: Try adjusting the number of clusters or check your reference FASTA matches your data

**Issue**: All cells assigned to one cluster
- **Solution**: Your sample may not actually be pooled, or there may be insufficient genetic variation

## References

- SoupOrCell paper: [Heaton et al., Nature Methods 2020](https://www.nature.com/articles/s41592-020-0820-z)
- SoupOrCell GitHub: https://github.com/wheaton5/souporcell
- 10X Genomics sample pooling: https://www.10xgenomics.com/support/single-cell-gene-expression/documentation/steps/library-prep/chromium-single-cell-gene-expression-reagent-kits-user-guide-v-3-1-chemistry
