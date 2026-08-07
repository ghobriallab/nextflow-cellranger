#!/usr/bin/env nextflow

/*
========================================================================================
    Single Cell RNA-seq Pipeline - 10X Genomics
========================================================================================
    Pipeline for processing 10X single-cell RNA-seq data
    Supports:
    - GEX (Gene Expression) data using cellranger count
    - VDJ (Immune Profiling) data using cellranger vdj
    - FLEX (Fixed RNA Profiling) multiplexed data using cellranger multi
    
    Sample IDs containing 'GEX' will be processed with cellranger count
    Sample IDs containing 'VDJ' will be processed with cellranger vdj
========================================================================================
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { CELLRANGER_COUNT } from './modules/local/cellranger_count/main'
include { CELLRANGER_MKREF } from './modules/local/cellranger_mkref/main'
include { CELLRANGER_MULTI } from './modules/local/cellranger_multi/main'
include { CELLRANGER_VDJ } from './modules/local/cellranger_vdj/main'
include { SOUPORCELL } from './modules/local/souporcell/main'
include { PREP_FASTQS } from './modules/local/prep_fastqs/main'

/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {
    /*
    ========================================================================================
        PRINT PARAMETER SUMMARY
    ========================================================================================
    */

    log.info """
    ========================================
    Single Cell RNA-seq Pipeline
    ========================================
    Output Directory   : ${params.outdir}
    Sample Sheet       : ${params.samplesheet}
    Data Type          : ${params.data_type}
    ${params.data_type != 'SOUPORCELL' ? "Reference          : ${params.reference}" : ''}
    ${params.vdj_reference ? "VDJ Reference      : ${params.vdj_reference}" : ''}
    ${params.data_type == 'FLEX' ? "Probe Set          : ${params.probe_set}" : ''}
    ${params.chemistry ? "Chemistry          : ${params.chemistry}" : 'Chemistry          : auto-detect'}
    ${params.data_type == 'SOUPORCELL' || params.run_souporcell ? "SoupOrCell Fasta   : ${params.souporcell_fasta}" : ''}
    ${params.data_type == 'SOUPORCELL' ? "SoupOrCell Mode    : Standalone (BAM files provided)" : ''}
    ${params.run_souporcell && params.data_type != 'SOUPORCELL' ? "Run SoupOrCell     : true" : ''}
    ${params.run_souporcell && params.souporcell_clusters_file ? "SoupOrCell Clusters: per-sample (from ${params.souporcell_clusters_file})" : ''}
    ${params.run_souporcell && !params.souporcell_clusters_file && params.data_type != 'SOUPORCELL' ? "SoupOrCell Clusters: ${params.souporcell_clusters} (default for all samples)" : ''}
    ========================================
    """

    
    // Parse input samplesheet
    ch_samplesheet = channel.fromPath(params.samplesheet, checkIfExists: true)

    // Resolve reference: build with mkref if fasta+gtf provided, otherwise use pre-built reference
    if (params.data_type != 'SOUPORCELL') {
        if (params.fasta && params.gtf) {
            CELLRANGER_MKREF(
                file(params.fasta, checkIfExists: true),
                file(params.gtf,   checkIfExists: true)
            )
            ch_reference = CELLRANGER_MKREF.out.reference
        } else {
            ch_reference = channel.value(file(params.reference, checkIfExists: true))
        }
    }
    // Branch workflow based on data type
    if (params.data_type == 'SOUPORCELL') {

        // For SOUPORCELL: parse samplesheet with sample_id, bam_file, barcodes, clusters
        ch_souporcell_input = ch_samplesheet
            .splitCsv(header: true, sep: ',')
            .map { row ->
                def sample_id = row.sample_id
                def bam_file = file(row.bam_file)
                def barcodes = file(row.barcodes)
                def clusters = row.clusters.toInteger()
                return tuple(sample_id, bam_file, barcodes, clusters)
            }

        SOUPORCELL(
            ch_souporcell_input,
            file(params.souporcell_fasta)
        )

    } else if (params.data_type == 'GEX') {

        // For GEX data: optionally preprocess FASTQs from a flat list of globs
        ch_samplesheet_globs = ch_samplesheet
            .splitCsv(header: true, sep: ',')
            .map { row -> 
                def sample_id = row.sample_id
                def glob_pattern = row.fastq_file
                // Collect all files matching the glob pattern
                def matched_files = files(glob_pattern)
                return tuple(sample_id, matched_files)
            }
            .groupTuple()
            .map { sid, file_lists -> 
                // Flatten the list of file lists into a single list
                def all_files = file_lists.flatten()
                return tuple(sid, all_files)
            }

        ch_prepped_fastqs = PREP_FASTQS(ch_samplesheet_globs)

        ch_samples = ch_prepped_fastqs.map { sid, fqdir -> tuple(sid, fqdir) }

        // Branch samples into GEX and VDJ based on sample_id
        ch_samples
            .branch { item ->
                gex: item[0] =~ /(?i).*GEX.*/
                vdj: item[0] =~ /(?i).*VDJ.*/
            }
            .set { ch_branched }

        // Process GEX samples
        CELLRANGER_COUNT(
            ch_branched.gex,
            ch_reference
        )

        // Process VDJ samples (if VDJ reference is provided)
        if (params.vdj_reference) {
            ch_vdj = ch_branched.vdj
                .map { sample_id, fastq_dir ->
                    def chain = sample_id ==~ /(?i).*TCR.*/ ? 'TR'
                               : sample_id ==~ /(?i).*BCR.*/ ? 'IG'
                               : null
                    tuple(sample_id, fastq_dir, chain)
                }
            CELLRANGER_VDJ(
                ch_vdj,
                file(params.vdj_reference)
            )
        }

        // Run SoupOrCell if enabled (only for GEX samples)
        if (params.run_souporcell) {
            // Create a channel for cluster counts per sample
            if (params.souporcell_clusters_file) {
                // Parse the clusters file and create a map of sample_id to cluster count
                ch_clusters = channel.fromPath(params.souporcell_clusters_file, checkIfExists: true)
                    .splitCsv(header: true, sep: ',')
                    .map { row -> 
                        tuple(row.sample_id, row.sample_count.toInteger())
                    }
                
                // Join with the souporcell input channel
                ch_souporcell_with_clusters = CELLRANGER_COUNT.out.souporcell_input
                    .join(ch_clusters, by: 0)
                    .map { sample_id, bam, barcodes, clusters ->
                        tuple(sample_id, bam, barcodes, clusters)
                    }
            } else {
                // Use the default cluster count for all samples
                ch_souporcell_with_clusters = CELLRANGER_COUNT.out.souporcell_input
                    .map { sample_id, bam, barcodes ->
                        tuple(sample_id, bam, barcodes, params.souporcell_clusters)
                    }
            }
            
            SOUPORCELL(
                ch_souporcell_with_clusters,
                file(params.souporcell_fasta)
            )
        }

    } else if (params.data_type == 'FLEX') {

        // For FLEX data: use cellranger multi (handles multiplexing)
        ch_multi_config = ch_samplesheet
            .splitCsv(header: true, sep: ',')
            .map { row ->
                def sample_id = row.sample_id
                def config_csv = row.multi_config
                def fastq_dir = row.fastqs
                return tuple(sample_id, file(config_csv), file(fastq_dir))
            }

        CELLRANGER_MULTI(
            ch_multi_config,
            ch_reference,
            file(params.probe_set)
        )

    } else {
        error "Invalid data_type: ${params.data_type}. Must be 'GEX', 'FLEX', or 'SOUPORCELL'"
    }


    /*
    ========================================================================================
        COMPLETION SUMMARY
    ========================================================================================
    */

    workflow.onComplete {
    log.info """
    ========================================
    Pipeline completed!
    ========================================
    """.stripIndent()
    }
     workflow.onError {
        log.error "Pipeline failed. Please refer to troubleshooting docs: https://nf-co.re/docs/usage/troubleshooting"
    }

}
