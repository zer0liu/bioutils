#!/bin/bash

#=====================================================================
#
# This script launchs 'runiprscan' in RunIprScan package repeatedly 
# until all proteins have been annotated by EBI InterProScan service.
#
# RunIprScan (http://michaelrthon.com/runiprscan/) is a command line 
# utility for scanning protein sequences with InterProScan. Due to unknown
# errors, runiprscan is always not able to complete the analyses of all
# protein sequences at a time. So it has to re-run the script repeatly
# until all sequences have been annotated.
#
# AUTHOR
#
#   zeroliu-at-gmail-dot-com
#
# VERSION
#
#   0.0.1   2017-07-07
#   0.0.2   2017-07-10  Bug fix
#
#=====================================================================

extractseq='/home/ypf/bin/extractseq.pl'
runiprscan='/home/ypf/bin/runiprscan'
email='longbow0@gmail.com'

f_total_acc='total_acc.txt'     # File for total accession numbers
f_comp_acc='cmp_acc.txt'        # File for completed accession numbers
f_incomp_acc='incomp_acc.txt'   # File for incompleted accession numbers
f_incomp_seq='incomp.faa'       # Incompleted sequences

# Operate command line arguments
usage='
Launch "runiprscan" repeatly until all proteins have been annotated.
Usage:
iter_iprscan.sh <seq file> <output dir>
'

if [[ $# -lt 2 ]]; then
    echo "$usage"
    exit 1
elif ! [[ -f $1 ]]; then
    echo "[ERROR] Protein sequence file '$1' not found!"
    exit 1
elif ! [[ -d $2 ]]; then
    echo "[WARNING] No output dir '$2' exists. Creating ..."
    if `mkdir $2`; then
        echo "Output dir '$2' created."
    else
        echo "[ERROR] Create output dir '$2' failed!"
        exit 1
    fi
fi

fseq=$1
dout=$2

# Get the protein sequence number
# echo "---+> $fseq"
total_seq_num=`grep -c '>' $fseq`

if [[ total_seq_num -eq 0 ]]; then
    echo "[ERROR] Input file '$fseq' is NOT a FASTA format sequence file!"
    exit 1
else
    echo "[NOTE] Total sequence number: $total_seq_num"
fi

# Get and sort all accession numbers into a file
# `perl -lne 'print $1 if /^>(\S+)/' $fseq | sort > $f_total_acc`
perl -lne 'print $1 if /^>(\S+)/' $fseq | sort > $f_total_acc

# t_acc_num=`wc -l $f_total_acc

# Total annotated sequence number
anno_num=0

# fin=$fseq

while [[ $anno_num -lt $total_seq_num ]]; do
    echo '[NOTE] Start InterProScan analysing ...'

    # Get the annotated file number FIRST, in case this is NOT an empty
    # directory
    # `ls $dout | sort > $f_comp_acc`
    ls $dout | sort > $f_comp_acc

    # Remove suffix '.xml' and leave accession numbers
    # `perl -lpi -e 's/\.xml//' cmp_acc.txt`
    perl -lpi -e 's/\.xml//' cmp_acc.txt

    anno_num=`wc -l < $f_comp_acc`

    if [[ $anno_num -eq 0 ]] ; then   # '$dout' NOT empty
        fin=$fseq

    else    # '$dout' is NOT empty
        echo "[NOTE] Annotated sequence number: $anno_num"

        # Get incompleted accession numbers

        # `comm -23 $f_total_acc $f_comp_acc > $f_incomp_acc`
        comm -23 $f_total_acc $f_comp_acc > $f_incomp_acc

        # Get incompleted sequences
        $extractseq $fseq $f_incomp_acc > $f_incomp_seq

        fin=$f_incomp_seq

        # Get sequence number of input file
        incomp_seq_num=`grep -c '>' $f_incomp_seq`

        # echo '[NOTE] Extracting unannotated sequences ...'
        echo "[NOTE] Remained sequence number: $incomp_seq_num"

        if [[ incomp_seq_num -eq 0 ]]; then
            break
        fi

    fi

    # Launch 'runiprscan'
    echo '[NOTE] Launching InterProScan ...'

    $runiprscan -v -i $fin -m $email -o $dout > iprscan.log 2>&1

    echo
    printf '=%.0s' {1..60}
    echo

done

echo "[DONE] Total $total_seq_num sequences annotated."

# Clean temporary files
rm $f_total_acc $f_comp_acc $f_incomp_acc $f_incomp_seq

exit 0

