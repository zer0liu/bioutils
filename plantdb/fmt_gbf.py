#!/usr/bin/python
'''
NAME

    fmt_gbf.py - Reformat NCBI Influenza Virus Sequence Annotation Tool
                 output to a formal GenBank format.

SYNOPSIS

DESCRIPTION
    
    A typical NCBI Influenza Virus Sequence Annotation Tools report is:

============================================================

LOCUS       EPI151964               2291 bp    DNA     linear       22-JUN-2017
DEFINITION  | A/chicken/Ghana/2534/2007 | A / H5N1 | 2007-04-24.
ACCESSION   
VERSION
KEYWORDS    .
SOURCE      Unknown.
  ORGANISM  Unknown.
            Unclassified.
FEATURES             Location/Qualifiers
     source          1..2291
                     /organism="unknown"
                     /mol_type="genomic DNA"
     gene            12..2291
                     /gene="PB2"
     CDS             12..2291
                     /gene="PB2"
                     /codon_start=1
                     /product="polymerase PB2"
                     /translation="MERIKELRDLMSKSRTREILTKTTVDHMAIIKKYTSGRQEKNPA
                     ...
                     SSILTDSQTATKRIRMAIN"
ORIGIN      
        1 atatattcaa tatggagaga ataaaggaat taagagatct aatgtcaaag tcccgcactc
        ...
     2281 ccatcaatta g
//

============================================================

    Here, this script works on these modifications:

    1. Modify 'DEFINITION'.
    2. Append accession number for 'ACCESSION'.
    3. Append accession number .version for 'VERSION'.
    4. Modify 'Source' like:
       'Influenza A virus (A/duck/Mongolia/769/2015(H4N6))
    5. Modify 'ORGANISM' to:

SOURCE      Influenza A virus (A/duck/Mongolia/769/2015(H4N6))
  ORGANISM  Influenza A virus (A/duck/Mongolia/769/2015(H4N6))
            Viruses; ssRNA viruses; ssRNA negative-strand viruses;
            Orthomyxoviridae; Influenzavirus A.

    6. Insert a FAKE 'REFERENCE' field:

REFERENCE   1
  AUTHORS   unknown
  TITLE     Direct Submission
  Journal   Submitted

    7. Add '/db_xref="taxon:11320"' into 'source' filed of 'FEATURES'. This
       NCBI Taxonomy ID indicates the Influenza A virus species.

AUTHOR

    zeroliu-at-gmail-dot-com

VERSION
    
    0.0.1   2017-06-27
    0.0.2   2017-07-12  Bug fix

'''

import argparse
import os
# import os.path
import re
import sys

__version__ = '0.0.1'

argParser   = argparse.ArgumentParser(
    description="Reformat NCBI Influenza Virus Sequence Annotation Tool report to a formal Genbank format file.")
argParser.add_argument('-i', '--in', action='store', 
    dest='fin', help='Input .gbf file')
argParser.add_argument('-o', '--out', action='store', 
    dest='fout', help='Output .gbk file')
argParser.add_argument('-v', '--version', 
    action='version', version='%(prog)s')

args        = argParser.parse_args()

# Check whether input file provided
if not args.fin:
    print('[ERROR] No INPUT .gbf filename!\n')
    argParser.print_help()
    sys.exit()

# Generate output filename, if necessary
if not args.fout:
    filename    = os.path.basename(args.fin)
    basename    = os.path.splitext(filename)[0]
    args.fout   = basename + '.gbk'
    print("[NOTICE] Output filename: %s" % (args.fout))

# Operate input .gbf and out .gbk files
F_newRec    = False # A flag to identify new record

with open(args.fin, 'r') as fh_in, open(args.fout, 'w') as fh_out:
    for line in fh_in:
        line    = line.rstrip() # Remove tailing '\n'

        if line.startswith('LOCUS'):
            F_newRec    = True              # Set new record flag
            accession   = line.split()[1]   # Parse Accession Number
            seq_len     = line.split()[2]   # Sequence length
            pub_date    = line.split()[-1]  # Sequence publish date

            print('Accession Number: {}' . format(accession))
        elif line.startswith('DEFINITION'):
            # Whether a multi-lines DEFINITION
            # Get the number of '|'
            num_vbar    = line.count('|')

            if num_vbar < 3:
                line    += next(fh_in)
            
            # Replace mulitple spaces into ONE
            line    = ' '.join(line.split())

            # In case sth. like
            # DEFINITION | r3567 | A / H5N1 | 2010-04-03
            items   = line.split('|')

            str_name    = items[1].strip()
            str_name    = re.sub(r'\s*\(H\d+N\d+\)', '', str_name)
            str_name    = re.sub(r'[ _]+H\d+N\d+', '', str_name)

            str_type    = items[2].strip()
            subtype     = str_type.split()[2] 
            
            # In some case, it will led the length of DEFINITION line
            # beyond 80 chars
            line    = 'DEFINITION  Influenza A virus (' + str_name \
                        + '(' + subtype + '))'
        elif line.startswith('ACCESSION'):
            line    = 'ACCESSION   ' + accession
        elif line.startswith('VERSION'):
            line    = 'VERSION     ' + accession + '.1'
        elif line.startswith('SOURCE'):
            line    = 'SOURCE      Influenza A virus '
            
            if str_name and subtype:
                line    = line + '(' + str_name + '(' + subtype + '))'
        elif line.startswith('  ORGANISM'):
            line    = '  ORGANISM  Influenza A virus '

            if str_name and subtype:
                line    = line + '(' + str_name + '(' + subtype + '))'
        elif line.startswith('            Unclassified.'):
            line    = \
'            Viruses; ssRNA viruses; ssRNA negative-strand viruses;\n\
            Orthomyxoviridae; Influenzavirus A.'
        
            # Then insert a fake REFERENCE field after SOURCE ORGANISM
            line    = line + '\n' + \
'REFERENCE   1  (bases 1 to ' + seq_len + ')\n' + \
'  AUTHORS   unknown\n\
  TITLE     Direct Submission\n\
  JOURNAL   Submitted (' + pub_date + ')'
        elif line.startswith('                     /organism'):
            line    = '                     /organism="Influenza A virus"'
        elif line.startswith('                     /mol_type'):
            line    = line + '\n' + \
            '                     /db_xref="taxon:11320"'
        else:
            pass

        fh_out.write(line + '\n')
