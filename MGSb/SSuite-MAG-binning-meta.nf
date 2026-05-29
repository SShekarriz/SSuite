#!/usr/bin/env nextflow

// Module INCLUDE statements (main modules)

// read mapping
include { BOWTIE2_BUILD } from './modules/bowtie2_build.nf'
include { BOWTIE2_ALIGN_ONLY } from './modules/bowtie2_align_only.nf'
include { SAMTOOLS } from './modules/samtools.nf'

// binners
include { COMEBIN } from './modules/comebin.nf'
include { SEMIBIN } from './modules/semibin.nf'
include { MAXBIN2 } from './modules/maxbin2.nf'
include { BINNY } from './modules/binny.nf'
include { METABAT2 } from './modules/metabat2.nf'
include { METABINNER } from './modules/metabinner.nf'
include { CONCOCT } from './modules/concoct.nf'
include { CHECKM2 } from './modules/checkm2.nf'
include { DASTOOLS } from './modules/dastools.nf'
include { GTDBTK } from './modules/gtdbtk.nf'
include { MULTIQC } from './modules/multiqc.nf'

// binning helper modules)
include { GENERATE_ABUND_MAXBIN2 } from './modules/generate_abund_maxbin2.nf'
include { GENERATE_DEPTH_METABAT2 } from './modules/generate_depth_metabat2.nf'
include { GENERATE_COVERAGE_METABINNER } from './modules/generate_coverage_metabinner.nf'
include { GENERATE_KMERS_METABINNER } from './modules/generate_kmers_metabinner.nf'
include { GENERATE_COVERAGE_CONCOCT } from './modules/generate_coverage_concoct.nf'
include { CUTUP_CONCOCT } from './modules/cutup_concoct.nf'
include { PREPARE_TSV_DASTOOLS } from './modules/prepare_tsv_dastools.nf'


// ========================================== MAIN WORKFLOW ================================================//

workflow {


    /*
     * ASSEMBLY AND READS IMPORT
     */


    // Create ASSEMBLY input channel (format [sample_id, contigs])
    contigs_ch = Channel.fromPath(params.input_csv)
        .splitCsv(header:true)
        .map { row ->
                // Define the ID and the Reads based on column headers
                def sample_id    = row.sample_id
                def contigs = file(row.assembly)

                // Return the clean tuple structure
                return [ sample_id, contigs ]
        }

     // Create READS input channel (format [sample_id, reads])
    decontam_reads_ch = Channel.fromPath(params.input_csv)
        .splitCsv(header:true)
        .map { row ->
                // Define the ID and the Reads based on column headers
                def sample_id    = row.sample_id
                def reads = [ file(row.fastq_DR1), file(row.fastq_DR2) ]

                // Return the clean tuple structure
                return [ sample_id, reads ]
        }

// ========================================================================================================= //


    /*
     * READ CROSS-MAPPING
     */

    // build index from contigs for every sample: [ sample_id, contigs ]
    BOWTIE2_BUILD(contigs_ch)

    // Cross-mapping: Generate every assembly-read pair (all builds vs all read channels)
    // in the form [ assembly_id, [index_files], read_id, [reads] ]
    cross_mapping_ch = BOWTIE2_BUILD.out.index.combine(decontam_reads_ch)

    // align reads to index (all reads to all assemblies)
    BOWTIE2_ALIGN_ONLY(cross_mapping_ch)

    // feed sams into samtools
    SAMTOOLS(BOWTIE2_ALIGN_ONLY.out.sam)

    // GROUP BAMS AND BAIS BY SAMPLE_ID
    // Input format: [sample_id, bam, bai]
    // Output format: [sample_id, [bam1, bam2, ..., bamN], [bai1, bai2, ..., baiN]]
    grouped_bams_ch = SAMTOOLS.out.bam_with_index
                      .groupTuple(by: 0)

    // join bam files with their corresponding sample contigs to preserve ID match
    contigs_cross_mapped_bams_ch = grouped_bams_ch.join(contigs_ch)


// ========================================================================================================= //

    /*
     * BINNING
     */

    // run binning module
    if (params.binning_method == 'comebin') {

        // run binning on id-joined contigs and bams
        COMEBIN(contigs_cross_mapped_bams_ch)
        bins_ch = COMEBIN.out.bins

    } else if (params.binning_method == 'semibin'){

        // run binning on id-joined contigs and bams
        SEMIBIN2(contigs_cross_mapped_bams_ch)
        bins_ch = SEMIBIN2.out.bins

    } else if (params.binning_method == 'maxbin2'){

        // run abundance assembly
        // use bam files joined with sample_id
        GENERATE_ABUND_MAXBIN2(grouped_bams_ch)

        // join with original contig files by id
        maxbin_input_ch = contigs_ch.join(GENERATE_ABUND_MAXBIN2.out.abund_list)

        // run binning on id-tagged contigs w/ abundance files
        MAXBIN2(maxbin_input_ch)
        bins_ch = MAXBIN2.out.bins

    } else if (params.binning_method == 'metabat2'){

        // generate depth file using internal helper function
        // use sorted .bam files and reference fasta (contig catalog)
        GENERATE_DEPTH_METABAT2(grouped_bams_ch)
        depth_ch = GENERATE_DEPTH_METABAT2.out.depth

        // join contigs with depth files
        metabat_input = contigs_ch.join(depth_ch)

        // run binning on id-tagged contigs with depth file from previous step
        METABAT2(metabat_input)
        bins_ch = METABAT2.out.bins

    } else if (params.binning_method == 'metabinner'){

        // generate coverage file using internal helper function
        // use depth file from previous metabat2 module to calculate coverage
        GENERATE_COVERAGE_METABINNER(depth_ch)
        coverage_ch = GENERATE_COVERAGE_METABINNER.out.coverage

        // generate kmer files (one per sample) using internal helper function
        // use contigs w/ additional length and threshold args (defined in params)
        GENERATE_KMER_METABINNER(contigs_ch, kmer_size, length_thresh)
        kmer_ch = GENERATE_KMER_METABINNER.out.coverage

        // join sample ID'ed contigs channel to kmer and coverage channels for same sample
        metabinner_input = contigs_ch
                .join(coverage_ch)
                .join(kmer_ch)

        // run binning on contigs + kmer + coverage files from previous steps
        METABINNER(metabinner_input)
        bins_ch = METABINNER.out.bins

    } else if (params.binning_method == 'binny'){

        // define channel targeting unifunc dir
        unifunc_asset_ch = Channel.value(file("/project/6007957/users/greenm11/software/magSuite/UniFunc/unifunc"))

        // run assembly on clean reads
        BINNY(contigs_cross_mapped_bams_ch, unifunc_asset_ch)
        bins_ch = BINNY.out.bins

    } else if (params.binning_method == 'concoct'){

        // Fragment the assemblies
        CUTUP_CONCOCT(contigs_ch)

        // Join fragmented BED with grouped BAMs to get coverage
        coverage_input = CUTUP_CONCOCT.out.bed.join(grouped_bams_ch)
        GENERATE_COVERAGE_CONCOCT(coverage_input)

        // join original contigs, cutup fasta and coverage for final binning
        concoct_final_input = contigs_ch
            .join(CUTUP_CONCOCT.out.fasta)
            .join(GENERATE_COVERAGE_CONCOCT.out.coverage)

        CONCOCT(concoct_final_input)
        bins_ch = CONCOCT.bins

    } else {

        error "invalid binning method"
    }


// ========================================================================================================= //

    /*
     * BIN REFINEMENT AND QC
     */

    if(params.refine_bins){

        // run DAStools helper module
        PREPARE_TSV_DASTOOLS(bins_ch, params.binning_method)
        tsv_ch = PREPARE_TSV_DASTOOLS.out.tsv

        // join tsv and contigs channels by sample ID
        contigs_tsv_ch = contigs_ch.join(tsv_ch)

        // run DAStools
        DASTOOLS(contigs_tsv_ch)
        bins_ch = DASTOOLS.out.refined_bins

    }

    // run checkm2 for bin QC
    CHECKM2(bins_ch)


// ========================================================================================================= //


    /*
     * TAXONOMY ASSIGNMENT
     */

    // taxonomy assignment via gtdb-tk
    GTDBTK(bins_ch)

}


// ========================================================================================================= //

// DONE

