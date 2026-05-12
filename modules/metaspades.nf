#!/usr/bin/env nextflow

process METASPADES {

        // define container image
        container "file://${params.apptainer_dir}/spades.sif"
        publishDir "results/metaspades", mode: 'copy'

        input:
        tuple val(sample_id), path(reads)

        output:
        tuple val(sample_id), path("*.scaffolds.fasta"), emit: scaffolds
        tuple val(sample_id), path("*.contigs.fasta"), emit: contigs

        script:
        """
        spades.py --meta -t ${task.cpus} \
                  -o ${sample_id}_output \
                  --pe1-1 ${reads[0]} --pe1-2 ${reads[1]} \
                  ${task.ext.args}
        """
}
