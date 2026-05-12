#!/usr/bin/env nextflow

process PREPARE_TSV_DASTOOLS {

    // define container image
	container "file://${params.apptainer_dir}/dastools.sif"
	publishDir "results/dastools/tsv", mode: 'copy'
    
    input:
    tuple val(sample_id), val(binner_name), path(bin_dir)
    
    output:
     tuple val(sample_id), path("${sample_id}_${binner_name}_contigs2bin.tsv"), emit: tsv

    script:
    """
	# Use -i . because Nextflow staged the bin_dir files into the root
	Fasta_to_Contig2Bin.sh -i . -e fa > ${sample_id}_${binner_name}_contigs2bin.tsv
    """
}
