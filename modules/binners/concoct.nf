#!/usr/bin/env nextflow

process CONCOCT {

        // define container image
        // container "oras://community.wave.seqera.io/library/concoct:1.1.0--076c81fe6e260a99"
        container "file://${params.apptainer_dir}/concoct.sif"
        publishDir "results/concoct", mode: 'copy'

        input:
        tuple val(sample_id), path(original_fasta), path(cutup_fasta), path(coverage_table)

        output:
        tuple val(sample_id), path("${sample_id}_concoct_bins/${sample_id}.concoct.*.fa*"), emit: bins
        tuple val(sample_id), path("${sample_id}_concoct_results/clustering_gt1000.csv"), emit: clustering

        script:
        def out_dir = "${sample_id}_concoct_bins"
        """
        ## create directories to keep results and bins separate
        mkdir ${sample_id}_concoct_results
        mkdir ${out_dir}

        # Run the binner to get the clustering CSV
        concoct \
            --composition_file ${cutup_fasta} \
            --coverage_file ${coverage_table} \
            -b ${sample_id}_concoct_results/ \
            -t ${task.cpus}

        # Extract the actual FASTA bins from the original assembly
        extract_fasta_bins.py \
            ${original_fasta} \
            ${sample_id}_concoct_results/clustering_gt1000.csv \
            --output_path ${out_dir}

        ## rename for later
        ${rename_bins(sample_id, 'concoct', out_dir)}
        """
}
