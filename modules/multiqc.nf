#!/usr/bin/env nextflow

process MULTIQC {

    //container "community.wave.seqera.io/library/pip_multiqc:ad8f247edb55897c"
    container "file://${params.apptainer_dir}/multiqc.sif"
    publishDir "results/multiqc", mode: 'copy'

    input:
    path 'inputs/*'
    val batch_id

    output:
    path "${batch)id}.html", emit: report
    path "${batch_id}_data", emit: data

    script:
    """
    multiqc inputs/ --filename "${batch_id}_multiQC_report.html" \
	   --title "Batch QC: ${batch_id}"
    """
}
