process CELLRANGER_MULTI {
    tag "$sample_id"
    label 'process_high'

    container "nfcore/cellranger:8.0.1"

    publishDir "${params.outdir}/${sample_id}", mode: params.publish_dir_mode

    input:
    tuple val(sample_id), path(multi_config)
    path reference

    output:
    tuple val(sample_id), path("${sample_id}/outs/per_sample_outs/*/count/sample_filtered_feature_bc_matrix"), emit: matrices
    tuple val(sample_id), path("${sample_id}/outs/per_sample_outs/*/metrics_summary.csv"), emit: metrics
    tuple val(sample_id), path("${sample_id}/outs/per_sample_outs/*/web_summary.html"), emit: web_summary
    tuple val(sample_id), path("${sample_id}/outs/multi/multiplexing_analysis"), emit: multiplexing_analysis, optional: true
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory ? "--localmem=${task.memory.toGiga()}" : ''

    """
    # Update the multi config with the correct reference path
    sed 's|REFERENCE_PATH|${reference}|g' ${multi_config} > config.csv

    cellranger multi \\
        --id=${sample_id} \\
        --csv=config.csv \\
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
    mkdir -p ${sample_id}/outs/per_sample_outs/sample1/count/sample_filtered_feature_bc_matrix
    mkdir -p ${sample_id}/outs/multi/multiplexing_analysis
    touch ${sample_id}/outs/per_sample_outs/sample1/metrics_summary.csv
    touch ${sample_id}/outs/per_sample_outs/sample1/web_summary.html
    touch versions.yml
    """
}
