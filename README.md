# Single Cell RNA-seq Pipeline - 10X Genomics

A Nextflow pipeline for processing 10X Genomics single-cell RNA-seq data using Cell Ranger.

## Features

- **GEX (Gene Expression) data**: Process standard 10X single-cell gene expression data using `cellranger count`
- **VDJ (Immune Profiling) data**: Process V(D)J immune receptor sequencing data using `cellranger vdj`
- **FLEX data**: Process multiplexed Fixed RNA Profiling data using `cellranger multi`
- **Multiome (ATAC + GEX) data**: Process joint single-cell ATAC + Gene Expression data using `cellranger-arc count` (separate tool/container from standard Cell Ranger)
- **SoupOrCell integration**: Optional demultiplexing and doublet detection for pooled samples
- **Docker containers**: All processes run in containers for reproducibility
- **Cloud-ready**: Configured for Google Cloud Platform with local testing profile
- **Flexible configuration**: Easy parameter customization via config files

## Pipeline Overview

```
Input FASTQ files
    |
    |-- GEX data --> cellranger count --> Filtered matrix + metrics
    |                      |
    |                      |--> [Optional] SoupOrCell --> Demultiplexing results
    |
    |-- VDJ data --> cellranger vdj --> V(D)J contig annotations + clonotypes
    |
    |-- FLEX data --> cellranger multi --> Per-sample matrices + multiplexing analysis
    |
    |-- MULTIOME data --> cellranger-arc count --> Joint ATAC + GEX matrix + peaks + clustering
```

## Quick Start

### Prerequisites

- Nextflow (>=23.04.0)
- Docker
- Cell Ranger reference genome (download from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads))
- VDJ reference (required for VDJ data only, download from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads))
- Probe set CSV file (required for FLEX data only, download from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads))
- Cell Ranger ARC reference (required for MULTIOME data only, download from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads) — not compatible with the standard Cell Ranger GEX reference above)

### Installation

```bash
git clone <repository>
cd nextflow-cellranger
```

### Running the Pipeline

#### For GEX (Gene Expression) data:

```bash
nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet samplesheet_gex.csv \
    --reference /path/to/refdata-gex-GRCh38-2024-A \
    --outdir results
```

#### With SoupOrCell demultiplexing (for pooled samples):

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

Note: SoupOrCell requires a reference genome FASTA file and the number of expected clusters/genotypes.

#### For GEX and VDJ (Gene Expression + Immune Profiling) data:

```bash
nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet samplesheet_gex_vdj.csv \
    --reference /path/to/refdata-gex-GRCh38-2024-A \
    --vdj_reference /path/to/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
    --outdir results
```

**Note**: For VDJ data, sample IDs in the samplesheet must contain 'VDJ' (e.g., `sample1_VDJ`, `donor1_VDJ_T`). GEX samples should contain 'GEX' (e.g., `sample1_GEX`, `donor1_GEX`). The pipeline will automatically route samples to the appropriate processing pipeline based on the sample ID.

#### For FLEX (Multiplexed) data:

```bash
nextflow run main.nf \
    -profile local \
    --data_type FLEX \
    --samplesheet samplesheet_flex.csv \
    --reference /path/to/refdata-gex-GRCh38-2024-A \
    --probe_set /path/to/Probe_Set_v1.0_GRCh38-2020-A.csv \
    --outdir results
```

**Note**: FLEX data requires a probe set CSV file specific to your gene panel. Download from [10X Genomics Probe Sets](https://www.10xgenomics.com/support/software/cell-ranger/downloads).

#### For MULTIOME (ATAC + Gene Expression) data:

```bash
nextflow run main.nf \
    -profile local \
    --data_type MULTIOME \
    --samplesheet samplesheet_multiome.csv \
    --arc_reference /path/to/refdata-cellranger-arc-GRCh38-2024-A \
    --outdir results
```

**Note**: Multiome data is processed with `cellranger-arc count`, a separate tool/container from standard Cell Ranger, requiring its own pre-built reference (`--arc_reference`, not compatible with `--reference`). See [docs/MULTIOME.md](docs/MULTIOME.md) for details.

## Input Files

### Samplesheet Format

#### GEX Samplesheet ([samplesheet_gex.csv](samplesheet_gex.csv))

```csv
sample_id,fastq_file
sample1,/path/to/fastqs/sample1/*_R{1,2}_*.fastq.gz
sample2,/path/to/fastqs/sample2/*_R{1,2}_*.fastq.gz
```

The `fastq_file` column should contain a glob pattern matching your FASTQ files. The pipeline will automatically organize them into a proper directory structure for Cell Ranger.

#### GEX + VDJ Samplesheet

For samples with both GEX and VDJ data, use sample IDs containing 'GEX' or 'VDJ' to route them correctly:

```csv
sample_id,fastq_file
donor1_GEX,/path/to/fastqs/donor1_gex/*_R{1,2}_*.fastq.gz
donor1_VDJ,/path/to/fastqs/donor1_vdj/*_R{1,2}_*.fastq.gz
donor2_GEX,/path/to/fastqs/donor2_gex/*_R{1,2}_*.fastq.gz
donor2_VDJ_T,/path/to/fastqs/donor2_vdj_t/*_R{1,2}_*.fastq.gz
```

**Important**: 
- Sample IDs containing 'GEX' (case-insensitive) will be processed with `cellranger count`
- Sample IDs containing 'VDJ' (case-insensitive) will be processed with `cellranger vdj`
- VDJ processing requires `--vdj_reference` parameter

#### FLEX Samplesheet ([samplesheet_flex.csv](samplesheet_flex.csv))

```csv
sample_id,multi_config,fastqs
run1,/path/to/multi_config_run1.csv,/path/to/fastqs/run1
run2,/path/to/multi_config_run2.csv,/path/to/fastqs/run2
```

#### FLEX Multi Config Format ([flex_multi_config_example.csv](flex_multi_config_example.csv))

See the Cell Ranger documentation for the multi config CSV format. Example:

```csv
[gene-expression]
reference,REFERENCE_PATH
probe-set,PROBE_SET_PATH
create-bam,false

[libraries]
fastq_id,fastqs,feature_types
flex_gex,/path/to/fastqs,Gene Expression

[samples]
sample_id,probe_barcode_ids,description
sample1,BC001|BC002,Control
sample2,BC003|BC004,Treated
```

Note: `REFERENCE_PATH` and `PROBE_SET_PATH` in the multi config will be automatically replaced with the actual reference and probe set paths.

#### MULTIOME Samplesheet ([samplesheet_multiome.csv](samplesheet_multiome.csv))

```csv
sample_id,gex_fastq_file,atac_fastq_file
sample1,/path/to/fastqs/sample1_gex/*_R{1,2}_*.fastq.gz,/path/to/fastqs/sample1_atac/*_R{1,2,3}_*.fastq.gz
sample2,/path/to/fastqs/sample2_gex/*_R{1,2}_*.fastq.gz,/path/to/fastqs/sample2_atac/*_R{1,2,3}_*.fastq.gz
```

Each row provides one sample with two independent glob patterns — one for the Gene Expression FASTQs, one for the Chromatin Accessibility (ATAC) FASTQs. Note ATAC FASTQs use `R1`/`R2`/`R3` (R2 is the 16bp barcode read), different from the standard GEX `R1`/`R2` pair. See [docs/MULTIOME.md](docs/MULTIOME.md) for details on how these are processed.

## Output Structure

```
results/
├── sample1/
│   └── outs/
│       ├── filtered_feature_bc_matrix/
│       │   ├── barcodes.tsv.gz
│       │   ├── features.tsv.gz
│       │   └── matrix.mtx.gz
│       ├── metrics_summary.csv
│       ├── web_summary.html
│       └── cloupe.cloupe
│   └── souporcell/              # (if --run_souporcell true)
│       └── sample1/
│           ├── clusters.tsv     # Cell cluster assignments
│           ├── cluster_genotypes.vcf  # Cluster genotypes
│           └── ambient_rna.txt  # Ambient RNA profile
├── sample2/
│   └── ...
└── pipeline_info/
    ├── execution_timeline.html
    ├── execution_report.html
    ├── execution_trace.txt
    └── pipeline_dag.html
```

## Configuration

### Docker Container

The pipeline uses a custom Cell Ranger Docker container. To build and use your own:

1. **Build the container**: See [docker/README.md](docker/README.md) for detailed instructions
2. **Update the container path** in your config or command line:

```bash
# In a custom config file
params {
    cellranger_container = 'gcr.io/your-project/cellranger:10.0.0'
}

# Or via command line
nextflow run main.nf --cellranger_container gcr.io/your-project/cellranger:10.0.0 ...
```

### Profiles

- `local`: Local execution with Docker (for testing)
- `gcp`: Google Cloud Platform execution with Google Batch
- `test`: Minimal resources for testing

### Parameters

Key parameters can be set in [nextflow.config](nextflow.config) or via command line:

```bash
--data_type         # 'GEX', 'FLEX', or 'MULTIOME'
--samplesheet       # Path to samplesheet CSV
--reference         # Path to Cell Ranger GEX reference
--vdj_reference     # Path to Cell Ranger VDJ reference (REQUIRED for VDJ samples)
--probe_set         # Path to probe set CSV (REQUIRED for FLEX only)
--arc_reference     # Path to Cell Ranger ARC reference (REQUIRED for MULTIOME only)
--outdir            # Output directory (default: ./results)
--expected_cells    # Expected number of cells (optional)
--force_cells       # Force cell number (optional)
--include_introns   # Include intronic reads (default: false)
--run_souporcell    # Enable SoupOrCell demultiplexing (default: false)
--souporcell_fasta  # Reference genome FASTA for SoupOrCell
--souporcell_clusters # Number of genotypes/clusters (default: 2)
```

### Module Configuration

Module-specific parameters are defined in [conf/modules.config](conf/modules.config). You can customize:
- Resource allocation (CPU, memory, time)
- Cell Ranger arguments
- Publishing options

## Additional Documentation

- **[VDJ (Immune Profiling)](docs/VDJ.md)**: Detailed guide for V(D)J immune receptor sequencing
- **[Multiome (ATAC + GEX)](docs/MULTIOME.md)**: Detailed guide for Multiome processing with `cellranger-arc`
- **[SoupOrCell](docs/SOUPORCELL.md)**: Guide for demultiplexing pooled samples

## Running on Google Cloud

1. Set up your Google Cloud project and credentials
2. Update the GCP project in your params file or command line:

```bash
# For GEX data
nextflow run main.nf \
    -profile gcp \
    --data_type GEX \
    --samplesheet samplesheet_gex.csv \
    --reference gs://bucket/refdata-gex-GRCh38-2024-A \
    --outdir gs://bucket/results \
    -c my_gcp_config.config

# For FLEX data
nextflow run main.nf \
    -profile gcp \
    --data_type FLEX \
    --samplesheet samplesheet_flex.csv \
    --reference gs://bucket/refdata-gex-GRCh38-2024-A \
    --probe_set gs://bucket/Probe_Set_v1.0_GRCh38-2020-A.csv \
    --outdir gs://bucket/results \
    -c my_gcp_config.config

# For MULTIOME data
nextflow run main.nf \
    -profile gcp \
    --data_type MULTIOME \
    --samplesheet samplesheet_multiome.csv \
    --arc_reference gs://bucket/refdata-cellranger-arc-GRCh38-2024-A \
    --outdir gs://bucket/results \
    -c my_gcp_config.config
```

Example GCP config (`my_gcp_config.config`):

```groovy
google {
    project = 'my-gcp-project'
    region = 'us-central1'
}
```

## Output Files

### GEX Data Output

- `filtered_feature_bc_matrix/`: Filtered gene-barcode matrix in MEX format
- `metrics_summary.csv`: Summary metrics from Cell Ranger
- `web_summary.html`: Interactive HTML report
- `cloupe.cloupe`: Loupe Browser file (optional)

### FLEX Data Output

- `per_sample_outs/`: Per-sample output directories containing matrices and metrics
- `multi/multiplexing_analysis/`: Multiplexing analysis results

### MULTIOME Data Output

- `filtered_feature_bc_matrix/` / `raw_feature_bc_matrix/`: Combined gene + peak feature-barcode matrix
- `atac_fragments.tsv.gz` (+ `.tbi` index): Per-fragment ATAC records
- `atac_peaks.bed`, `atac_peak_annotation.tsv`: Called ATAC peaks and annotations
- `atac_possorted_bam.bam` / `gex_possorted_bam.bam`: Per-assay alignments (omitted if `--create_bam=false`)
- `per_barcode_metrics.csv`, `summary.csv`, `web_summary.html`: QC metrics and report
- `analysis/`: Clustering, dimensionality reduction, TF motif analysis, feature linkage

See [docs/MULTIOME.md](docs/MULTIOME.md) for full details.

### SoupOrCell Output (when enabled)

When `--run_souporcell true` is set, the following files are generated in `<sample_id>/souporcell/`:

- `clusters.tsv`: Cell barcode to cluster assignments with doublet detection
- `cluster_genotypes.vcf`: Called genotypes for each cluster
- `ambient_rna.txt`: Ambient RNA contamination profile

## Test Data

Place test data in the [test_data](test_data) directory. You can download small test datasets from 10X Genomics:
- [1k PBMCs from a Healthy Donor (v3 chemistry)](https://www.10xgenomics.com/datasets/1-k-pbm-cs-from-a-healthy-donor-v-3-chemistry-3-standard-3-0-0)

## Development

### Setting Up Documentation for AI-Assisted Development

To enable AI agents (like Claude) to access Nextflow and nf-core documentation for better code assistance, download the documentation repositories to the parent folder:

```bash
cd ..  # Navigate to parent folder (Ghobrial/)

# Download Nextflow documentation (shallow clone for faster download)
git clone --depth 1 https://github.com/nextflow-io/nextflow.git nextflow-master

# Download nf-core website/documentation (shallow clone for faster download)
git clone --depth 1 https://github.com/nf-core/website.git website-main

cd nextflow-cellranger  # Return to project directory
```

**Note**: Using `--depth 1` creates a shallow clone with only the latest commit, significantly reducing download size and time. The documentation files will be available in:
- `nextflow-master/docs/` - Nextflow documentation (markdown files)
- `website-main/markdown/` - nf-core documentation and best practices

These documentation folders are referenced in [Claude.md](Claude.md) and allow AI agents to:
- Reference official Nextflow syntax and best practices
- Follow nf-core module patterns and conventions
- Use up-to-date DSL2 syntax
- Implement proper error handling and resource management

The folders are excluded from git tracking via [.gitignore](.gitignore).

### Directory Structure After Setup

```
Ghobrial/
├── nextflow-cellranger/          # This pipeline
│   ├── main.nf
│   ├── modules/
│   ├── conf/
│   └── Claude.md
├── nextflow-master/            # Nextflow documentation
│   └── docs/
└── website-main/               # nf-core documentation
    └── markdown/
```

### Development Workflow

1. Ensure documentation is available in parent folder
2. Claude will use markdown files from these folders when generating code
3. Follow the patterns and best practices from the documentation
4. Reference [Claude.md](Claude.md) for project-specific guidelines

## Troubleshooting

### Common Issues

1. **Out of memory errors**: Increase `--max_memory` or adjust resources in [conf/modules.config](conf/modules.config)
2. **Cell Ranger version**: Ensure Docker image version matches your data requirements
3. **Reference not found**: Verify reference path is accessible and correctly formatted

## Citation

If you use this pipeline, please cite:
- Nextflow: https://www.nextflow.io/
- Cell Ranger: 10X Genomics Cell Ranger Software

## License

[Add your license here]

## Contact

[Add contact information]
