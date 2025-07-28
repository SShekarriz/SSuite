#!/usr/bin/env nextflow

process UNICYCLE {

    container "community.wave.seqera.io/library/pip_unicycle:9fca2ce54c7c9be3"
    publishDir "results/unicycle", mode: 'copy'

    input:
    tuple path(read1), path(read2)
    path index_zip

    output:
    path(contigs.fasta) , emit: assembled_contigs
    path(assembly_report.txt) , emit: assembly_report


    script:
    """
    tar -xzvf $index_zip

    unicycler -1 ${read1} -2 ${read2} \
                -o results/unicycle/${read1.baseName}_assembly \
                --threads 10
    """
}
