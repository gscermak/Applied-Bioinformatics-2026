# Applied Bioinformatics 2026

## Week14 - Generate a Count Matrix for Transcription-Based RNA-Seq

## Introduction


### Genome-Based vs. Transcriptome-Based RNA-Seq

Genome-based and transcriptome-based RNA-seq provide complementary information about gene expression. Genome-based RNA-seq aligns sequencing reads to a reference genome, allowing us to examine gene expression, exon coverage, and splice junctions. Transcriptome-based RNA-seq quantifies reads against known transcript sequences, allowing us to estimate the abundance of individual transcript isoforms.

#### 1. Example: Two Genes with Alternative Splicing

Consider two hypothetical genes, Gene A and Gene B. Each contains three exons and produces two transcript isoforms. The second isoform skips Exon 2.

```text
GENE A

Genome:        [Exon 1]---[Exon 2]---[Exon 3]
                  |          |          |
Transcript A1: [Exon 1]---[Exon 2]---[Exon 3]
Transcript A2: [Exon 1]--------------[Exon 3]


GENE B

Genome:        [Exon 1]---[Exon 2]---[Exon 3]
                  |          |          |
Transcript B1: [Exon 1]---[Exon 2]---[Exon 3]
Transcript B2: [Exon 1]--------------[Exon 3]
```

Both genes can produce different transcript isoforms through alternative splicing. The second isoform of each gene skips Exon 2.

#### 2. Genome-Based RNA-Seq

In our genome-based workflow, HISAT2 aligns RNA-seq reads to the reference genome, and featureCounts assigns reads to annotated genes.

```text
              REFERENCE GENOME
                     |
                   HISAT2
                     |
               Aligned reads
                     |
                featureCounts
                     |
               GENE COUNTS
                     |
              +------+------+
              |             |
            Gene A        Gene B
              |             |
             100           100
```

Both genes have 100 assigned counts, suggesting similar expression levels in this simplified example. However, the gene-level count matrix does not tell us which transcript isoforms contributed to those counts.

Genome-based alignment also allows us to examine exon coverage and splice junctions in IGV, providing evidence of alternative splicing.

#### 3. Transcriptome-Based RNA-Seq

In our transcriptome-based workflow, Salmon estimates the abundance of individual transcripts using a reference transcriptome.

```text
              REFERENCE TRANSCRIPTOME
                       |
                     Salmon
                       |
               TRANSCRIPT COUNTS
                       |
              +--------+--------+
              |                 |
            Gene A            Gene B
              |                 |
         +----+----+       +----+----+
         |         |       |         |
        A1        A2      B1        B2
        90        10      20        80
         |         |       |         |
         +----+----+       +----+----+
              |                 |
          Total 100         Total 100
```

Although both genes have the same total estimated counts, their transcript expression patterns are very different.

Gene A primarily produces transcript A1, while Gene B primarily produces transcript B2.

This information is not directly available from a conventional gene-level count matrix.

#### 4. Comparison of the Two Approaches

| Question | Genome-Based | Transcriptome-Based |
|---|---|---|
| How much is a gene expressed? | Yes | Yes, by aggregating transcripts |
| Which known transcript isoform is most abundant? | Requires additional analysis | Yes |
| Where do reads align on the genome? | Yes | Not directly |
| Can splice junctions be examined in IGV? | Yes | Not directly |
| Can known transcripts be quantified? | With additional tools | Yes |
| Can novel splice junctions be investigated? | Yes | Limited by the reference transcriptome |

#### 5. Biological Significance: An Isoform Switch

A particularly important application of transcriptome-based RNA-seq is detecting changes in transcript usage without changes in total gene expression.

Consider Gene A under two experimental conditions:

```text
                   BEFORE       AFTER
                   ------       -----

Transcript A1         90           10
Transcript A2         10           90
                    ----         ----
Gene A Total         100          100
```

The total estimated expression of Gene A remains unchanged at 100 counts.

However, the dominant transcript changes from A1 to A2.

This is called an *isoform switch*.

If the two transcripts encode proteins with different structures or functions, this change could have important biological consequences even though total gene expression remains constant.

A gene-level count matrix alone would not reveal this change.

#### 6. Conclusion

Genome-based RNA-seq provides information about gene expression and the genomic locations of aligned reads, including exon coverage and splice junctions. Transcriptome-based RNA-seq provides estimates of individual transcript abundance, making it possible to investigate alternative splicing and changes in isoform usage.

Our HISAT2 and featureCounts workflow produced gene-level counts, while our Salmon workflow produced transcript-level estimates that we subsequently aggregated into gene-level counts.

Both approaches are useful, but they answer different biological questions. Most importantly, **a gene can maintain the same overall expression while dramatically changing which transcript isoforms it produces.**

*Note: The counts in this example are hypothetical and intended to illustrate the biological distinction. Salmon estimates the abundance of transcripts represented in its reference transcriptome.*

### Generate a count matrix

Generate two count matrices from transcript-level quantification.

When performing transcript-level quantification, the results can be summarized at two different levels:

1. Transcript-level counts: how the tool reports the counts.
2. Gene-level counts: the sum of the transcript-level counts for all transcripts in a gene.

#### Relevant chapters¶

* Set up the R environment - ensure you have the necessary packages installed
* Transcriptome-based RNA-Seq - transcript-level quantification
* Combine counts - tutorial on summarizing counts

Solve this problem with two different R scripts, or with a single R script that has two behaviors you can select.

Place the scripts into the src subdirectory of your repository.

#### The task¶

Visualize the coverage for all samples and the GTF file in IGV.

Perform the transcript-based quantification.

Now let the AI prompting palooza begin. Write one or more R scripts that:

1. Combine the individual transcript counts into a single transcript-level count matrix.
2. Combine the resulting transcript-level counts into another gene-level count matrix.
3. Ensure that both count matrices also have gene names associated with each row.

Refer to your previous assignment that visually identified highly expressed genes. Does your count matrix support the visually identified behavior?

## Analysis

Run make to view the help and options:

```bash
make
```

```
# Salmon RNA-seq Transcript Quantification
#
# SAMPLE=HBR_1
# THREADS=4
# JOBS=2
#
# make data    Download and prepare tutorial data
# make index   Build Salmon transcript index
# make counts  Quantify one sample
# make all     Run index and counts for one sample
# make batch   Process all samples and generate count matrices
# make clean   Remove downloaded data and generated results
```

Run make batch which processes all the samples and generate count matrixes:

```bash
make batch
```

## Results

View the transcript-level count matrix (first 5 genes with nonzero expression)

```bash
# 1. Transcript-level count matrix (first 5 expressed transcripts)
# Retain transcript ID and gene name; preserve original precision.
xan filter 'HBR_1 > 0 || UHR_1 > 0' counts/transcript_counts.csv \
    | xan slice -l 5 \
    | xan select transcript_id,gene_name,HBR_1,HBR_2,HBR_3,UHR_1,UHR_2,UHR_3 \
    | xan view --hide-index
```

```text
Displaying 8 cols from 5 rows of <stdin>
┌───────────────────┬───────────────┬───────┬───────┬───────┬───────┬───────┬───────┐
│ transcript_id     │ gene_name     │ HBR_1 │ HBR_2 │ HBR_3 │ UHR_1 │ UHR_2 │ UHR_3 │
├───────────────────┼───────────────┼───────┼───────┼───────┼───────┼───────┼───────┤
│ ENST00000623391.1 │ LA16c-60D12.1 │ 1.001 │ 4.999 │ 1     │ 6.431 │ 3.409 │ 7.753 │
│ ENST00000623199.1 │ LA16c-60D12.2 │ 2     │ 1     │ 1.001 │ 6.674 │ 8.287 │ 2.992 │
│ ENST00000426025.1 │ NF1P6         │ 0     │ 0     │ 0     │ 1     │ 1     │ 0     │
│ ENST00000621704.4 │ POTEH         │ 0     │ 0     │ 1     │ 6.153 │ 0     │ 2.282 │
│ ENST00000452800.1 │ POTEH         │ 0     │ 0     │ 0     │ 1.847 │ 0     │ 0     │
└───────────────────┴───────────────┴───────┴───────┴───────┴───────┴───────┴───────┘
```

View the gene-level count matrix (first 5 genes with nonzero expression)

```bash
# 2. Gene-level count matrix (first 5 expressed genes)
# Retain gene name and all six samples; preserve original precision.
xan filter 'HBR_1 > 0 || UHR_1 > 0' counts/gene_counts.csv \
    | xan slice -l 5 \
    | xan select gene_name,HBR_1,HBR_2,HBR_3,UHR_1,UHR_2,UHR_3 \
    | xan view --hide-index
```

```text
Displaying 7 cols from 5 rows of <stdin>
┌───────────┬────────┬─────────┬────────┬─────────┬─────────┬─────────┐
│ gene_name │ HBR_1  │ HBR_2   │ HBR_3  │ UHR_1   │ UHR_2   │ UHR_3   │
├───────────┼────────┼─────────┼────────┼─────────┼─────────┼─────────┤
│ MAPK8IP2  │ 402    │ 543.815 │ 474    │ 14      │ 17.34   │ 8.981   │
│ BID       │ 40     │ 42.999  │ 49     │ 105.001 │ 63.999  │ 103.685 │
│ TYMP      │ 13.515 │ 11      │ 19     │ 47.001  │ 18.891  │ 26      │
│ NCAPH2    │ 80.001 │ 83.999  │ 77.831 │ 212.929 │ 124.082 │ 166.022 │
│ RTN4R     │ 71     │ 91.999  │ 82     │ 18      │ 10      │ 11      │
└───────────┴────────┴─────────┴────────┴─────────┴─────────┴─────────┘
```

### Validation of RNA-Seq Gene Expression Using Count Matrices

#### Question

Refer to your previous assignment that visually identified highly expressed genes. Does your count matrix support the visually identified behavior?

#### Methodology

To validate the transcriptome-based RNA-seq results, the gene-level count matrix generated from Salmon quantification was examined for two genes previously investigated using IGV: MAPK1 and YWHAH.

The gene-level count matrix contains estimated expression counts for 1,369 genes across six samples: three Human Brain Reference (HBR) replicates and three Universal Human Reference (UHR) replicates.

The counts were obtained by aggregating transcript-level abundance estimates from Salmon. Gene identifiers and names were obtained from the `chr22.gtf` annotation file.

The analysis compared estimated counts across all six samples and calculated the mean expression and HBR/UHR expression ratio for each gene.

#### Analysis Commands

The following command extracts the MAPK1 and YWHAH records from the gene-level count matrix:

```bash
# Extract MAPK1 and YWHAH gene-level counts
grep -E '"(MAPK1|YWHAH)"' counts/gene_counts.csv
```

Output:

```text
"ENSG00000100030.14","MAPK1",735,942.999,895,826,491,654.001
"ENSG00000128245.14","YWHAH",1027.001,1354,1145.001,333,217.999,293
```

#### Results

The following table presents the estimated gene-level counts across all six samples. Values are rounded to the nearest whole count.

| Gene | HBR_1 | HBR_2 | HBR_3 | UHR_1 | UHR_2 | UHR_3 |
|---|---:|---:|---:|---:|---:|---:|
| MAPK1 | 735 | 943 | 895 | 826 | 491 | 654 |
| YWHAH | 1,027 | 1,354 | 1,145 | 333 | 218 | 293 |

Mean estimated counts were calculated for each experimental group:

```text
MAPK1

HBR Mean = (735 + 943 + 895) / 3 = 857.67
UHR Mean = (826 + 491 + 654) / 3 = 657.00

HBR/UHR Ratio = 857.67 / 657.00 = 1.31


YWHAH

HBR Mean = (1027 + 1354 + 1145) / 3 = 1175.33
UHR Mean = (333 + 218 + 293) / 3 = 281.33

HBR/UHR Ratio = 1175.33 / 281.33 = 4.18
```

The following table summarizes the mean estimated counts and expression ratios.

| Gene | HBR Mean | UHR Mean | HBR/UHR Ratio |
|---|---:|---:|---:|
| MAPK1 | 857.67 | 657.00 | 1.31 |
| YWHAH | 1,175.33 | 281.33 | 4.18 |

#### Interpretation

The gene-level count matrix supports the expression patterns previously observed in IGV.

MAPK1 exhibits moderately higher estimated expression in HBR than UHR, with an HBR/UHR ratio of approximately 1.31. However, the individual replicate counts overlap between the two groups, suggesting that this difference is less pronounced.

YWHAH exhibits substantially higher estimated expression in HBR, with an HBR/UHR ratio of approximately 4.18. This agrees with the earlier IGV observation that YWHAH showed stronger RNA-seq coverage in the HBR samples.

All three HBR replicates have higher YWHAH counts than any of the three UHR replicates, providing additional support for the observed expression difference.

These comparisons use unnormalized estimated counts. Consequently, the calculated ratios are descriptive and should not be interpreted as statistically validated differential expression measurements.

A subsequent differential expression analysis using DESeq2 would account for library size differences and biological variability between replicates.

#### Conclusion

The Salmon-derived gene-level count matrix supports the previously observed IGV expression patterns for MAPK1 and YWHAH.

Both genes exhibit higher mean estimated expression in HBR than UHR, with YWHAH showing the substantially larger and more consistent difference across replicates.

This exercise demonstrates how transcript-level RNA-seq quantification can be aggregated into gene-level expression estimates and used to evaluate observations initially made through genome-browser visualization.

The agreement between the count matrix and IGV observations provides supporting evidence for the biological interpretation, while statistical analysis remains necessary to determine whether the observed differences represent significant differential gene expression.

## RNA-Seq Transcript Quantification and Gene Expression Analysis Summary

Building on the previous genome-based RNA-Seq exercise, which used HISAT2 and IGV to visually investigate gene expression, this exercise employed Salmon to quantify transcript abundance and evaluate whether the resulting gene-level counts supported the earlier observations. A reproducible Makefile workflow processed six RNA-Seq samples consisting of three Human Brain Reference (HBR) and three Universal Human Reference (UHR) replicates. Generative AI was used to develop two R scripts: `src/combine_transcript_counts.r`, which combined Salmon quantification results into a transcript-level count matrix, and `src/combine_gene_counts.r`, which aggregated transcript estimates into a gene-level count matrix using annotations from `chr22.gtf`. The resulting matrices were examined using `xan`, with particular attention given to MAPK1 and YWHAH, two genes previously investigated using IGV. The results supported the earlier visual observations: MAPK1 was expressed in both experimental groups, with approximately 1.31-fold higher mean estimated counts in HBR, while YWHAH exhibited approximately 4.18-fold higher mean estimated counts in HBR. The YWHAH result was consistent with the approximately 3.2-fold difference in local sequencing coverage observed in the previous exercise, although the two estimates represent different measurements and are not directly interchangeable. Furthermore, all three HBR replicates exhibited higher YWHAH counts than any of the UHR replicates, reinforcing the consistency of the observed expression difference. The previously observed low expression of HORMAD2 was not evaluated in the current count matrix comparison. Although these findings provide quantitative support for the earlier IGV observations, the Salmon-derived counts were not normalized for library size, and statistical significance was not evaluated. Overall, this exercise demonstrated how AI-assisted R programming, transcriptome-based quantification, and reproducible bioinformatics workflows can extend visual observations into quantitative gene expression analysis. Most importantly, it reinforced the progression from exploratory genome-browser visualization to quantitative measurement, establishing a foundation for subsequent statistical validation using DESeq2 or edgeR.