# Applied Bioinformatics 2026

## Week06 - Get FASTQ fron SRA

In this exercise we are asked to indentify a run in SRA of the organism we used in the Download Genome Data exercise, download it from SRA, run a QC report, run fastQC and then rerun a QC report to determine any changes made to the data files.


1. Write a Makefile that downloads the first N reads from an SRR accession. N is a smaller subset of the total number of reads. Do not download the whole dataset.
2. Keep the Makefile generic: changing the accession number alone should be enough to download reads from a different sequencing platform.
3. Place the files in directories named after the data type.
4. Run a QC visualization on the downloaded reads and save the report.
5. Apply a QC method to the reads, then run the same visualization on the trimmed reads and save that report.
6. Write a README.md that a reviewer can follow without asking you questions.

### Download reads for your genome

Invoke the makefile to see the options:

```bash
make
```

```
Usage:
  make all      Run the complete workflow
  make clean    Remove generated files

Current settings:
  SRR=SRR27606652
  SAMPLE=412f
  N=1000
```

The contents of the makefile follows:

```bash
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
```

Run the pipeline:

```bash
make all
```

```
mkdir -p fastq
# Display SRA metadata
bio search SRR27606652
[
    {
        "run_accession": "SRR27606652",
        "sample_accession": "SAMN39484834",
        "sample_alias": "412F-DNA-002",
        "sample_description": "Gastric biopsy from WIHCC",
        "first_public": "2024-02-07",
        "country": "USA:Arizona",
        "scientific_name": "Helicobacter pylori",
        "fastq_bytes": "39204040;36008332",
        "base_count": "211527837",
        "read_count": "441603",
        "library_name": "412F_illumina",
        "library_strategy": "WGS",
        "library_source": "GENOMIC",
        "library_layout": "PAIRED",
        "instrument_platform": "ILLUMINA",
        "instrument_model": "Illumina MiSeq",
        "study_title": "Whole genome sequencing of Helicobacter pylori isolates",
        "fastq_url": [
            "https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR276/052/SRR27606652/SRR27606652_1.fastq.gz",
            "https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR276/052/SRR27606652/SRR27606652_2.fastq.gz"
        ],
        "info": "39 MB, 36 MB files; 0.4 million reads; 211.5 million sequenced bases"
    }
]
# Download the first N spots
fastq-dump -X 1000 -F \
        --outdir fastq \
        --split-files SRR27606652
Read 1000 spots for SRR27606652
Written 1000 spots for SRR27606652
# Rename downloaded reads to the sample name
mv fastq/SRR27606652_1.fastq fastq/412f_1.fastq
mv fastq/SRR27606652_2.fastq fastq/412f_2.fastq
# Statistics for raw reads
seqkit stats fastq/412f*.fastq
processed files:  2 / 2 [======================================] ETA: 0s. done
file                format  type  num_seqs  sum_len  min_len  avg_len  max_len
fastq/412f_1.fastq  FASTQ   DNA      1,000  251,000      251      251      251
fastq/412f_2.fastq  FASTQ   DNA      1,000  228,000      228      228      228
# FastQC on raw reads
fastqc fastq/412f*.fastq
null
null
Started analysis of 412f_1.fastq
Approx 100% complete for 412f_1.fastq
Analysis complete for 412f_1.fastq
Started analysis of 412f_2.fastq
Approx 100% complete for 412f_2.fastq
Analysis complete for 412f_2.fastq
# Trim adapters and low-quality bases
fastp \
        --detect_adapter_for_pe \
        --cut_tail \
        -i fastq/412f_1.fastq -I fastq/412f_2.fastq \
        -o fastq/412f_1.trimmed.fastq -O fastq/412f_2.trimmed.fastq
Detecting adapter sequence for read1...
No adapter detected for read1

Detecting adapter sequence for read2...
No adapter detected for read2

Read1 before filtering:
total reads: 1000
total bases: 251000
Q20 bases: 235898(93.9833%)
Q30 bases: 230342(91.7697%)
Q40 bases: 92(0.0366534%)

Read2 before filtering:
total reads: 1000
total bases: 228000
Q20 bases: 198040(86.8596%)
Q30 bases: 189039(82.9118%)
Q40 bases: 9(0.00394737%)

Read1 after filtering:
total reads: 949
total bases: 231871
Q20 bases: 223619(96.4411%)
Q30 bases: 220020(94.889%)
Q40 bases: 92(0.0396772%)

Read2 after filtering:
total reads: 949
total bases: 210630
Q20 bases: 192163(91.2325%)
Q30 bases: 186175(88.3896%)
Q40 bases: 9(0.0042729%)

Filtering result:
reads passed filter: 1898
reads failed due to low quality: 102
reads failed due to too many N: 0
reads failed due to too short: 0
reads failed due to adapter dimer: 0
reads with adapter trimmed: 158
bases trimmed due to adapters: 9246

Duplication rate: 0%

Insert size peak (evaluated by paired-end reads): 251

JSON report: fastp.json
HTML report: fastp.html

fastp --detect_adapter_for_pe --cut_tail -i fastq/412f_1.fastq -I fastq/412f_2.fastq -o fastq/412f_1.trimmed.fastq -O fastq/412f_2.trimmed.fastq 
fastp v1.3.6, time used: 1 seconds
# Statistics for trimmed reads
seqkit stats fastq/412f*.trimmed.fastq
processed files:  2 / 2 [======================================] ETA: 0s. done
file                        format  type  num_seqs  sum_len  min_len  avg_len  max_len
fastq/412f_1.trimmed.fastq  FASTQ   DNA        949  231,871       74    244.3      251
fastq/412f_2.trimmed.fastq  FASTQ   DNA        949  210,630       24    221.9      228
# FastQC on trimmed reads
fastqc fastq/412f*.trimmed.fastq
null
null
Started analysis of 412f_1.trimmed.fastq
Analysis complete for 412f_1.trimmed.fastq
Started analysis of 412f_2.trimmed.fastq
Analysis complete for 412f_2.trimmed.fastq
# Combined QC report
multiqc --fullnames .

/// MultiQC 🔍 v1.35

     update_config | Not cleaning sample names
       file_search | Search path: /home/user/Documents/bioinfo/412f
         searching | ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 18/18  
             fastp | Found 1 reports
            fastqc | Found 4 reports
     write_results | Data        : multiqc_data
     write_results | Report      : multiqc_report.html
           multiqc | MultiQC complete

```
### What to put in README

*1. How popular is this genome? How many datasets are available?*

A search of the NCBI Sequence Read Archive (SRA) for *Helicobacter pylori* returned 19,965 records. Of these, 5,471 were directly classified as *H. pylori*, showing that this organism is well represented in public sequencing databases. The search also showed 5,418 genome-sequencing datasets, indicating that *H. pylori* has been studied extensively.

![NCBI SRA search results for Helicobacter pylori](Screenshot%20from%202026-10-11%2016-06-19.png)

*Figure: NCBI SRA search results for Helicobacter pylori. The search returned 19,965 records, including 5,471 records directly classified as H. pylori and 5,418 genome-sequencing datasets.*

*2. What is the breakdown by sequencing strategy and platform (or some other attribute)?*

The SRA results show that *Helicobacter pylori* has been studied using several sequencing strategies and platforms. Genome sequencing accounts for 5,418 datasets, while exome sequencing accounts for 1,386; smaller categories include epigenomics and RNA-Seq. Illumina is by far the most common platform, with 17,226 records, followed by Oxford Nanopore with 1,006 and PacBio SMRT with 756. This shows that most *H. pylori* sequencing data were generated with Illumina, although long-read technologies are also well represented.

| Attribute | Count |
|---|---:|
| Genome strategy | 5,418 |
| Exome strategy | 1,386 |
| Illumina | 17,226 |
| Oxford Nanopore | 1,006 |
| PacBio SMRT | 756 |

*3. What do you find interesting or surprising?*

I found it interesting that *Helicobacter pylori* appears in such a wide variety of sequencing studies, not just whole-genome projects. Although genome sequencing is a major category, the SRA search also includes exome, epigenomic, RNA-Seq, and many other types of datasets. This suggests that *H. pylori* is being studied from many different biological perspectives, not simply by sequencing its genome.

*Did the QC step make a visual difference?*

The QC step made only a modest visual difference because the original reads were already high quality. In the MultiQC sequence-quality plot, all four files—`412f_1.fastq`, `412f_1.trimmed.fastq`, `412f_2.fastq`, and `412f_2.trimmed.fastq`—passed the per-base sequence quality check. The trimmed reads are slightly shorter and show some improvement toward the ends of the reads, but there is no dramatic before-and-after change. Overall, the figure shows that trimming cleaned the reads while preserving their already good quality.

![MultiQC sequence quality comparison before and after trimming](Screenshot%20from%202026-10-12%2009-16-34.png)

*Figure: MultiQC sequence quality histograms comparing `412f_1.fastq`, `412f_1.trimmed.fastq`, `412f_2.fastq`, and `412f_2.trimmed.fastq`. All four files passed the per-base sequence quality check, showing that the reads were already high quality before trimming.*

### Summary

This exercise used SRA data for *Helicobacter pylori* to build a simple reproducible FASTQ quality-control workflow. A subset of reads was downloaded with `fastq-dump`, summarized with `seqkit`, and examined with FastQC before and after trimming with `fastp`; MultiQC was then used to compare the results in a single report. The raw reads were already of generally high quality, so trimming produced only a modest visual change in the sequence-quality plots, while still removing adapter sequence and low-quality read ends and preserving most of the data. The exercise also showed that *H. pylori* is well represented in the SRA and has been studied using several sequencing strategies and platforms. Overall, the workflow demonstrated how to download, inspect, clean, compare, and summarize sequencing reads using a simple Makefile.