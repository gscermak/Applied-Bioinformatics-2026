
#!/usr/bin/env Rscript

# ============================================================
# Task 1: Combine Salmon transcript-level counts
#
# Input:
#   design.csv
#   gtf/chr22.gtf
#   counts/<sample>/quant.sf
#
# Output:
#   counts/transcript_counts.csv
#
# Each row represents one transcript.
# Each sample is represented by one column.
# Gene IDs and gene names are obtained from the GTF.
# ============================================================

suppressPackageStartupMessages({
  library(tximport)
})

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

DESIGN <- "design.csv"
GTF <- "gtf/chr22.gtf"
OUTPUT <- "counts/transcript_counts.csv"

# ------------------------------------------------------------
# Read sample design
# ------------------------------------------------------------

design <- read.csv(
  DESIGN,
  stringsAsFactors = FALSE
)

samples <- design$sample

# Construct Salmon file paths.
files <- file.path("counts", samples, "quant.sf")
names(files) <- samples

# Verify input files exist.
if (!all(file.exists(files))) {
  stop(
    "Missing Salmon files:\n",
    paste(files[!file.exists(files)], collapse = "\n")
  )
}

# ------------------------------------------------------------
# Read transcript annotations from GTF
# ------------------------------------------------------------

# IMPORTANT:
# quote = "" preserves quotation marks in GTF attributes.

gtf <- read.delim(
  GTF,
  header = FALSE,
  sep = "\t",
  quote = "",
  comment.char = "#",
  stringsAsFactors = FALSE
)

# Keep transcript records only.
gtf <- gtf[gtf$V3 == "transcript", ]

# Extract an attribute from the GTF attribute column.
extract_attribute <- function(x, key) {

  pattern <- paste0(
    "(?:^|;[[:space:]]*)",
    key,
    '[[:space:]]+"([^"]+)"'
  )

  result <- regmatches(
    x,
    regexec(pattern, x, perl = TRUE)
  )

  vapply(
    result,
    function(y) {
      if (length(y) > 1) {
        y[2]
      } else {
        NA_character_
      }
    },
    character(1)
  )
}

# Build transcript annotation table.
annotations <- data.frame(
  transcript_id = extract_attribute(
    gtf$V9, "transcript_id"
  ),
  gene_id = extract_attribute(
    gtf$V9, "gene_id"
  ),
  gene_name = extract_attribute(
    gtf$V9, "gene_name"
  ),
  stringsAsFactors = FALSE
)

# Remove missing transcript IDs and duplicate records.
annotations <- annotations[
  !is.na(annotations$transcript_id),
]

annotations <- unique(annotations)

# Verify that each transcript maps to one annotation.
if (anyDuplicated(annotations$transcript_id)) {
  stop("Conflicting or duplicate transcript annotations in GTF.")
}

# ------------------------------------------------------------
# Import Salmon transcript counts
# ------------------------------------------------------------

txi <- tximport(
  files,
  type = "salmon",
  txOut = TRUE
)

# Extract estimated transcript counts.
counts <- as.data.frame(txi$counts)

# Preserve transcript identifiers.
counts$transcript_id <- rownames(counts)

# ------------------------------------------------------------
# Associate gene annotations
# ------------------------------------------------------------

# Match Salmon transcripts to GTF annotations.
index <- match(
  counts$transcript_id,
  annotations$transcript_id
)

# Build final transcript count matrix.
result <- data.frame(
  transcript_id = counts$transcript_id,
  gene_id = annotations$gene_id[index],
  gene_name = annotations$gene_name[index],
  counts[, samples, drop = FALSE],
  check.names = FALSE,
  stringsAsFactors = FALSE
)

# ------------------------------------------------------------
# Validate results
# ------------------------------------------------------------

missing_gene_ids <- sum(is.na(result$gene_id))
missing_gene_names <- sum(is.na(result$gene_name))

if (missing_gene_ids > 0) {
  warning(
    missing_gene_ids,
    " transcripts have no matching gene ID."
  )
}

if (missing_gene_names > 0) {
  warning(
    missing_gene_names,
    " transcripts have no matching gene name."
  )
}

# ------------------------------------------------------------
# Save transcript count matrix
# ------------------------------------------------------------

dir.create(
  dirname(OUTPUT),
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  result,
  OUTPUT,
  row.names = FALSE,
  na = ""
)

# ------------------------------------------------------------
# Report results
# ------------------------------------------------------------

cat("\n")
cat("========================================\n")
cat(" Transcript-Level Count Matrix\n")
cat("========================================\n")
cat("Output:             ", OUTPUT, "\n")
cat("Transcripts:        ", nrow(result), "\n")
cat("Samples:            ", length(samples), "\n")
cat("Missing gene IDs:   ", missing_gene_ids, "\n")
cat("Missing gene names: ", missing_gene_names, "\n")
cat("========================================\n\n")
