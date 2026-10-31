# URL of the FASTA reference genome
GCF_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz

# URL of the GFF reference genome annotation
GFF_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.gff.gz

# Name of the reference genome
GENOME_NAME = CHC155

# Genome FASTA file
GENOME_FASTA = fasta/$(GENOME_NAME).fasta

# GFF annotation file
GFF = gff/$(GENOME_NAME).gff

# Default SRR accession number
SRR = SRR27606652

# Default sample name
SAMPLE_NAME = 412F

# Number of reads to download
N = 40000

# FASTQ files
FASTQ_1 = fastq/$(SRR)_1.fastq
FASTQ_2 = fastq/$(SRR)_2.fastq


# BAM file derived from the sample name
BAM = bam/$(SAMPLE_NAME).bam
# BWA index sentinel
INDEX = $(GENOME_FASTA).bwt

# Variant output files
VCF = vcf/variants.vcf.gz
STATS = vcf/variants.stats.txt

# Annotation parameters for mpileup
ANN = -d 100 --annotate 'INFO/AD,FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/SP'

# Call parameters
CALL = --ploidy 2 --annotate 'FORMAT/GQ'

# Current directory
DIR = $(shell pwd)

# Command to send commands to IGV
IGV = nc -q 1 localhost 60151

# Design file
DESIGN = design.csv

# GNU Parallel command
PARALLEL = parallel --colsep , --header : --eta -j 2


# ------------------------------------------------------------
# All definitions above this line. All code below this line.
# ------------------------------------------------------------

usage:
	@echo "#"
	@echo "# Variant calling with bcftools"
	@echo "#"
	@echo "# GENOME_NAME=$(GENOME_NAME)"
	@echo "# GENOME_FASTA=$(GENOME_FASTA)"
	@echo "# SAMPLE_NAME=$(SAMPLE_NAME)"
	@echo "# SRR=$(SRR)"
	@echo "# N=$(N)"
	@echo "#"
	@echo "# BAM=$(BAM)"
	@echo "# VCF=$(VCF)"
	@echo "# STATS=$(STATS)"
	@echo "#"
	@echo "# Available targets:"
	@echo "#   make all    - process one sample and call variants"
	@echo "#   make batch  - process samples from design.csv in parallel and call variants"
	@echo "#   make igv    - visualize the variant results in IGV"
	@echo "#   make clean  - remove all generated files and directories"
	@echo "#"


# Download the genome.
genome: $(GENOME_FASTA)

$(GENOME_FASTA):
	mkdir -p $(dir $@)
	curl -fsSL $(GCF_URL) | gunzip > $@
	seqkit stats $@


# Download the GFF annotation.
gff: $(GFF)
	ls -lh $(GFF)

$(GFF):
	mkdir -p $(dir $@)
	curl -fsSL $(GFF_URL) | gunzip -c > $@


# Download the FASTQ files.
fastq: $(FASTQ_1) $(FASTQ_2)

$(FASTQ_1) $(FASTQ_2):
	mkdir -p $(dir $@)
	fastq-dump -X $(N) --split-files -O $(dir $@) $(SRR)
	seqkit stats $(FASTQ_1) $(FASTQ_2)


# Index the genome.
index: $(INDEX)

$(INDEX): $(GENOME_FASTA)
	bwa index $<


# Align the FASTQ files to the genome.
align: $(BAM)
	ls -lh $(BAM)

$(BAM): $(INDEX) $(FASTQ_1) $(FASTQ_2)
	mkdir -p $(dir $@)
	bwa mem $(GENOME_FASTA) $(FASTQ_1) $(FASTQ_2) | samtools sort -o $@
	samtools index $@
	samtools flagstat $@


# Call variants using all BAM files currently in the bam directory.
# This works with either one BAM or multiple BAMs.
call:
	mkdir -p $(dir $(VCF))

	bcftools mpileup $(ANN) -O u \
		-f $(GENOME_FASTA) \
		bam/*.bam | \
		bcftools call $(CALL) -mv -O u | \
		bcftools norm -f $(GENOME_FASTA) -d all -O u | \
		bcftools sort --write-index -O z -o $(VCF)

	bcftools stats $(VCF) > $(STATS)

	grep '^SN' $(STATS)

	ls -lh $(VCF)


# Run the workflow for a single sample.
all: gff genome align
	$(MAKE) call


# Run the workflow using the design file.
batch:
	# Prepare the shared reference genome, annotation, and BWA index.
	$(MAKE) genome
	$(MAKE) gff
	$(MAKE) index

	# Download and align samples from the design file in parallel.
	cat $(DESIGN) | head -10 | $(PARALLEL) \
		$(MAKE) \
		SRR={run_accession} \
		SAMPLE_NAME={sample_alias} \
		N=$(N) \
		align

	# Call variants using all BAM files produced by the batch.
	$(MAKE) call


# Visualize the variant results with IGV.
igv:
	echo "new" | $(IGV)
	echo "genome $(DIR)/$(GENOME_FASTA)" | $(IGV)
	echo "load $(DIR)/$(GFF)" | $(IGV)
	echo "load $(DIR)/$(VCF)" | $(IGV)


# Remove all generated files and directories.
clean:
	rm -rf fasta gff fastq bam vcf


.PHONY: usage all batch genome gff fastq index align call igv clean