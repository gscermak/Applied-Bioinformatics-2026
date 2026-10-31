# Applied Bioinformatics 2026
# Generic multi-sample VCF wrapper
#
# Default example:
# Helicobacter pylori CHC155
# BioProject PRJNA1066305
#
# The wrapper:
#   1. Prepares the shared reference.
#   2. Runs bcftools.2026.mk once for each sample through align.
#   3. Jointly calls variants across all BAM files.
#   4. Produces one multisample VCF file.


# Inner single-sample Makefile.
PIPELINE = bcftools.2026.mk


# Inner Makefile target used for each sample.
INNER_TARGET = align


# URL of the FASTA reference genome.
GCF_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz


# URL of the GFF reference genome annotation.
GFF_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.gff.gz


# Name of the reference genome.
GENOME_NAME = CHC155


# Reference FASTA.
GENOME_FASTA = fasta/$(GENOME_NAME).fasta


# Samples.
# Format: SRR:SAMPLE_NAME
SAMPLES = \
	SRR27606653:408F \
	SRR27606652:412F \
	SRR27606651:427F


# Number of reads/spots to download for each sample.
N = 40000


# Extract sample names from SAMPLES.
SAMPLE_NAMES = $(foreach s,$(SAMPLES),$(word 2,$(subst :, ,$(s))))


# BAM directory.
BAM_DIR = bam


# Build BAM filenames automatically.
BAMS = $(addprefix $(BAM_DIR)/,$(addsuffix .bam,$(SAMPLE_NAMES)))


# Create one wrapper target for each sample.
SAMPLE_TARGETS = $(addprefix sample-,$(SAMPLE_NAMES))


# VCF directory.
VCF_DIR = vcf


# Multisample VCF produced by the joint variant call.
MULTI_VCF = $(VCF_DIR)/multisample.vcf.gz


# Statistics file for the multisample VCF.
STATS = $(VCF_DIR)/multisample.stats.txt


# Maximum mpileup depth.
MAX_DEPTH = 100


# mpileup annotations.
MPILEUP_ANNOTATE = INFO/AD,FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/SP


# Variant calling parameters.
PLOIDY = 2
CALL_ANNOTATE = FORMAT/GQ


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


.PHONY: help all reference samples jointcall clean $(SAMPLE_TARGETS)


# Default target.
help:
	@echo "#"
	@echo "# Applied Bioinformatics 2026"
	@echo "# Generic multi-sample VCF pipeline"
	@echo "#"
	@echo "# GENOME_NAME=$(GENOME_NAME)"
	@echo "#"
	@echo "# Samples:"
	@echo "#   $(SAMPLE_NAMES)"
	@echo "#"
	@echo "# Number of reads:"
	@echo "#   N=$(N)"
	@echo "#"
	@echo "# BAM files:"
	@echo "#   $(BAMS)"
	@echo "#"
	@echo "# Multisample VCF:"
	@echo "#   $(MULTI_VCF)"
	@echo "#"
	@echo "# Targets:"
	@echo "#   make -f multisample-vcf.mk reference"
	@echo "#   make -f multisample-vcf.mk samples"
	@echo "#   make -f multisample-vcf.mk jointcall"
	@echo "#   make -f multisample-vcf.mk all"
	@echo "#   make -f multisample-vcf.mk clean"
	@echo "#"
	@echo "# Dry run:"
	@echo "#   make -n -f multisample-vcf.mk all"
	@echo "#"


# Run the complete workflow.
all: jointcall


# Prepare the shared reference once.
reference:
	$(MAKE) -f $(PIPELINE) reference \
		GCF_URL=$(GCF_URL) \
		GFF_URL=$(GFF_URL) \
		GENOME_NAME=$(GENOME_NAME)


# Build all sample BAM files.
samples: reference $(SAMPLE_TARGETS)


# Generate one recursive alignment target for each sample.
define SAMPLE_RULE

sample-$(word 2,$(subst :, ,$(1))):
	$(MAKE) -f $(PIPELINE) $(INNER_TARGET) \
		GCF_URL=$(GCF_URL) \
		GFF_URL=$(GFF_URL) \
		GENOME_NAME=$(GENOME_NAME) \
		SRR=$(word 1,$(subst :, ,$(1))) \
		SAMPLE_NAME=$(word 2,$(subst :, ,$(1))) \
		N=$(N)

endef


# Create all sample targets.
$(foreach s,$(SAMPLES),$(eval $(call SAMPLE_RULE,$(s))))


# Jointly call variants across all BAM files
# and produce one multisample VCF.
jointcall: samples
	mkdir -p $(VCF_DIR)

	bcftools mpileup \
		-d $(MAX_DEPTH) \
		--annotate '$(MPILEUP_ANNOTATE)' \
		-O u \
		-f $(GENOME_FASTA) \
		$(BAMS) | \
	bcftools call \
		--ploidy $(PLOIDY) \
		--annotate '$(CALL_ANNOTATE)' \
		-mv \
		-O u | \
	bcftools norm \
		-f $(GENOME_FASTA) \
		-d all \
		-O u | \
	bcftools sort \
		--write-index \
		-O z \
		-o $(MULTI_VCF)

	bcftools stats $(MULTI_VCF) > $(STATS)


# Clean the complete workflow.
clean:
	$(MAKE) -f $(PIPELINE) clean \
		GCF_URL=$(GCF_URL) \
		GFF_URL=$(GFF_URL) \
		GENOME_NAME=$(GENOME_NAME)