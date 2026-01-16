process SOUPORCELL {
    tag "$sample_id"
    label 'process_medium'
    stageOutMode = 'copy'
    publishDir "${params.outdir}/${sample_id}/souporcell", mode: params.publish_dir_mode

    container 'community.wave.seqera.io/library/souporcell_gxx:f648658dde2cdd53'

    input:
    tuple val(sample_id), path(bam), path(barcodes), val(clusters)
    path fasta

    output:
    tuple val(sample_id), path("**/clusters.tsv")         , emit: clusters
    tuple val(sample_id), path("**/cluster_genotypes.vcf"), emit: vcf
    tuple val(sample_id), path("**/ambient_rna.txt")      , emit: ambient_rna
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${sample_id}"
    def VERSION = '2.5' // WARN: Version information not provided by tool on CLI

    """
    mkdir -p temp
    export TMPDIR=./temp

    souporcell_pipeline.py \\
        -i $bam \\
        -b $barcodes \\
        -f $fasta \\
        -t $task.cpus \\
        -o $prefix \\
        -k $clusters \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        souporcell: $VERSION
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${sample_id}"
    def VERSION = '2.5'
    
    """
    mkdir -p ${prefix}
    touch ${prefix}/clusters.tsv
    touch ${prefix}/cluster_genotypes.vcf
    touch ${prefix}/ambient_rna.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        souporcell: $VERSION
    END_VERSIONS
    """
}
