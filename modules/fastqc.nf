#!/usr/bin/env nextflow

process FASTQC {

    //container "community.wave.seqera.io/library/fastqc:0.12.1--af7a5314d5015c29"
    container "file://${params.apptainer_dir}/fastqc.sif"
    publishDir "results/fastqc", mode: 'symlink'

    input:
    path reads

    output:
    path "*_fastqc.zip", emit: zip
    path "*_fastqc.html", emit: html

    script:
    """
    fastqc ${reads}
    """
}

process FASTQCB {

    container "file://${params.apptainer_dir}/fastqc.sif"
    publishDir "results/fastqc_bwa", mode: 'symlink'

    input:
    path reads

    output:
    path "*_fastqc.zip", emit: zip
    path "*_fastqc.html", emit: html

    script:
    """
    fastqc ${reads}
    """
}


process FASTQCK {

    container "file://${params.apptainer_dir}/fastqc.sif"
    publishDir "results/fastqc_kraken", mode: 'symlink'

    input:
    path reads

    output:
    path "*_fastqc.zip", emit: zip
    path "*_fastqc.html", emit: html

    script:
    """
    fastqc ${reads}
    """
}

process FASTQCKN {

    container "file://${params.apptainer_dir}/fastqc.sif"
    publishDir "results/fastqc_kneadata", mode: 'symlink'

    input:
    path reads

    output:
    path "*_fastqc.zip", emit: zip
    path "*_fastqc.html", emit: html

    script:
    """
    fastqc ${reads}
    """
}