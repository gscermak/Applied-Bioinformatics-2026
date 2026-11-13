#!/usr/bin/env Rscript

# ============================================================
# Task 2: Combine transcript counts into gene-level counts
#
# Input:
#   counts/transcript_counts.csv
#
# Output:
#   counts/gene_counts.csv
#
# Each row represents one gene.
# Transcript counts belonging to the same gene are summed.
# ============================================================

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

INPUT <- "results/transcript_counts.csv"
OUTPUT <- "results/gene_counts.csv"

# ------------------------------------------------------------
# Read transcript-level count matrix
# ------------------------------------------------------------

if (!file.exists(INPUT)) {
  stop("Missing input file: ", INPUT)
}

transcripts <- read.csv(
  INPUT,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# Identify sample columns.
sample_columns <- setdiff(
  names(transcripts),
  c("transcript_id", "gene_id", "gene_name")
)

# ------------------------------------------------------------
# Validate transcript annotations
# ------------------------------------------------------------

if (anyNA(transcripts$gene_id) ||
    any(transcripts$gene_id == "")) {
  stop("Some transcripts have missing gene IDs.")
}

# Verify that each gene ID has one gene name.
gene_names <- unique(
  transcripts[, c("gene_id", "gene_name")]
)

if (anyDuplicated(gene_names$gene_id)) {
  stop("Conflicting gene names found for the same gene ID.")
}

# ------------------------------------------------------------
# Aggregate transcript counts by gene
# ------------------------------------------------------------

# Sum the estimated counts of all transcripts belonging
# to each gene, independently for each sample.

gene_counts <- aggregate(
  transcripts[, sample_columns, drop = FALSE],
  by = list(gene_id = transcripts$gene_id),
  FUN = sum
)

# ------------------------------------------------------------
# Add gene names
# ------------------------------------------------------------

index <- match(
  gene_counts$gene_id,
  gene_names$gene_id
)

gene_counts$gene_name <- gene_names$gene_name[index]

# Arrange columns.
gene_counts <- gene_counts[
  ,
  c("gene_id", "gene_name", sample_columns)
]

# ------------------------------------------------------------
# Validate aggregation
# ------------------------------------------------------------

# The sum of transcript counts should equal the sum
# of gene counts for each sample, within numerical tolerance.

transcript_totals <- colSums(
  transcripts[, sample_columns, drop = FALSE]
)

gene_totals <- colSums(
  gene_counts[, sample_columns, drop = FALSE]
)

if (!isTRUE(all.equal(
  unname(transcript_totals),
  unname(gene_totals),
  tolerance = 1e-8
))) {
  stop("Validation failed: transcript and gene totals differ.")
}

# ------------------------------------------------------------
# Save gene-level count matrix
# ------------------------------------------------------------

dir.create(
  dirname(OUTPUT),
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  gene_counts,
  OUTPUT,
  row.names = FALSE
)

# ------------------------------------------------------------
# Report results
# ------------------------------------------------------------

cat("\n")
cat("========================================\n")
cat(" Gene-Level Count Matrix\n")
cat("========================================\n")
cat("Output:             ", OUTPUT, "\n")
cat("Transcripts:        ", nrow(transcripts), "\n")
cat("Genes:              ", nrow(gene_counts), "\n")
cat("Samples:            ", length(sample_columns), "\n")
cat("Missing gene names: ",
    sum(is.na(gene_counts$gene_name)), "\n")
cat("Count totals:        Validated\n")
cat("========================================\n\n")