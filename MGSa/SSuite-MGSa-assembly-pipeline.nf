#!/usr/bin/env nextflow

// Module INCLUDE statements (main modules)
include { FASTQC as FASTQC_RAW } from '../modules/fastqc.nf'
include { FASTQC as FASTQC_TRIMMED } from '../modules/fastqc.nf'
include { FASTP } from '../modules/fastp.nf'
include { BWAMEM2 } from '../modules/bwamem2.nf'
include { KRAKEN2 } from '../modules/kraken2.nf'
include { MEGAHIT } from '../modules/megahit.nf'
include { METASPADES } from '../modules/metaspades.nf'
include { QUAST } from '../modules/quast.nf'
include { FILTER_CONTIGS } from '../modules/filter_contigs.nf'
include { PROKKA } from '../modules/prokka.nf'
include { BAKTA } from '../modules/bakta.nf'
include { MULTIQC } from '../modules/multiqc.nf'


// ========================================== MAIN WORKFLOW ================================================//

workflow {

/*
 * DATA PARSING
 */

    // Create input channel (format [sample_id, [read1, read2] ])
    reads_ch = Channel.fromPath(params.input_csv)
        .splitCsv(header:true)
        .map { row ->
                // Define the ID and the Reads based on column headers
                def sample_id = row.sample_id
                def reads = [ file(row.fastq_1), file(row.fastq_2) ]

                // Return the clean tuple structure
                return [ sample_id, reads ]
        }

// ========================================================================================================= //

/*
 * READ CLEANING AND QC
 */

    if(params.run_trim_decontam == true){

        // Call QC module
        FASTQC_RAW(reads_ch)

        // call Adapter trimming module
        FASTP(reads_ch)

        // run decontam module
        if (params.decontam_method == 'bwa') {

                // run decontam on trimmed reads
                BWAMEM2(FASTP.out.trimmed_reads, file(params.bwamem_index))

                // rerun QC on decontam reads
                FASTQC_TRIMMED(BWAMEM2.out.decontam_reads)

                decontam_reads_ch = BWAMEM2.out.decontam_reads

        } else if (params.decontam_method == 'kraken2'){

                // run decontam on trimmed reads
                KRAKEN2(FASTP.out.trimmed_reads, file(params.kraken_index))

                // rerun QC on decontam reads
                FASTQC_TRIMMED(KRAKEN2.out.decontam_reads)

                decontam_reads_ch = KRAKEN2.out.decontam_reads

        } else {
                error "invalid decontamination method"
        }

    } else {

        decontam_reads_ch = reads_ch

        // Call QC module
        FASTQC_TRIMMED(decontam_reads_ch)

    }

// ========================================================================================================= //

 /*
 * METAGENOME ASSEMBLY, QC, and FILTERING
 */

     // run assembly module
    if (params.assembly_method == 'metaspades') {

        // run assembly on clean reads
        METASPADES(decontam_reads_ch)

        // run QC on assembled contigs
        QUAST(METASPADES.out.contigs)

        contigs_ch = METASPADES.out.contigs

    } else if (params.assembly_method == 'megahit'){

        // run assembly on clean reads
        MEGAHIT(decontam_reads_ch)

        // run QC on assembled contigs
        QUAST(MEGAHIT.out.contigs)

        contigs_ch = MEGAHIT.out.contigs

    } else {
        error "invalid assembly method"
    }

    // filter small contigs if desired
    if (params.filter_contigs == true){

        // run filtering module on contigs
        FILTER_CONTIGS(contigs_ch)

        final_contigs_ch = FILTER_CONTIGS.out.filtered_contigs

    } else {

        final_contigs_ch = contigs_ch

    }

// ========================================================================================================= //

/*
 * GENOME ANNOTATION
 */

    if(params.annotation){

        // run genome annotation
        // NOTE: THIS IS RUN ON CONTIGS NOT BINS

        if (params.annotation_method == 'bakta') {

            // genome annotation via bakta
            BAKTA(final_contigs_ch)

        } else if (params.annotation_method == 'prokka'){

            // genome annotation via Prokka
            PROKKA(final_contigs_ch)

        } else {

        error "invalid annotation method"
        }
    }

// ========================================================================================================= //

/*
 * FINAL QC
 */


// Aggregate all QC outputs for MultiQC
// Removes sample_id, leaves [zip, dir, quast_files], flatten to list of paths
// then gathers all paths for ALL SAMPLES (batch output)
 ch_multiqc = FASTQC_TRIMMED.out.zip
        .join( QUAST.out.results )
        .map { it.tail() }
        .flatten()
        .collect()

    // Run MultiQC once on the aggregated collection of QC files
    MULTIQC(ch_multiqc, params.batch_id)

}

// ========================================================================================================= //

// DONE
