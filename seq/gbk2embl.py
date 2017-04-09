#!/usr/bin/python3

"""
Name
    
    gbk2embl.py - Convert NCBI GenBank format file into EBI EMBL format.

SYNOPSYIS

    gbk2embl.py <gbk file> <embl file>

DESCRIPTION

AUTHOR

    zeroliu-at-gmail-dot-com

VERSION

    0.0.1   2016-09-26

"""

from Bio import SeqIO
import argparse
import os
import sys

#===========================================================
#
#                   Funciont
#
#===========================================================



#===========================================================
#
#                   Main
#
#===========================================================

# Create and parse command line arguments
argParser   = argparse.ArgumentParser(
    description="Convert NCBI GenBank format file into EMBL format.")
argParser.add_argument("fgb", action="store",
    help="Input NCBI GenBank format file.")
argParser.add_argument("febl", action="store", nargs="?",
    help="Outupt EBI EMBL format file. Optional")

args    = argParser.parse_args()

if not args.fgb:   # Whether input file exists
    sys.exit("[ERROR] No input GenBank filename!")
else:
    fgb     = args.fgb

if args.febl:  # Whether output file exists
    febl    = args.febl
else:
    filename, file_ext  = os.path.splitext(args.fgb)
    febl    = filename + '.embl'

## DEBUG
print(">>>Input file: %s" % fgb)
print(">>>Output file: %s" % febl)

fh_gb   = open(fgb, "rU")
fh_ebl  = open(febl, "w")

for seq_rec in SeqIO.parse(fh_gb, 'genbank'):
    print("Seq ID:\t %s" % seq_rec.id)
    SeqIO.write(seq_rec, fh_ebl, 'embl')

print("Done!")

fh_gb.close()
fh_ebl.close()

