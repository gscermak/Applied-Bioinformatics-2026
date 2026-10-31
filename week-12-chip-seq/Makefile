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

# SRR accession number
SRR = SRR14698470

# Sample name
SAMPLE = DdrO_rep1

# Number of reads/spots to download
N = 1000000

# Number of threads used by each BWA alignment
THREADS ?= 2

# Number of samples processed in parallel
JOBS ?= 2

# Read 1 and Read 2 in FASTQ format.
# These runs are paired-end sequencing.
R1 = fastq/$(SRR)_1.fastq
R2 = fastq/$(SRR)_2.fastq

# BAM file derived from the sample name
BAM = bam/$(SAMPLE).bam

# BigWig coverage file
BW = bw/$(SAMPLE).bw

# BWA index sentinel
INDEX = $(FASTA).bwt

# Background sample name
BKG = Input_rep1

# Background BAM file
BAM_BKG = bam/$(BKG).bam

# Approximate genome size of D. radiodurans R1_13939O
GENOME_SIZE = 3279219

# Output peak file
PEAKS = peaks/$(SAMPLE)_peaks.narrowPeak

# Current directory
DIR = $(shell pwd)

# Netcat command to send commands to IGV
NC = nc -q 1 localhost 60151

# The design file
DESIGN = design.csv

# Run two jobs at a time with two alignment threads each.
# Default maximum CPU use during alignment = 2 x 2 = 4 threads.
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


# Download the four annotated GenBank records and combine them.
$(GB):
	mkdir -p $(dir $@)
	for acc in $(ACCESSIONS); do \
		curl -fsSL --http1.1 \
			"https://www.ncbi.nlm.nih.gov/sviewer/viewer.fcgi?id=$${acc}&db=nuccore&report=genbank&retmode=text"; \
	done > $@


# Convert the GenBank annotation to GFF3,
# sort it, compress it, and create a Tabix index.
gff: $(GFF)
	@ls -lh $(GFF)
	@ls -lh $(GFF).tbi


$(GFF): $(GB)
	mkdir -p $(dir $@)
	genbank_to -g $(GB) --gff3 gff/$(NAME).gff3
	awk '/^##FASTA/ {exit} {print}' gff/$(NAME).gff3 > gff/$(NAME).features.gff3
	grep '^#' gff/$(NAME).features.gff3 > gff/$(NAME).header
	grep -v '^#' gff/$(NAME).features.gff3 | \
		sort -k1,1 -k4,4n > gff/$(NAME).sorted.gff3
	cat gff/$(NAME).header gff/$(NAME).sorted.gff3 | \
		bgzip > $@
	tabix -p gff $@
	rm -f \
		gff/$(NAME).features.gff3 \
		gff/$(NAME).header \
		gff/$(NAME).sorted.gff3

# Download the paired-end FASTQ reads.
fastq: $(R1) $(R2)
	@ls -lh $(R1)
	@ls -lh $(R2)


$(R1) $(R2):
	mkdir -p $(dir $@)
	fastq-dump \
		-X $(N) \
		--split-files \
		-O $(dir $@) \
		$(SRR)
	seqkit stats $(R1) $(R2)


# Build the BWA reference index.
index: $(INDEX)


$(INDEX): $(FASTA)
	bwa index $<


# Align reads and generate BigWig coverage.
align: $(BAM) $(BW)
	@ls -lh $(BAM)
	@ls -lh $(BAM).bai
	@ls -lh $(BW)


# Align paired-end reads to the reference genome.
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


# Generate a BigWig coverage file.
$(BW): $(BAM)
	mkdir -p $(dir $@)
	bamCoverage \
		--binSize 1 \
		--bam $< \
		-o $@


# Call narrow ChIP-seq peaks relative to the Input background.
$(PEAKS): $(BAM) $(BAM_BKG)
	mkdir -p $(dir $@)
	macs3 callpeak \
		-f BAMPE \
		-g $(GENOME_SIZE) \
		-n $(SAMPLE) \
		-t $(BAM) \
		-c $(BAM_BKG) \
		--outdir peaks

peaks: $(PEAKS)
	@ls -lh $(PEAKS)


# Run the single-sample workflow.
all: genome align


# Process all samples listed in design.csv.
batch:
	cat $(DESIGN) | $(PARALLEL) \
		make \
		SRR={run} \
		SAMPLE={sample} \
		THREADS=$(THREADS) \
		all


# Load the reference, annotation, and BigWig files into IGV.
igv:
	echo "new" | $(NC)
	echo "genome $(DIR)/$(FASTA)" | $(NC)
	echo "load $(DIR)/$(GFF)" | $(NC)
	cat $(DESIGN) | $(PARALLEL) \
		'echo "load $(DIR)/bw/{sample}.bw" | $(NC)'


# Remove all generated data directories.
clean:
	rm -rf fasta gff fastq bam bw peaks


.PHONY: help genome gff fastq index align peaks all batch igv clean