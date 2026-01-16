process CELLRANGER_VDJ {
    tag "$sample_id"
    stageOutMode 'copy'
    publishDir "${params.outdir}/${sample_id}", mode: params.publish_dir_mode

    input:
    tuple val(sample_id), path(fastq_dir)
    path reference

    output:
    tuple val(sample_id), path("${sample_id}/outs"), emit: vdj_results
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory ? "--localmem=${task.memory.toGiga()}" : ''

    """
    # Resolve absolute paths for reference and fastqs
    REF_PATH=\$(readlink -f ${reference})
    FASTQ_PATH=\$(readlink -f ${fastq_dir})
    
    cellranger vdj \\
        --id=${sample_id} \\
        --reference=\${REF_PATH} \\
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
    mkdir -p ${sample_id}/outs/filtered_contig_annotations
    touch ${sample_id}/outs/metrics_summary.csv
    touch ${sample_id}/outs/web_summary.html
    touch ${sample_id}/outs/filtered_contig_annotations.csv
    touch ${sample_id}/outs/clonotypes.csv
    touch versions.yml
    """
}
