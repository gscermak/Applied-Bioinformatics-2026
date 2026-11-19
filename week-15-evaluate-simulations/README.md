# Applied Bioinformatics 2026

## Assignment 15: Evaluate Simulations

## Introduction

### Evaluate simulations

In the RNA-Seq simulation assignment I presented the rationale for running differential expression analysis on simulated data.

The resulting edger.csv or deseq2.csv file will contain a column for the status of the gene, which comes from the simulation and indicates wether it was changed or not: changed or unchanged. The file also contains a column for the FDR (False Discovery Rate) adjusted p-value that the method determined based on the simulated data.

#### The task

Run a simulation then perform a differential expression analysis on the simulated data.

Study by eye the resulting csv file. Think about how each value was determined. Try to understand the logic behind the results.

Write code that compares the known state with the results of the differential expression analysis and finds the:

* TP: True positives - genes that were changed and have an FDR < 0.05
* FP: False positives - genes that were unchanged yet have FDR < 0.05
* TN: True negatives - genes that were unchanged and have FDR >= 0.05
* FN: False negatives - genes that were changed yet have FDR >= 0.05

Come up with one (or more) scoring formula(s) that use these values to quantify the performanc as a single number.

#### Submission requirements

Summarize your findings in a README.md file.

* How many TP, FP, TN, and FN did you get?
* Do edgeR and DESeq2 produce the same results?
* Which method seems to be more accurate?
* If you rerun the simulation, do you get the same results?

## Analysis

Invoke the stats environment:

```bash
stats
```

```
# Activating stats ... 
(stats) 
```

Run make to see the options:

```bash
make
```

```
RNA-Seq Simulation Workflow
====================================
make download   Download R scripts
make simulate   Generate simulated RNA-seq data
make edger      Run edgeR analysis
make deseq2     Run DESeq2 analysis
make evaluate   Calculate classification and F1 scores
make results    Display saved results
make all        Run complete workflow
make clean      Remove generated data and results

Simulation random seed: 40
```

Run make all -n to see the commands to be executed:

```bash
make all -n
```

```
Rscript src/simulate_counts.r -s 40
test -s simulated_counts.csv
test -s simulated_design.csv
Rscript src/edger.r -c simulated_counts.csv -d simulated_design.csv
test -s edger.csv
Rscript src/deseq2.r -c simulated_counts.csv -d simulated_design.csv
test -s deseq2.csv
mkdir -p results
Rscript src/evaluate_simulation.r
test -s results/simulation_evaluation.csv
echo ""
echo "Saved Evaluation Results"
echo "===================================="
cat results/simulation_evaluation.csv
echo ""
echo "RNA-Seq simulation workflow complete."
```

Run the simulation:

```bash
make all
```

```
Rscript src/simulate_counts.r -s 40
#
# RNA-Seq count matrix simulation
#
# https://bioconductor.org/packages/release/bioc/html/PROPER.html
# Pass the -h flag to get help on parameters
# Random seed: 40 
# Dispersion: low (bottomly)
# Minimum total count: 10 
# Library size: 1 million reads
# Replicates: 3 
# Total genes: 10000 
# Genes with data: 3473
# Genes that changed: 181 (1.8%)
# Changed genes that pass filter: 150 (82.9%)
# Saving design to: simulated_design.csv 
# Saving counts to: simulated_counts.csv 
test -s simulated_counts.csv
test -s simulated_design.csv
Rscript src/edger.r -c simulated_counts.csv -d simulated_design.csv
#
# Differential expression with edgeR
#
# https://bioconductor.org/packages/release/bioc/html/edgeR.html
# Pass the -h flag to get help on parameters
# Loading design from: simulated_design.csv 
# Reference group: A 
# Comparison group: B 
# Group A has 3 samples
# Group B has 3 samples
# Loading counts from: simulated_counts.csv 
# Input: 10000 genes
# Filtering low-count genes
# Removed: 7827 genes
# Method: qlf 
# Fitting edgeR on 2173 genes
# Contrast: B vs A 
# Fitted: 2173 genes
# Uncorrected P-values < 0.05: 187 (8.6%)
# Significant FDR < 0.05: 76 (3.5%)
# Saving results to: edger.csv 
test -s edger.csv
Rscript src/deseq2.r -c simulated_counts.csv -d simulated_design.csv
# Running DESeq2 
# Design: simulated_design.csv 
# Counts: simulated_counts.csv 
# Sample column: sample 
# Factor column: group 
# Group A has 3 samples.
# Group B has 3 samples.
# Initializing  DESeq2 tibble dplyr tools ... done
converting counts to integer mode
estimating size factors
estimating dispersions
gene-wise dispersion estimates
mean-dispersion relationship
final dispersion estimates
fitting model and testing
# Input: 10000 rows
# Removed: 6935 rows
# Fitted: 3065 rows
# Significant PVal: 190 ( 6.2 %)
# Significant FDRs: 98 ( 3.2 %)
# Results: deseq2.csv 
test -s deseq2.csv
mkdir -p results
Rscript src/evaluate_simulation.r

====================================
 RNA-Seq Simulation Evaluation
====================================

Ground Truth:
Total genes:    10000 
Changed genes:  181 
Unchanged:      9819 

F1 Formula:
F1 = 2 * TP / (2 * TP + FP + FN)

Classification Results:
 Method TP FP   TN  FN    F1
  edgeR 73  3 9816 108 0.568
 DESeq2 84 14 9805  97 0.602

Interpretation:
F1 ranges from 0 to 1.
Higher scores indicate better performance.

Higher F1 Score: DESeq2

Evaluation includes all simulated genes.
Filtered genes are treated as negative predictions.

Results saved to results/simulation_evaluation.csv
test -s results/simulation_evaluation.csv

Saved Evaluation Results
====================================
"Method","TP","FP","TN","FN","F1"
"edgeR",73,3,9816,108,0.568
"DESeq2",84,14,9805,97,0.602

RNA-Seq simulation workflow complete.
```

## Results

### *How many TP, FP, TN, and FN did you get?*

### RNA-Seq Differential Expression Evaluation Results

| Method | TP | FP | TN | FN | F1 Score |
|--------|---:|---:|---:|---:|---------:|
| edgeR  | 73 | 3  | 9,816 | 108 | 0.568 |
| DESeq2 | 84 | 14 | 9,805 | 97  | 0.602 |

### *Do edgeR and DESeq2 produce the same results?*

No. Although edgeR and DESeq2 analyzed the same simulated RNA-seq dataset using the same experimental design, they produced different results. edgeR correctly identified 73 changed genes with only 3 false positives, while DESeq2 correctly identified 84 changed genes but produced 14 false positives. DESeq2 achieved a slightly higher F1 score (0.602 versus 0.568), indicating a better balance between precision and sensitivity in this simulation. Neither method detected all 181 genuinely changed genes. These differences reflect variations in statistical modeling and gene filtering, demonstrating that the choice of analysis method can influence the interpretation of differential gene expression.

### *Which method seems to be more accurate?*

DESeq2 appears to perform slightly better in this simulation, achieving an F1 score of 0.602 compared with 0.568 for edgeR. DESeq2 correctly identified 84 changed genes, while edgeR identified 73. However, edgeR produced fewer false positives (3 versus 14), indicating greater precision. Although DESeq2 achieved the higher F1 score, the difference is relatively small. These results suggest that DESeq2 provides a slightly better balance between detecting genuine expression changes and avoiding false positives, but additional simulations would be needed to determine whether this advantage is consistent.

### *If you rerun the simulation, do you get the same results?*

Yes, provided the simulation uses the same random seed, parameters, and software versions. Initially, our simulation produced different results because the random seed changed from 40 to 39. We modified the Makefile to use a fixed random seed of 40, ensuring that the same simulated RNA-seq dataset is generated each time. Consequently, edgeR and DESeq2 should produce identical results across repeated runs under the same computational conditions. If we change the random seed, the simulated gene expression data will change, potentially producing different numbers of true positives, false positives, true negatives, false negatives, and F1 scores. This demonstrates the importance of controlling random variation to ensure reproducibility in bioinformatics experiments.

## Summary

In this exercise, we simulated RNA-seq count data containing 10,000 genes, including 181 deliberately changed genes, to evaluate the performance of edgeR and DESeq2 in detecting differential gene expression. Both methods analyzed the same simulated dataset and experimental design, allowing us to compare their results against the known ground truth. We developed R scripts to calculate true positives (TP), false positives (FP), true negatives (TN), and false negatives (FN), then automated the workflow using a Makefile with a fixed random seed of 40 to ensure reproducibility. We selected the F1 score as our primary performance statistic because it combines precision and sensitivity into a single measure while accounting for both false positives and false negatives. The F1 score is calculated as `F1 = 2 × TP / (2 × TP + FP + FN)`, with values ranging from 0 (poor performance) to 1 (perfect performance). DESeq2 achieved a slightly higher F1 score (0.602) than edgeR (0.568), although edgeR produced fewer false positives. Our evaluation included all simulated genes, treating filtered-out genes as negative predictions. The exercise demonstrated that statistical significance does not necessarily capture all genuine biological expression changes and that different analytical methods can produce different conclusions from identical data. It also highlighted the importance of simulation, reproducibility, and appropriate performance metrics when evaluating bioinformatics methods.