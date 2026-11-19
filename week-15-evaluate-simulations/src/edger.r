#!/usr/bin/env Rscript

# Differential expression with edgeR.
# The first group in the design file is the reference.
# log2FC is log2(second group / first group).
# Low-count genes are dropped with filterByExpr().
# METHOD "qlf" is the quasi-likelihood F-test.
# METHOD "classic" is the exact test.
# FDR is the Benjamini-Hochberg adjusted p-value.
# Normalized sample columns use TMM normalization, returned on the count scale.

# Input sample design. Columns: sample, group.
DESIGN_FILE = "design.csv"

# Input counts. An id column plus one column per sample.
COUNT_FILE = "counts.csv"

# Output differential expression table.
RESULT_FILE = "edger.csv"

# edgeR test. "qlf" or "classic".
METHOD = "qlf"

# Minimum count passed to filterByExpr().
MIN_COUNT = 10

# P-value and FDR cutoff reported in the summary.
PVAL = 0.05

# Install the optparse package automatically.
if(!require(optparse, quietly=T)){
  install.packages("optparse", repos="http://cran.us.r-project.org")
  library(optparse)
}

# Command line options.
option_list = list(

  make_option(c("-d", "--design_file"), action="store", default=DESIGN_FILE, dest="design_file", type="character",
              help="input sample design [%default]"),

  make_option(c("-c", "--count_file"), action="store", default=COUNT_FILE, dest="count_file", type="character",
              help="input counts with an id column [%default]"),

  make_option(c("-o", "--output"), action="store", default=RESULT_FILE, dest="result_file", type="character",
              help="output differential expression table [%default]"),

  make_option(c("-e", "--method"), action="store", default=METHOD, dest="method", type="character",
              help="edgeR test: qlf or classic [%default]"),

  make_option(c("-m", "--mincount"), action="store", default=MIN_COUNT, dest="min_count", type="integer",
              help="minimum count passed to filterByExpr() [%default]"),

  make_option(c("-p", "--pval"), action="store", default=PVAL, dest="pval", type="double",
              help="p-value and FDR cutoff reported in the summary [%default]")
)

# Parse the options.
opt = parse_args(OptionParser(option_list=option_list))

# Set the values from the options.
design_file = opt$design_file
count_file = opt$count_file
result_file = opt$result_file
method = opt$method
min_count = opt$min_count
pval = opt$pval

method = match.arg(method, c("qlf", "classic"))

cat("#\n")
cat("# Differential expression with edgeR\n")
cat("#\n")
cat("# https://bioconductor.org/packages/release/bioc/html/edgeR.html\n")
cat("# Pass the -h flag to get help on parameters\n")

suppressPackageStartupMessages(library(edgeR))

# Read the sample design and check that it has two groups.
read_design <- function(path) {
  cat("# Loading design from:", path, "\n")
  design <- read.csv(path, strip.white = TRUE, stringsAsFactors = FALSE)
  if (!all(c("sample", "group") %in% names(design))) {
    stop("Design file must have sample and group columns")
  }
  if (anyDuplicated(design$sample)) stop("Sample names are not unique")
  design$group <- factor(design$group, levels = unique(design$group))
  groups <- levels(design$group)
  if (length(groups) != 2) {
    stop("Design must contain exactly two groups, found: ", paste(groups, collapse = ", "))
  }
  if (any(table(design$group) < 2)) stop("Each group needs at least two samples")
  cat("# Reference group:", groups[1], "\n")
  cat("# Comparison group:", groups[2], "\n")
  for (g in groups) {
    cat("# Group", g, "has", sum(design$group == g), "samples\n")
  }
  design
}

# Read the count table and check that every design sample is present.
read_counts <- function(path, design) {
  cat("# Loading counts from:", path, "\n")
  counts <- read.csv(path, check.names = FALSE, strip.white = TRUE, stringsAsFactors = FALSE)
  if (!"id" %in% names(counts)) stop("Count file must have an id column")
  if (anyDuplicated(counts$id)) stop("Ids are not unique")
  missing <- setdiff(design$sample, colnames(counts))
  if (length(missing)) {
    stop("Missing samples in counts: ", paste(missing, collapse = ", "))
  }
  if (anyNA(counts[, design$sample])) stop("Count matrix contains missing values")
  cat("# Input:", nrow(counts), "genes\n")
  counts
}

# Integer count matrix with genes as rows and samples as columns.
count_matrix <- function(counts, samples) {
  mat <- round(as.matrix(counts[, samples, drop = FALSE]))
  storage.mode(mat) <- "integer"
  rownames(mat) <- counts$id
  if (any(mat < 0)) stop("Counts must be non-negative")
  mat
}

# Fit edgeR and return the test table plus TMM-normalized counts.
fit_edger <- function(mat, design) {
  groups <- levels(design$group)
  dge <- DGEList(counts = mat, group = design$group)
  keep <- filterByExpr(dge, min.count = min_count)
  cat("# Filtering low-count genes\n")
  cat("# Removed:", sum(!keep), "genes\n")
  dge <- dge[keep, , keep.lib.sizes = FALSE]
  if (!nrow(dge)) stop("No genes passed the count filter")
  dge <- normLibSizes(dge)

  cat("# Method:", method, "\n")
  cat("# Fitting edgeR on", nrow(dge), "genes\n")
  cat("# Contrast:", groups[2], "vs", groups[1], "\n")

  if (method == "qlf") {
    model <- data.frame(group = dge$samples$group)
    design_mat <- model.matrix(~group, data = model)
    dge <- estimateDisp(dge, design_mat)
    fit <- glmQLFit(dge, design_mat)
    test <- glmQLFTest(fit, coef = 2)
  } else {
    dge <- estimateCommonDisp(dge)
    dge <- estimateTagwiseDisp(dge)
    test <- exactTest(dge, pair = c(groups[1], groups[2]))
  }

  # Library size times the TMM factor. Dividing by it puts samples on one scale.
  scale <- dge$samples$lib.size * dge$samples$norm.factors
  norm <- sweep(dge$counts, 2, scale, "/") * mean(scale)
  list(res = topTags(test, n = Inf, sort.by = "none")$table, norm = norm)
}

# Same columns as deseq2.2026.r, so the two tables can be compared.
result_table <- function(counts, design, res, norm) {
  groups <- levels(design$group)
  a <- design$sample[design$group == groups[1]]
  b <- design$sample[design$group == groups[2]]
  genes <- rownames(res)
  anno_cols <- setdiff(colnames(counts), design$sample)
  anno <- counts[match(genes, counts$id), anno_cols, drop = FALSE]
  rownames(anno) <- NULL

  pvalue <- res$PValue
  fdr <- res$FDR
  pvalue[is.na(pvalue)] <- 1
  fdr[is.na(fdr)] <- 1
  norm <- norm[genes, c(a, b), drop = FALSE]
  lfc <- as.numeric(res$logFC)

  tab <- data.frame(
    anno,
    baseMean = round(rowMeans(norm), 1),
    baseMeanA = round(rowMeans(norm[, a, drop = FALSE]), 1),
    baseMeanB = round(rowMeans(norm[, b, drop = FALSE]), 1),
    foldChange = round(2 ^ lfc, 3),
    log2FC = round(lfc, 3),
    PValue = signif(as.numeric(pvalue), 4),
    FDR = signif(as.numeric(fdr), 4),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  rownames(tab) <- genes
  tab <- tab[order(tab$FDR, tab$PValue), , drop = FALSE]
  tab$falsePos <- round(seq_len(nrow(tab)) * tab$FDR, 1)
  for (sample in c(a, b)) {
    tab[[sample]] <- round(norm[rownames(tab), sample], 1)
  }
  rownames(tab) <- NULL
  tab
}

# Print how many genes pass the p-value and FDR cutoffs.
report <- function(tab) {
  n <- nrow(tab)
  n_p <- sum(tab$PValue < pval)
  n_f <- sum(tab$FDR < pval)
  cat(sprintf("# Fitted: %d genes\n", n))
  cat(sprintf("# Uncorrected P-values < 0.05: %d (%.1f%%)\n", n_p, 100 * n_p / n))
  cat(sprintf("# Significant FDR < 0.05: %d (%.1f%%)\n", n_f, 100 * n_f / n))
}

design <- read_design(design_file)
counts <- read_counts(count_file, design)
fit <- fit_edger(count_matrix(counts, design$sample), design)
tab <- result_table(counts, design, fit$res, fit$norm)
report(tab)

dir.create(dirname(result_file), showWarnings = FALSE, recursive = TRUE)
cat("# Saving results to:", result_file, "\n")
write.csv(tab, result_file, row.names = FALSE, quote = FALSE)
