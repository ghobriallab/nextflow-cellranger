process CELLRANGER_MKREF {
    tag "mkref"
    label 'process_high'
    publishDir "${params.outdir}/reference", mode: params.publish_dir_mode

    input:
    path fasta
    path gtf

    output:
    path "${params.genome_name}", emit: reference
    path "versions.yml",         emit: versions

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory ? "--memgb=${task.memory.toGiga()}" : ''
    """
    cellranger mkref \\
        --genome=${params.genome_name} \\
        --fasta=${fasta} \\
        --genes=${gtf} \\
        --nthreads=${task.cpus} \\
        ${memory} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellranger: \$(cellranger --version 2>&1 | sed 's/cellranger //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${params.genome_name}
    touch ${params.genome_name}/genome.fa
    touch versions.yml
    """
}
