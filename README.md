
# bioutils
Routine utilities for seuqnece operation

## align

Utilities for convert alignment file format and extract subsequences from an alignment.

* aln2nex.pl      Convert alignment to NEXUS
* aln2phys.pl     Convert alignment to sequential PHYLIP
* aln4phyml.pl    Convert alignment to PHYLIP format for PhyML input (i.e., long seuqnec ID)
* alnscore.pl     Score alignment
* comb_alns.pl    Combine multiply algnment file into one
* extractalign.pl Extract regions of an alignment
* phy2paml.pl     Convert PHYLIP alignment for PAML input.

## blast2taxon

Parse NCBI BLAST report and store into an SQLite3 database. Also provided scripts to statistic BLAST reports in Excel format.

## keggdb

Parse KEGG data and store into an SQLite3 database.

**See also:** [Bio::KEGGI](http://search.cpan.org/~zeroliu/Bio-KEGGI-v0.1.50/lib/Bio/KEGGI.pm)

## seq

Utilities for routine sequence operation

* conv_date.pl        Convert 'yyyy-mm-dd' format date in seuqnce id to day of year or decimal
* date2dec.pl         Convert 'yyyy-mm-dd' format date to decimal
* dec2date.pl         Convert decimal of year to date, in 'yyyy-mm-dd' format
* extractseq.pl       Extract sequences from a multi-FASTA sequence file according to given sequence IDs
* gbk2embl.py         Convert NCBI GenBank format file into EMBL
* get_seq_by_kw.pl    Get seqences from a multi-FASTA file according to given keywords
* get_seqlen.pl       Get sequence lenth
* grp_seq_by_len.pl   Group sequences according to length
* rm_seq_by_id.pl     Remove sequences according to given IDs
* rm_seq_by_kw.pl     Remove sequences according to given keywords
* rnd_pick_seq.pl     Random pick sequences from a multi-FASTA file
* seqlen.py           Get sequence length
* sort_seq_by_len.pl  Sort sequences according to sequence length
* split_seqfile.pl    Split large multi-FASTA sequence file into many small files
* splitmf.pl          same to above
* transeq.pl          Translate nucleotide sequences into protein

## sql_gui

A GTK2 interface to query SQLite3/PostgreSQL database.

## taxonomy

Parse and load NCBI taxonomy into a local SQLite3 database.

**Note:** NCBI taxonomy in available at [NCBI ftp](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/)

## virdb

Parse GenBank format viral genome file (usually downloaded from GenBank) and load into an SQLite3 database.

@2017-07-04: Added new scripts, fmt_gbf.py and upd_ga_info.py, to load GISAID sequences into the database.
The work flow is:
1. Download nucleotide sequences from GISAID in FASTA formata. Keep the sequence header format is "DNA Accession no. | Isolate name | Type | Collection date".
2. Anntate GISAID nucleotide sequences by [NCBI Influenza Virus Sequence Annotation Tool](https://www.ncbi.nlm.nih.gov/genomes/FLU/Database/annotation.cgi). Download the reports, in '.gbf' format.
3. Run script, fmt_gbf.py, to format the '.gbf' file into '.gbk' file.
4. Load re-formatted '.gbk' file into target database.
5. Load GISAID strain information (in a '.csv' file) into the database by script 'upd_ga_info.py'.

