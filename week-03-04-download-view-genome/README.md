# Applied Bioinformatics 2026

## Week02 and Week03 - Bioinformatics Data

This two week exercise requires downloading and viewing bioinformatic datafile of an organism of our choice, *Helicobacter pylori*, strain CHC155.

*Helicobacter pylori* is a bacterium that has accompanied human populations for thousands of years and shows strong genetic differences among populations from different geographic regions. Because its evolutionary history is closely associated with human migration and population history, *H. pylori* has been used as an additional source of evidence for reconstructing patterns of human dispersal. I chose strain CHC155 because it has a complete, well-annotated reference genome and provides an interesting connection between the bioinformatics methods used in this project and concepts from the Human Population and Evolutionary Genetics course, particularly migration, population structure, and genetic variation.

The following makefile was developed with ChatGPT to provide options to download/index files and view the genome with IGV.

The following displays the help:

```bash
make
```

```
AGenome:    chc155
Accession: GCF_025998455.1

Available commands:

  make download   Download, rename, and index data
  make igv        Load genome and annotation into IGV
  make clean      Remove downloaded/generated files
```

There is also a hidden command for `make clean` that removes any old data files.

See below for the entire makefile:

```bash
# Make sure we run in bash.
SHELL = bash


# ---------------------------------------------------------
# GENOME SETTINGS
# ---------------------------------------------------------

# NCBI assembly accession.
ACCESSION ?= GCF_025998455.1

# Short readable name used for local files.
GENOME ?= chc155


# ---------------------------------------------------------
# DIRECTORIES AND FILES
# ---------------------------------------------------------

FASTA_DIR = fasta
GFF_DIR   = gff

# Temporary NCBI Datasets download area.
DATA_DIR = ncbi_dataset_$(GENOME)
ZIP      = $(GENOME)_dataset.zip

# Renamed local files.
FASTA       = $(FASTA_DIR)/$(GENOME).fna
FASTA_INDEX = $(FASTA).fai

GFF       = $(GFF_DIR)/$(GENOME).gff3
GFF_GZ    = $(GFF).gz
GFF_INDEX = $(GFF_GZ).tbi

# Location of files inside the NCBI Datasets package.
NCBI_DIR = $(DATA_DIR)/ncbi_dataset/data/$(ACCESSION)

# Marker indicating that the NCBI package has been extracted.
EXTRACT_MARKER = $(DATA_DIR)/.extracted


# ---------------------------------------------------------
# IGV COMMAND PORT
# ---------------------------------------------------------

IGV = nc -q 1 localhost 60151


# ---------------------------------------------------------
# AVAILABLE COMMANDS
# ---------------------------------------------------------

.PHONY: all download igv clean


all:
	@echo ""
	@echo "Genome:    $(GENOME)"
	@echo "Accession: $(ACCESSION)"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  make download   Download, rename, and index data"
	@echo "  make igv        Load genome and annotation into IGV"
	@echo "  make clean      Remove downloaded/generated files"
	@echo ""


# ---------------------------------------------------------
# DOWNLOAD AND PREPARE DATA
# ---------------------------------------------------------

download: $(FASTA) $(FASTA_INDEX) $(GFF) $(GFF_INDEX)
	@echo ""
	@echo "Data preparation complete."
	@echo ""
	@echo "FASTA: $(FASTA)"
	@echo "GFF3:  $(GFF)"
	@echo ""


# ---------------------------------------------------------
# DOWNLOAD NCBI DATASET
# ---------------------------------------------------------

$(ZIP):
	@echo "Downloading $(ACCESSION) from NCBI Datasets..."
	datasets download genome accession $(ACCESSION) \
		--include genome,gff3 \
		--filename $(ZIP)


# ---------------------------------------------------------
# EXTRACT NCBI DATASET
# ---------------------------------------------------------

$(EXTRACT_MARKER): $(ZIP)
	@echo "Extracting NCBI data package..."
	rm -rf $(DATA_DIR)
	unzip -q $(ZIP) -d $(DATA_DIR)
	touch $(EXTRACT_MARKER)


# ---------------------------------------------------------
# FASTA
# ---------------------------------------------------------

# Copy and rename the genomic FASTA.
$(FASTA): $(EXTRACT_MARKER)
	@echo "Renaming genomic FASTA to $(FASTA)..."
	mkdir -p $(FASTA_DIR)
	cp $(NCBI_DIR)/*_genomic.fna $(FASTA)


# Index the FASTA.
$(FASTA_INDEX): $(FASTA)
	@echo "Indexing FASTA..."
	samtools faidx $(FASTA)


# ---------------------------------------------------------
# GFF3
# ---------------------------------------------------------

# Copy, rename, and coordinate-sort the GFF3 file.
$(GFF): $(EXTRACT_MARKER)
	@echo "Renaming and sorting GFF3 to $(GFF)..."
	mkdir -p $(GFF_DIR)

	# Keep the GFF3 header.
	awk '/^##FASTA/ {exit} /^#/ {print}' \
		$(NCBI_DIR)/genomic.gff > $(GFF)

	# Sort annotation records by sequence and coordinate.
	awk -F '\t' \
		'/^##FASTA/ {exit} !/^#/ && NF == 9 {print}' \
		$(NCBI_DIR)/genomic.gff | \
		LC_ALL=C sort -t $$'\t' -k1,1 -k4,4n >> $(GFF)


# Compress the GFF3.
$(GFF_GZ): $(GFF)
	@echo "Compressing GFF3..."
	bgzip -kf $(GFF)


# Index the compressed GFF3.
$(GFF_INDEX): $(GFF_GZ)
	@echo "Indexing GFF3..."
	tabix -f -p gff $(GFF_GZ)


# ---------------------------------------------------------
# IGV
# ---------------------------------------------------------

igv: $(FASTA) $(GFF)

	@echo "Loading $(GENOME) into IGV..."

	# Start a new IGV session.
	echo "new" | $(IGV)

	# Load the reference genome.
	echo "genome $(CURDIR)/$(FASTA)" | $(IGV)

	# Load the annotation.
	echo "load $(CURDIR)/$(GFF)" | $(IGV)

	# Expand the annotation track.
	echo "expand" | $(IGV)


# ---------------------------------------------------------
# CLEAN
# ---------------------------------------------------------

clean:
	rm -rf $(FASTA_DIR) $(GFF_DIR) $(DATA_DIR) $(ZIP)
```

## Week02 - Download genome data

First, let's download and index the fasta and gff files for the genome:

```bash
make download
```

```
Downloading GCF_025998455.1 from NCBI Datasets...
datasets download genome accession GCF_025998455.1 \
        --include genome,gff3 \
        --filename chc155_dataset.zip
New version of client (18.38.0) available at https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/LATEST/linux-amd64/datasets.
Collecting 1 genome record [================================================] 100% 1/1
Downloading: chc155_dataset.zip    651kB valid data package
Validating package files [================================================] 100% 6/6
Extracting NCBI data package...
rm -rf ncbi_dataset_chc155
unzip -q chc155_dataset.zip -d ncbi_dataset_chc155
touch ncbi_dataset_chc155/.extracted
Renaming genomic FASTA to fasta/chc155.fna...
mkdir -p fasta
cp ncbi_dataset_chc155/ncbi_dataset/data/GCF_025998455.1/*_genomic.fna fasta/chc155.fna
Indexing FASTA...
samtools faidx fasta/chc155.fna
Renaming and sorting GFF3 to gff/chc155.gff3...
mkdir -p gff
# Keep the GFF3 header.
awk '/^##FASTA/ {exit} /^#/ {print}' \
        ncbi_dataset_chc155/ncbi_dataset/data/GCF_025998455.1/genomic.gff > gff/chc155.gff3
# Sort annotation records by sequence and coordinate.
awk -F '\t' \
        '/^##FASTA/ {exit} !/^#/ && NF == 9 {print}' \
        ncbi_dataset_chc155/ncbi_dataset/data/GCF_025998455.1/genomic.gff | \
        LC_ALL=C sort -t $'\t' -k1,1 -k4,4n >> gff/chc155.gff3
Compressing GFF3...
bgzip -kf gff/chc155.gff3
Indexing GFF3...
tabix -f -p gff gff/chc155.gff3.gz

Data preparation complete.

FASTA: fasta/chc155.fna
GFF3:  gff/chc155.gff3
```

Look at the first 20 lines of the GFF file to see what we are looking at:

```bash
head -n 20 gff/chc155.gff3
```

```
##gff-version 3
#!gff-spec-version 1.21
#!processor NCBI annotwriter
#!genome-build ASM2599845v1
#!genome-build-accession NCBI_Assembly:GCF_025998455.1
#!annotation-date 12/09/2025 11:21:48
#!annotation-source NCBI RefSeq GCF_025998455.1-RS_2025_12_09
##sequence-region NZ_AP026446.1 1 1696601
##species https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=210
###
NZ_AP026446.1   RefSeq  region  1       1696601 .       +       .       ID=NZ_AP026446.1:1..1696601;Dbxref=taxon:210;Is_circular=true;Name=ANONYMOUS;collection-date=2015;country=Viet Nam;culture-collection=ATCC:43504;gbkey=Src;genome=chromosome;isolation-source=Gastric biopsies;mol_type=genomic DNA;nat-host=Homo sapiens;strain=CHC155;type-material=type strain of Helicobacter pylori
NZ_AP026446.1   Protein Homology        CDS     101     1468    .       +       0       ID=cds-WP_120857687.1;Parent=gene-OW489_RS00005;Dbxref=GenBank:WP_120857687.1,GeneID:93236273;Name=WP_120857687.1;Ontology_term=GO:0006270,GO:0006275,GO:0003677,GO:0003688,GO:0005524;gbkey=CDS;gene=dnaA;go_function=DNA binding|0003677||IEA,DNA replication origin binding|0003688||IEA,ATP binding|0005524||IEA;go_process=DNA replication initiation|0006270||IEA,regulation of DNA replication|0006275||IEA;inference=COORDINATES: similar to AA sequence:RefSeq:WP_000380615.1;locus_tag=OW489_RS00005;product=chromosomal replication initiator protein DnaA;protein_id=WP_120857687.1;transl_table=11
NZ_AP026446.1   RefSeq  gene    101     1468    .       +       .       ID=gene-OW489_RS00005;Dbxref=GeneID:93236273;Name=dnaA;gbkey=Gene;gene=dnaA;gene_biotype=protein_coding;locus_tag=OW489_RS00005;old_locus_tag=CHC155_00010
NZ_AP026446.1   Protein Homology        CDS     1689    3122    .       +       0       ID=cds-WP_120857685.1;Parent=gene-OW489_RS00010;Dbxref=GenBank:WP_120857685.1,GeneID:93236274;Name=WP_120857685.1;gbkey=CDS;inference=COORDINATES: similar to AA sequence:RefSeq:WP_000751676.1;locus_tag=OW489_RS00010;product=competence protein;protein_id=WP_120857685.1;transl_table=11
NZ_AP026446.1   RefSeq  gene    1689    3122    .       +       .       ID=gene-OW489_RS00010;Dbxref=GeneID:93236274;Name=OW489_RS00010;gbkey=Gene;gene_biotype=protein_coding;locus_tag=OW489_RS00010;old_locus_tag=CHC155_00020
NZ_AP026446.1   RefSeq  gene    3125    3200    .       -       .       ID=gene-OW489_RS00015;Dbxref=GeneID:93236275;Name=OW489_RS00015;gbkey=Gene;gene_biotype=tRNA;locus_tag=OW489_RS00015;old_locus_tag=CHC155_t00010
NZ_AP026446.1   tRNAscan-SE     exon    3125    3200    .       -       .       ID=exon-OW489_RS00015-1;Parent=rna-OW489_RS00015;Dbxref=GeneID:93236275;anticodon=(pos:complement(3165..3167));gbkey=tRNA;inference=COORDINATES: profile:tRNAscan-SE:2.0.12;locus_tag=OW489_RS00015;product=tRNA-Phe
NZ_AP026446.1   tRNAscan-SE     tRNA    3125    3200    .       -       .       ID=rna-OW489_RS00015;Parent=gene-OW489_RS00015;Dbxref=GeneID:93236275;anticodon=(pos:complement(3165..3167));gbkey=tRNA;inference=COORDINATES: profile:tRNAscan-SE:2.0.12;locus_tag=OW489_RS00015;product=tRNA-Phe
NZ_AP026446.1   Protein Homology        CDS     3300    4052    .       +       0       ID=cds-WP_000767551.1;Parent=gene-OW489_RS00020;Dbxref=GenBank:WP_000767551.1,GeneID:93236276;Name=WP_000767551.1;gbkey=CDS;inference=COORDINATES: similar to AA sequence:RefSeq:WP_001936700.1;locus_tag=OW489_RS00020;product=exodeoxyribonuclease III;protein_id=WP_000767551.1;transl_table=11
NZ_AP026446.1   RefSeq  gene    3300    4052    .       +       .       ID=gene-OW489_RS00020;Dbxref=GeneID:93236276;Name=OW489_RS00020;gbkey=Gene;gene_biotype=protein_coding;locus_tag=OW489_RS00020;old_locus_tag=CHC155_00030
```

*How big is the genome size?*

```bash
awk '{sum += $2} END {print "Genome size is:", sum, "bp"}' fasta/chc155.fna.fai
```

```
Genome size is: 1696601 bp
```

*How many chromosomes does it have?*

```bash
echo "Number of chromosomes is: $(grep -P '\tregion\t' gff/chc155.gff3 | grep 'genome=chromosome' | wc -l)"
```

```
Number of chromosomes is: 1
```

*How many annotations are in the annotation file?*

```bash
echo "Number of annotations is: $(grep -v '^#' gff/chc155.gff3 | wc -l)"
```

```
Number of annotations is: 3304
```

*What are the the number and type of the different features in the annotation file?*

```bash
echo "Feature types in the genome:" && grep -v '^#' gff/chc155.gff3 | cut -f 3 | sort | uniq -c | sort -nr
```

```
Feature types in the genome:
   1584 CDS
   1551 gene
     78 pseudogene
     45 exon
     36 tRNA
      6 rRNA
      1 tmRNA
      1 region
      1 SRP_RNA
      1 RNase_P_RNA
```

*How complete is this genomic build?*

First, see how many separate sequences/replicons make up the assembly:

```bash
echo "Number of sequence regions is: $(grep -c '^##sequence-region' gff/chc155.gff3)"
```

```
Number of sequence regions is: 1
```

Then check for unresolved bases (Ns) in the FASTA:

```bash
echo "Number of unresolved bases is: $(grep -v '^>' fasta/chc155.fna | tr -cd 'Nn' | wc -c)"
```

```
Number of unresolved bases is: 0
```

Finally, see whether the replicons are identified as complete circular molecules:

```bash
echo "Number of circular replicons is: $(grep -P '\tregion\t' gff/chc155.gff3 | grep -c 'Is_circular=true')"
```

```
Number of circular replicons is: 1
```

The *Helicobacter pylori* CHC155 annotation file describes a complete 1.70 Mb circular chromosome and contains 3,304 annotated features. Most of the annotation consists of protein-coding regions, including 1,551 genes and 1,584 CDS features, along with 78 pseudogenes. The genome also contains 36 tRNAs, 6 rRNAs, 45 exons, and several specialized RNA features, including tmRNA, SRP RNA, and RNase P RNA. Overall, the annotation shows that *H. pylori* CHC155 has the compact, gene-rich organization expected for a bacterial genome, with relatively few noncoding RNA features compared with protein-coding genes.

## Week03 - Visualize a genome

Run the IGV section of the make file start igv and display the genome (IGV must be started manually):

```bash
make igv
```

```
# Create a new IGV session.
echo "new" | nc -q 1 localhost 60151
OK
# Load the CHC155 genome.
echo "genome /home/user/Documents/bioinfo/chc155/fasta/chc155.fna" | nc -q 1 localhost 60151
OK
# Load the CHC155 annotation.
echo "load /home/user/Documents/bioinfo/chc155/gff/chc155.gff3" | nc -q 1 localhost 60151
OK
# Color negative-strand features red.
echo "setAltColor 255,0,0 chc155.gff3" | nc -q 1 localhost 60151
OK
# Go to a useful region near the start of the chromosome.
echo "goto NZ_AP026446.1:1-50000" | nc -q 1 localhost 60151
OK
# Expand the annotation track.
echo "expand" | nc -q 1 localhost 60151
OK
# Take a snapshot of the current IGV view.
echo "snapshot chc155_overview.png" | nc -q 1 localhost 60151
OK
```

*How tightly packed are the genes in this genome?*

The genes in the *Helicobacter pylori* CHC155 genome are very tightly packed. The IGV whole-genome view shows gene annotations distributed almost continuously across the 1.70 Mb chromosome, with only small gaps between most neighboring genes and relatively little unannotated space. This compact organization is typical of bacterial genomes, where a large proportion of the chromosome is devoted to coding or other functional sequences.

![IGV whole-genome view of Helicobacter pylori CHC155](Screenshot%20from%202026-10-10%2012-44-25.png)

*Figure explanation:* The IGV screenshot shows the complete CHC155 chromosome, approximately 1.70 Mb in length. The dense blue annotation track extends across nearly the entire chromosome, indicating that genes and other annotated features are closely spaced with few large intergenic regions.

*Pick a coordinate on a chromosome and describe the sequence around it.*

I selected coordinate **1,362,899** on chromosome `NZ_AP026446.1`. This position lies within the small forward-strand gene **`rpmJ`**, with **`infA`** located upstream and **`rpsM`** downstream. The IGV view shows the individual nucleotide bases in this region together with the possible codon translations. The genes are closely spaced, with little intergenic DNA between them, which again shows the compact organization of the *Helicobacter pylori* CHC155 genome.

![IGV sequence view around coordinate 1,362,899 in Helicobacter pylori CHC155](Screenshot%20from%202026-10-10%2012-54-58.png)

*Figure explanation:* The IGV screenshot is centered near coordinate **1,362,899** on chromosome `NZ_AP026446.1`. The `rpmJ` gene is visible in the middle of the annotation track on the forward strand, with neighboring genes `infA` and `rpsM`. At this zoom level, IGV displays the DNA bases and translated reading frames above the annotation track.

#*Describe the start codon.*

The start codon for the *Helicobacter pylori* CHC155 `rpmJ` gene is **ATG**. Because `rpmJ` is located on the forward (`+`) strand, the sequence is read from left to right, and the ATG marks the beginning of the coding region. In IGV, this start codon is highlighted in green and translates to **methionine (M)**, the amino acid that typically begins protein synthesis.

![IGV view of the rpmJ start codon in Helicobacter pylori CHC155](Screenshot%20from%202026-10-10%2013-01-51.png)

*Figure explanation:* The IGV screenshot shows the beginning of the `rpmJ` coding sequence on the forward strand. The **ATG** start codon is highlighted in green and corresponds to **methionine (M)** in the translated amino-acid sequence. The following bases are grouped into codons that continue the protein-coding sequence.

*Describe the stop codon.*

The `rpmJ` gene ends with the stop codon **TAA**. In IGV, the stop codon is shown as a red `*` at the end of the translated coding sequence. Unlike codons that specify amino acids, TAA does not code for an amino acid; instead, it signals the ribosome to stop translation, marking the end of the protein-coding region.

![IGV view of the rpmJ stop codon in Helicobacter pylori CHC155](Screenshot%20from%202026-10-10%2013-07-50.png)

*Figure explanation:* The IGV screenshot shows the end of the `rpmJ` gene on the forward strand. The final codon is **TAA**, represented by the red `*`, which marks the termination of translation. The neighboring `rpsM` gene begins shortly downstream, again showing the tightly packed organization of the *Helicobacter pylori* CHC155 genome.

Exploring the *Helicobacter pylori* CHC155 genome in IGV showed that the chromosome is compact and densely packed with genes, with relatively little intergenic space between neighboring features. By zooming from the whole chromosome into a small region around the `rpmJ` gene, we were able to examine the DNA sequence directly, identify nearby genes, and view how the coding sequence is translated. The `rpmJ` gene is on the forward strand, begins with an **ATG** start codon, and ends with a **TAA** stop codon. It encodes the 50S ribosomal protein L36, a small structural component of the bacterial ribosome that helps support protein synthesis. Overall, IGV provided a clear visual connection between genome organization, nucleotide sequence, gene orientation, and biological function.
