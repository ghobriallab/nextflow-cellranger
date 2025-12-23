#!/usr/bin/env nextflow

/*
========================================================================================
    Single Cell RNA-seq Pipeline - 10X Genomics
========================================================================================
    Pipeline for processing 10X single-cell RNA-seq data
    Supports:
    - GEX (Gene Expression) data using cellranger count
    - FLEX (Fixed RNA Profiling) multiplexed data using cellranger multi
========================================================================================
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { CELLRANGER_COUNT } from './modules/local/cellranger_count/main'
include { CELLRANGER_MULTI } from './modules/local/cellranger_multi/main'
include { SOUPORCELL } from './modules/local/souporcell/main'

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
    Reference          : ${params.reference}
    ${params.data_type == 'FLEX' ? "Probe Set          : ${params.probe_set}" : ''}
    ${params.run_souporcell ? "Run SoupOrCell     : true" : ''}
    ${params.run_souporcell ? "SoupOrCell Fasta   : ${params.souporcell_fasta}" : ''}
    ${params.run_souporcell ? "SoupOrCell Clusters: ${params.souporcell_clusters}" : ''}
    ========================================
    """

    
    // Parse input samplesheet
    ch_samplesheet = Channel.fromPath(params.samplesheet, checkIfExists: true)
    ch_reference = Channel.fromPath(params.reference, checkIfExists: true)
    ch_probe_set = params.data_type == 'FLEX' ? Channel.fromPath(params.probe_set, checkIfExists: true) : null
    // Branch workflow based on data type
    if (params.data_type == 'GEX') {

        // For GEX data: use cellranger count
        ch_samples = ch_samplesheet
            .splitCsv(header: true, sep: ',')
            .map { row ->
                def sample_id = row.sample_id
                def fastq_dir = row.fastq_dir
                return tuple(sample_id, file(fastq_dir))
            }

        CELLRANGER_COUNT(
            ch_samples,
            file(params.reference)
        )

        // Run SoupOrCell if enabled
        if (params.run_souporcell) {
            SOUPORCELL(
                CELLRANGER_COUNT.out.souporcell_input,
                file(params.souporcell_fasta),
                params.souporcell_clusters
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
            file(params.reference),
            file(params.probe_set)
        )

    } else {
        error "Invalid data_type: ${params.data_type}. Must be 'GEX' or 'FLEX'"
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
