#!/usr/bin/env nextflow

// Module INCLUDE statements
include { FASTQC } from './modules/fastqc.nf'
include { FASTP } from './modules/fastp.nf'
include { KRAKEN2 } from './modules/kraken2.nf'
include { METAPHLAN4 } from './modules/metaphlan4.nf'
include { FASTQCB } from './modules/fastqc.nf'
include { FASTQCK } from './modules/fastqc.nf'
include { HUMANN4 } from './modules/humann4.nf'
include { MULTIQC } from './modules/multiqc.nf'

/*
 * Pipeline parameters
 */

// Primary input
params.input_csv = "data/subset_data.csv"
params.kraken2_db_index_zip = "dbs/k2_human.tar.gz"
params.metaphlan4_db_index_zip = "dbs/mpa_vOct2.tar.gz"
params.humann4_db_index_zip = "dbs/humann4.0.0a1.tar.gz"
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

    //Assign taxonomy to human genome kraken(MinusB)
    KRAKEN2(FASTP.out.trimmed_reads, file (params.kraken2_db_index_zip))
    
    FASTQCK(KRAKEN2.out.decontam_reads)

    //Assign taxonomy to microial reads
    METAPHLAN4(KRAKEN2.out.decontam_reads, file (params.metaphlan4_db_index_zip))

    //Assign function to microbial reads
    if (!params.skip_functional_profile) {
        HUMANN4(KRAKEN2.out.decontam_reads, file(params.humann4_db_index_zip), METAPHLAN4.out.taxa_profile)
    } else {
        log.info "Skipping HUMANN4 functional annotation step as requested."
    }

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
