# Surette Lab – Suite of Microbiome Workflows

A collection of reproducible workflows developed in the Surette Lab for microbiome data analysis using best-practice tools and standardized processing steps.

---

## Metagenomic Profiling Pipeline (SSuite-meta)

**SSuite-meta** is a Nextflow-based pipeline for generating taxonomic and functional profiles from shotgun metagenomic sequencing data.

The pipeline performs:

- Quality filtering of raw reads using **fastp**
- Removal of host (human) DNA using **Kraken2** with **CHM13 T2T** as the reference genome
- Taxonomic profiling using **MetaPhlAn 4**
- Functional profiling using **HUMAnN 4**

Multiple host decontamination strategies are supported, allowing users to tailor processing to their data and analysis requirements.

---

## Installation

### Requirements

- Linux or macOS
- Java **17 or later**
- Nextflow

---

### 1. Install Java

Nextflow requires Java 17 or newer.

#### Using SDKMAN! (recommended)

```bash
curl -s https://get.sdkman.io | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 17.0.10-tem
```

### 2. Install Nextflow

Nextflow is distributed as a self-contained executable. Download and make executable.

```bash
wget -qO- https://get.nextflow.io | bash
chmod +x nextflow
```

## Usage

### Running the Pipeline

The SSuite-meta pipeline is executed using Nextflow. A typical run requires a sample sheet in CSV format, a configuration file defining pipeline parameters, and an execution profile matching the target environment.

#### Example command

```bash
PIPELINE_PATH=/path/to/SSuite-meta.nf
CSV_FILE=/path/to/batch_id.csv

nextflow -log "logs/batch_id_nextflow.log" \
    run ${PIPELINE_PATH} \
    -profile <profile_name> \
    --input_csv ${CSV_FILE} \
    -with-report "results/batch_id_report.html" \
    -c "/path/to/pipeline.config" \
    --outdir "results/batch_id_results" \
    --base_dir "temp/batch_id_temp" \
    -resume
```

## Pipeline Options (Summary)

### Input and Output

- `--input_csv`  
  CSV file defining the input metagenomic FASTQ files and associated sample information.

- `--outdir`  
  Output directory where final taxonomic and functional profiling results are written.

- `--base_dir`  
  Temporary working directory used by Nextflow for intermediate files and execution metadata.

---

### Execution and Configuration

- `-profile`  
  Nextflow execution profile specifying the computing environment (e.g. local, cluster scheduler, container backend).

- `-c`  
  Custom Nextflow configuration file controlling resource allocation, database paths, and tool parameters.

---

### Reporting and Logging

- `-with-report`  
  Generates an HTML report summarizing pipeline performance, execution time, and resource usage.

- `-log`  
  Path to the Nextflow runtime log file for this run.

---

### Workflow Control

- `-resume`  
  Allows the pipeline to resume from previously completed steps in the event of interruption.

