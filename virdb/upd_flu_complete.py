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
#   0.0.1       2018-07-10  Starting
#
# LICENSE
#
#   Distributed under terms of the MIT license.

import argparse
import csv
import gzip
import sqlite3
import sys
import requests

from collections import namedtuple

__version__ = '0.0.1'



#===========================================================
#
#                   Subroutines
#
#===========================================================

#
# Download 'influenza_na.dat' file
#
def fetch_dat():
    "Download 'influenza_na.dat' from NCBI ftp into current directory"

    url = 'https://ftp.ncbi.nih.gov/genomes/INFLUENZA/influenza_na.dat.gz'
    fdat= 'na_dat.gz'

    try:
        r   = requests.get(url)
    except requests.exceptions.RequestException as e:
        print(e)
        sys.exit(1)

    with open(fdat, "wb") as fh_dat:
        fh_dat.write(r.content)

    fh_dat.close()

    return(fdat)

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
    help = 'Input influenza_na.dat.gz file. Optional.'
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

if not args.db:
    print('[ERROR] No database file provided!')
    arg_parser.print_help()
    sys.exit()

if not args.fin:
    print('[NOTE] No input influenza_na.dat.gz file provided!')
    print('[NOTE] Downloading from NCBI ftp ...')
    fin = fetch_dat()
else:
    fin = args.fin

# Counter for updated sequences
num_upd_seq = 0

with sqlite3.connect(args.db) as conn, gzip.open(fin, 'rt') as fh_in:
    reader  = csv.reader(fh_in, delimiter = '\t')
    
    cursor  = conn.cursor()

    # Enable SQLite3 bulk mode
    cursor.executescript('''
       PRAGMA synchronous   = OFF;
       PRAGMA cache_size    = 100000;
    ''')

    print("[NOTE] Updating table 'sequence' ...")

    for row in reader:
        acc = row[0]
        completeness    = row[-1]

        print("[NOTE] Updating: " , acc)

        sql = '''
            UPDATE sequence
            SET
                complete    = ?
            WHERE
                accession   = ?
        '''

        try:
            cursor.execute(sql, (completeness, acc,))
        except Exception as err:
            print("[ERROR] Update table 'sequence' failed!\n, err")
            conn.rollback()
        else:
            conn.commit()
            num_upd_seq += 1

print('[DONE] Updated {} sequences.\n' . format(num_upd_seq))

