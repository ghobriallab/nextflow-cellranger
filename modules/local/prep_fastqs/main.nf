process PREP_FASTQS {
    tag "$sample_id"
    label 'process_low'

    input:
    tuple val(sample_id), path(fastq_files)
    val(dir_suffix)

    output:
    tuple val(sample_id), path("${sample_id}${dir_suffix}"), emit: fastq_dir

    script:
    // Rename FASTQs to sample-based filenames per lane/read
    """
    set -euo pipefail

    mkdir -p ${sample_id}${dir_suffix}

    # Rename each FASTQ file to include sample_id prefix
    for f in ${fastq_files}; do
        base=\$(basename "\${f}")
        # Extract suffix: _S[0-9]+_L[0-9]+_[RI][0-9]+_001.fastq.gz
        # (covers GEX R1/R2 and ATAC R1/R2/R3/I1 reads)
        suffix=\$(printf "%s" "\${base}" | sed -E 's/^.*(_S[0-9]+_L[0-9]+_[RI][0-9]+_001\\.fastq\\.gz)\$/\\1/')
        if [[ "\${suffix}" =~ ^_S[0-9]+_L[0-9]+_[RI][0-9]+_001\\.fastq\\.gz\$ ]]; then
            cp "\${f}" "${sample_id}${dir_suffix}/${sample_id}\${suffix}"
        else
            # If pattern doesn't match, copy as-is with sample prefix
            cp "\${f}" "${sample_id}${dir_suffix}/${sample_id}_\${base}"
        fi
    done
    """
}