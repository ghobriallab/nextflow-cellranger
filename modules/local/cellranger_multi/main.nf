process CELLRANGER_MULTI {
    tag "$sample_id"
    label 'process_high'

    publishDir "${params.outdir}/${sample_id}", mode: params.publish_dir_mode

    input:
    tuple val(sample_id), path(multi_config), path(fastq_dir)
    path reference
    path probe_set

    output:
    path "flex_S1/outs/**", emit: cellranger_results
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory ? "--localmem=${task.memory.toGiga()}" : ''

    """
    # Resolve absolute paths for reference and probe-set
    REF_PATH=\$(readlink -f ${reference})
    PROBE_PATH=\$(readlink -f ${probe_set})
    FASTQ_PATH=\$(readlink -f ${fastq_dir})
    
    # Update the multi config with the correct reference and probe-set paths
    sed "s|REFERENCE_PATH|\${REF_PATH}|g; s|PROBE_SET_PATH|\${PROBE_PATH}|g" ${multi_config} > config.csv
    sed "s|FASTQ_PATH|\${FASTQ_PATH}|g" config.csv > config_updated.csv
    mv config_updated.csv config.csv
    cat config.csv
    ls -lh *
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
