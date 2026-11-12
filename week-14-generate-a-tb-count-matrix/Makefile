# ============================================================
# RNA-Seq Transcript Quantification with Salmon
# ============================================================

.DEFAULT_GOAL := help

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

# Data and reference
DATA_URL = http://data.biostarhandbook.com/data/rnaseq-tutorial-2026.tar.gz

FASTA = fasta/chr22.transcripts.fa
GTF = gtf/chr22.gtf

FASTA_IDX_DIR = fasta/chr22.salmon
FASTA_IDX = $(FASTA_IDX_DIR)/index.ctab

# Sample inputs and outputs
SAMPLE ?= HBR_1
R1 = fastq/$(SAMPLE)_R1.fq

COUNT_DIR = counts/$(SAMPLE)
COUNTS = $(COUNT_DIR)/quant.sf

DESIGN = design.csv

# R scripts
TRANSCRIPT_SCRIPT = src/combine_transcript_counts.r
GENE_SCRIPT = src/combine_gene_counts.r

# Combined count matrices
TRANSCRIPT_MATRIX = counts/transcript_counts.csv
GENE_MATRIX = counts/gene_counts.csv

# Performance
THREADS ?= 4
JOBS ?= 2

PARALLEL = parallel --eta --colsep , --header : --jobs $(JOBS) --lb

# ------------------------------------------------------------
# Makefile settings
# ------------------------------------------------------------

SHELL = bash
.SHELLFLAGS = -eu -o pipefail -c

.DELETE_ON_ERROR:

MAKEFLAGS += --warn-undefined-variables --no-builtin-rules --no-print-directory

# ------------------------------------------------------------
# Phony targets
# ------------------------------------------------------------

.PHONY: help data index counts all batch clean

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------

help:
	@echo '# Salmon RNA-seq Transcript Quantification'
	@echo '#'
	@echo '# SAMPLE=$(SAMPLE)'
	@echo '# THREADS=$(THREADS)'
	@echo '# JOBS=$(JOBS)'
	@echo '#'
	@echo '# make data    Download and prepare tutorial data'
	@echo '# make index   Build Salmon transcript index'
	@echo '# make counts  Quantify one sample'
	@echo '# make all     Run index and counts for one sample'
	@echo '# make batch   Process all samples and generate count matrices'
	@echo '# make clean   Remove downloaded data and generated results'

# ------------------------------------------------------------
# Download and prepare data
# ------------------------------------------------------------

# Download and extract the tutorial archive.
# The stamp prevents repeated downloads.

.data_downloaded:
	curl -fL --retry 3 '$(DATA_URL)' | tar xzvf -
	touch $@

# Verify the reference FASTA and GTF files.

$(FASTA) $(GTF): .data_downloaded
	@test -s '$@' || { echo 'Missing expected file: $@' >&2; exit 1; }

# Verify sample FASTQ files.

fastq/%_R1.fq: .data_downloaded
	@test -s '$@' || { echo 'Missing expected FASTQ: $@' >&2; exit 1; }

data: $(FASTA) $(GTF) $(R1)
	ls -lh '$(FASTA)' '$(GTF)' '$(R1)'

# ------------------------------------------------------------
# Build Salmon transcript index
# ------------------------------------------------------------

$(FASTA_IDX): $(FASTA)
	salmon index \
		--transcripts '$(FASTA)' \
		--index '$(FASTA_IDX_DIR)' \
		--threads $(THREADS)

index: $(FASTA_IDX)
	ls -lh '$(FASTA_IDX)'

# ------------------------------------------------------------
# Quantify transcript abundance
# ------------------------------------------------------------

# Quantify one sample using Salmon.
# The sample name determines the input FASTQ and output directory.

$(COUNTS): $(FASTA_IDX) $(R1)
	mkdir -p '$(COUNT_DIR)'
	salmon quant \
		--index '$(FASTA_IDX_DIR)' \
		--libType A \
		-r '$(R1)' \
		--threads $(THREADS) \
		--output '$(COUNT_DIR)'

counts: $(COUNTS)
	ls -lh '$(COUNTS)'

# ------------------------------------------------------------
# Process one sample
# ------------------------------------------------------------

all: counts

# ------------------------------------------------------------
# Batch processing
# ------------------------------------------------------------

# Processing order:
#
# 1. Download and prepare reference files
# 2. Build Salmon transcript index
# 3. Quantify all samples using GNU Parallel
# 4. Combine transcript-level counts using R
# 5. Display first five expressed transcripts in terminal
# 6. Aggregate transcript counts into gene counts using R
# 7. Display first five expressed genes in terminal

batch: index $(GTF)
	@test -s '$(DESIGN)' || { echo 'Missing design file: $(DESIGN)' >&2; exit 1; }

	@echo '========================================'
	@echo ' Salmon Batch Quantification'
	@echo '========================================'

	$(PARALLEL) $(MAKE) SAMPLE={sample} THREADS=$(THREADS) all :::: '$(DESIGN)'

	@echo '========================================'
	@echo ' Generating Transcript-Level Count Matrix'
	@echo '========================================'

	Rscript '$(TRANSCRIPT_SCRIPT)'

	@echo 'First five transcripts with nonzero HBR_1 or UHR_1 counts:'
	xan filter 'HBR_1 > 0 || UHR_1 > 0' '$(TRANSCRIPT_MATRIX)' \
		| xan slice -l 5 \
		| xan view

	@echo '========================================'
	@echo ' Generating Gene-Level Count Matrix'
	@echo '========================================'

	Rscript '$(GENE_SCRIPT)'

	@echo 'First five genes with nonzero HBR_1 or UHR_1 counts:'
	xan filter 'HBR_1 > 0 || UHR_1 > 0' '$(GENE_MATRIX)' \
		| xan slice -l 5 \
		| xan view

	@echo '========================================'
	@echo ' RNA-Seq Batch Processing Complete'
	@echo '========================================'

	@echo 'Transcript matrix: $(TRANSCRIPT_MATRIX)'
	@echo 'Gene matrix:       $(GENE_MATRIX)'

# ------------------------------------------------------------
# Clean project
# ------------------------------------------------------------

# Return the project to its initial state.
#
# Remove:
#   - Downloaded reference files
#   - Downloaded sequencing data
#   - Salmon transcript index
#   - Individual Salmon quantification results
#   - Combined transcript and gene count matrices
#   - Download marker
#
# Preserve:
#   - Makefile
#   - design.csv
#   - src/ R scripts
#
# WARNING:
# All files inside fasta/, fastq/, gtf/, and counts/
# will be permanently deleted.

clean:
	rm -rf -- fasta/ fastq/ gtf/ counts/
	rm -f -- .data_downloaded

	@echo '========================================'
	@echo ' Project Reset Complete'
	@echo '========================================'