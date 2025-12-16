# Test Data Directory

Place test FASTQ files and reference data here for pipeline testing.

## Recommended Test Datasets

Download small test datasets from 10X Genomics:

### GEX Data
- [1k PBMCs from a Healthy Donor (v3 chemistry)](https://www.10xgenomics.com/datasets/1-k-pbm-cs-from-a-healthy-donor-v-3-chemistry-3-standard-3-0-0)
  - Small dataset suitable for testing
  - Download FASTQ files and place in `test_data/fastqs/pbmc1k/`

### FLEX Data
- [Flex 5K PBMCs](https://www.10xgenomics.com/datasets/5k-pbmcs-from-a-healthy-donor-gene-expression-and-cell-multiplexing)
  - Multiplexed dataset for testing FLEX pipeline
  - Download FASTQ files and place in `test_data/fastqs/flex_pbmc5k/`

### Reference Genome

Download Cell Ranger reference from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads):
- Human (GRCh38): `refdata-gex-GRCh38-2024-A`
- Mouse (mm10): `refdata-gex-mm10-2024-A`

Extract and place in `test_data/reference/`

## Directory Structure

```
test_data/
├── fastqs/
│   ├── pbmc1k/
│   │   ├── pbmc1k_S1_L001_R1_001.fastq.gz
│   │   └── pbmc1k_S1_L001_R2_001.fastq.gz
│   └── flex_pbmc5k/
│       ├── sample_S1_L001_R1_001.fastq.gz
│       └── sample_S1_L001_R2_001.fastq.gz
└── reference/
    └── refdata-gex-GRCh38-2024-A/
        ├── fasta/
        ├── genes/
        └── ...
```

## Running Tests

Once test data is in place, run:

```bash
# Test GEX pipeline
nextflow run main.nf \
    -profile test \
    --data_type GEX \
    --samplesheet test_samplesheet_gex.csv \
    --reference test_data/reference/refdata-gex-GRCh38-2024-A \
    --outdir test_results

# Test FLEX pipeline
nextflow run main.nf \
    -profile test \
    --data_type FLEX \
    --samplesheet test_samplesheet_flex.csv \
    --reference test_data/reference/refdata-gex-GRCh38-2024-A \
    --outdir test_results
```
