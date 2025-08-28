#!/usr/bin/env nextflow

process BWAMEM2 {

    //container "community.wave.seqera.io/library/bwa-mem2_samtools:b7ce408fd27b2698"
    container "file://${params.apptainer_dir}/bwamem2.sif"
    publishDir "results/bwa-mem2", mode: 'symlink'

    input:
    tuple path(read1), path(read2)
    path index_zip

    output:
    tuple path("*.D.R1.fastq"), path("*.D.R2.fastq"), emit: decontam_reads

    script:
    """
    tar -xzvf $index_zip
    bwa-mem2 mem -t 10 ${index_zip.simpleName}.fa \
    ${read1} ${read2} | samtools view -@ 10 -b \
    -f 12 -F 256 - | samtools sort -n -@ 10 - | samtools fastq -@ 10 \
    -1 ${read1.simpleName}.D.R1.fastq -2 ${read2.simpleName}.D.R2.fastq \
    -0 /dev/null -s /dev/null -n -
    
    """
}

//-f 12 -F 256 - | samtools sort -n -@ 10 - | samtools fastq -@ 10 \