#!/usr/bin/env nextflow

process PREPARE_TSV_DASTOOLS {

    // define container image
	container "file://${params.apptainer_dir}/dastools.sif"
	publishDir "results/dastools/tsv", mode: 'copy'
    
    input:
    tuple val(sample_id), path(bin_dir)
	val binner_name
    
    output:
    tuple val(sample_id), path("${sample_id}_${binner_name}_contigs2bin.tsv"), emit: tsv

    script:
    """
	# 1. Peek inside bin directory to see if files end in .fa or .fasta
    FIRST_FILE=\$(ls *.fa* | head -n 1)
    EXT=\${FIRST_FILE##*.}

    # 2. Pass the dynamic extension to the helper script
    Fasta_to_Contig2Bin.sh \
        -i . \
        -e \$EXT \
        > ${sample_id}_${binner_name}_contig2bin.tsv
    """
}
