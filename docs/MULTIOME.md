# Multiome (ATAC + Gene Expression) Support

This pipeline supports 10x Genomics Chromium Single Cell Multiome ATAC + Gene Expression data using **Cell Ranger ARC** (`cellranger-arc`), a separate tool/binary from standard Cell Ranger used for GEX, VDJ, and FLEX.

## Overview

Cell Ranger ARC jointly processes paired ATAC and Gene Expression libraries from the same cells and performs:
- Barcode processing and alignment for both assays
- Peak calling (ATAC) and gene quantification (GEX)
- Joint cell calling across both modalities
- Combined `filtered_feature_bc_matrix` (genes + peaks)

**Important**: Cell Ranger ARC is a different binary with its own reference format and its own Docker container (`cellranger_arc_container`, default `cellranger-arc:2.2.0`). It is **not** compatible with standard `cellranger` references built via `CELLRANGER_MKREF`, and does not share a container with `CELLRANGER_COUNT`/`CELLRANGER_VDJ`/`CELLRANGER_MULTI`.

## Required Files

### ARC Reference

Download a pre-built `cellranger-arc`-compatible reference from [10X Genomics](https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads), e.g.:

- `refdata-cellranger-arc-GRCh38-2024-A` (Human)
- `refdata-cellranger-arc-mm10-2024-A` (Mouse)

This pipeline currently only supports pointing at a pre-built ARC reference via `--arc_reference`; building a custom ARC reference on the fly (`cellranger-arc mkref`) is not yet implemented.

### FASTQ Layout

Each sample needs **two separate FASTQ sets** — one for the Gene Expression library, one for the Chromatin Accessibility (ATAC) library. These are typically delivered as separate folders per technology, with the sample ID embedded in the filenames.

Note ATAC FASTQs use a 3-read-plus-index naming convention (`R1`/`R2`/`R3`, where `R2` is the 16bp barcode read), different from the standard GEX `R1`/`R2` pair.

## Usage

```bash
nextflow run main.nf \
    -profile local \
    --data_type MULTIOME \
    --samplesheet samplesheet_multiome.csv \
    --arc_reference /path/to/refdata-cellranger-arc-GRCh38-2024-A \
    --outdir results
```

## Samplesheet Format

**Example: [samplesheet_multiome.csv](../samplesheet_multiome.csv)**

```csv
sample_id,gex_fastq_file,atac_fastq_file
sample1,/path/to/fastqs/sample1_gex/*_R{1,2}_*.fastq.gz,/path/to/fastqs/sample1_atac/*_R{1,2,3}_*.fastq.gz
sample2,/path/to/fastqs/sample2_gex/*_R{1,2}_*.fastq.gz,/path/to/fastqs/sample2_atac/*_R{1,2,3}_*.fastq.gz
```

Each row provides one sample with two independent glob patterns, one per technology. The pipeline:
1. Resolves each glob and reorganizes/renames matched FASTQs into Cell Ranger's expected naming convention (reusing the same `PREP_FASTQS` logic used for GEX/VDJ, run once per technology).
2. Generates a `libraries.csv` for `cellranger-arc count` with rows:
   ```csv
   fastqs,sample,library_type
   /abs/path/to/sample1_gex_fastqs,sample1,Gene Expression
   /abs/path/to/sample1_atac_fastqs,sample1,Chromatin Accessibility
   ```
3. Runs `cellranger-arc count --id=<sample_id> --reference=<arc_reference> --libraries=libraries.csv`.

## Output Files

```
results/
└── sample1/
    ├── filtered_feature_bc_matrix/      # Combined gene + peak matrix
    ├── raw_feature_bc_matrix/
    ├── filtered_feature_bc_matrix.h5
    ├── raw_feature_bc_matrix.h5
    ├── atac_fragments.tsv.gz            # Per-fragment ATAC records (+ .tbi index)
    ├── atac_peaks.bed
    ├── atac_peak_annotation.tsv
    ├── atac_cut_sites.bigwig
    ├── atac_possorted_bam.bam           # (omitted if --create_bam=false)
    ├── gex_possorted_bam.bam            # (omitted if --create_bam=false)
    ├── gex_molecule_info.h5
    ├── per_barcode_metrics.csv          # Per-barcode QC metrics
    ├── summary.csv
    ├── web_summary.html
    ├── cloupe.cloupe
    └── analysis/                        # Clustering, dimensionality reduction, TF motifs, feature linkage
```

## Testing

Real (non-stub) Multiome test fixtures were validated by running `cellranger-arc testrun --id=tiny` inside the built container, which extracts to bundled tiny real FASTQs and a matching arc-compatible reference at `/opt/cellranger-arc-<version>/external/arc_testrun_files/` inside the image (no separate download needed — it ships with the licensed binary). These were copied out and uploaded to:

- `gs://ghobrial-pipelines/test-data/multiome_tiny/fastqs/`
- `gs://ghobrial-pipelines/references/refdata-cellranger-arc-tiny-2.2.0/`

Confirmed working end-to-end on GCP Batch (`-profile gcp,test`) with `CELLRANGER_ARC_COUNT` resources bumped to 8 cpus / 16GB in the `test` profile (conf set in [nextflow.config](../nextflow.config)) — enough for real (non-stub) execution on tiny data without full production-scale (16 cpus / 92GB) resources.

**Note**: `cellranger-arc count` in 2.2.0 requires `--create-bam=true|false` as a mandatory flag (unlike standard `cellranger count`, where it's optional) — this is wired to the existing `params.create_bam` setting in [modules/local/cellranger_arc_count/main.nf](../modules/local/cellranger_arc_count/main.nf).

## Additional Resources

- [Cell Ranger ARC count](https://www.10xgenomics.com/support/software/cell-ranger-arc/latest/analysis/running-pipelines/cr-arc-count)
- [Specifying Input FASTQ Files for cellranger-arc count](https://www.10xgenomics.com/support/software/cell-ranger-arc/latest/analysis/inputs/specifying-input-fastq-count)
- [Cell Ranger ARC references](https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads)
