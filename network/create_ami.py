#!/usr/bin/python
"""
Name

    create_ami.py   - Create '.ami' file for fluxus network software

SYNOPSIS

    create_ami.py [--snp] <Fasta file> <data>
DESCRIPTION

    Fluxus network .ami file format:

============================================================
  ;1.0                              <- Unknown
CH1;CH2;CH3;CH4;CH5;                <- Amino acid site, a string
10;10;10;10;10;                     <- Amino acid site weight, an integer. Default 10
>SQ1;1;P1;G1;L1;GP1A;GP2A;GP3A;     <- FASTA format sequences:
ABCDE                                  The head include 8 fields, seperated and ended by ';'
>SQ2;1;P2;G2;L2;GP1B;GP2B;GP3B;        (1) Sequence name: <= 6-char
BAFGH                                  (2) Sequence frequency. Default 1
>SQ3;1;P1;G2;L1;GP1A;GP2C;GP3C;        (3) Phenotype
BAAID                                  (4) Geography
>SQ4;1;P3;G3;L1;GP1C;GP2A;GP3A;        (5) Lineage
AGCBA                                  (6-8) Group1-3
>SQ5;1;P1;G2;L3;GP1B;GP2C;GP3A;
AKFFC
============================================================

AUTHORS

    zeroliu-at-gmail-dot-com

VERSION

    0.0.1   2016-08-31

"""

from Bio import AlignIO
import argparse
import sys
import regex as re

#===========================================================
#
#                   Functions
#
#===========================================================

def get_snp(aln, rmgap=False):
    """
    Desc:
        Get variation sites from given alignment.
    Args:
        aln     - A MultipleSeqAlignment object
        rmgap   - Remove gaps in alignment.
                  Default False
    Ret:
        sv      - A MultipleSeqAlignment object
    """

    num_seqs    = len(aln)          # No. of sequences in MSA
    aln_len     = len(aln[0])  # Length of MSA

    # DEBUG
    #print("Alignment:\nSeq No.:\t{}Aln length:\t{}". format(num_seqs, aln_len))

    snp_sites   = ""
    snp_aln     = None

    for site in range(0, aln_len):
        ss_aln_str  = aln[:, site]  # Single site alignment string
        # Check whether this string consists of ONLY ONE character
        #F_IsSingleChar  = False     # A flag, whether slice string is composed
                                    # of a single character
        if rmgap:   # Dismoss/remove gaps
            ss_aln_str  = ss_aln_str.replace("-", "")

        if (ss_aln_str == len(ss_aln_str) * ss_aln_str[0]):
            """The single slice string consists of ONLY ONE character"""
            continue;
        else:
            if snp_sites == "":
                snp_sites   = "S" + str(site + 1) + ";"
            else:
                snp_sites   += "S" + str(site + 1) + ";"

            ss_aln  = aln[:, site:site+1] # Single site alignment MSA object

            if snp_aln is None:
                snp_aln = ss_aln
            else:
                snp_aln += ss_aln

    # print(snp_aln)
    return snp_sites, snp_aln

def get_data(file):
    "Read and parse data file for fluxus network"

    try:
        fh_data = open(file, "rU")
    except IOError:
        sys.exit("[ERROR] Open data file 'file' failed!")

    data    = {}    # A dictionary

    for line in fh_data:
        if line[0] == "#":
            next
        elif line in ["\n", "\r\n"]    :
            next
        else:
            line.rstrip("\r\n") # Remove tailing newline chars
            items   = line.split()
            data[items[0]]  = ";".join(items[1:]) \
                + ";" * (7 - len(items))

    fh_data.close()

    return data

#===========================================================
#
#                   Main
#
#===========================================================

# Parse command line arguments
argParser   = argparse.ArgumentParser(
    description="Create '.ami' file for fluxus next software")
argParser.add_argument("fseq", action="store",
    help="Fasta format sequence file")
argParser.add_argument("fdata", action="store",
    help="Tab-delimited data file")
argParser.add_argument("fami", action="store",
    help="Output .ami file")
argParser.add_argument("--snp", action="store_true",
    help="Output variation sites only")
argParser.add_argument("--rmgap", action="store_true",
    help="Dismiss gap for alignment")

args    = argParser.parse_args()

# Parse alignment
aln = AlignIO.read(args.fseq, "fasta")

# Parse data file for fluxux network software
info    = get_data(args.fdata)   # info is a dictionary

# Get variation sites is necessary
if args.snp:
    result_sites, result_aln  = get_snp(aln, args.rmgap)
else:
    result_aln  = aln

    len_aln = length(aln[0])

    result_sites    = ""
    for i in range(0, len_aln):
        if result_sites == "":
            result_sites    = "S" + str(i+1) + ";"
        else:
            result_sites    +=  "S" + str(i+1) + ";"

# Output file
try:
    fh_ami  = open(args.fami, "w")
except IOError:
    sys.exit("[ERROR] Create output .ami file failed!")

# Output .ami file header
fh_ami.write("  ;1.0\n")
fh_ami.write( result_sites + "\n")
fh_ami.write("10;" * result_sites.count(";") + "\n")

# Trim seq ID to 6 characters if necessary
# This is REQUIRED for fluxus network software

for seq_rec in result_aln:
    if len(seq_rec) > 6:    # Simply get the first 6 characters
        seq_rec.id  = seq_rec.id[0:6] + ";" + "1" + ";" + info[ seq_rec.id ]
    else:                   # Keep original seq ID
        seq_rec.id  = seq_rec.id + ";" + "1" + ";" + info[ seq_rec.id ]

    fh_ami.write(">" + seq_rec.id + ";" + "\n")
    fh_ami.write(str(seq_rec.seq) + "\n")

fh_ami.close()

print("OK!")
