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