#!/usr/bin/env nextflow

process FASTP {

    container "community.wave.seqera.io/library/fastp:0.24.1--6214360065b44e0b"
    publishDir "results/fastp", mode: 'symlink'

    input:
    tuple path(read1), path(read2)

    output:
    tuple path("*.T.R1.fastq"), path("*.T.R2.fastq"), emit: trimmed_reads
    path "*.fastp.html", emit: html_report

    script:
    """
    fastp -i ${read1} -I ${read2} \
        -o ${read1.simpleName}.T.R1.fastq \
        -O ${read2.simpleName}.T.R2.fastq \
        --thread 8 --html ${read1.simpleName}.fastp.html

    """
}
