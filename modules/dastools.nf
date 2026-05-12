#!/usr/bin/env nextflow

process DASTOOLS {

	// define container image
	container "file://${params.apptainer_dir}/dastools.sif"
	publishDir "results/dastools", mode: 'copy'

	input:
	tuple val(sample_id), path(bins_tsv), path(contigs)

	output:
	path "${sample_id}_DASTool_summary.tsv", emit: summary
	path "${sample_id}_DASTool_contigs2bin.tsv", emit: contigs2bin
	path "${sample_id}_allBins.eval", emit: eval
	tuple val(sample_id), path("${sample_id}_DASTool_bins/*.fa"), emit: refined_bins

	script:
	def bin_dir = "${sample_id}_DASTool_bins"
      	"""
	DAS_Tool -i ${bins_tsv} \
             -c ${contigs} \
             -o "${sample_id}" \
             --write_bins \
             --threads ${task.cpus}

	# rename the files using global function
    	${rename_bins(sample_id, 'dastool', bin_dir)}
	"""
}
