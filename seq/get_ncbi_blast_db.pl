#!/usr/bin/perl

=head1 NAME

    get_ncbi_blast_db.pl - Batch download pre-formatted NCBI BLAST 
                           database.

=head1 SYNOPSIS

=head1 DESCRIOTION

    This script depends the `lftp` commands to download database files
    from NCBI ftp:

    ftp://ftp.ncbi.nlm.nih.gov/blast/db/

=head1 AUTHOR
    
    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2020-11-06
    0.0.2   2021-01-06
    0.0.3   2021-01-18
    0.1.0   2020-05-07

=cut

use 5.12.1;
use strict;
use warnings;

use File::Which;
use Getopt::Long;
use Smart::Comments;
use Term::ProgressBar;

# Pre-defined Variables
# NCBI ftp
my $NCBI_FTP_URL    = 'ftp.ncbi.nlm.nih.gov';
my $NCBI_FTP_USER   = 'anonymous';
my $NCBI_FTP_PWD    = 'anonymous';

# Remote (NCBI) database dir
my $NCBI_BLAST_DIR  = 'blast/db/';

# Local database cache dir
my $LOCAL_CACHE_DIR = '/data/db/pool/ncbi';

# Local database dir
my $LOCAL_BLASTDB_DIR   = '/data/db/blast';

# Ftp options
my $INTEVAL    = 30;    # FTP download interval, 30s

# Default database to be download
my @BLAST_DB   = ('nt', 'nr');

# Default operations
my $F_UNZIP    = 0;    # Default not unzip files.

#===========================================================
#
#               Main
#
#===========================================================

# Check whether `lftp` command available

my $lftp_path   = which 'lftp';

die "Please install `lftp` first!\n"
    unless (defined $lftp_path);

## $lftp_path

my ($dbs);

GetOptions(
    "d=s"   => \$dbs,   # database to be downloaded
    "u"     => \F_UNZIP,    # Whether unzip files after download.
    "h"     => sub { usage() }
);


#===========================================================
#
#               Subroutines
#
#===========================================================

#
# usage
# 

sub usage {
    say << "EOS";
Download NCBI predefined blast databases.
usage:
  get_ncbi_blast_db.pl -d <dbs> -u
Options:
  -d <dbs>: Databases to be downloaded. Separated by spaces.
            Supporting database name:
                nr nt env_nr env_nt mito taxdb
  -u:       Decompress downloaded database files.
            Default FALSE.

EOS
}

#
# get_db
#

sub get_db {}
