#!/usr/bin/env Rscript

#
# Read count simulator with PROPER
#
# Wu H, Wang C, Wu Z (2014). "PROPER: Comprehensive Power Evaluation for Differential Expression using RNA-seq." Bioinformatics.
#
# https://bioconductor.org/packages/release/bioc/html/PROPER.html
#
# BiocManager::install("PROPER")
#

# The simulated design file.
DESIGN_FILE = "simulated_design.csv"

# The simulated counts file.
COUNTS_FILE = "simulated_counts.csv"

# The number of simulated genes.
N_GENES = 10000

# The number of replicates.
N_REPS = 3

# A gene passes when its total count is at least this.
# Same rule as deseq2.2026.r: rowSums >= MIN_COUNT.
MIN_COUNT = 10

# Library size in millions of reads per sample.
# 1 is 1 million reads. 1.2 is 1.2 million.
LIBRARY_SIZE = 1

# Within-group dispersion, taken from a PROPER dataset.
# zero = maqc (technical replicates, dispersion near 0)
# low = bottomly (inbred mice, small dispersion)
# medium = gilad (male vs female liver, moderate dispersion)
# high = cheung (unrelated individuals, large dispersion)
DISPERSION = "low"

# Random seed. 0 draws a seed from 1 to 100.
SEED = 0

# Install the optparse package automatically.
if(!require(optparse, quietly=T)){
  install.packages("optparse", repos="http://cran.us.r-project.org")
  library(optparse)
}

# Command line options.
option_list = list(

  make_option(c("-d", "--design_file"), action="store", default=DESIGN_FILE, dest="design_file", type='character',
              help="simulated design file [%default]"),

  make_option(c("-o", "--output"), action="store", default=COUNTS_FILE, dest="counts_file", type='character',
              help="simulated counts  [%default]"),

  make_option(c("-n", "--ngenes"), action="store", default=N_GENES, dest="n_genes", type='integer',
              help="the number of simulated genes [%default]"),

  make_option(c("-r", "--nreps"), action="store", default=N_REPS, dest="n_reps", type='integer',
              help="the number of replicates [%default]"),

  make_option(c("-e", "--dispersion"), action="store", default=DISPERSION, dest="dispersion", type='character',
              help="dispersion: zero, low, medium, high [%default]"),

  make_option(c("-m", "--mincount"), action="store", default=MIN_COUNT, dest="min_count", type='integer',
              help="a gene passes when its total count is at least this [%default]"),

  make_option(c("-l", "--library_size"), action="store", default=LIBRARY_SIZE, dest="library_size", type='double',
              help="library size in millions of reads per sample [%default]"),

  make_option(c("-s", "--seed"), action="store", default=SEED, dest="n_seed", type='integer',
              help="set the seed for the simulation [%default]")
)

# Parse the options.
opt = parse_args(OptionParser(option_list=option_list))

# Set the values from the options.
design_file = opt$design_file
counts_file = opt$counts_file
n_genes = opt$n_genes
n_reps = opt$n_reps
dispersion = opt$dispersion
min_count = opt$min_count
library_size = opt$library_size
n_seed= opt$n_seed

# Map the dispersion label to a PROPER dataset.
dispersion = match.arg(dispersion, c("zero", "low", "medium", "high"))
e_name = switch(dispersion,
  zero = "maqc",
  low = "bottomly",
  medium = "gilad",
  high = "cheung"
)

# Load required Bioconductor packages.
pkgs <- c("PROPER")
cat("#\n")
cat("# RNA-Seq count matrix simulation\n")
cat("#\n")
cat("# https://bioconductor.org/packages/release/bioc/html/PROPER.html\n")
cat("# Pass the -h flag to get help on parameters\n")
status = suppressPackageStartupMessages(
  lapply(pkgs, library, character.only = TRUE)
)

# Set the seed. Random seed if not specified.
if (n_seed == 0) {
    seed <- sample.int(100,size=1)
} else {
    seed <- n_seed
}


cat("# Random seed:", seed, "\n")
cat("# Dispersion: ", dispersion, " (", e_name, ")\n", sep = "")
cat("# Minimum total count:", min_count, "\n")
cat("# Library size:", library_size, "million reads\n")

opts = RNAseq.SimOptions.2grp(ngenes=n_genes, sim.seed=seed,
       lBaselineExpr=e_name,
       lOD=e_name,
)

# Scale the sampled means so they sum to the requested library size.
# Exact zeros in the source study stay zero.
target = library_size * 1e6
base = exp(opts$lBaselineExpr)
base[!is.finite(base)] = 0
opts$lBaselineExpr = opts$lBaselineExpr + log(target / sum(base))

# Run the simulation.
sim = simRNAseq(opts, n1=n_reps, n2=n_reps)

# The simulation matrix.
mat <- sim$counts

# Generating A1, A2 ... and B1, B2 ... as sample names.
s1 = paste(rep("A", n_reps), 1:n_reps, sep="")
s2 = paste(rep("B", n_reps), 1:n_reps, sep="")

# Combine the sample names.
samples = c(s1, s2)

# Generate the groups: A and B
groups = c(rep("A", n_reps), rep("B", n_reps))

# Set the sample names on the simulation.
colnames(mat) <- samples

# Counts are whole reads.
mat <- round(mat)
storage.mode(mat) <- "integer"

# Create gene names for the simulated counts.
names = paste(rep("GENE-"), 1:n_genes, sep="")

# Create the dataframe. All genes are unchanged and fail the count filter.
df = data.frame(id=names, status="unchanged", filter="fail")

# Combine the metadata with the counts.
df = cbind(df, mat)

# A gene has data when it has at least one count.
has_data = rowSums(mat) > 0

# Only a change with data is marked as changed.
changed = sim$DEid[has_data[sim$DEid]]
df$status[changed] = "changed"

# A gene passes when its total count meets the minimum.
# Same rule as deseq2.2026.r. edgeR filterByExpr() is stricter.
df$filter[rowSums(mat) >= min_count] = "pass"

n_data = sum(has_data)
n_changed = sum(df$status == "changed")
n_above = sum(df$status == "changed" & df$filter == "pass")

# Sort to put changed genes first.
df = df[order(df$status != "changed"),]

# Report how many genes the simulation marked.
# Generate the simulation options.
cat("# Replicates:", n_reps, "\n")
cat("# Total genes:", n_genes, "\n")

perc_data = round(n_data / n_genes * 100, 1)
cat("# Genes with data: ", n_data, "\n", sep = "")

perc_changed = round(n_changed / n_genes * 100, 1)
cat("# Genes that changed: ", n_changed, " (", perc_changed, "%)\n", sep = "")

perc_above = 0
if (n_changed > 0) {
  perc_above = round(n_above / n_changed * 100, 1)
}
cat("# Changed genes that pass filter: ", n_above, " (", perc_above, "%)\n", sep = "")

cat("# Saving design to:", design_file, "\n")
cat("# Saving counts to:", counts_file, "\n")

# Design columns match the differential expression scripts: sample, group.
design = data.frame(sample=samples, group=groups)
write.csv(design, design_file, row.names=FALSE, quote=FALSE)

write.csv(df, counts_file, row.names=FALSE, quote=FALSE)
