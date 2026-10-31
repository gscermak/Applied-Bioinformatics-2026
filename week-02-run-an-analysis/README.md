# Applied Bioinformatics 2026

## Week 02 - Run a full analysis

This portion of this week's lab asks us to run a make to demo snp calls. When running make the first time this is what I got:

```bash
make
```

```
Usage:

    make fastq   # downloads the FASTQ data
    make vcf     # generates a VCF file
    make igv     # opens IGV with the data

Default parameters:

   ACC=AF086833  SRR=SRR1553425  CPU=4  LIMIT=10000

```

I then ran make vcf which ran both the fastq and vcf piplines.

Then, I ran make igv (with igv running). This did not work and required that I made the following change to the igv portion of the makefile:

```bash
# Automating IGV visualization
# IGV = nc localhost 60151
IGV = nc -q 1 localhost 60151
PWD = $(shell pwd)
igv:
	# Create a new session
	echo "new" | ${IGV}
```


Cut/paste block.

```bash

```

```

```

