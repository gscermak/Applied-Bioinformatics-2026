# GenBank accessions for the four replicons of the
# Deinococcus radiodurans R1 ATCC 13939O reference genome.
ACCESSIONS = CP068791.1 CP068792.1 CP068793.1 CP068794.1

# Name of the reference genome
NAME = R1_13939O

# Genome FASTA file
FASTA = fasta/$(NAME).fa.gz

# GenBank annotation file
GB = gff/$(NAME).gb

# GFF annotation file
GFF = gff/$(NAME).gff.gz

# SRR accession number for the default ChIP sample
SRR = SRR14698470

# Default ChIP sample name
SAMPLE = DdrO_rep1

# Number of spots to download
N = 1000000

# Number of threads used by each BWA alignment
THREADS ?= 2

# Number of samples processed in parallel
JOBS ?= 2

# Paired-end FASTQ files for the current ChIP sample
R1 = fastq/$(SRR)_1.fastq
R2 = fastq/$(SRR)_2.fastq

# BAM file for the current ChIP sample
BAM = bam/$(SAMPLE).bam

# BigWig coverage file for the current ChIP sample
BW = bw/$(SAMPLE).bw

# BWA index sentinel
INDEX = $(FASTA).bwt

# Input control sample
CONTROL = Input_rep1

# SRA accession for the Input control
CONTROL_SRR = SRR14698473

# Paired-end FASTQ files for the Input control
CONTROL_R1 = fastq/$(CONTROL_SRR)_1.fastq
CONTROL_R2 = fastq/$(CONTROL_SRR)_2.fastq

# BAM and BigWig files for the Input control
BAM_CONTROL = bam/$(CONTROL).bam
BW_CONTROL = bw/$(CONTROL).bw

# Effective genome size of D. radiodurans R1_13939O
GENOME_SIZE = 3279219

# Output peak file for the current ChIP sample
PEAKS = peaks/$(SAMPLE)_peaks.narrowPeak

# Current directory
DIR = $(shell pwd)

# Netcat command to send commands to IGV
NC = nc -q 1 localhost 60151

# Design file
DESIGN = design.csv

# Run multiple samples in parallel
PARALLEL = parallel --eta --colsep , --header : --jobs $(JOBS) --lb

# Safety settings
SHELL = bash
.SHELLFLAGS = -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules


# --- All definitions above this line. All code below this line ---


.DEFAULT_GOAL := help


help:
	@echo
	@echo "DdrO ChIP-seq workflow"
	@echo
	@echo "Usage:"
	@echo "  make all"
	@echo "  make batch"
	@echo "  make control"
	@echo "  make peaks"
	@echo "  make igv"
	@echo "  make clean"
	@echo
	@echo "Current settings:"
	@echo "  NAME      = $(NAME)"
	@echo "  SRR       = $(SRR)"
	@echo "  SAMPLE    = $(SAMPLE)"
	@echo "  N         = $(N)"
	@echo "  THREADS   = $(THREADS)"
	@echo "  JOBS      = $(JOBS)"
	@echo
	@echo "CPU use during parallel alignment:"
	@echo "  $(JOBS) jobs x $(THREADS) threads = up to $$(( $(JOBS) * $(THREADS) )) threads"
	@echo


# ---------------------------------------------------------
# Reference genome
# ---------------------------------------------------------

# Download and prepare the reference genome and annotation.
genome: $(FASTA) $(GFF)
	@ls -lh $(FASTA)
	@ls -lh $(FASTA).fai
	@ls -lh $(GFF)
	@ls -lh $(GFF).tbi


# Download the four reference replicons, combine them,
# compress the FASTA, and create the FASTA index.
$(FASTA):
	mkdir -p $(dir $@)
	for acc in $(ACCESSIONS); do \
		curl -fsSL --http1.1 \
			"https://www.ncbi.nlm.nih.gov/sviewer/viewer.fcgi?id=$${acc}&db=nuccore&report=fasta&retmode=text"; \
	done | bgzip > $@
	samtools faidx $@
	seqkit stats $@


# ---------------------------------------------------------
# Genome annotation
# ---------------------------------------------------------

# Download the four annotated GenBank records and combine them.
$(GB):
	mkdir -p $(dir $@)
	for acc in $(ACCESSIONS); do \
		curl -fsSL --http1.1 \
			"https://www.ncbi.nlm.nih.gov/sviewer/viewer.fcgi?id=$${acc}&db=nuccore&report=genbank&retmode=text"; \
	done > $@


# Convert GenBank annotation to GFF3,
# remove the embedded FASTA section,
# sort, compress, and create a Tabix index.
gff: $(GFF)
	@ls -lh $(GFF)
	@ls -lh $(GFF).tbi


$(GFF): $(GB)
	mkdir -p $(dir $@)
	genbank_to -g $(GB) --gff3 gff/$(NAME).gff3
	awk '/^##FASTA/ {exit} {print}' \
		gff/$(NAME).gff3 > gff/$(NAME).features.gff3
	grep '^#' \
		gff/$(NAME).features.gff3 > gff/$(NAME).header
	grep -v '^#' \
		gff/$(NAME).features.gff3 | \
		sort -k1,1 -k4,4n > gff/$(NAME).sorted.gff3
	cat \
		gff/$(NAME).header \
		gff/$(NAME).sorted.gff3 | \
		bgzip > $@
	tabix -p gff $@
	rm -f \
		gff/$(NAME).features.gff3 \
		gff/$(NAME).header \
		gff/$(NAME).sorted.gff3


# ---------------------------------------------------------
# BWA index
# ---------------------------------------------------------

index: $(INDEX)


$(INDEX): $(FASTA)
	bwa index $<


# ---------------------------------------------------------
# ChIP FASTQ files
# ---------------------------------------------------------

fastq: $(R1) $(R2)
	@ls -lh $(R1)
	@ls -lh $(R2)


# fastq-dump --split-files creates both paired-end files
# in one operation. &: tells Make that both files are
# produced together by the same recipe.
$(R1) $(R2) &:
	mkdir -p fastq
	fastq-dump \
		-X $(N) \
		--split-files \
		-O fastq \
		$(SRR)
	seqkit stats $(R1) $(R2)


# ---------------------------------------------------------
# ChIP alignment
# ---------------------------------------------------------

align: $(BAM) $(BW)
	@ls -lh $(BAM)
	@ls -lh $(BAM).bai
	@ls -lh $(BW)


$(BAM): $(INDEX) $(R1) $(R2)
	mkdir -p $(dir $@)
	bwa mem \
		-t $(THREADS) \
		$(FASTA) \
		$(R1) \
		$(R2) | \
		samtools sort -o $@
	samtools index $@
	samtools flagstat $@


$(BW): $(BAM)
	mkdir -p $(dir $@)
	bamCoverage \
		--binSize 1 \
		--bam $< \
		-o $@


# ---------------------------------------------------------
# Input control
# ---------------------------------------------------------

# Download the paired-end Input control FASTQ files.
# These are also a grouped target so fastq-dump runs once.
$(CONTROL_R1) $(CONTROL_R2) &:
	mkdir -p fastq
	fastq-dump \
		-X $(N) \
		--split-files \
		-O fastq \
		$(CONTROL_SRR)
	seqkit stats $(CONTROL_R1) $(CONTROL_R2)


# Align the Input control.
$(BAM_CONTROL): $(INDEX) $(CONTROL_R1) $(CONTROL_R2)
	mkdir -p $(dir $@)
	bwa mem \
		-t $(THREADS) \
		$(FASTA) \
		$(CONTROL_R1) \
		$(CONTROL_R2) | \
		samtools sort -o $@
	samtools index $@
	samtools flagstat $@


# Generate the Input control BigWig coverage file.
$(BW_CONTROL): $(BAM_CONTROL)
	mkdir -p $(dir $@)
	bamCoverage \
		--binSize 1 \
		--bam $< \
		-o $@


# Build the complete Input control.
control: $(BAM_CONTROL) $(BW_CONTROL)
	@ls -lh $(BAM_CONTROL)
	@ls -lh $(BAM_CONTROL).bai
	@ls -lh $(BW_CONTROL)


# ---------------------------------------------------------
# Peak calling
# ---------------------------------------------------------

# Call narrow DdrO ChIP-seq peaks relative to the Input control.
$(PEAKS): $(BAM) $(BAM_CONTROL)
	mkdir -p $(dir $@)
	macs3 callpeak \
		-f BAMPE \
		-g $(GENOME_SIZE) \
		-n $(SAMPLE) \
		-t $(BAM) \
		-c $(BAM_CONTROL) \
		--outdir peaks


peaks: $(PEAKS)
	@ls -lh $(PEAKS)


# ---------------------------------------------------------
# Complete workflows
# ---------------------------------------------------------

# Complete single-sample workflow.
#
# Starting from an empty project this will:
#   1. prepare the reference and annotation
#   2. process the selected DdrO sample
#   3. process the Input control
#   4. call peaks
all: genome align control peaks


# Complete batch workflow.
#
# The shared reference and Input control are prepared first.
# The Input row is excluded because Input is the control,
# not a ChIP treatment for peak calling.
batch: genome control
	awk -F, 'NR == 1 || $$2 != "Input"' $(DESIGN) | \
		$(PARALLEL) \
		make \
		SRR={run} \
		SAMPLE={sample} \
		THREADS=$(THREADS) \
		all


# ---------------------------------------------------------
# IGV
# ---------------------------------------------------------

# Load the reference, annotation, and all BigWig files into IGV.
igv:
	echo "new" | $(NC)
	echo "genome $(DIR)/$(FASTA)" | $(NC)
	echo "load $(DIR)/$(GFF)" | $(NC)
	for file in $(DIR)/bw/*.bw; do \
		echo "load $$file" | $(NC); \
	done


# ---------------------------------------------------------
# Clean
# ---------------------------------------------------------

clean:
	rm -rf fasta gff fastq bam bw peaks


.PHONY: \
	help \
	genome \
	gff \
	index \
	fastq \
	align \
	control \
	peaks \
	all \
	batch \
	igv \
	clean