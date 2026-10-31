# Applied Bioinformatics 2026
# Generate a BAM file
#
# This Makefile downloads a reference genome and FASTQ reads,
# indexes the genome with BWA, aligns the reads to the reference,
# and creates a sorted and indexed BAM file.

# URL of the reference genome
GENOME_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz

# Name of the reference genome
GENOME_NAME = CHC155

# Genome fasta file
GENOME_FASTA = fasta/$(GENOME_NAME).fasta

# SRA accession number
SRR = SRR27606652

# Number of reads to download
N = 40000

# Fastq files
FASTQ_1 = fastq/$(SRR)_1.fastq
FASTQ_2 = fastq/$(SRR)_2.fastq

# Sample name
SAMPLE_NAME = 412F

# BAM file derived from the sample name
BAM = bam/$(SAMPLE_NAME).bam

# BWA index sentinel
INDEX = $(GENOME_FASTA).bwt


# --- All definitions above this line. All code below this line ---

# Show available commands and variables.
help:
	@echo "Applied Bioinformatics 2026"
	@echo "Generate a BAM file"
	@echo ""
	@echo "This Makefile downloads a reference genome and FASTQ reads,"
	@echo "indexes the genome with BWA, aligns the reads to the reference,"
	@echo "and creates a sorted and indexed BAM file."
	@echo ""
	@echo "Available commands:"
	@echo "  make all      Run the complete BAM workflow"
	@echo "  make genome   Download the reference genome"
	@echo "  make fastq    Download FASTQ reads from SRA"
	@echo "  make index    Index the reference genome with BWA"
	@echo "  make align    Align reads and create a BAM file"
	@echo "  make clean    Remove generated files"
	@echo ""
	@echo "Configurable variables:"
	@echo "  GENOME_URL=$(GENOME_URL)"
	@echo "  GENOME_NAME=$(GENOME_NAME)"
	@echo "  SRR=$(SRR)"
	@echo "  N=$(N)"
	@echo "  SAMPLE_NAME=$(SAMPLE_NAME)"

# Run all steps.
all: genome fastq index align

# Download the genome.
genome: $(GENOME_FASTA)

$(GENOME_FASTA):
	mkdir -p $(dir $@)
	curl -fsSL $(GENOME_URL) | gunzip > $@
	seqkit stats $@

# Download FASTQ files from SRA.
fastq: $(FASTQ_1) $(FASTQ_2)

$(FASTQ_1) $(FASTQ_2):
	mkdir -p $(dir $@)
	fastq-dump -X $(N) --split-files -O $(dir $@) $(SRR)
	seqkit stats $(FASTQ_1) $(FASTQ_2)

# Index the genome.
index: $(INDEX)

$(INDEX): $(GENOME_FASTA)
	bwa index $<

# Align the FASTQ reads to the reference genome.
align: $(BAM)

$(BAM): $(INDEX) $(FASTQ_1) $(FASTQ_2)
	mkdir -p $(dir $@)
	bwa mem $(GENOME_FASTA) $(FASTQ_1) $(FASTQ_2) | samtools sort -o $@
	samtools index $@
	samtools flagstat $@

# Remove generated files.
clean:
	rm -rf fasta fastq bam

.PHONY: help all genome fastq index align clean