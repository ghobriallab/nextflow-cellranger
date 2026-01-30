process CELLRANGER_COUNT {
    tag "$sample_id"
    stageOutMode 'copy'
    publishDir "${params.outdir}/${sample_id}", mode: params.publish_dir_mode, saveAs: { filename ->
        // Strip the sample_id/outs/ prefix to publish contents directly
        filename.replaceFirst(/^[^\/]+\/outs\//, '')
    }

    input:
    tuple val(sample_id), path(fastq_dir)
    path reference

    output:
    tuple val(sample_id), path("${sample_id}/outs"), emit: matrix
    tuple val(sample_id), path("${sample_id}/outs/possorted_genome_bam.bam"), path("${sample_id}/outs/raw_feature_bc_matrix/barcodes.tsv.gz"), emit: souporcell_input
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory ? "--localmem=${task.memory.toGiga()}" : ''

    """
    # Resolve absolute paths for reference and fastqs
    REF_PATH=\$(readlink -f ${reference})
    FASTQ_PATH=\$(readlink -f ${fastq_dir})
    
    cellranger count \\
        --id=${sample_id} \\
        --transcriptome=\${REF_PATH} \\
        --fastqs=\${FASTQ_PATH} \\
        --sample=${sample_id} \\
        --localcores=${task.cpus} \\
        ${memory} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellranger: \$(cellranger --version 2>&1 | sed 's/cellranger //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${sample_id}/outs/filtered_feature_bc_matrix
    touch ${sample_id}/outs/metrics_summary.csv
    touch ${sample_id}/outs/web_summary.html
    touch versions.yml
    """
}
