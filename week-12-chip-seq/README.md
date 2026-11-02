# Applied Bioinformatics 2026

## Week12 - ChIP-seq

## Introduction

### ChIP-seq

In the Create a workflow assignment you built a pipeline that calls variants for many samples from a design file.

You are now asked to reuse that pipeline. You may keep the same genome or select a new one. But for sequencing data, select ChIP-seq or ATAC-seq, and replace the variant call with peak calling.

Recall that in SRA you can filter the data to show you only certain library types.

Course materials:

* Peak detection
* Introduction to ChIP-seq
* ChIP-seq analysis
* Nucleosome positioning

### Call peaks

Find a BioProject with ChIP-seq or ATAC-seq reads for the genome you have been using. The project should have at least two replicates in both groups.

1. You may start from the Makefile you already have and replace the variant-calling step with peak calling. You can use a Makefile someone else has written, see: Nucleosome positioning.
2. Create a design.csv describing the samples and their groups.
3. Generate peak calls for each sample.
4. Load the coverage tracks and the peak files in IGV and 5. compare the calls within each replicate group.
Write a README.md that a reviewer can follow.

Implementation suggestions:

Since peak calling requires both a background and a condition you might want to add a background target to the Makefile to process the background samples. Many solutions are possible here.

1. make background could run the workflow for the background samples.
2. make peaks could call peaks for a condition relative to the background.

It is not required to do it this way. It is just a suggestion.

What to put in the README¶

1. Summarize the project: the assay, the organism, how many samples, and what the control and the condition are.
2. Describe how to run the workflow so a reviewer can reproduce it.
3. How many peaks were called in each sample?
4. How consistent are the peak calls within replicates? Show one region where the replicates agree and one region where they do not.

Include screenshots of both regions from IGV.

### Introduction to ChIP-seq

Proteins bind to DNA for many reasons. Some proteins help **turn genes on or off**, some help organize and package DNA, and others are involved in DNA repair, replication, or chromosome structure. **ChIP-seq** is a method used to determine **where a particular protein is associated with DNA across the genome**.

The basic idea is to preserve the protein-DNA interaction, break the DNA into smaller pieces, and use an antibody that recognizes the protein of interest.

```text
Before fragmentation

DNA =====================================

               [Protein]
                  |
                  v

DNA =============[====]==================
```

The DNA is then broken into many fragments. Some fragments have the protein of interest attached, while most do not.

```text
After fragmentation

------     ------[Protein]------     ------     ------[Protein]------

  DNA            DNA + protein        DNA            DNA + protein
```

An antibody that recognizes the protein is added. It pulls out the protein together with the DNA fragment attached to it.

```text
Antibody selection

------[Protein]------        ------[Protein]------
        |                            |
     antibody                     antibody
        |                            |
        v                            v

------ selected DNA ------    ------ selected DNA ------
```

The protein is then removed, leaving the enriched DNA fragments. These fragments are sequenced.

The sequencing reads are aligned back to a reference genome. If many reads pile up in the same region, that region shows increased coverage and may form a **peak**.

```text
Reference genome
--------------------------------------------

Aligned reads

              ========
            ============
           ==============
             ==========
               ======

Coverage

                   /\
                  /  \
_________________/    \_________________

                   PEAK
```

A peak suggests that the protein was commonly associated with that region of DNA. For a transcription factor, a peak may identify a regulatory site near a gene. For histones or histone modifications, peaks may cover larger regions of chromatin.

ChIP-seq experiments often include an **Input control**. The Input sample represents the normal background distribution of genomic DNA before immunoprecipitation. Peak-calling software compares the ChIP sample with this background so that ordinary sequencing or mapping variation is less likely to be mistaken for true protein binding.

```text
ChIP sample
______________/████████\______________

Input
_______________________________________

                 |
                 v
          enriched region
```

Replicates are also important. If several independent ChIP-seq samples show a peak at the same genomic location, confidence in that binding site increases.

```text
Replicate 1    -----[======]-----
Replicate 2    ------[=====]-----
Replicate 3    -----[=======]----

                     |
                     v

           reproducible binding
```

The overall workflow is:

```text
Protein bound to DNA
        |
        v
Preserve interaction
        |
        v
Fragment DNA
        |
        v
Pull down protein with antibody
        |
        v
Recover attached DNA
        |
        v
Sequence DNA
        |
        v
Align reads to reference genome
        |
        v
Call peaks
```

In simple terms, ChIP-seq answers the question:

**Where does this protein bind the genome?**

ChIP-seq alone does not always tell us what effect that binding has. Other methods, such as RNA-seq, can be combined with ChIP-seq to determine whether genes near those binding sites also change their expression.

### Characterization of the Radiation Desiccation Response Regulon of the Radioresistant Bacterium *Deinococcus radiodurans* by Integrative Genomic Analyses

This project is based on the 2021 paper by Eugénie et al., published in *Cells*: **[Characterization of the Radiation Desiccation Response Regulon of the Radioresistant Bacterium *Deinococcus radiodurans* by Integrative Genomic Analyses](https://www.mdpi.com/2073-4409/10/10/2536)**. The study investigated how the transcriptional repressor **DdrO** controls the radiation and desiccation response of *Deinococcus radiodurans*. Under normal conditions, DdrO represses a group of stress-response genes. Following DNA damage, the metalloprotease IrrE cleaves DdrO, releasing this repression and allowing stress-response genes to be expressed.

The researchers combined **ChIP-seq and RNA-seq** to study this regulatory system. ChIP-seq was used to determine where DdrO binds to the genome, while RNA-seq was used to determine which genes change expression when DdrO regulation is altered. Combining these approaches allowed the researchers to identify genes that are likely to be directly controlled by DdrO rather than genes whose expression changes only indirectly.

The sequencing data are available through NCBI under BioProject **[PRJNA734175](https://www.ncbi.nlm.nih.gov/bioproject/?term=PRJNA734175)**. The ChIP-seq portion of the experiment contains three DdrO immunoprecipitation replicates together with Input and Mock controls. For this exercise, the three DdrO replicates are analyzed using the Input sample as the background control for peak calling.

The researchers also resequenced their laboratory stock of *D. radiodurans* R1 (ATCC 13939) to obtain an accurate reference for ChIP-seq and RNA-seq analysis. The complete genome sequence and annotation were deposited in GenBank under accession numbers **CP068791, CP068792, CP068793, and CP068794**.

The goal of this exercise is to reproduce part of the ChIP-seq analysis by aligning the DdrO ChIP-seq reads to this reference genome, generating coverage tracks, calling enriched regions with MACS3, and comparing the resulting peaks among the three DdrO replicates. Regions where the replicates produce overlapping peaks provide stronger evidence for reproducible DdrO binding, while regions where the replicates disagree illustrate variability in the ChIP-seq signal.

## Analysis

Use bio to retrieve information about the bioproject and runs to assist with the development of a design file:

```bash
bio search PRJNA734175 --csv > PRJNA734175_runinfo.csv
```

Use xan to view the output:

```bash
xan view PRJNA734175_runinfo.csv
```

| run_accession | sample_description | library_strategy | library_layout |
| ------------- | ------------------ | ---------------- | -------------- |
| SRR14698442   | 17370_6H-rep3      | RNA-Seq          | PAIRED         |
| SRR14698444   | 17370_8H-rep2      | RNA-Seq          | PAIRED         |
| SRR14698453   | 17357_1H-rep2      | RNA-Seq          | PAIRED         |
| SRR14698455   | 17357_4H-rep1      | RNA-Seq          | PAIRED         |
| SRR14698461   | 17357_8H-rep1      | RNA-Seq          | PAIRED         |
| SRR14698474   | MOCK-GY9613-rep1   | ChIP-Seq         | PAIRED         |
| SRR14698436   | 17370_1H-rep3      | RNA-Seq          | PAIRED         |
| SRR14698437   | 17370_4H-rep1      | RNA-Seq          | PAIRED         |
| SRR14698440   | 17370_6H-rep1      | RNA-Seq          | PAIRED         |
| SRR14698443   | 17370_8H-rep1      | RNA-Seq          | PAIRED         |
| SRR14698449   | 17370_24H-rep1     | RNA-Seq          | PAIRED         |
| SRR14698454   | 17357_1H-rep3      | RNA-Seq          | PAIRED         |
| SRR14698458   | 17357_6H-rep1      | RNA-Seq          | PAIRED         |
| SRR14698460   | 17357_6H-rep3      | RNA-Seq          | PAIRED         |
| SRR14698465   | 17357_16H-rep2     | RNA-Seq          | PAIRED         |
| SRR14698470   | IP-GY18220-rep1    | ChIP-Seq         | PAIRED         |
| SRR14698471   | IP-GY18220-rep2    | ChIP-Seq         | PAIRED         |
| SRR14698434   | 17370_1H-rep1      | RNA-Seq          | PAIRED         |
| SRR14698438   | 17370_4H-rep2      | RNA-Seq          | PAIRED         |
| SRR14698439   | 17370_4H-rep3      | RNA-Seq          | PAIRED         |
| SRR14698441   | 17370_6H-rep2      | RNA-Seq          | PAIRED         |
| SRR14698447   | 17370_16H-rep2     | RNA-Seq          | PAIRED         |
| SRR14698448   | 17370_16H-rep3     | RNA-Seq          | PAIRED         |
| SRR14698451   | 17370_24H-rep3     | RNA-Seq          | PAIRED         |
| SRR14698469   | 17357_24H-rep3     | RNA-Seq          | PAIRED         |
| SRR14698472   | IP-GY18220-rep3    | ChIP-Seq         | PAIRED         |
| SRR14698473   | INPUT-GY18220-rep1 | ChIP-Seq         | PAIRED         |
| SRR14698445   | 17370_8H-rep3      | RNA-Seq          | PAIRED         |
| SRR14698456   | 17357_4H-rep2      | RNA-Seq          | PAIRED         |
| SRR14698457   | 17357_4H-rep3      | RNA-Seq          | PAIRED         |
| SRR14698467   | 17357_24H-rep1     | RNA-Seq          | PAIRED         |
| SRR14698435   | 17370_1H-rep2      | RNA-Seq          | PAIRED         |
| SRR14698446   | 17370_16H-rep1     | RNA-Seq          | PAIRED         |
| SRR14698450   | 17370_24H-rep2     | RNA-Seq          | PAIRED         |
| SRR14698452   | 17357_1H-rep1      | RNA-Seq          | PAIRED         |
| SRR14698459   | 17357_6H-rep2      | RNA-Seq          | PAIRED         |
| SRR14698462   | 17357_8H-rep2      | RNA-Seq          | PAIRED         |
| SRR14698463   | 17357_8H-rep3      | RNA-Seq          | PAIRED         |
| SRR14698464   | 17357_16H-rep1     | RNA-Seq          | PAIRED         |
| SRR14698466   | 17357_16H-rep3     | RNA-Seq          | PAIRED         |
| SRR14698468   | 17357_24H-rep2     | RNA-Seq          | PAIRED         |


View the design file:

```bash
xan to md design.csv
```

| run         | type  | method   | sample     |
| ----------- | ----- | -------- | ---------- |
| SRR14698470 | DdrO  | ChIP_Seq | DdrO_rep1  |
| SRR14698471 | DdrO  | ChIP_Seq | DdrO_rep2  |
| SRR14698472 | DdrO  | ChIP_Seq | DdrO_rep3  |
| SRR14698473 | Input | ChIP_Seq | Input_rep1 |

Run make to see the options:

```bash
make
```

```
DdrO ChIP-seq workflow

Usage:
  make all
  make batch
  make background
  make peaks
  make igv
  make clean

Current settings:
  NAME      = R1_13939O
  SRR       = SRR14698470
  SAMPLE    = DdrO_rep1
  N         = 1000000
  THREADS   = 4
  JOBS      = 2

CPU use during parallel alignment:
  2 jobs x 4 threads = up to 8 threads
```

Run make for single sample to see the commands:

```bash
make all -n
```

```
mkdir -p fasta/
for acc in CP068791.1 CP068792.1 CP068793.1 CP068794.1; do \
        curl -fsSL --http1.1 \
                "https://www.ncbi.nlm.nih.gov/sviewer/viewer.fcgi?id=${acc}&db=nuccore&report=fasta&retmode=text"; \
done | bgzip > fasta/R1_13939O.fa.gz
samtools faidx fasta/R1_13939O.fa.gz
seqkit stats fasta/R1_13939O.fa.gz
mkdir -p gff/
for acc in CP068791.1 CP068792.1 CP068793.1 CP068794.1; do \
        curl -fsSL --http1.1 \
                "https://www.ncbi.nlm.nih.gov/sviewer/viewer.fcgi?id=${acc}&db=nuccore&report=genbank&retmode=text"; \
done > gff/R1_13939O.gb
mkdir -p gff/
genbank_to -g gff/R1_13939O.gb --gff3 gff/R1_13939O.gff3
awk '/^##FASTA/ {exit} {print}' gff/R1_13939O.gff3 > gff/R1_13939O.features.gff3
grep '^#' gff/R1_13939O.features.gff3 > gff/R1_13939O.header
grep -v '^#' gff/R1_13939O.features.gff3 | \
        sort -k1,1 -k4,4n > gff/R1_13939O.sorted.gff3
cat gff/R1_13939O.header gff/R1_13939O.sorted.gff3 | \
        bgzip > gff/R1_13939O.gff.gz
tabix -p gff gff/R1_13939O.gff.gz
rm -f \
        gff/R1_13939O.features.gff3 \
        gff/R1_13939O.header \
        gff/R1_13939O.sorted.gff3
ls -lh fasta/R1_13939O.fa.gz
ls -lh fasta/R1_13939O.fa.gz.fai
ls -lh gff/R1_13939O.gff.gz
ls -lh gff/R1_13939O.gff.gz.tbi
bwa index fasta/R1_13939O.fa.gz
mkdir -p fastq/
fastq-dump \
        -X 1000000 \
        --split-files \
        -O fastq/ \
        SRR14698470
seqkit stats fastq/SRR14698470_1.fastq fastq/SRR14698470_2.fastq
mkdir -p fastq/
fastq-dump \
        -X 1000000 \
        --split-files \
        -O fastq/ \
        SRR14698470
seqkit stats fastq/SRR14698470_1.fastq fastq/SRR14698470_2.fastq
mkdir -p bam/
bwa mem \
        -t 4 \
        fasta/R1_13939O.fa.gz \
        fastq/SRR14698470_1.fastq \
        fastq/SRR14698470_2.fastq | \
        samtools sort -o bam/DdrO_rep1.bam
samtools index bam/DdrO_rep1.bam
samtools flagstat bam/DdrO_rep1.bam
mkdir -p bw/
bamCoverage \
        --binSize 1 \
        --bam bam/DdrO_rep1.bam \
        -o bw/DdrO_rep1.bw
ls -lh bam/DdrO_rep1.bam
ls -lh bam/DdrO_rep1.bam.bai
ls -lh bw/DdrO_rep1.bw
make \
        SRR=SRR14698473 \
        SAMPLE=Input_rep1 \
        THREADS=4 \
        align
make[1]: Entering directory '/home/user/Documents/bioinfo/assign-12-chip-seq'
mkdir -p fasta/
for acc in CP068791.1 CP068792.1 CP068793.1 CP068794.1; do \
        curl -fsSL --http1.1 \
                "https://www.ncbi.nlm.nih.gov/sviewer/viewer.fcgi?id=${acc}&db=nuccore&report=fasta&retmode=text"; \
done | bgzip > fasta/R1_13939O.fa.gz
samtools faidx fasta/R1_13939O.fa.gz
seqkit stats fasta/R1_13939O.fa.gz
bwa index fasta/R1_13939O.fa.gz
mkdir -p fastq/
fastq-dump \
        -X 1000000 \
        --split-files \
        -O fastq/ \
        SRR14698473
seqkit stats fastq/SRR14698473_1.fastq fastq/SRR14698473_2.fastq
mkdir -p fastq/
fastq-dump \
        -X 1000000 \
        --split-files \
        -O fastq/ \
        SRR14698473
seqkit stats fastq/SRR14698473_1.fastq fastq/SRR14698473_2.fastq
mkdir -p bam/
bwa mem \
        -t 4 \
        fasta/R1_13939O.fa.gz \
        fastq/SRR14698473_1.fastq \
        fastq/SRR14698473_2.fastq | \
        samtools sort -o bam/Input_rep1.bam
samtools index bam/Input_rep1.bam
samtools flagstat bam/Input_rep1.bam
mkdir -p bw/
bamCoverage \
        --binSize 1 \
        --bam bam/Input_rep1.bam \
        -o bw/Input_rep1.bw
ls -lh bam/Input_rep1.bam
ls -lh bam/Input_rep1.bam.bai
ls -lh bw/Input_rep1.bw
make[1]: Leaving directory '/home/user/Documents/bioinfo/assign-12-chip-seq'
mkdir -p peaks/
macs3 callpeak \
        -f BAMPE \
        -g 3279219 \
        -n DdrO_rep1 \
        -t bam/DdrO_rep1.bam \
        -c bam/Input_rep1.bam \
        --outdir peaks
ls -lh peaks/DdrO_rep1_peaks.narrowPeak
```

Run make for single sample:

```bash
make all
```

Run the batch target with the design file, design.csv:

```bash
make batch
```

Visualize the coverage files with IGV. Color them by sample type, then the visual investigation may begin:

```bash
make igv
```

```
echo "new" | nc -q 1 localhost 60151
OK
echo "genome /home/user/Documents/bioinfo/chipseq/fasta/R1_13939O.fa.gz" | nc -q 1 localhost 60151
OK
echo "load /home/user/Documents/bioinfo/chipseq/gff/R1_13939O.gff.gz" | nc -q 1 localhost 60151
OK
cat design.csv | parallel --eta --colsep , --header : --jobs 2 --lb \
        'echo "load /home/user/Documents/bioinfo/chipseq/bw/{sample}.bw" | nc -q 1 localhost 60151'

Computers / CPU threads / Max jobs to run
1:local / 16 / 2

Computer:jobs running/jobs completed/%of started jobs/Average seconds to complete
ETA: 0s Left: 4 AVG: 0.00s  local:2/0/100%/0.0s OK
ETA: 0s Left: 4 AVG: 0.00s  local:2/0/100%/0.0s OK
ETA: 0s Left: 2 AVG: 0.00s  local:2/2/100%/0.5s OK
ETA: 0s Left: 2 AVG: 0.00s  local:2/2/100%/0.5s OK
ETA: 0s Left: 0 AVG: 0.25s  local:0/4/100%/0.5s 
```

## Results

### Viewing ChIP-seq Coverage in IGV

The BigWig coverage files for the three DdrO ChIP-seq replicates and the Input control were loaded into IGV and assigned different colors to make the tracks easy to distinguish: **DdrO_rep1 in green, DdrO_rep2 in magenta, DdrO_rep3 in blue, and Input_rep1 in red**. The three DdrO replicates show a strong enrichment signal at approximately **164 kb on CP068792.1**, while the Input control remains comparatively low and broadly distributed. The agreement among the three DdrO tracks suggests that this region is a reproducible site of DdrO enrichment.

![ChIP-seq coverage tracks in IGV](Screenshot%20From%202026-10-28%2015-01-22.png)

**Figure description:** IGV view of the BigWig coverage tracks across approximately 161–169 kb of chromosome CP068792.1. DdrO_rep1 (green), DdrO_rep2 (magenta), and DdrO_rep3 (blue) each show a distinct peak near 164 kb at approximately the same genomic position. The Input control (red) shows lower, more broadly distributed background coverage and lacks a comparable sharp peak at this location. The consistent enrichment across all three DdrO replicates provides visual evidence for a reproducible DdrO-associated region.

### *How many peaks were called in each sample?*

```bash
wc -l peaks/*_peaks.narrowPeak
```

```
  383 peaks/DdrO_rep1_peaks.narrowPeak
  322 peaks/DdrO_rep2_peaks.narrowPeak
  348 peaks/DdrO_rep3_peaks.narrowPeak
    0 peaks/Input_rep1_peaks.narrowPeak
 1053 total
```

### How consistent are the peak calls within replicates? Show one region where the replicates agree and one region where they do not.

The peak calls are generally consistent across the three DdrO replicates, although some differences are present. In this region of CP068792.1, all three replicates call an overlapping peak near **279 kb**, providing a good example of replicate agreement. In contrast, near **275.5 kb**, DdrO_rep1 and DdrO_rep3 call peaks at approximately the same location, while DdrO_rep2 does not. This shows that many DdrO-binding regions are reproducible across replicates, while other weaker or more variable regions may not be detected consistently in every sample.

![Comparison of DdrO peak calls among replicates](Screenshot%20From%202026-10-28%2015-35-34.png)

**Figure description:** IGV view of the three DdrO narrowPeak tracks across approximately 273–282 kb of CP068792.1. Near **279 kb**, DdrO_rep1, DdrO_rep2, and DdrO_rep3 all contain overlapping peak calls, demonstrating strong agreement among the replicates. Near **275.5 kb**, peaks are present in DdrO_rep1 and DdrO_rep3 but absent from DdrO_rep2, providing an example of replicate disagreement. The annotation track below the peaks shows the genomic features present in the same region.

## Summary

This exercise developed a complete ChIP-seq workflow for the *Deinococcus radiodurans* DdrO project associated with BioProject **PRJNA734175** and the paper *Characterization of the Radiation Desiccation Response Regulon of the Radioresistant Bacterium Deinococcus radiodurans by Integrative Genomic Analyses*. We identified the exact resequenced R1 laboratory reference used by the study, downloaded its four GenBank replicons (**CP068791.1–CP068794.1**), combined them into a single reference genome, converted the GenBank annotation to GFF3, and created the required FASTA, BWA, and Tabix indexes. A `design.csv` was created for three DdrO ChIP-seq replicates and one Input control, and the Makefile was adapted from the earlier working workflow while preserving its batch-processing structure. The paired-end reads were downloaded, aligned to the reference, converted into indexed BAM files, and summarized as BigWig coverage tracks for IGV. The Input sample was used as the background control for MACS3 peak calling, with `BAMPE` specified so the paired-end fragment information was used correctly. In IGV, the three DdrO coverage tracks showed reproducible enrichment at several genomic regions while the Input remained comparatively low and broad. The resulting narrowPeak files were then compared directly across replicates, revealing regions where all three DdrO samples agreed and other regions where only some replicates produced a peak. Overall, the exercise demonstrated the complete path from raw ChIP-seq reads and a study-specific reference genome to alignment, coverage visualization, background-controlled peak calling, and biological assessment of replicate consistency.

