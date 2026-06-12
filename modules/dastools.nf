#!/usr/bin/env nextflow

process DASTOOLS {

	// define container image
	container "file://${params.apptainer_dir}/dastools.sif"
	publishDir "results/dastools", mode: 'copy'

	input:
	tuple val(sample_id), path(contigs), path(bins_tsv)

	output:
	path "${sample_id}_DASTool_summary.tsv", emit: summary
	// note: contigs2bin output only relevant if running QC on multiple binners
	path "${sample_id}_DASTool_contigs2bin.tsv", optional: true, emit: contigs2bin
	tuple val(sample_id), path("${sample_id}_DASTool_bins/*.fa"), emit: refined_bins

	script:
	def bin_dir = "${sample_id}_DASTool_bins"
    """
	DAS_Tool -i ${bins_tsv} \
             -c ${contigs} \
			 -l ${params.binning_method} \
             -o "${sample_id}" \
             --write_bins \
             --threads ${task.cpus}
	"""
}
