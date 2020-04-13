#!/usr/bin/python3

"""
Name

    create_rdf.py   - Create multistate '.rdf' file for fluxus network software

SYNOPSIS

    create_rdf.py [--snp] <Fasta file> <data>

DESCRIPTION

    Fluxus network multistate '.rdf' contains Variation sites ONLY.

    File format:

============================================================
  ;1.0                  <-  Unknown
CH1;CH2;CH3;CH4;CH5;    <-  nucleotide site name, delimited by ';'
10;10;10;20;10;         <-  Corresponding site weight. Default 10
>SQ1;1;P1;G1;L1;;;;     <-  Fasta format sequences:
AGGCT                   <-  The header includes 8 fields, delimited by ';'
>SQ2;1;P2;G2;L2;;;;         (1) Sequence name, length <= 6-char
AACCT                       (2) Sequence frequency. Default 1
>SQ3;2;P3;G3;L3;;;;         (3) Phenotype
TGGCC                       (4) Geography
>SQ4;3;P4;G4;L4;;;;         (5) Lienage
ATTTA                       (6-8) Group 1-3
>SQ5;1;P5;G5;L5;;;;
GGAAT
============================================================

AUTHORS

    zeroliu-at-gmail-dot-com

VERSION

    0.0.1   2016-09-05
    0.0.2   2016-09-06  Fix bugs.

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

def get_vsites(aln, rmgaps):
    """
    Desc:
        Get variation sites from given alignment.
    Args:
        aln     - A MultipleSeqAlignment object
        rmgap   - Remove gaps in alignment.
                  Default True
    Ret:
        vsites      - Location of variation sites
        vsites_aln  - A MultipleSeqAlignment object for variation sites
    """

    # num_seqs    = len(aln)      # No. of sequences in MSA
    aln_len     = len(aln[0])   # Length of MSA

    print("Alignment length: %s\n" % aln_len)

    # DEBUG
    #print("Alignment:\nSeq No.:\t{}Aln length:\t{}". format(num_seqs, aln_len))

    vsites      = ""    # Locations of variation sites, delimited by ";"
    vsites_aln  = None  # MultipleSeqAlignment object for variation sites

    for site in range(0, aln_len):
        ss_aln_str  = aln[:, site]  # Single site alignment string

        # Convert to uppercase
        ss_aln_str  = ss_aln_str.upper()

        if rmgaps:
            if '-' in ss_aln_str:   # Dismoss/remove sites with gaps
                continue
        else:
            ss_aln_str  = ss_aln_str.replace("-", "") # Remove '-' in string

        if (ss_aln_str == len(ss_aln_str) * ss_aln_str[0]):
            """The single slice string consists of ONLY ONE character"""
            continue;
        else:
            #print("Site:\t{}" . format(site))
            #print("Leading char:\t{}" . format(ss_aln_str[0]))
            #print("Whole column:\t{}" . format(ss_aln_str))

            #input("Press Enter to continue ...")

            if vsites == "":
                vsites   = "S" + str(site + 1) + ";"
            else:
                vsites   += "S" + str(site + 1) + ";"

            # print("Variation site:\t%s" % vsites)
            # Get single site alignment MSA object
            ss_aln  = aln[:, site:site+1]

            if vsites_aln is None:
                vsites_aln = ss_aln
            else:
                vsites_aln += ss_aln

    # print(snp_aln)
    return vsites, vsites_aln

#===========================================================

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

# Create and parse command line arguments
argParser   = argparse.ArgumentParser(
    description="Create multistate '.rdf' file for fluxus next software")
argParser.add_argument("fseq", action="store",
    help="Fasta format nucleotide sequence alignment file")
argParser.add_argument("fdata", action="store",
    help="Tab-delimited data file")
argParser.add_argument("frdf", action="store",
    help="Output .rdf file")
argParser.add_argument("--vsites", action="store_true",
    help="Output variation sites only. Default TRUE.")
argParser.add_argument("--rmgaps", action="store_false",
    help="Dismiss sites with gaps. Default FALSE.")

args    = argParser.parse_args()

print("[DEBUG] %s\n" % (args))

# Parse alignment
print("[DEBUG] Reading alignment file {}" . format(args.fseq))
aln = AlignIO.read(args.fseq, "fasta")

# Parse data file for fluxux network software
info    = get_data(args.fdata)   # info is a dictionary

# Get variation sites if necessary
if args.vsites: # Output variation sites
    result_sites, result_aln  = get_vsites(aln, args.rmgaps)
else:           # Output total alignment
    result_aln  = aln

    len_aln     = len(aln[0])
    result_sites    = ""
    for i in range(0, len_aln):
        if result_sites == "":
            result_sites    = "S" + str(i+1) + ";"
        else:
            result_sites    +=  "S" + str(i+1) + ";"

print("Total variation sites:\t%i" % ( len( result_aln[0] ) ))

# Output file
try:
    fh_rdf  = open(args.frdf, "w")
except IOError:
    sys.exit("[ERROR] Create output .ami file failed!")

# Output .ami file header
fh_rdf.write("  ;1.0\n")
fh_rdf.write( result_sites + "\n")
fh_rdf.write("10;" * result_sites.count(";") + "\n")

# Trim seq ID to 6 characters if necessary
# This is REQUIRED for fluxus network software

for seq_rec in result_aln:
    if len(seq_rec) > 6:    # Simply get the first 6 characters
        seq_rec.id  = seq_rec.id[0:6] + ";" + "1" + ";" + info[ seq_rec.id ]
    else:                   # Keep original seq ID
        seq_rec.id  = seq_rec.id + ";" + "1" + ";" + info[ seq_rec.id ]

    fh_rdf.write(">" + seq_rec.id + ";" + "\n")
    fh_rdf.write(str(seq_rec.seq) + "\n")

fh_rdf.close()

print("OK!")
