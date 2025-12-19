process CELLRANGER_COUNT {
    tag "$sample_id"
    label 'process_high'

    publishDir "${params.outdir}/${sample_id}", mode: params.publish_dir_mode

    input:
    tuple val(sample_id), path(fastq_dir)
    path reference

    output:
    tuple val(sample_id), path("${sample_id}/outs/**"), emit: matrix
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory ? "--localmem=${task.memory.toGiga()}" : ''

    """
    cellranger count \\
        --id=${sample_id} \\
        --transcriptome=${reference} \\
        --fastqs=${fastq_dir} \\
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
