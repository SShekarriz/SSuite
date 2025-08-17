#!/usr/bin/env nextflow

// Module INCLUDE statements
include { FASTQC } from './modules/fastqc.nf'
include { FASTQCB } from './modules/fastqc.nf'
include { FASTQCK } from './modules/fastqc.nf'
include { FASTQCKN } from './modules/fastqc.nf'
include { FASTP } from './modules/fastp.nf'
include { KRAKEN2 } from './modules/kraken2.nf'
include { BWAMEM2 } from './modules/bwamem2.nf'
include { KNEADDATA } from './modules/kneadata.nf'
include { METAPHLAN4 } from './modules/metaphlan4.nf'
include { HUMANN4 } from './modules/humann4.nf'
include { MULTIQC } from './modules/multiqc.nf'

/*
 * Pipeline parameters
 */
params.input_csv = "data/subset_data.csv"
params.bwamem_index = "/dataone/common/ref_dbs/SSuite_dbs/hg38.tar.gz"
params.kneadata_index = "/dataone/common/ref_dbs/SSuite_dbs/hg37_kneaddata.tar.gz"
params.kraken2_db_index_zip = "/dataone/common/ref_dbs/SSuite_dbs/k2_human.tar.gz"
params.metaphlan4_db_index_zip = "/dataone/common/ref_dbs/SSuite_dbs/mpa_vOct2.tar.gz"
params.humann4_db_index_zip = "/dataone/common/ref_dbs/SSuite_dbs/humann4.0.0a1.tar.gz"
params.report_id = "all_paired-end"
params.skip_functional_profile = false
params.decontam_method = "kraken2" // Options: 'kraken2', 'bwa', 'kneaddata'

workflow {

    // Validate decontamination method
    if (!['kraken2', 'bwa', 'kneaddata'].contains(params.decontam_method)) {
        error "Invalid decontamination method: ${params.decontam_method}. Choose from 'kraken2', 'bwa', or 'kneaddata'."
    }

    // Create input channel
    read_ch = Channel.fromPath(params.input_csv)
        .splitCsv(header:true)
        .map { row -> [file(row.fastq_1), file(row.fastq_2)] }

    // Initial QC
    FASTQC(read_ch)

    // Adapter trimming
    FASTP(read_ch)

    // Choose decontamination method
    if (params.decontam_method == 'bwa') {
        BWAMEM2(FASTP.out.trimmed_reads, file(params.bwamem_index))
        FASTQCB(BWAMEM2.out.decontam_reads)
        decontam_reads_ch = BWAMEM2.out.decontam_reads
    } else if (params.decontam_method == 'kneaddata') {
        KNEADDATA(FASTP.out.trimmed_reads, file(params.kneadata_index))
        FASTQCKN(KNEADDATA.out.decontam_reads)
        decontam_reads_ch = KNEADDATA.out.decontam_reads
    } else {
        KRAKEN2(FASTP.out.trimmed_reads, file(params.kraken2_db_index_zip))
        FASTQCK(KRAKEN2.out.decontam_reads)
        decontam_reads_ch = KRAKEN2.out.decontam_reads
    }

    // Taxonomic profiling
    METAPHLAN4(decontam_reads_ch, file(params.metaphlan4_db_index_zip))

    // Functional profiling
    if (!params.skip_functional_profile) {
        HUMANN4(decontam_reads_ch, file(params.humann4_db_index_zip), METAPHLAN4.out.taxa_profile)
    } else {
        log.info "Skipping HUMANN4 functional annotation step as requested."
    }

    // MultiQC report
    MULTIQC(
        FASTQC.out.zip.mix(
        FASTQC.out.html,
        FASTQCK.out.zip,
        FASTQCK.out.html,
        ).collect(),
        params.report_id
    )
}
