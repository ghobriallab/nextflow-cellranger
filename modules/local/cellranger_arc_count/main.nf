process CELLRANGER_ARC_COUNT {
    tag "$sample_id"
    publishDir "${params.outdir}", mode: params.publish_dir_mode, saveAs: { filename ->
        filename.replaceFirst(/^([^\/]+)\/outs\//, '$1/')
    }

    input:
    tuple val(sample_id), path(gex_fastq_dir), path(atac_fastq_dir)
    path reference

    output:
    tuple val(sample_id), path("${sample_id}/outs/**"), emit: matrix
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory ? "--localmem=${task.memory.toGiga()}" : ''
    """
    # Resolve absolute paths for reference and fastqs
    REF_PATH=\$(readlink -f ${reference})
    GEX_FASTQ_PATH=\$(readlink -f ${gex_fastq_dir})
    ATAC_FASTQ_PATH=\$(readlink -f ${atac_fastq_dir})

    cat <<-END_LIBRARIES > libraries.csv
    fastqs,sample,library_type
    \${GEX_FASTQ_PATH},${sample_id},Gene Expression
    \${ATAC_FASTQ_PATH},${sample_id},Chromatin Accessibility
    END_LIBRARIES

    cellranger-arc count \\
        --id=${sample_id} \\
        --reference=\${REF_PATH} \\
        --libraries=libraries.csv \\
        --create-bam=${params.create_bam ? 'true' : 'false'} \\
        --localcores=${task.cpus} \\
        ${memory} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellranger-arc: \$(cellranger-arc --version 2>&1 | sed 's/cellranger-arc //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${sample_id}/outs/filtered_feature_bc_matrix
    touch ${sample_id}/outs/metrics_summary.csv
    touch ${sample_id}/outs/web_summary.html
    touch ${sample_id}/outs/atac_fragments.tsv.gz
    touch ${sample_id}/outs/per_barcode_metrics.csv
    touch versions.yml
    """
}
