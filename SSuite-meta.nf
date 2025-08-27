#!/usr/bin/env nextflow

// Module INCLUDE statements
include { FASTP } from './modules/fastp.nf'


/*
 * Pipeline parameters
 */

// Primary input
params.input_csv = "data/subset_data.csv"


workflow {

    // Create input channel
    read_ch = Channel.fromPath(params.input_csv)
        .splitCsv(header:true)
        .map { row -> [file(row.fastq_1), file(row.fastq_2)] }


    // Adapter trimming and post-trimming QC
    FASTP(read_ch)

}