# Applied Bioinformatics 2026
# Download a subset of SRA reads, rename them to the sample name,
# run QC, trim reads, run QC again, and summarize with MultiQC.

# Variables
SRR ?= SRR27606652
N ?= 1000
SAMPLE ?= 412f

# Input reads
R1 = fastq/$(SAMPLE)_1.fastq
R2 = fastq/$(SAMPLE)_2.fastq

# Trimmed reads
T1 = fastq/$(SAMPLE)_1.trimmed.fastq
T2 = fastq/$(SAMPLE)_2.trimmed.fastq

# Show help when "make" is run by itself
.DEFAULT_GOAL := help

.PHONY: help all clean

# --- All definitions above this line. All code below this line ---

help:
	@echo "Usage:"
	@echo "  make all      Run the complete workflow"
	@echo "  make clean    Remove generated files"
	@echo
	@echo "Current settings:"
	@echo "  SRR=$(SRR)"
	@echo "  SAMPLE=$(SAMPLE)"
	@echo "  N=$(N)"

all:
	mkdir -p fastq

	# Display SRA metadata
	bio search $(SRR)

	# Download the first N spots
	fastq-dump -X $(N) -F \
		--outdir fastq \
		--split-files $(SRR)

	# Rename downloaded reads to the sample name
	mv fastq/$(SRR)_1.fastq fastq/$(SAMPLE)_1.fastq
	mv fastq/$(SRR)_2.fastq fastq/$(SAMPLE)_2.fastq

	# Statistics for raw reads
	seqkit stats fastq/$(SAMPLE)*.fastq

	# FastQC on raw reads
	fastqc fastq/$(SAMPLE)*.fastq

	# Trim adapters and low-quality bases
	fastp \
		--detect_adapter_for_pe \
		--cut_tail \
		-i $(R1) -I $(R2) \
		-o $(T1) -O $(T2)

	# Statistics for trimmed reads
	seqkit stats fastq/$(SAMPLE)*.trimmed.fastq

	# FastQC on trimmed reads
	fastqc fastq/$(SAMPLE)*.trimmed.fastq

	# Combined QC report
	multiqc --fullnames .

clean:
	rm -rf fastq
	rm -rf multiqc_data multiqc_report.html
	rm -f fastp.html fastp.json