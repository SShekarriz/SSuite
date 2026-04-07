# Surette Lab – Suite of Microbiome Workflows

A collection of reproducible workflows developed in the Surette Lab for microbiome data analysis, with a focus on metagenomic profiling using best-practice tools and standardized processing steps.

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
