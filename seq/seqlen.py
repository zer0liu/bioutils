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

print("Input file:\t%s" % (fin))
print("Seq ID\tLength")
print("====\t====")

fh_in   = open(fin, "rU")

for seq_rec in SeqIO.parse(fh_in, fmt):
    print("%s\t%s" % (seq_rec.id, len(seq_rec)))

fh_in.close()

#print('-' * 40)

exit()
