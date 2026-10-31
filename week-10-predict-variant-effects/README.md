# Applied Bioinformatics 2026

## Week10 - Predict Variant Effects

## Introduction

### Predict variant effects

The primary challenge of this assignment is that it asks you to use your previous solutions as LEGO blocks. But as we know from playing with LEGOs, the important part is that the pieces all fit together and are generic enough to be used in a new context.

In the Generate a VCF file assignment you called variants from your alignment and created a VCF file.

In the Multi-sample VCF lecture I describe how to merge multiple VF files into a single one.

You will now need to generate a multisample VCF file based on the genome you selected. Use at least three samples, then annotate a few of the variants to try to tell what effect the change has on the protein.

You may start with the previous Makefile and add the annotation steps.

Study Variant effect prediction and Variant effect software before you start.

### Annotate a few variants

1. Select a few variants that fall in a coding sequence. If the VCF has none, choose a different sample.
2. Predict the effect of each variant either by eye or with a software tool.
3. Record the reference codon, the alternate codon, and the amino acid change. Use the genetic code for your organism.
4. Write a README.md that a reviewer can follow.

### What to put in the README

* Which variants did you annotate, and which gene does each one fall in?
* For each variant, what is the reference codon, the alternate codon, and the amino acid change?

Include the commands needed to run the Makefile, a screenshot of one variant lined up with the translated coding sequence in IGV, and the software output for that variant.

## Analysis

In this exercise I modified `bcftools.2026.mk` to include downloading the annotation file for the reference genome, the I developed a wrapper makefile, `multisample-vcf.mk`, that runs a pipeline for the reference genome (fasta, GFF and index), the strains (fastq, BAM) and finally a multisample vcf.

Run the help target for `multisample-vcf.mk`:

```bash
make -f multisample-vcf.mk help
```

```
#
# Applied Bioinformatics 2026
# Generic multi-sample VCF pipeline
#
# GENOME_NAME=CHC155
#
# Samples:
#   408F 412F 427F
#
# Number of reads:
#   N=40000
#
# BAM files:
#   bam/408F.bam bam/412F.bam bam/427F.bam
#
# Multisample VCF:
#   vcf/multisample.vcf.gz
#
# Targets:
#   make -f multisample-vcf.mk reference
#   make -f multisample-vcf.mk samples
#   make -f multisample-vcf.mk jointcall
#   make -f multisample-vcf.mk all
#   make -f multisample-vcf.mk clean
#
# Dry run:
#   make -n -f multisample-vcf.mk all
#
```

A hypothetical four-sample run against a different reference could look like this:

```bash
make -f multisample-vcf.mk all \
GCF_URL=https://example.org/new_reference_genome.fna.gz \
GFF_URL=https://example.org/new_reference_annotation.gff.gz \
GENOME_NAME=NEWGENOME \
SAMPLES="SRR111111:SAMPLE1 SRR222222:SAMPLE2 SRR333333:SAMPLE3 SRR444444:SAMPLE4" \
N=40000
```

How is that for using Lego building blocks!

Do a dry run to see all of the commands/parameters that would be executed:

```bash
make -n -f multisample-vcf.mk all
```

```
make -f bcftools.2026.mk reference \
        GCF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz \
        GFF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.gff.gz \
        GENOME_NAME=CHC155
make[1]: Entering directory '/home/user/Documents/bioinfo/pve'
mkdir -p fasta/
curl -fsSL https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz | gunzip -c > fasta/CHC155.fasta
seqkit stats fasta/CHC155.fasta
samtools faidx fasta/CHC155.fasta
bwa index fasta/CHC155.fasta
mkdir -p gff/
curl -fsSL https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.gff.gz | gunzip -c > gff/CHC155.gff
ls -lh gff/CHC155.gff
bgzip -c gff/CHC155.gff > gff/CHC155.gff.gz
tabix -p gff gff/CHC155.gff.gz
make[1]: Leaving directory '/home/user/Documents/bioinfo/pve'
make -f bcftools.2026.mk align GCF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz GFF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.gff.gz GENOME_NAME=CHC155 SRR=SRR27606653 SAMPLE_NAME=408F N=40000
make -f bcftools.2026.mk align GCF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz GFF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.gff.gz GENOME_NAME=CHC155 SRR=SRR27606652 SAMPLE_NAME=412F N=40000
make -f bcftools.2026.mk align GCF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.fna.gz GFF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/025/998/455/GCF_025998455.1_ASM2599845v1/GCF_025998455.1_ASM2599845v1_genomic.gff.gz GENOME_NAME=CHC155 SRR=SRR27606651 SAMPLE_NAME=427F N=40000
mkdir -p vcf
bcftools mpileup \
        -d 100 \
        --annotate 'INFO/AD,FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/SP' \
        -O u \
        -f fasta/CHC155.fasta \
        bam/408F.bam bam/412F.bam bam/427F.bam | \
bcftools call \
        --ploidy 2 \
        --annotate 'FORMAT/GQ' \
        -mv \
        -O u | \
bcftools norm \
        -f fasta/CHC155.fasta \
        -d all \
        -O u | \
bcftools sort \
        --write-index \
        -O z \
        -o vcf/multisample.vcf.gz
bcftools stats vcf/multisample.vcf.gz > vcf/multisample.stats.txt
```

Run the entire pipeline:

```bash
make -f multisample-vcf.mk all > multisample-vcf.log
```

## Results

Get a summary of the `multisample.stats.txt` file:

```bash
grep '^SN' vcf/multisample.stats.txt
```

```
SN      0       number of samples:      3
SN      0       number of records:      50322
SN      0       number of no-ALTs:      0
SN      0       number of SNPs: 49394
SN      0       number of MNPs: 0
SN      0       number of indels:       928
SN      0       number of others:       0
SN      0       number of multiallelic sites:   51
SN      0       number of multiallelic SNP sites:       41
```

Load the required files for analysis into IGV:

```
IGV FILE LOADING ORDER

1. Reference genome
   Use: Genomes → Load Genome from File...

   /home/user/Documents/bioinfo/pve/fasta/CHC155.fasta


2. Genome annotation
   Use: File → Load from File...

   /home/user/Documents/bioinfo/pve/gff/CHC155.gff.gz


3. Sample BAM files
   Use: File → Load from File...

   /home/user/Documents/bioinfo/pve/bam/408F.bam

   /home/user/Documents/bioinfo/pve/bam/412F.bam

   /home/user/Documents/bioinfo/pve/bam/427F.bam


4. Multisample VCF
   Use: File → Load from File...

   /home/user/Documents/bioinfo/pve/vcf/multisample.vcf.gz
   ```

## Example 1

A variant in the multisample VCF was examined near position 847,807 on chromosome NZ_AP026446.1. The variant is supported by the read alignments from samples 408F, 412F, and 427F and occurs within the protein-coding gene OW489_RS03975, which encodes a SurA N-terminal domain-containing protein.

The reference sequence displayed in IGV contains CTT, while the aligned reads show a C→T substitution, producing TTT on the displayed strand. Because OW489_RS03975 is on the reverse strand, the coding-strand codons are the reverse complements: CTT becomes AAG and TTT becomes AAA. Both AAG and AAA encode lysine (K), so the nucleotide change does not alter the amino acid. This is therefore a synonymous SNP.

![IGV view of the synonymous variant](Screenshot%20from%202026-10-16%2009-49-51.png)

The figure shows the multisample VCF call together with the BAM alignments for 408F, 412F, and 427F. The red T bases in the alignments indicate a C→T difference relative to the CHC155 reference. Because the affected CDS is on the reverse strand, the coding change is AAG→AAA, and both codons translate to lysine (K), confirming that the variant is synonymous.

## Example 2

A second variant in the multisample VCF was examined near position 847,888 on chromosome NZ_AP026446.1. The variant is supported by the read alignments from samples 408F, 412F, and 427F and occurs within the same protein-coding gene, OW489_RS03975, which encodes a SurA N-terminal domain-containing protein.

The reference sequence displayed in IGV contains the codon GCT, while the aligned reads show a G→A substitution, producing ACT on the displayed strand. Because OW489_RS03975 is on the reverse strand, the coding-strand codons are the reverse complements: GCT becomes AGC and ACT becomes AGT. Both AGC and AGT encode serine (S), so the nucleotide change does not alter the amino acid. This is therefore a synonymous SNP.

![IGV view of the second synonymous variant](Screenshot%20from%202026-10-16%2014-13-45.png)

The figure shows the multisample VCF call together with the BAM alignments for 408F, 412F, and 427F. The green A bases in the alignments indicate a G→A difference relative to the CHC155 reference. Because the affected CDS is on the reverse strand, the displayed change GCT→ACT corresponds to the coding-strand change AGC→AGT. Both codons translate to serine (S), confirming that the variant is synonymous.

## Example 3

A third variant in the multisample VCF was examined near position 848,070 on chromosome NZ_AP026446.1. The variant is supported by the read alignments from samples 408F, 412F, and 427F and occurs within the same reverse-strand protein-coding region.

The CHC155 reference contains T at the variant position, while the aligned reads contain C, producing a T→C SNP. In the displayed reference strand, the affected codon changes from TAA to CAA. Although TAA is normally a stop codon when read on the forward strand, this gene is on the reverse strand. The reverse-complement coding-strand change is therefore TTA→TTG. Both TTA and TTG encode leucine (L), so the amino acid does not change. This is another synonymous SNP.

![IGV view of the third synonymous variant](Screenshot%20from%202026-10-16%2014-19-42.png)

The figure shows the multisample VCF call and supporting BAM alignments for 408F, 412F, and 427F. The blue C bases indicate a T→C difference from the CHC155 reference. The GFF translation track identifies the affected codon as leucine on the reverse strand. Therefore, the displayed TAA→CAA change corresponds to TTA→TTG on the coding strand, with both codons encoding leucine (L).

## Summary

In this exercise, a generic multi-sample variant-calling workflow was built using a reusable single-sample Makefile and a wrapper Makefile. The CHC155 reference genome and GFF annotation were downloaded and indexed, three *Helicobacter pylori* samples (408F, 412F, and 427F) were aligned to the reference, and the resulting BAM files were jointly analyzed with `bcftools` to create a multisample VCF. The variants were then inspected in IGV together with the BAM alignments, reference sequence, and gene annotation. Three example SNPs were examined within a reverse-strand coding region, and in each case the reverse-complement codon showed that the nucleotide change was synonymous and did not alter the encoded amino acid.