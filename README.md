# Single Cell RNA-seq Pipeline - 10X Genomics

A Nextflow pipeline for processing 10X Genomics single-cell RNA-seq data using Cell Ranger.

## Features

- **GEX (Gene Expression) data**: Process standard 10X single-cell gene expression data using `cellranger count`
- **FLEX data**: Process multiplexed Fixed RNA Profiling data using `cellranger multi`
- **Docker containers**: All processes run in containers for reproducibility
- **Cloud-ready**: Configured for Google Cloud Platform with local testing profile
- **Flexible configuration**: Easy parameter customization via config files

## Pipeline Overview

```
Input FASTQ files
    |
    |-- GEX data --> cellranger count --> Filtered matrix + metrics
    |
    |-- FLEX data --> cellranger multi --> Per-sample matrices + multiplexing analysis
```

## Quick Start

### Prerequisites

- Nextflow (>=23.04.0)
- Docker
- Cell Ranger reference genome (download from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads))

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

#### For FLEX (Multiplexed) data:

```bash
nextflow run main.nf \
    -profile local \
    --data_type FLEX \
    --samplesheet samplesheet_flex.csv \
    --reference /path/to/refdata-gex-GRCh38-2024-A \
    --outdir results
```

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
├── sample2/
│   └── ...
└── pipeline_info/
    ├── execution_timeline.html
    ├── execution_report.html
    ├── execution_trace.txt
    └── pipeline_dag.html
```

## Configuration

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
--outdir            # Output directory (default: ./results)
--expected_cells    # Expected number of cells (optional)
--force_cells       # Force cell number (optional)
--include_introns   # Include intronic reads (default: false)
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
nextflow run main.nf \
    -profile gcp \
    --data_type GEX \
    --samplesheet samplesheet_gex.csv \
    --reference gs://bucket/refdata-gex-GRCh38-2024-A \
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

## Test Data

Place test data in the [test_data](test_data) directory. You can download small test datasets from 10X Genomics:
- [1k PBMCs from a Healthy Donor (v3 chemistry)](https://www.10xgenomics.com/datasets/1-k-pbm-cs-from-a-healthy-donor-v-3-chemistry-3-standard-3-0-0)

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
