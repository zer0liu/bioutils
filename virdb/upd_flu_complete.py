#! /usr/bin/python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# NAME
#
#   upd_flu_complete.py - Update flu sequence completeness information.
#
# SYNOPSIS
#
# DESCRIPTION
#
#   Based on the NCBI Influenza Virus Resource ftp:
#
#       ftp://ftp.ncbi.nih.gov/genomes/INFLUENZA/influenza_na.dat
#
#   The completeness for sequences are:
#
#       c   - Sequences have complete coding regions including start
#             and stop codons
#       nc  - a.k.a. nearly complete. Sequences only missing start
#             and/or stop codons.
#       p   - Partial sequences.
#
# AUTHOR
#
#   zeroliu-at-gmail-dot-com
#
# VERSION
#
#   0.0.1       2018-07-10
#
# LICENSE
#
#   Distributed under terms of the MIT license.

import argparse
import csv
import gzip
import sqlite3
import sys

__version__ = '0.0.1'

#===========================================================
#
#                   Subroutines
#
#===========================================================



#===========================================================
#
#                   Main
#
#===========================================================

# Command line arguments
arg_parser  = argparse.ArgumentParser(
    description = '''
Update sequence completeness information in database according to 
NCBI Influenza Virus Resources ftp.

Data downloaded from NCBI ftp:
  ftp://ftp.ncbi.nih.gov/genomes/INFLUENZA/influenza_na.dat.gz
'''
)

arg_parser.add_argument(
    '-i', '--in', action = 'store', dest = 'fin',
    help = 'Input influenza_na.dat file.'
)

arg_parser.add_argument(
    '-d', '--db', action = 'store', dest = 'db',
    help = 'SQLite3 database file.'
)

arg_parser.add_argument(
    '-v', '--version', action = 'version',
    version = '%(prog)s V' + __version__
)

args    = arg_parser.parse_args()

if not args.fin:
    print('[ERROR] No input influenza_na.dat(.gz) file provided!\n')
    arg_parser.print_help()
    sys.exit()
elif not args.db:
    print('[ERROR] No database file provided!\n')
    arg_parser.print_help()
    sys.exit()
else:
    pass

# Counter for updated sequences
num_upd_seq = 0

with sqlite3.connect(args.db) as conn, open(args.fin, 'rt') as fh_in:
    
