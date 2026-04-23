#!/usr/bin/env nextflow

process COMEBIN {

        // define container image
        // container "oras://community.wave.seqera.io/library/comebin:1.0.4--12fdcf0118ec044d"
        container "file://${params.apptainer_dir}/comebin.sif"
        publishDir "results/comebin", mode: 'copy'

        input:
        tuple val(sample_id), path(bams), path(bais), path(contigs)

        output:
        tuple val(sample_id), path("${sample_id}_comebin_bins/bins/${sample_id}.comebin.*.fa*"), emit: bins
        path "comebin.log", emit: log

        script:
        def out_dir = "${sample_id}_comebin_bins"
        def bin_dir = "${out_dir}/bins"
        """
        comebin multi_sample_bin \
            --input_fasta "${contigs}" \
            --input_bam ${bams} \
            --output_dir "${out_dir}" \
            --threads ${task.cpus} \
            > comebin.log 2>&1

        ## rename for later
        ${rename_bins(sample_id, 'comebin', bin_dir)}

        """
}
