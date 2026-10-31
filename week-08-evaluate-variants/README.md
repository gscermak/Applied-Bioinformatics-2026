# Applied Bioinformatics 2026

## Week08 - Evaluate Variants

In this assignment, visually evaluate existing alignments and identify variants.

Five samples have been sequenced with paired-end reads. A BAM file has been generated for each sample. Each sample may show a different type of variation (or no variation at all).

Visually inspect each file and make your best guess at what kind of variation is present.

No code writing is required.

### Sample 1

The instructor describes Sample 1 as ideal data with no sequencing errors and a mutation rate of `0.0005` per base. Once a mutation occurs, there is a 30% chance that it will be an indel. The sample contains `8` variants: `5` SNPs, `2` insertions, and `1` deletion. Some variants are homozygous and others are heterozygous, and the variants should be easy to identify visually in IGV.

![Instructor's IGV view and description of Sample 1](Screenshot%20from%202026-10-14%2011-14-45.png)

*Instructor's IGV view and description of Sample 1, showing the expected pattern of eight variants across the Ebola reference genome.*

My IGV view of Sample 1 shows the reads aligned across the Ebola reference genome. The reads are colored by strand, with the pink/red and blue colors representing reads aligned in opposite orientations. The variant positions appear as narrow vertical features that are repeated across multiple reads. From the whole-genome view, I identified five candidate SNPs and two insertions, matching the instructor's description.

![Whole-genome IGV view of Sample 1](Screenshot%20from%202026-10-14%2010-58-16.png)

*Whole-genome IGV view of Sample 1. The pink/red and blue read colors indicate read strand. Narrow colored vertical columns indicate SNPs, while the purple `I` markers identify insertions. Five SNPs and two insertions can be recognized across the genome.*

The deletion was more difficult to identify in the whole-genome view because IGV displays deletions as small gaps or dark lines within aligned reads rather than labeling them with a `D`. After zooming into the region near 8 kb, a vertical series of small black gaps became visible across multiple reads at approximately the same coordinate. This pattern is consistent with the single deletion described by the instructor.

![Zoomed IGV view showing the deletion in Sample 1](Screenshot%20from%202026-10-14%2011-01-10.png)

*Zoomed IGV view near 8 kb. The small black gaps aligned vertically across multiple reads indicate the deletion. Because the same gap occurs in several independent reads at the same genomic position, it represents a consistent sequence variant rather than a random alignment artifact.*

Overall, my visual inspection of Sample 1 agrees with the instructor's expected results. I identified `8` variants consisting of `5` SNPs, `2` insertions, and `1` deletion. The SNPs appeared as repeated colored base differences, the insertions were clearly marked by purple `I` symbols, and the deletion became apparent only after zooming in and identifying the repeated gap across multiple reads. The exercise also showed that strand coloring affects the appearance of the reads but is separate from the colored bases and indel markers used to identify sequence variants.

### Sample 2

The instructor describes Sample 2 as the same underlying data as Sample 1, but with a high sequencing error rate of `3%` (`0.03`). The true variants are the same as in Sample 1, but the reads contain many sequencing errors. As a result, the true variants are much harder to identify visually because they are masked by background noise.

![Instructor's IGV view and description of Sample 2](Screenshot%20from%202026-10-14%2011-26-26.png)

*Instructor's IGV view of Sample 2. The reads contain many colored mismatches caused by the simulated 3% sequencing error rate, making the true variants difficult to distinguish visually.*

My IGV view of Sample 2 shows much more background variation than Sample 1. Colored mismatches occur throughout nearly every read, which is consistent with the simulated 3% sequencing error rate. The two insertions can still be recognized by the vertical purple `I` markers, but the SNPs are difficult to identify visually because true variants are mixed with many random sequencing errors.

![Whole-genome IGV view of Sample 2](Screenshot%20from%202026-10-14%2011-27-09.png)

*Whole-genome IGV view of Sample 2. Numerous colored base mismatches are distributed throughout the aligned reads because of sequencing error. The two insertion sites remain visible as vertical purple `I` markers, but the SNPs are much harder to distinguish from the background noise.*

Overall, Sample 2 demonstrates how sequencing error can obscure real biological variation. Although the true variants are the same as in Sample 1, the large number of random mismatches makes visual identification much less reliable. A true variant should appear consistently at the same genomic position across multiple reads, while sequencing errors tend to be scattered more randomly throughout the alignments.

### Sample 3

The instructor describes Sample 3 as containing three copy number variations (CNVs). A reference arrangement represented as `ABCDEFG` has been changed to `ABBCDDDEFFG`, so region `B` is present twice, region `D` is present three times, and region `F` is present twice. The instructor notes that coverage can be used to estimate the number of copies present, although coverage alone does not show whether the duplicated regions are arranged in tandem.

![Instructor's IGV view and description of Sample 3](Screenshot%20from%202026-10-14%2011-42-18.png)

*Instructor's IGV view of Sample 3. The elevated coverage regions represent copy number variations, with approximately two copies of region `B`, three copies of region `D`, and two copies of region `F`.*

My IGV view of Sample 3 shows three clear regions of increased read coverage in the left portion of the genome. Two of these regions have coverage that is roughly twice the normal baseline, while the central region has the greatest coverage and is approximately three times the baseline. This pattern is consistent with two copies of `B`, three copies of `D`, and two copies of `F`.

![Whole-genome IGV view of Sample 3](Screenshot%20from%202026-10-14%2011-51-42.png)

*Whole-genome IGV view of Sample 3. The gray coverage track shows three elevated regions. The two smaller increases are consistent with approximately two copies, while the larger central increase is consistent with approximately three copies. The lower coverage across the remainder of the genome represents the normal single-copy baseline.*

Overall, Sample 3 demonstrates how copy number variation can be detected from changes in sequencing depth. Extra copies of a genomic region generate additional reads, and when those reads are aligned back to a reference containing only one copy, they pile up at the same reference location and produce increased coverage. The relative coverage therefore provides an estimate of copy number, but it does not by itself reveal the exact physical arrangement of the duplicated regions.

### Sample 4

The instructor describes Sample 4 as an inversion. In the simplified example, `ABC` is still present as `ABC`, but region `B` has been reverse complemented. Because an inversion changes the orientation of a DNA segment rather than necessarily changing the amount of DNA present, the most useful evidence in IGV comes from paired-read orientation rather than from changes in coverage.

![Instructor's IGV view and description of Sample 4](Screenshot%20from%202026-10-14%2012-32-16.png)

*Instructor's IGV view of Sample 4. The inversion is best visualized by examining read-pair orientation because the inverted segment causes some paired reads to align in an unexpected direction.*

In the initial whole-genome view, coverage remains relatively uniform across most of the genome, which is consistent with an inversion rather than a copy number change. However, a localized region around approximately 5–6 kb shows an unusual concentration of alignment features, suggesting that a structural change is present in this part of the genome.

![Default whole-genome IGV view of Sample 4](Screenshot%20from%202026-10-14%2012-35-37.png)

*Default IGV view of Sample 4. The coverage track remains fairly even, but a localized region around 5–6 kb shows an unusual alignment pattern that suggests a structural rearrangement.*

To examine the suspected inversion more clearly, the BAM track was changed to the following IGV settings:

- `View as pairs` → ON
- `Color alignments by` → `pair orientation`

These settings make it easier to identify paired reads whose orientation differs from the normal pattern.

![Zoomed IGV view of the inversion in Sample 4](Screenshot%20from%202026-10-14%2012-41-26.png)

*Zoomed IGV view of Sample 4 using paired-read orientation coloring. Most gray read pairs outside the affected region point in opposite directions, while the turquoise read pairs within the approximately 4.7–6.0 kb region have both mates pointing to the right. This abnormal pair orientation is evidence of an inversion and helps identify the approximate inversion boundaries.*

Overall, Sample 4 demonstrates how an inversion can be detected from abnormal paired-read orientation. The coverage remains relatively normal because the DNA has been rearranged rather than duplicated or deleted. In the inverted region, many paired reads show an unusual same-direction orientation compared with the normal opposite-direction pattern outside the region. This discordant orientation is the main visual evidence for the inversion in IGV.

### Sample 5

The instructor describes Sample 5 as a translocation or rearrangement in which the sequence order changes from `ABCD` to `ACBD`. The DNA segments are still present, but their positions relative to one another have changed. The instructor notes that this structural change is best visualized in IGV by examining paired-end reads and coloring the alignments by insert size.

![Instructor's IGV view and description of Sample 5](Screenshot%20from%202026-10-14%2012-55-18.png)

*Instructor's IGV view of Sample 5. The rearrangement changes the order of genomic segments, and abnormal paired-read spacing helps reveal the translocation.*

In the default whole-genome view, coverage remains relatively uniform across most of the genome. However, a concentrated region around approximately 5–7 kb shows unusual alignment patterns, providing an initial clue that a structural rearrangement is present.

![Default whole-genome IGV view of Sample 5](Screenshot%20from%202026-10-14%2012-57-40.png)

*Default IGV view of Sample 5. Coverage remains fairly even, but the region around 5–7 kb contains an unusual concentration of alignment features consistent with a structural rearrangement.*

To examine the rearrangement more clearly, the BAM track was changed to the following IGV settings:

- `View as pairs` → ON
- `Color alignments by` → `insert size`

These settings highlight read pairs whose mapped distance differs from the expected fragment size.

![Zoomed IGV view of the translocation in Sample 5](Screenshot%20from%202026-10-14%2013-00-41.png)

*Zoomed IGV view of Sample 5 using paired reads colored by insert size. The long red paired-read connections between approximately 4.6 and 6.2 kb indicate unusually large mapped insert sizes. Additional colored reads near approximately 7 kb provide further evidence of abnormal paired-read spacing associated with the rearrangement.*

Overall, Sample 5 demonstrates how a translocation or genomic rearrangement can be detected through abnormal paired-read insert sizes. Reads spanning a new junction in the sample may originate from fragments of normal physical size, but when aligned to the original reference genome, their mates can map much farther apart than expected. The resulting clusters of abnormally colored paired reads provide evidence that the order of genomic regions differs from the reference.

## Summary

This exercise demonstrated how different types of genomic variation produce distinct structural changes in DNA and different visual patterns in IGV. Across Samples 1–5, we examined SNPs, insertions, deletions, sequencing-error noise, copy number variation, inversions, and translocations or rearrangements. The exercise also showed that the most useful IGV display depends on the type of variation being investigated.

### Sample 1 – SNPs, Insertions, and a Deletion

Sample 1 contained ideal data with no sequencing errors and included `5` SNPs, `2` insertions, and `1` deletion. Because the reads were clean, these variants were easy to identify visually.

    SNP
    Reference:   A C G T A C
    Sample:      A C A T A C
                     ^
                  base changed

    Insertion
    Reference:   A C G - - T A
    Sample:      A C G T T T A
                       ^^
                    bases added

    Deletion
    Reference:   A C G T T A C
    Sample:      A C G - - A C
                       ^^
                    bases removed

A SNP changes a single nucleotide without changing the overall length of the DNA. In IGV, SNPs appeared as colored bases repeated at the same genomic position across multiple reads. An insertion adds one or more bases relative to the reference and was marked by a purple `I`. A deletion removes one or more bases and appeared as a small gap or dark line across several reads.

### Sample 2 – Effect of Sequencing Error

Sample 2 contained the same underlying variants as Sample 1, but a `3%` sequencing error rate introduced many additional random mismatches.

    True variant:
    --------G--------
    --------G--------
    --------G--------

    Sequencing errors:
    --A--------------
    ----------T------
    ----C------------
    ------------G----

The true variants were still present, but they were much harder to distinguish because colored mismatches occurred throughout nearly every read. A true variant tends to appear repeatedly at the same genomic position across multiple reads, while sequencing errors tend to be scattered more randomly. Sample 2 demonstrated how sequencing noise can obscure real biological variation.

### Sample 3 – Copy Number Variation

Sample 3 demonstrated copy number variation (CNV), where larger regions of DNA were present in extra copies.

    Reference:
    A - B - C - D - E - F - G

    Sample:
    A - B - B - C - D - D - D - E - F - F - G
        2 copies       3 copies        2 copies

Extra copies of a region produce additional sequencing reads from that region. When those reads are aligned back to a reference containing only one copy, they pile up at the same location.

    Normal region       ≈ 1× coverage
    Duplicated region   ≈ 2× coverage
    Triplicated region  ≈ 3× coverage

In IGV, the CNVs were identified primarily from changes in the coverage track. Two regions had roughly twice the normal coverage, while the central region had roughly three times the normal coverage. This showed that coverage depth can be used to estimate relative copy number, although coverage alone does not reveal exactly where the additional copies are physically located.

### Sample 4 – Inversion

Sample 4 demonstrated an inversion, where a segment of DNA is flipped and becomes reverse complemented.

    Reference:
    A ---> B ---> C

    Inversion:
    A ---> <--- B ---> C

The DNA segment is still present, but its orientation has been reversed. Because the amount of DNA may remain approximately the same, coverage does not necessarily change dramatically.

The useful IGV settings were:

- `View as pairs` → ON
- `Color alignments by` → `pair orientation`

Most gray read pairs outside the affected region pointed in opposite directions, while the colored read pairs within the inversion region had both mates pointing in the same direction. This abnormal paired-read orientation provided evidence for the inversion and helped identify its approximate boundaries.

### Sample 5 – Translocation / Rearrangement

Sample 5 demonstrated a translocation or rearrangement in which genomic segments changed their relative positions.

    Reference:
    A - B - C - D

    Sample:
    A - C - B - D

The DNA segments were still present, but their order had changed. A paired-end fragment spanning one of the new junctions could therefore map to locations that are much farther apart than expected when aligned back to the original reference.

    Normal pair:

    → ----------- ←
       expected distance

    Rearrangement-spanning pair:

    → ------------------------------- ←
            abnormal mapped distance

The useful IGV settings were:

- `View as pairs` → ON
- `Color alignments by` → `insert size`

Clusters of colored paired reads with unusually large insert sizes provided evidence that the genomic segments had been rearranged relative to the reference.

Overall, the five samples showed that different genomic variants leave different signatures in aligned sequencing data. SNPs change individual bases, insertions add bases, deletions remove bases, sequencing errors create background noise, CNVs change the number of copies of larger DNA segments, inversions flip segments into the reverse-complement orientation, and translocations or rearrangements change the order or location of genomic segments. IGV makes these differences visible through base mismatches, indel markers, coverage depth, paired-read orientation, and insert size.

