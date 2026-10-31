# Applied Bioinformatics 2026
# Single-sample alignment and variant calling pipeline
#
# Default example:
# Helicobacter pylori CHC155
# BioProject PRJNA1066305
# SRR27606652 / 412F
#
# SRR, SAMPLE_NAME, and N may be overridden
# from the command line or by a wrapper Makefile.


# URL of the FASTA reference genome.
GCF_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz

# URL of the GFF reference genome annotation.
GFF_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.gff.gz

# Name of the reference genome.
GENOME_NAME = CHC155

# Reference FASTA.
GENOME_FASTA = fasta/$(GENOME_NAME).fasta

# FASTA samtools index.
FASTA_INDEX = $(GENOME_FASTA).fai

# BWA index sentinel.
BWA_INDEX = $(GENOME_FASTA).bwt

# Reference GFF annotation.
GFF = gff/$(GENOME_NAME).gff

# BGZF-compressed GFF.
GFF_BGZ = $(GFF).gz

# Tabix GFF index.
GFF_INDEX = $(GFF_BGZ).tbi

# SRR accession number.
SRR = SRR27606652

# Sample name.
SAMPLE_NAME = 412F

# Number of spots to download.
N = 40000

# FASTQ files.
FASTQ_1 = fastq/$(SRR)_1.fastq
FASTQ_2 = fastq/$(SRR)_2.fastq

# BAM file.
BAM = bam/$(SAMPLE_NAME).bam

# Output single-sample VCF.
VCF = vcf/$(SAMPLE_NAME).vcf.gz

# Read group used to identify the sample in the BAM.
READ_GROUP = @RG\tID:$(SAMPLE_NAME)\tSM:$(SAMPLE_NAME)

# Annotation parameters for bcftools mpileup.
ANN = -d 100 --annotate 'INFO/AD,FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/SP'

# Parameters for bcftools call.
CALL = --ploidy 2 --annotate 'FORMAT/GQ'

# Use Bash.
SHELL = bash

# Stop on errors, undefined shell variables, and failed pipelines.
.SHELLFLAGS = -eu -o pipefail -c

# Delete incomplete targets when a recipe fails.
.DELETE_ON_ERROR:

# Warn about undefined Make variables.
MAKEFLAGS += --warn-undefined-variables

# Disable Make's built-in rules.
MAKEFLAGS += --no-builtin-rules


# ------------------------------------------------------------
# All definitions above this line. All code below this line.
# ------------------------------------------------------------


# Default target.
help:
	@echo "#"
	@echo "# Applied Bioinformatics 2026"
	@echo "#"
	@echo "# Single-sample alignment and variant calling"
	@echo "#"
	@echo "# GENOME_NAME=$(GENOME_NAME)"
	@echo "# GENOME_FASTA=$(GENOME_FASTA)"
	@echo "# FASTA_INDEX=$(FASTA_INDEX)"
	@echo "# GFF=$(GFF)"
	@echo "# GFF_INDEX=$(GFF_INDEX)"
	@echo "#"
	@echo "# SAMPLE_NAME=$(SAMPLE_NAME)"
	@echo "# SRR=$(SRR)"
	@echo "# N=$(N)"
	@echo "#"
	@echo "# BAM=$(BAM)"
	@echo "# VCF=$(VCF)"
	@echo "#"
	@echo "# Targets:"
	@echo "#   make reference"
	@echo "#   make fastq"
	@echo "#   make align"
	@echo "#   make call"
	@echo "#   make all"
	@echo "#   make clean"
	@echo "#"


# ------------------------------------------------------------
# Prepare the complete shared reference.
# ------------------------------------------------------------

reference: $(GENOME_FASTA) $(FASTA_INDEX) $(BWA_INDEX) \
           $(GFF) $(GFF_BGZ) $(GFF_INDEX)


# Download the reference FASTA.
$(GENOME_FASTA):
	mkdir -p $(dir $@)
	curl -fsSL $(GCF_URL) | gunzip -c > $@
	seqkit stats $@


# Create the samtools FASTA index.
$(FASTA_INDEX): $(GENOME_FASTA)
	samtools faidx $<


# Create the BWA reference indexes.
$(BWA_INDEX): $(GENOME_FASTA)
	bwa index $<


# Download the reference GFF.
$(GFF):
	mkdir -p $(dir $@)
	curl -fsSL $(GFF_URL) | gunzip -c > $@
	ls -lh $@


# BGZF-compress the GFF.
$(GFF_BGZ): $(GFF)
	bgzip -c $< > $@


# Create the Tabix index for the GFF.
$(GFF_INDEX): $(GFF_BGZ)
	tabix -p gff $<


# ------------------------------------------------------------
# Download the sample reads.
# ------------------------------------------------------------

fastq: $(FASTQ_1) $(FASTQ_2)


$(FASTQ_1) $(FASTQ_2):
	mkdir -p $(dir $@)
	fastq-dump -X $(N) --split-files -O $(dir $@) $(SRR)
	seqkit stats $(FASTQ_1) $(FASTQ_2)


# ------------------------------------------------------------
# Align one sample.
# ------------------------------------------------------------

align: $(BAM)
	ls -lh $(BAM)


# The BAM requires the fully prepared shared reference
# plus this sample's FASTQ files.
$(BAM): $(GENOME_FASTA) $(FASTA_INDEX) $(BWA_INDEX) \
        $(GFF) $(GFF_BGZ) $(GFF_INDEX) \
        $(FASTQ_1) $(FASTQ_2)

	mkdir -p $(dir $@)

	bwa mem \
		-R '$(READ_GROUP)' \
		$(GENOME_FASTA) \
		$(FASTQ_1) \
		$(FASTQ_2) | \
		samtools sort -o $@

	samtools index $@
	samtools flagstat $@


# ------------------------------------------------------------
# Call variants for one sample.
# ------------------------------------------------------------

call: $(VCF)
	ls -lh $(VCF)


$(VCF): $(BAM) $(GENOME_FASTA)
	mkdir -p $(dir $@)

	bcftools mpileup $(ANN) \
		-O u \
		-f $(GENOME_FASTA) \
		$(BAM) | \
	bcftools call $(CALL) \
		-mv \
		-O u | \
	bcftools norm \
		-f $(GENOME_FASTA) \
		-d all \
		-O u | \
	bcftools sort \
		--write-index \
		-O z \
		-o $(VCF)


# ------------------------------------------------------------
# Run the complete single-sample pipeline.
# ------------------------------------------------------------

all: reference call


# ------------------------------------------------------------
# Remove all generated files and directories.
# ------------------------------------------------------------

clean:
	rm -rf fasta fastq gff bam vcf


.PHONY: help reference fastq align call all clean