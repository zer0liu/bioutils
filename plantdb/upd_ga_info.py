#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
NAME

    upd_ga_info.py - Update GISAID sequence information in related virdb 
                     database.
                     
SYNOPSIS

DESCRIPTION

    Update information for GISAID sequence database.

    Especially the 'virus' and 'sequence' tables.
    
AUTHOR

    zeroliu-at-gmail-dot-com
    
VERSION

    2017-06-28  0.0.1
'''

import argparse
import csv
import os
import sqlite3
import sys

__version__ = '0.0.1'

#===========================================================
#
#                   Subroutines
#
#===========================================================

def get_virid(conn, acc):
    "Query table 'sequence' for 'vir_id'"

    try:
        cursor  = conn.cursor()
        sql = 'SELECT vir_id FROM sequence WHERE accession = ?'
        cursor.execute(sql, (acc,))

    # Since one sqeuence 'accession' related to one 'vir_id'
        row = cursor.fetchone()

    except Exception as err: 
        print('[ERROR] Query table "sequence" failed!\n', err)
    else:
        # return row['vir_id']
        return row[0]

#===========================================================
#
#                   Main
#
#===========================================================

# Command line arguments
arg_parser   = argparse.ArgumentParser(
    description='Update GISAID sequence information for virdb database.'
)

arg_parser.add_argument('-i', '--in', action='store', dest='fin',
                        help='Input GISAID information file')
arg_parser.add_argument('-d', '--db', action='store', dest='db',
                        help='SQLite3 database file')
arg_parser.add_argument('-v', '--version', action='version',
                        version='%(prog)s V' + __version__)

args    = arg_parser.parse_args()

if not args.fin:
    print('[ERROR] No input GISAID information CSV file!\n')
    arg_parser.print_help()
    sys.exit()
elif not args.db:
    print('[ERROR] No virdb database file!\n')
    arg_parser.print_help()
    sys.exit()
else:
    pass
    
# A dictionary for segment
# segments    = {'PB2' : '1', 'PB1' : '2', 'PA' : '3', 'HA' : '4', \
#                 'NP' : '5', 'NA' : '6', 'MP' : '7', 'NS' : '8'}

segments    = {'PB2' : 'PB2', 'PB1' : 'PB1', 'PA' : 'PA', \
               'HA' : 'HA', 'NP' : 'NP', 'NA' : 'NA', \
               'MP' : 'MP', 'NS' : 'NS'}

# A counter for number of correcty updated records
iso_counter = 0
seq_counter = 0

with sqlite3.connect(args.db) as conn, open(args.fin, 'r') as fh_in:
    reader  = csv.DictReader(fh_in) # Header lines

    cursor  = conn.cursor()
    
    for row in reader:
        # print('[ROW] ', row)
        isolate     = row['Isolate_Id'] or ''
        strain      = row['Isolate_Name'] or ''
        serotype    = row['Subtype'].split()[2] or ''
        country     = row['Location'] or ''
        host        = row['Host'] or ''
        collect_date    = row['Collection_Date'] or ''
        tissue_type     = row['Animal_Specimen_Source'] or ''

        print('Isolate: ', isolate)

        # Segment EPI accession numbers
        acc         = dict()
        acc['PB2']  = row['PB2 Segment_Id'].split('|')[0].strip() or ''
        acc['PB1']  = row['PB1 Segment_Id'].split('|')[0].strip() or ''
        acc['PA']   = row['PA Segment_Id'].split('|')[0].strip() or ''
        acc['HA']   = row['HA Segment_Id'].split('|')[0].strip() or ''
        acc['NP']   = row['NP Segment_Id'].split('|')[0].strip() or ''
        acc['NA']   = row['NA Segment_Id'].split('|')[0].strip() or ''
        acc['MP']   = row['MP Segment_Id'].split('|')[0].strip() or ''
        acc['NS']   = row['NS Segment_Id'].split('|')[0].strip() or ''

        # Update 'virus' and 'sequence' tables
        try:
            for seg in ('PB2', 'PB1', 'PA', 'HA', 'NP', 'NA', 'MP', 'NS'):
                # print('Segment: {}\tAccession: {}' . format(seg, acc[seg]))
                if not acc[seg]:
                    next
                else:
                    print('Segment: {}\tAccession: "{}"' \
                        . format(seg, acc[seg]))
                    vir_id  = get_virid(conn, acc[seg])   # get 'vir_id'

                    # Update 'sequence.segment'
                    sql = '''
                        UPDATE sequence 
                        SET 
                            segment = ?
                        WHERE 
                            vir_id = ?
                    '''

                    cursor.execute(sql, (segments[seg], vir_id,))

                    # Update table 'virus'
                    sql = '''
                        UPDATE virus
                        SET
                            strain          = ?,
                            isolate         = ?,
                            serotype        = ?,
                            country         = ?,
                            host            = ?,
                            collect_date    = ?,
                            tissue_type     = ?
                        WHERE
                            id  = ?
                    '''

                    cursor.execute(sql, (strain, isolate, serotype, \
                        country, host, collect_date, tissue_type, vir_id,))

        except Exception as err:
            print('[ERROR] Update table failed!\n', err)

            # Show Error type, filename and line no.
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print('Type: {}\nFilename: {}\nLine No. {}\n' \
                . format(exc_type, fname, exc_tb.tb_lineno))
            conn.rollback()
        else:
            conn.commit()

            iso_counter += 1

print('[DONE] Successfully updated {} isolates.' . format(iso_counter))
