# ============================================================
# Evaluate RNA-Seq Differential Expression Simulation
# ============================================================
#
# Purpose:
# Compare edgeR and DESeq2 against the known simulation
# ground truth using TP, FP, TN, FN, and F1 scores.
#
# Inputs:
#   simulated_counts.csv
#   edger.csv
#   deseq2.csv
#
# Output:
#   results/simulation_evaluation.csv
#
# F1 Formula:
#   F1 = 2 * TP / (2 * TP + FP + FN)
#
# Interpretation:
#   F1 = 1.0  Perfect classification
#   F1 = 0.0  No successful positive classifications
#
# Higher F1 scores indicate better performance.
#
# Genes excluded during filtering are classified as
# negative predictions.
#
# ============================================================

# ------------------------------------------------------------
# Read Simulation Ground Truth
# ------------------------------------------------------------

truth <- read.csv("simulated_counts.csv")

# Confirm gene identifiers are unique.
stopifnot(!anyDuplicated(truth$id))

# ------------------------------------------------------------
# Evaluation Function
# ------------------------------------------------------------

evaluate <- function(filename, method) {

  # Read differential expression results.
  df <- read.csv(filename)

  stopifnot(!anyDuplicated(df$id))

  # Match results to the original simulated gene IDs.
  index <- match(truth$id, df$id)

  # Missing genes are treated as negative predictions.
  # Missing FDR values are also treated as negative.
  predicted <- !is.na(index)

  predicted[predicted] <-
    !is.na(df$FDR[index[predicted]]) &
    df$FDR[index[predicted]] < 0.05

  # Known simulation ground truth.
  changed <- truth$status == "changed"

  # Classification counts.
  TP <- sum(changed & predicted)
  FP <- sum(!changed & predicted)
  TN <- sum(!changed & !predicted)
  FN <- sum(changed & !predicted)

  # Calculate F1 score.
  denominator <- 2 * TP + FP + FN

  F1 <- if (denominator == 0) {
    0
  } else {
    2 * TP / denominator
  }

  # Return results.
  data.frame(
    Method = method,
    TP = TP,
    FP = FP,
    TN = TN,
    FN = FN,
    F1 = round(F1, 3)
  )
}

# ------------------------------------------------------------
# Evaluate Both Methods
# ------------------------------------------------------------

edger <- evaluate("edger.csv", "edgeR")
deseq <- evaluate("deseq2.csv", "DESeq2")

results <- rbind(edger, deseq)

# ------------------------------------------------------------
# Display Results
# ------------------------------------------------------------

cat("\n====================================\n")
cat(" RNA-Seq Simulation Evaluation\n")
cat("====================================\n\n")

cat("Ground Truth:\n")
cat("Total genes:   ", nrow(truth), "\n")
cat("Changed genes: ", sum(truth$status == "changed"), "\n")
cat("Unchanged:     ", sum(truth$status == "unchanged"), "\n\n")

cat("F1 Formula:\n")
cat("F1 = 2 * TP / (2 * TP + FP + FN)\n\n")

cat("Classification Results:\n")
print(results, row.names = FALSE)

cat("\nInterpretation:\n")
cat("F1 ranges from 0 to 1.\n")
cat("Higher scores indicate better performance.\n\n")

# Identify the higher-scoring method.
if (edger$F1 > deseq$F1) {
  cat("Higher F1 Score: edgeR\n")
} else if (deseq$F1 > edger$F1) {
  cat("Higher F1 Score: DESeq2\n")
} else {
  cat("Both methods achieved the same F1 score.\n")
}

cat("\nEvaluation includes all simulated genes.\n")
cat("Filtered genes are treated as negative predictions.\n")

# ------------------------------------------------------------
# Save Results
# ------------------------------------------------------------

dir.create("results", showWarnings = FALSE)

write.csv(
  results,
  "results/simulation_evaluation.csv",
  row.names = FALSE
)

cat("\nResults saved to results/simulation_evaluation.csv\n")