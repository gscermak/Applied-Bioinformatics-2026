# ============================================================================
# Genome-based RNA-Seq Analysis
# Human Chromosome 22: HBR vs UHR
#
# Applied Bioinformatics 2026
#
# Single sample:
#   make SAMPLE=HBR_1 all
#
# All samples:
#   make batch
#
# Visualize:
#   make igv
# ============================================================================

.DEFAULT_GOAL := help

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

THREADS ?= 4
JOBS ?= 2

# Download source
DATA_URL = http://data.biostarhandbook.com/data/rnaseq-tutorial-2026.tar.gz

# Reference genome and annotation
FASTA = fasta/chr22.genome.fa
GTF = gtf/chr22.gtf

# Sample configuration
SAMPLE ?= HBR_1
DESIGN = design.csv

# Input reads
R1 = fastq/$(SAMPLE)_R1.fq

# Output files
BAM = bam/$(SAMPLE).bam
BW = bw/$(SAMPLE).bw
COUNT = counts/$(SAMPLE).txt

# IGV configuration
DIR = $(CURDIR)
NC = nc -q 1 localhost 60151

# GNU Parallel
PARALLEL = parallel --eta --colsep , --header : --jobs $(JOBS) --lb
JOBLOG = batch.log

# Makefile used by batch jobs
MAKEFILE = $(firstword $(MAKEFILE_LIST))

# All FASTQ files supplied by the archive
SAMPLES = HBR_1 HBR_2 HBR_3 UHR_1 UHR_2 UHR_3
FASTQ = $(addprefix fastq/,$(addsuffix _R1.fq,$(SAMPLES)))

# --- All definitions above this line ---

# ----------------------------------------------------------------------------
# Make settings
# ----------------------------------------------------------------------------

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules --no-print-directory

.PHONY: help data index align count counts all batch igv clean

# ============================================================================
# Help
# ============================================================================

help:
	@echo "#"
	@echo "# Genome-based RNA-Seq: Human Chromosome 22"
	@echo "#"
	@echo "# SAMPLE=$(SAMPLE)"
	@echo "# THREADS=$(THREADS)"
	@echo "# JOBS=$(JOBS)"
	@echo "# FASTA=$(FASTA)"
	@echo "# GTF=$(GTF)"
	@echo "# R1=$(R1)"
	@echo "# BAM=$(BAM)"
	@echo "# BW=$(BW)"
	@echo "# COUNT=$(COUNT)"
	@echo "#"
	@echo "# make data"
	@echo "# make index"
	@echo "# make align"
	@echo "# make count"
	@echo "# make all"
	@echo "# make batch"
	@echo "# make igv"
	@echo "# make clean"
	@echo "#"

# ============================================================================
# Download data
# ============================================================================

# One archive extraction produces all reference and FASTQ files.
# Grouped targets ensure the recipe runs only once.

$(FASTA) $(GTF) $(FASTQ) &:
	curl -fL --retry 3 "$(DATA_URL)" | tar xzvf -

data: $(FASTA) $(GTF) $(R1)

# ============================================================================
# HISAT2 genome index
# ============================================================================

$(FASTA).1.ht2: $(FASTA)
	hisat2-build -p $(THREADS) "$(FASTA)" "$(FASTA)"

index: $(FASTA).1.ht2

# ============================================================================
# Align RNA-Seq reads
# ============================================================================

$(BAM): $(FASTA).1.ht2 $(R1)
	mkdir -p bam
	hisat2 --threads $(THREADS) --sensitive \
		-x "$(FASTA)" \
		-U "$(R1)" | \
		samtools sort --threads $(THREADS) \
			--write-index -o "$(BAM)"

# ============================================================================
# Generate BigWig coverage
# ============================================================================

$(BW): $(BAM)
	mkdir -p bw
	bamCoverage \
		--binSize 1 \
		--numberOfProcessors $(THREADS) \
		-b "$(BAM)" \
		-o "$(BW)"

align: $(BAM) $(BW)

# ============================================================================
# Count reads assigned to genes
# ============================================================================

# Reverse-stranded RNA-Seq.

$(COUNT): $(BAM) $(GTF)
	mkdir -p counts
	featureCounts \
		-T $(THREADS) \
		-a "$(GTF)" \
		-s 2 \
		-o "$(COUNT)" \
		"$(BAM)"

count counts: $(COUNT)

# ============================================================================
# Process one sample
# ============================================================================

all: counts align

# ============================================================================
# Process all samples
# ============================================================================

# Prepare shared data and index before starting parallel jobs.

batch: data index
	cat "$(DESIGN)" | $(PARALLEL) \
		--joblog "$(JOBLOG)" \
		$(MAKE) -f "$(MAKEFILE)" \
		THREADS=$(THREADS) \
		SAMPLE={sample} all

# ============================================================================
# Visualize with IGV
# ============================================================================

# IGV must be running with its command port enabled.

# ============================================================================
# Visualize with IGV
# ============================================================================

igv:
	echo "new" | $(NC)
	echo "genome $(DIR)/$(FASTA)" | $(NC)
	echo "load $(DIR)/$(GTF)" | $(NC)
	@if [[ -f "$(DESIGN)" ]]; then \
		while IFS=, read -r sample rest; do \
			[[ "$$sample" == "sample" || -z "$$sample" ]] && continue; \
			echo "load $(DIR)/bw/$$sample.bw" | $(NC); \
		done < "$(DESIGN)"; \
	else \
		echo "load $(DIR)/$(BW)" | $(NC); \
	fi

# ============================================================================
# Clean
# ============================================================================

clean:
	rm -rf fasta fastq gtf bam bw counts
	rm -f "$(JOBLOG)"