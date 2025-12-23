# Single Cell RNA-seq Pipeline - 10X Genomics

A Nextflow pipeline for processing 10X Genomics single-cell RNA-seq data using Cell Ranger.

## Features

- **GEX (Gene Expression) data**: Process standard 10X single-cell gene expression data using `cellranger count`
- **FLEX data**: Process multiplexed Fixed RNA Profiling data using `cellranger multi`
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
    |-- FLEX data --> cellranger multi --> Per-sample matrices + multiplexing analysis
```

## Quick Start

### Prerequisites

- Nextflow (>=23.04.0)
- Docker
- Cell Ranger reference genome (download from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads))
- Probe set CSV file (required for FLEX data only, download from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads))

### Installation

```bash
git clone <repository>
cd nextflow-template
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

## Input Files

### Samplesheet Format

#### GEX Samplesheet ([samplesheet_gex.csv](samplesheet_gex.csv))

```csv
sample_id,fastq_dir
sample1,/path/to/fastqs/sample1
sample2,/path/to/fastqs/sample2
```

#### FLEX Samplesheet ([samplesheet_flex.csv](samplesheet_flex.csv))

```csv
sample_id,multi_config
run1,/path/to/multi_config_run1.csv
run2,/path/to/multi_config_run2.csv
```

#### FLEX Multi Config Format ([multi_config_example.csv](multi_config_example.csv))

See the Cell Ranger documentation for the multi config CSV format. Example:

```csv
[gene-expression]
reference,REFERENCE_PATH
create-bam,true

[libraries]
fastq_id,fastqs,lanes,physical_library_id,feature_types,subsample_rate
GEX_sample1,/path/to/fastqs,any,GEX1,Gene Expression,

[samples]
sample_id,cmo_ids,description
Sample1,CMO301,Patient 1
Sample2,CMO302,Patient 2
```

Note: `REFERENCE_PATH` in the multi config will be automatically replaced with the actual reference path.

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

Key parameters can be set in [conf/params.config](conf/params.config) or via command line:

```bash
--data_type         # 'GEX' or 'FLEX'
--samplesheet       # Path to samplesheet CSV
--reference         # Path to Cell Ranger reference
--probe_set         # Path to probe set CSV (REQUIRED for FLEX only)
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

cd nextflow-template  # Return to project directory
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
├── nextflow-template/          # This pipeline
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
