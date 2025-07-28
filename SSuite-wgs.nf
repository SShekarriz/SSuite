#!/usr/bin/env nextflow

// Module INCLUDE statements
include { FASTQC } from './modules/fastqc.nf'
include { FASTP } from './modules/fastp.nf'
include { MULTIQC } from './modules/multiqc.nf'
include { UNICYCLE } from './modules/unicycle.nf'

/*
 * Pipeline parameters
 */

// Primary input
params.input_csv = "data/subset_data.csv"
params.report_id = "all_paired-end"
params.skip_functional_profile = false


workflow {

    // Create input channel
    read_ch = Channel.fromPath(params.input_csv)
        .splitCsv(header:true)
        .map { row -> [file(row.fastq_1), file(row.fastq_2)] }

    // Call processes
    FASTQC(read_ch)

    // Adapter trimming and post-trimming QC
    FASTP(read_ch)

    // De novo assembly of paired-end reads
    UNICYCLE(
        read_ch,
        params.report_id
    )

    // Comprehensive QC report generation
    MULTIQC(
        FASTQC.out.zip.mix(
        FASTQC.out.html,
        FASTQCK.out.zip,
        FASTQCK.out.html,
        ).collect(),
        params.report_id
    )

}
