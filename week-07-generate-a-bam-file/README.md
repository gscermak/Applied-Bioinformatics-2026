# Applied Bioinformatics 2026

## Week07 - Generate a BAM file

In the Download genome data assignment you obtained a genome. In the Get FASTQ from SRA assignment you downloaded reads for that genome.

You will be asked to align the reads to the genome and create a BAM alignment file. Study the How to align method before you start.

### Align the reads to your genome

Work with a subset of N reads, not the whole dataset.

Using the genome size and the sequencing data properties, estimate the N number of reads you should download to get a coverage of at least 10x. If that number is more than a million, consider selecting a different, smaller genome unless you have more powerful hardware at your disposal. A portable laptop is not suited to a large genome alignment processes.

1. Write a Makefile that aligns the reads and creates a BAM file.
2. Run a statistics report on the BAM file.
3. Visualize the BAM file in IGV.
4. Write a README.md that a reviewer can follow.

### What to put in the README

* Explain how you arrived at N
* What percent of the reads align?
* What do the alignments look like? Do the reads show errors or variations?
* Is the coverage uniform?

Run make to see help:

```bash
make
```

```
Applied Bioinformatics 2026
Generate a BAM file

This Makefile downloads a reference genome and FASTQ reads,
indexes the genome with BWA, aligns the reads to the reference,
and creates a sorted and indexed BAM file.

Available commands:
  make all      Run the complete BAM workflow
  make genome   Download the reference genome
  make fastq    Download FASTQ reads from SRA
  make index    Index the reference genome with BWA
  make align    Align reads and create a BAM file
  make clean    Remove generated files

Configurable variables:
  GENOME_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz
  GENOME_NAME=CHC155
  SRR=SRR27606652
  N=40000
  SAMPLE_NAME=412F
```

View the makefile:

```
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
```

Run the makefile:

```bash
make
```

```
mkdir -p fasta/
curl -fsSL https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz | gunzip > fasta/CHC155.fasta
seqkit stats fasta/CHC155.fasta
file                format  type  num_seqs    sum_len    min_len    avg_len    max_len
fasta/CHC155.fasta  FASTA   DNA          1  1,696,601  1,696,601  1,696,601  1,696,601
mkdir -p fastq/
fastq-dump -X 40000 --split-files -O fastq/ SRR27606652
Read 40000 spots for SRR27606652
Written 40000 spots for SRR27606652
seqkit stats fastq/SRR27606652_1.fastq fastq/SRR27606652_2.fastq
processed files:  2 / 2 [======================================] ETA: 0s. done
file                       format  type  num_seqs     sum_len  min_len  avg_len  max_len
fastq/SRR27606652_1.fastq  FASTQ   DNA     40,000  10,040,000      251      251      251
fastq/SRR27606652_2.fastq  FASTQ   DNA     40,000   9,120,000      228      228      228
bwa index fasta/CHC155.fasta
[bwa_index] Pack FASTA... 0.01 sec
[bwa_index] Construct BWT for the packed sequence...
[bwa_index] 0.44 seconds elapse.
[bwa_index] Update BWT... 0.01 sec
[bwa_index] Pack forward-only FASTA... 0.01 sec
[bwa_index] Construct SA from BWT and Occ... 0.20 sec
[main] Version: 0.7.19-r1273
[main] CMD: bwa index fasta/CHC155.fasta
[main] Real time: 0.772 sec; CPU: 0.669 sec
mkdir -p bam/
bwa mem fasta/CHC155.fasta fastq/SRR27606652_1.fastq fastq/SRR27606652_2.fastq | samtools sort -o bam/412F.bam
[M::bwa_idx_load_from_disk] read 0 ALT contigs
[M::process] read 41754 sequences (10000083 bp)...
[M::process] read 38246 sequences (9159917 bp)...
[M::mem_pestat] # candidate unique pairs for (FF, FR, RF, RR): (0, 17026, 4, 0)
[M::mem_pestat] skip orientation FF as there are not enough pairs
[M::mem_pestat] analyzing insert size distribution for orientation FR...
[M::mem_pestat] (25, 50, 75) percentile: (334, 435, 524)
[M::mem_pestat] low and high boundaries for computing mean and std.dev: (1, 904)
[M::mem_pestat] mean and std.dev: (425.96, 136.60)
[M::mem_pestat] low and high boundaries for proper pairs: (1, 1094)
[M::mem_pestat] skip orientation RF as there are not enough pairs
[M::mem_pestat] skip orientation RR as there are not enough pairs
[M::mem_process_seqs] Processed 41754 reads in 10.419 CPU sec, 10.483 real sec
[M::mem_pestat] # candidate unique pairs for (FF, FR, RF, RR): (0, 15580, 6, 0)
[M::mem_pestat] skip orientation FF as there are not enough pairs
[M::mem_pestat] analyzing insert size distribution for orientation FR...
[M::mem_pestat] (25, 50, 75) percentile: (337, 436, 525)
[M::mem_pestat] low and high boundaries for computing mean and std.dev: (1, 901)
[M::mem_pestat] mean and std.dev: (427.99, 135.64)
[M::mem_pestat] low and high boundaries for proper pairs: (1, 1089)
[M::mem_pestat] skip orientation RF as there are not enough pairs
[M::mem_pestat] skip orientation RR as there are not enough pairs
[M::mem_process_seqs] Processed 38246 reads in 9.866 CPU sec, 9.890 real sec
[main] Version: 0.7.19-r1273
[main] CMD: bwa mem fasta/CHC155.fasta fastq/SRR27606652_1.fastq fastq/SRR27606652_2.fastq
[main] Real time: 20.504 sec; CPU: 20.394 sec
samtools index bam/412F.bam
samtools flagstat bam/412F.bam
80951 + 0 in total (QC-passed reads + QC-failed reads)
80000 + 0 primary
0 + 0 secondary
951 + 0 supplementary
0 + 0 duplicates
0 + 0 primary duplicates
70802 + 0 mapped (87.46% : N/A)
69851 + 0 primary mapped (87.31% : N/A)
80000 + 0 paired in sequencing
40000 + 0 read1
40000 + 0 read2
67888 + 0 properly paired (84.86% : N/A)
68576 + 0 with itself and mate mapped
1275 + 0 singletons (1.59% : N/A)
0 + 0 with mate mapped to a different chr
0 + 0 with mate mapped to a different chr (mapQ>=5)
```

*How I arrived at N*

```
How I determined sequencing coverage:

1. Get the CHC155 reference genome size from seqkit stats:

fasta/CHC155.fasta
sum_len = 1,696,601 bases

Genome size (G) = 1,696,601 bases


2. Get the total number of sequenced bases from the 412F FASTQ files:

fastq/SRR27606652_1.fastq
sum_len = 10,040,000 bases

fastq/SRR27606652_2.fastq
sum_len = 9,120,000 bases

Total sequenced bases (T):

T = 10,040,000 + 9,120,000
T = 19,160,000 bases


3. Calculate theoretical coverage:

Coverage = total sequenced bases / genome size

C = T / G

C = 19,160,000 / 1,696,601

C ≈ 11.3x


4. Account for the reads that actually mapped.

From samtools flagstat:

69851 primary mapped (87.31%)

So approximately 87.31% of the reads contributed useful alignments.

Estimated mapped coverage:

11.3x × 0.8731 ≈ 9.9x


RESULT:

Theoretical coverage ≈ 11.3x
Estimated mapped coverage ≈ 9.9x

Therefore, using N = 40000 gave us approximately the 10x mapped coverage we were aiming for.
```

*What percent of the reads align?*

```
80,000 real reads
~87% mapped
~85% mapped properly as pairs
~1.6% had only one mate map
```

*What do the alignments look like? Do the reads show errors or variations?* 

*Is the coverage uniform?*

The 412F reads align well across much of the CHC155 reference region, but the coverage is not uniform. The gray portions of the aligned reads represent bases that match the reference, while the colored bases indicate positions where the 412F reads differ from the CHC155 reference. Repeated colored bases at the same position across several reads are consistent with real sequence variation, while isolated colored bases may represent sequencing error or lower-confidence differences. The coverage track also rises and falls across the region, showing that some positions are covered by many reads while others have much lower coverage.

![IGV view of 412F reads aligned to the CHC155 reference](Screenshot%20from%202026-10-13%2009-01-58.png)

*Figure: IGV view of the 412F BAM file aligned to the CHC155 reference genome. The upper coverage track shows that read depth varies across the region rather than remaining uniform. The gray read alignments indicate agreement with the reference sequence, while colored bases mark nucleotide differences from the reference. Vertical groups of the same colored base across multiple reads are stronger candidates for real variants, whereas isolated colored bases may reflect sequencing error.*

### Summary

In this exercise, we built a Makefile workflow that downloaded the CHC155 reference genome and 412F sequencing reads, indexed the reference with BWA, aligned the reads, and produced a sorted and indexed BAM file. By increasing the FASTQ subset to 40,000 read pairs, we obtained about 11.3× theoretical coverage and roughly 10× mapped coverage, with about 87% of primary reads mapping to the CHC155 reference and about 85% mapping as proper pairs. Viewing the BAM file in IGV showed that coverage varies across the genome rather than remaining uniform, while most aligned bases match the reference and colored bases reveal candidate sequence differences between 412F and CHC155. Overall, the exercise demonstrated the complete path from raw sequencing reads to an interpretable BAM alignment and provided a practical introduction to coverage, mapping quality, and visual identification of possible variants.