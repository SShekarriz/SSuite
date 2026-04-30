#!/usr/bin/env nextflow

process CHECKM2 {

	// define container image
	// container "oras://community.wave.seqera.io/library/checkm2:1.1.0--450784eb7a60b7bf"
	container "file://${params.apptainer_dir}/checkm2.sif"
	publishDir "results/checkm2", mode: 'copy'

	input:
	tuple val(sample_id), path(bins_dir)
	
	output:
	tuple val(sample_id), path("${sample_id}_checkm2/*"), emit: results


	script:
      	"""
	checkm2 predict --threads ${task.cpus} \\
                    --input ${bins_dir} \\
                    --output-directory ${sample_id}_checkm2}
	"""
}
