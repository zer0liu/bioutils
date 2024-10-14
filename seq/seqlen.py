#!/usr/bin/python

'''
NAME

    seqlen.py   - Display each sequence length

SYNOPSIS

DESCRIPTION

AUTHORS

    zeroliu-at-gmail-dot-com

VERSION
    
    0.0.1   2016-10-14
    0.0.2   2019-11-16  Now output only 1 line heading information
    0.0.3   2024-09-26  Fix bugs for Python 3.11.

'''

from Bio import SeqIO
import argparse
import os
import sys

argParser   = argparse.ArgumentParser(
    description="Display each sequence length.")
argParser.add_argument("fin", action="store",
    help="Input sequence file.")
argParser.add_argument("fmt", action="store", nargs="?",
    help="""Input sequence file format. Default 'fasta'.""")

args    = argParser.parse_args()

if not args.fin:
    sys.exit("[ERROR] No input sequence filename.")
else:
    fin = args.fin


if not args.fmt:
    fmt = 'fasta'
else:
    fmt = args.fmt

# print("Input file:\t%s" % (fin))
print("#SeqID\tLength")
# print("====\t====")

# fh_in   = open(fin, "rU")
# For Python 3.11 and later
fh_in   = open(fin, "r")


for seq_rec in SeqIO.parse(fh_in, fmt):
    print("%s\t%s" % (seq_rec.id, len(seq_rec)))

fh_in.close()

#print('-' * 40)

exit()
