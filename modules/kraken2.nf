#!/usr/bin/env nextflow

process KRAKEN2 {

    //container "community.wave.seqera.io/library/kraken2:2.1.5--2bd828274d201d82"
    container "file://${params.apptainer_dir}/kraken2.sif"
    publishDir "results/kraken2", mode: 'copy'

    input:
    tuple path(read1), path(read2)
    path index_zip

    output:
    tuple path("*_DR_1.fastq"), path("*_DR_2.fastq"), emit: decontam_reads
    tuple path("*_CR_1.fastq"), path("*_CR_2.fastq"), emit: contam_reads

    script:
    """
    tar -xzvf $index_zip

    kraken2 --db ${index_zip.simpleName} ${read1} ${read2} \
    --use-names --paired --threads 10 \
    --output ${read1.simpleName}.names --report ${read1.simpleName}.report \
    --unclassified-out ${read1.simpleName}_DR#.fastq \
    --classified-out ${read1.simpleName}_CR#.fastq
    
    """
}

//--confidence 0.05 \

// the input should not be zipped and the version was updated.
//kraken2 --db k2_human /data/IMG105_S37.R1.fastq.gz /data/IMG105_S37.R2.fastq.gz --threads 10 
// --unclassified-out IMG105_S37_unclass#.fastq --classified-out IMG105_S37_class#.fastq 
// --output IMG105_S37.names --report IMG105_S37.report --use-names --paired

//    extract_kraken_reads.py -k ${read1.simpleName}.names --report ${read1.simpleName}.report \
//    -s1 ${read1} -s2 ${read2} \
//    -o ${read1.simpleName}.D.R1.fq -o2 ${read2.simpleName}.D.R2.fq \
//    --taxid 9606 --exclude --fastq-output