# ============================================================
# RNA-Seq Simulation and Differential Expression Analysis
# ============================================================

.DEFAULT_GOAL := help

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:

MAKEFLAGS += --warn-undefined-variables --no-builtin-rules

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

RSCRIPT := Rscript
CURL    := curl -fsSL

SRC     := src
RESULTS := results

BASE_URL := https://data.biostarhandbook.com/rscript

# Fixed random seed for reproducible simulations.
SEED := 40

SIM_SCRIPT   := $(SRC)/simulate_counts.r
EDGER_SCRIPT := $(SRC)/edger.r
DESEQ_SCRIPT := $(SRC)/deseq2.r
EVAL_SCRIPT  := $(SRC)/evaluate_simulation.r

COUNTS := simulated_counts.csv
DESIGN := simulated_design.csv

EDGER := edger.csv
DESEQ := deseq2.csv

SUMMARY := $(RESULTS)/simulation_evaluation.csv

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------

.PHONY: help
help:
	@echo ""
	@echo "RNA-Seq Simulation Workflow"
	@echo "===================================="
	@echo "make download   Download R scripts"
	@echo "make simulate   Generate simulated RNA-seq data"
	@echo "make edger      Run edgeR analysis"
	@echo "make deseq2     Run DESeq2 analysis"
	@echo "make evaluate   Calculate classification and F1 scores"
	@echo "make results    Display saved results"
	@echo "make all        Run complete workflow"
	@echo "make clean      Remove generated data and results"
	@echo ""
	@echo "Simulation random seed: $(SEED)"
	@echo ""

# ------------------------------------------------------------
# Download Scripts
# ------------------------------------------------------------

.PHONY: download
download: $(SIM_SCRIPT) $(EDGER_SCRIPT) $(DESEQ_SCRIPT)

$(SRC):
	mkdir -p $(SRC)

$(SIM_SCRIPT): | $(SRC)
	$(CURL) $(BASE_URL)/simulate_counts.2026.r -o $@

$(EDGER_SCRIPT): | $(SRC)
	$(CURL) $(BASE_URL)/edger.2026.r -o $@

$(DESEQ_SCRIPT): | $(SRC)
	$(CURL) $(BASE_URL)/deseq2.2026.r -o $@

# ------------------------------------------------------------
# Simulate RNA-Seq Counts
# ------------------------------------------------------------

.PHONY: simulate
simulate: $(COUNTS) $(DESIGN)

# Generate reproducible simulated data using seed 40.
$(COUNTS) $(DESIGN) &: $(SIM_SCRIPT)
	$(RSCRIPT) $(SIM_SCRIPT) -s $(SEED)
	test -s $(COUNTS)
	test -s $(DESIGN)

# ------------------------------------------------------------
# Run Differential Expression
# ------------------------------------------------------------

.PHONY: edger deseq2
edger: $(EDGER)
deseq2: $(DESEQ)

$(EDGER): $(COUNTS) $(DESIGN) $(EDGER_SCRIPT)
	$(RSCRIPT) $(EDGER_SCRIPT) -c $(COUNTS) -d $(DESIGN)
	test -s $(EDGER)

$(DESEQ): $(COUNTS) $(DESIGN) $(DESEQ_SCRIPT)
	$(RSCRIPT) $(DESEQ_SCRIPT) -c $(COUNTS) -d $(DESIGN)
	test -s $(DESEQ)

# ------------------------------------------------------------
# Evaluate Classification Performance
# ------------------------------------------------------------

.PHONY: evaluate
evaluate: $(SUMMARY)

$(SUMMARY): $(COUNTS) $(EDGER) $(DESEQ) $(EVAL_SCRIPT)
	mkdir -p $(RESULTS)
	$(RSCRIPT) $(EVAL_SCRIPT)
	test -s $(SUMMARY)

# ------------------------------------------------------------
# Display Results
# ------------------------------------------------------------

.PHONY: results
results: $(SUMMARY)
	@echo ""
	@echo "Saved Evaluation Results"
	@echo "===================================="
	@cat $(SUMMARY)
	@echo ""

# ------------------------------------------------------------
# Complete Workflow
# ------------------------------------------------------------

.PHONY: all
all: results
	@echo "RNA-Seq simulation workflow complete."

# ------------------------------------------------------------
# Clean Generated Files
# ------------------------------------------------------------

.PHONY: clean
clean:
	rm -f $(COUNTS) $(DESIGN)
	rm -f $(EDGER) $(DESEQ)
	rm -f $(SUMMARY)
	@echo "Generated simulation files removed."