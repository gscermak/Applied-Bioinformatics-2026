#!/usr/bin/env python3

import sys
import gzip
from Bio import SeqIO
from Bio.Seq import Seq


def open_text_file(filename):
    """
    Open either a normal text file or a gzip-compressed text file.
    """
    if filename.endswith(".gz"):
        return gzip.open(filename, "rt")

    return open(filename, "r")


def load_reference(fasta_file):
    """
    Load the reference FASTA into a dictionary.

    Key:
        chromosome/contig name

    Value:
        DNA sequence
    """
    return {
        record.id: str(record.seq).upper()
        for record in SeqIO.parse(fasta_file, "fasta")
    }


def load_cds_features(gff_file):
    """
    Read CDS features from a GFF file.

    Stores:
        sequence ID
        start
        end
        strand
        phase
        gene/locus tag
    """
    features = []

    with open_text_file(gff_file) as handle:

        for line in handle:

            # Skip comments
            if line.startswith("#"):
                continue

            fields = line.rstrip().split("\t")

            if len(fields) != 9:
                continue

            (
                seqid,
                source,
                feature_type,
                start,
                end,
                score,
                strand,
                phase,
                attributes,
            ) = fields

            # Only use coding sequences
            if feature_type != "CDS":
                continue

            gene_id = "unknown"

            for item in attributes.split(";"):

                if item.startswith("gene="):
                    gene_id = item.split("=", 1)[1]

                elif item.startswith("locus_tag="):
                    gene_id = item.split("=", 1)[1]

            features.append(
                {
                    "seqid": seqid,
                    "start": int(start),
                    "end": int(end),
                    "strand": strand,
                    "phase": int(phase) if phase != "." else 0,
                    "gene": gene_id,
                }
            )

    return features


def find_cds(features, chrom, pos):
    """
    Find a CDS feature containing the variant position.
    """
    for feature in features:

        if (
            feature["seqid"] == chrom
            and feature["start"] <= pos <= feature["end"]
        ):
            return feature

    return None


def classify_indel(ref, alt):
    """
    Classify a simple insertion or deletion.

    If the length change is not divisible by 3,
    the reading frame is shifted.

    If the length change is divisible by 3,
    amino acids are inserted or deleted without
    changing the reading frame.
    """
    change = len(alt) - len(ref)

    if change % 3 != 0:
        return "frameshift"

    if change > 0:
        return "inframe_insertion"

    if change < 0:
        return "inframe_deletion"

    return "complex"


def classify_snp(reference, feature, chrom, pos, ref, alt):
    """
    Determine the coding consequence of a SNP.
    """
    start = feature["start"]
    end = feature["end"]
    strand = feature["strand"]
    phase = feature["phase"]

    # Extract the CDS sequence
    cds_seq = reference[chrom][start - 1:end]

    # Reverse-complement minus-strand genes
    if strand == "-":
        cds_seq = str(Seq(cds_seq).reverse_complement())

    # Determine variant position within the CDS
    if strand == "+":
        offset = pos - start
    else:
        offset = end - pos

    # Account for GFF phase
    offset -= phase

    if offset < 0:
        return "unknown", "-", "-", "-", "-"

    # Determine which codon contains the variant
    codon_index = offset // 3
    codon_position = offset % 3

    codon_start = codon_index * 3 + phase

    ref_codon = cds_seq[codon_start:codon_start + 3]

    if len(ref_codon) != 3:
        return "unknown", ref_codon, "-", "-", "-"

    # ALT base must be complemented for a minus-strand CDS
    alt_base = alt

    if strand == "-":
        alt_base = str(Seq(alt).complement())

    # Create altered codon
    alt_codon_list = list(ref_codon)
    alt_codon_list[codon_position] = alt_base

    alt_codon = "".join(alt_codon_list)

    # Translate reference and altered codons
    ref_aa = str(Seq(ref_codon).translate())
    alt_aa = str(Seq(alt_codon).translate())

    # Classify the consequence
    if codon_index == 0 and ref_aa == "M" and alt_aa != "M":
        consequence = "start_lost"

    elif ref_aa == alt_aa:
        consequence = "synonymous"

    elif alt_aa == "*" and ref_aa != "*":
        consequence = "stop_gained"

    elif ref_aa == "*" and alt_aa != "*":
        consequence = "stop_lost"

    else:
        consequence = "missense"

    return (
        consequence,
        ref_codon,
        alt_codon,
        ref_aa,
        alt_aa,
    )


def print_header():
    """
    Print a descriptive header for the output file.
    """
    print("# Variant Effect Annotator")
    print("#")
    print("# Purpose:")
    print("#   Classify simple genetic variant consequences using")
    print("#   a reference FASTA, GFF annotation, and VCF file.")
    print("#")
    print("# Variant consequences detected:")
    print("#")
    print("#   intergenic")
    print("#       Variant is outside a coding sequence.")
    print("#")
    print("#   synonymous")
    print("#       DNA changes but the encoded amino acid does not.")
    print("#")
    print("#   missense")
    print("#       DNA change causes a different amino acid.")
    print("#")
    print("#   stop_gained")
    print("#       Variant creates a premature stop codon.")
    print("#")
    print("#   stop_lost")
    print("#       Variant removes a normal stop codon.")
    print("#")
    print("#   start_lost")
    print("#       Variant disrupts the normal start codon.")
    print("#")
    print("#   frameshift")
    print("#       Insertion or deletion changes the reading frame.")
    print("#")
    print("#   inframe_insertion")
    print("#       Bases are inserted in multiples of three.")
    print("#")
    print("#   inframe_deletion")
    print("#       Bases are deleted in multiples of three.")
    print("#")
    print("#   unknown")
    print("#       Program could not confidently classify the variant.")
    print("#")
    print("# IGV_GOTO:")
    print("#   Coordinate that can be copied directly into IGV.")
    print("#   Example: NZ_AP026446.1:45678")
    print("#")
    print("# Notes:")
    print("#   This is a simplified teaching program.")
    print("#   It does not replace full variant-effect software")
    print("#   such as bcftools csq, SnpEff, or Ensembl VEP.")
    print("#")

    print(
        "CHROM\tPOS\tREF\tALT\tGENE\tSTRAND\t"
        "REF_CODON\tALT_CODON\tREF_AA\tALT_AA\t"
        "CONSEQUENCE\tIGV_GOTO"
    )


def process_vcf(vcf_file, reference, features):
    """
    Read variants from a VCF or VCF.GZ file and report
    their predicted consequences.
    """

    print_header()

    with open_text_file(vcf_file) as handle:

        for line in handle:

            # Skip VCF header lines
            if line.startswith("#"):
                continue

            fields = line.rstrip().split("\t")

            chrom = fields[0]
            pos = int(fields[1])
            ref = fields[3]
            alt = fields[4]

            # Create coordinate for IGV
            igv_goto = f"{chrom}:{pos}"

            # Skip multiallelic sites in this simple version
            if "," in alt:
                continue

            # Find overlapping CDS
            feature = find_cds(features, chrom, pos)

            # Variant is outside a CDS
            if feature is None:

                print(
                    f"{chrom}\t{pos}\t{ref}\t{alt}\t"
                    f"-\t-\t-\t-\t-\t-\t"
                    f"intergenic\t{igv_goto}"
                )

                continue

            # SNP
            if len(ref) == 1 and len(alt) == 1:

                (
                    consequence,
                    ref_codon,
                    alt_codon,
                    ref_aa,
                    alt_aa,
                ) = classify_snp(
                    reference,
                    feature,
                    chrom,
                    pos,
                    ref,
                    alt,
                )

            # Simple insertion or deletion
            else:

                consequence = classify_indel(ref, alt)

                ref_codon = "-"
                alt_codon = "-"
                ref_aa = "-"
                alt_aa = "-"

            print(
                f"{chrom}\t{pos}\t{ref}\t{alt}\t"
                f"{feature['gene']}\t{feature['strand']}\t"
                f"{ref_codon}\t{alt_codon}\t"
                f"{ref_aa}\t{alt_aa}\t"
                f"{consequence}\t{igv_goto}"
            )


def main():
    """
    Command-line interface.
    """

    if len(sys.argv) != 4:

        print(
            f"Usage: {sys.argv[0]} "
            "reference.fasta annotation.gff variants.vcf[.gz]"
        )

        sys.exit(1)

    fasta_file = sys.argv[1]
    gff_file = sys.argv[2]
    vcf_file = sys.argv[3]

    # Load reference and annotation
    reference = load_reference(fasta_file)
    features = load_cds_features(gff_file)

    # Analyze variants
    process_vcf(
        vcf_file,
        reference,
        features,
    )


if __name__ == "__main__":
    main()