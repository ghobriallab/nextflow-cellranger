# VDJ (Immune Profiling) Support

This pipeline supports V(D)J immune receptor sequencing using Cell Ranger VDJ. VDJ sequencing allows you to profile T cell and B cell receptor repertoires from single cells.

## Overview

Cell Ranger VDJ takes FASTQ files from 10X Immune Profiling libraries and performs:
- V(D)J sequence assembly and annotation
- Clonotype calling
- Paired chain analysis (alpha-beta for TCR, heavy-light for BCR)
- CDR3 sequence identification

## Sample ID Convention

**Important**: The pipeline automatically detects VDJ samples based on the sample ID. Sample IDs must contain the string `VDJ` (case-insensitive) to be processed with `cellranger vdj`.

Examples of valid VDJ sample IDs:
- `donor1_VDJ`
- `sample_VDJ_T` (T cell receptor)
- `sample_VDJ_B` (B cell receptor)
- `PATIENT1_vdj_tcr`
- `my_VDJ_sample_01`

## Required Files

### VDJ Reference

Download the appropriate VDJ reference from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads):

**Human:**
- `refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0` (T cell and B cell)

**Mouse:**
- `refdata-cellranger-vdj-GRCm38-alts-ensembl-7.0.0` (T cell and B cell)

### GEX Reference (for paired GEX samples)

If you're processing both GEX and VDJ from the same samples, you'll also need a GEX reference:
- `refdata-gex-GRCh38-2024-A` (Human)
- `refdata-gex-mm10-2024-A` (Mouse)

## Usage

### Basic VDJ Processing

```bash
nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet samplesheet_vdj.csv \
    --vdj_reference /path/to/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
    --outdir results
```

### Paired GEX + VDJ Processing

For experiments with both gene expression and immune profiling:

```bash
nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet samplesheet_gex_vdj.csv \
    --reference /path/to/refdata-gex-GRCh38-2024-A \
    --vdj_reference /path/to/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
    --outdir results
```

## Samplesheet Format

Use the same format as GEX samples, but include 'VDJ' in the sample ID:

**Example: [samplesheet_gex_vdj.csv](samplesheet_gex_vdj.csv)**

```csv
sample_id,fastq_file
donor1_GEX,/path/to/fastqs/donor1_gex/*_R{1,2}_*.fastq.gz
donor1_VDJ_T,/path/to/fastqs/donor1_vdj_t/*_R{1,2}_*.fastq.gz
donor2_GEX,/path/to/fastqs/donor2_gex/*_R{1,2}_*.fastq.gz
donor2_VDJ_B,/path/to/fastqs/donor2_vdj_b/*_R{1,2}_*.fastq.gz
```

**Notes:**
- GEX samples will be processed with `cellranger count` using `--reference`
- VDJ samples will be processed with `cellranger vdj` using `--vdj_reference`
- Both can be in the same samplesheet

## Output Files

VDJ processing creates the following output structure:

```
results/
└── donor1_VDJ_T/
    └── outs/
        ├── filtered_contig_annotations.csv  # Assembled and filtered contig annotations
        ├── clonotypes.csv                   # Clonotype information
        ├── consensus_annotations.csv        # Consensus annotations
        ├── filtered_contig.fasta           # Assembled contig sequences
        ├── airr_rearrangement.tsv          # AIRR-compliant format
        ├── web_summary.html                 # QC metrics and visualization
        └── metrics_summary.csv              # Summary metrics
```

### Key Output Files

#### filtered_contig_annotations.csv

Contains annotations for each assembled V(D)J contig:
- `barcode`: Cell barcode
- `contig_id`: Contig identifier
- `chain`: Chain type (TRA, TRB for TCR; IGH, IGL, IGK for BCR)
- `v_gene`, `d_gene`, `j_gene`, `c_gene`: Gene assignments
- `cdr3`: CDR3 nucleotide sequence
- `cdr3_aa`: CDR3 amino acid sequence
- `productive`: Whether the contig is productive

#### clonotypes.csv

Clonotype definitions and frequencies:
- `clonotype_id`: Unique clonotype identifier
- `frequency`: Number of cells with this clonotype
- `proportion`: Fraction of cells with this clonotype
- `cdr3s_aa`: CDR3 amino acid sequences
- `cdr3s_nt`: CDR3 nucleotide sequences

#### web_summary.html

Interactive HTML report with:
- Sequencing and mapping metrics
- V(D)J gene usage
- Clonotype diversity
- Productive vs non-productive contigs
- Paired chain statistics

## Common Use Cases

### T Cell Receptor (TCR) Profiling

```bash
# Process TCR VDJ data
nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet tcr_samples.csv \
    --vdj_reference /path/to/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
    --outdir results_tcr
```

### B Cell Receptor (BCR) Profiling

```bash
# Process BCR VDJ data
nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet bcr_samples.csv \
    --vdj_reference /path/to/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
    --outdir results_bcr
```

### Combined GEX + TCR Analysis

```bash
# Process both gene expression and TCR data
nextflow run main.nf \
    -profile local \
    --data_type GEX \
    --samplesheet combined_gex_tcr.csv \
    --reference /path/to/refdata-gex-GRCh38-2024-A \
    --vdj_reference /path/to/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
    --outdir results_combined
```

## Integration with Downstream Analysis

VDJ output can be integrated with GEX data using tools like:
- **Seurat**: `Read10X_vdj()` function
- **Scanpy**: Import contig annotations
- **scRepertoire**: Specialized TCR/BCR analysis
- **immunarch**: Immune repertoire analysis

## Troubleshooting

### Low VDJ Cell Detection

If you see fewer VDJ cells than expected:
1. Check library concentration and quality
2. Verify correct VDJ reference (human vs mouse)
3. Check sequencing depth (aim for 5000 reads/cell)

### Unpaired Chains

High numbers of unpaired chains may indicate:
1. Low cell viability
2. Insufficient sequencing depth
3. Technical issues with library preparation

### Reference Mismatch

Ensure you're using:
- VDJ reference for VDJ samples (`--vdj_reference`)
- GEX reference for GEX samples (`--reference`)
- Matching species (human vs mouse)

## Additional Resources

- [Cell Ranger VDJ Documentation](https://www.10xgenomics.com/support/software/cell-ranger/latest/analysis/running-pipelines/cr-vdj)
- [Understanding VDJ Output](https://www.10xgenomics.com/support/software/cell-ranger/latest/analysis/outputs/cr-5p-outputs-vdj)
- [VDJ References](https://www.10xgenomics.com/support/software/cell-ranger/downloads)
