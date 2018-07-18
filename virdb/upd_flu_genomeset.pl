#!/usr/bin/perl

=head1 NAME

    upd_flu_genomeset.pl - Update genomeset information in database
                           according to NCBI Influenza Virus Resource 
                           ftp file: 'genomeset.dat'.
=SYNOPSIS

=DESCRIPTION

    Download https://ftp.ncbi.nih.gov/genomes/INFLUENZA/genomeset.dat.gz
    and parse, then update related table 'genomeset' of database.

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2018-07-11
    0.0.2   - 2018-07-18    Check existance of accession number before insert

=cut

use 5.010;
use strict;
use warnings;

use DBI;
use Getopt::Long;
use LWP::Simple;
use Smart::Comments;
use Switch;

my $dat_url = 'ftp://ftp.ncbi.nih.gov/genomes/INFLUENZA/genomeset.dat.gz';

my ($fdb, $fdat);
my $dbh;

GetOptions(
    "d=s"   => \$fdb,
    "i=s"   => \$fdat,
    "h"     => sub { usage() }
);

unless (defined $fdb) {
    warn "[ERROR] No database file provided!\n\n";
    
    usage();

    exit 1;
}

# Download 'genomeset.dat.gz' if necessary
unless (defined $fdat)  {
    warn "[NOTE] No 'genomeset.dat.gz' file provided.\n";
    warn "[NOTE] Start downloading ...\n";

    $fdat   = get_dat($dat_url);
}

# Connect to database
die "[ERROR] Connect SQLite3 database 'fdb' failed!\n"
   unless ($dbh = conn_db($fdb));

# Enable bulk mode
die "[ERROR] Enable database bulk mode failed!\n"
   unless ( en_db_bulk($dbh) );

my $num_ins = 0;

open(my $fh_dat, "<:gzip", $fdat)
    or die "[ERROR] Failed to open gzip file '$fdat'!\n$!\n";

while (<$fh_dat>) {
    next if /^#/;
    next if /^\s*$/;
    chomp;

    my @items   = split /\t/;

    my $acc     = $items[0];

    if ( chk_seq_acc($acc, $dbh) ) {
        # warn "[WARN] Sequence '$acc' already exists!\n";
        next;
    };

    my $host    = $items[1];
    my $segment = $items[2];
    my $serotype= $items[3];
    my $country = $items[4];
    my $col_date= $items[5];
    my $seqlen  = $items[6];
    my $vir_name= $items[7];
    my $age     = $items[8];
    my $gender  = $items[9];
    my $groupid = $items[10];

    $serotype   =~ s/,\s/,/;    # Remove space after ','
    $col_date   =~ s/\//-/g;    # Replace '/' in date to '-'

    my $str_name= '';
    if ( $vir_name =~ /^Influenza.+?\((.+?)[\)|\(]/) {
        $str_name   = $1;
    }
    else {
        warn "[WARN] No influenza virus strain found in '$vir_name'!\n";
    }

    my $sqlstr  = 'INSERT INTO genomeset (' .
                        'accession, ' .
                        'host, ' .
                        'segment, ' .
                        'serotype, ' .
                        'country, ' .
                        'col_date, ' .
                        'seq_len, ' .
                        'vir_name, ' .
                        'str_name,' .
                        'age, ' .
                        'gender, ' .
                        'group_id) ' .
                    'VALUES (' .
                        $dbh->quote($acc)       . ', ' .
                        $dbh->quote($host)      . ', ' .
                        $dbh->quote($segment)   . ', ' .
                        $dbh->quote($serotype)  . ', ' .
                        $dbh->quote($country)   . ', ' .
                        $dbh->quote($col_date)  . ', ' .
                        $dbh->quote($seqlen)    . ', ' .
                        $dbh->quote($vir_name)  . ', ' .
                        $dbh->quote($str_name)  . ', ' .
                        $dbh->quote($age)       . ', ' .
                        $dbh->quote($gender)    . ', ' .
                        $dbh->quote($groupid)   . ');'
                    ;

    # $sqlstr

    eval {
        my $sth = $dbh->prepare($sqlstr);
        $sth->execute();
    };

    if ($@) {
        warn "[ERROR] Insert into table 'genomeset' failed!\n";
        warn "[ERROR] ", $@, "\n";
    }
    else {
        $num_ins++;
    }
}

$dbh->disconnect();

close $fh_dat;

say "[DONE] Update genomeset information succeeded!";

#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Display usage information
  Returns:  None
  Args:     None

=cut

sub usage {
    say << 'EOS';
Update genomeset information in database according to NCBI Influenza
Virus Resource ftp file 'genomeset.dat.gz'.
Usage:
  upd_flu_genomeset.pl -d <db> -i <genomeset.dat.gz>
Note:
  From: ftp://ftp.ncbi.nih.gov/genomes/INFLUENZA/genomeset.dat.gz
EOS
}

=pod

  Name:     get_dat
  Usage:    get_dat($url)
  Function: Download file 'genomeset.dat.gz' from NCBI ftp.
  Args:     $url
  Return:   A filename
            undef for any errors

=cut

sub get_dat {
    my ($url)   = @_;

    my $file    = 'genomeset.dat.gz';

    my $rc      = getstore($url, $file);

    if ( is_error($rc) ) {
        die "[ERROR] Failed to download 'genomeset.dat.gz' from NCBI ftp.\n";
    }
    else {
        say "[OK] Download 'genomeset.dat.gz' succeeded.";
    }

    return $file;
}

=pod

  Name:     conn_db
  Usage:    conn_db($fdb)
  Function: Connect to given SQLite3 database file
  Returns:  A database handle
  Args:     A string

=cut

sub conn_db {
    my ($fdb)   = @_;

    my $dbh;

    unless (-f $fdb) {   # Whether is a plain file
        say "[ERROR] SQLite3 file '$fdb' error!";
        return;
    }

    eval {
	    $dbh = DBI->connect(
            "dbi:SQLite:dbname=$fdb", 
	        "", "",
	        {
	            RaiseError  => 1,
	            PrintError  => 1,
	            AutoCommit  => 1,
	        }
	    ) or die $DBI::errstr, "\n";
    };

    if ($@) {
        warn "[FATAL] Connect to SQLite3 database '$fdb' failed!\n";

        return;
    }

    return $dbh;
}

=pod

  Name:     en_db_bulk
  Usage:    en_db_bulk($dbh)
  Function: Enable bulk INSERT or UPDATE operation
  Args:     $dbh
  Returns:  None
            undef for any errors

=cut

sub en_db_bulk {
    # return unless (defined $dbh);
    my ($dbh)   = @_;

    eval {
        $dbh->do("PRAGMA synchronous = OFF");
        $dbh->do("PRAGMA cache_size  = 100000");    # Cache siez 100M
    };
    if ($@) {
        warn "[ERROR] Setup database PRAGMA failed!\n$@\n";
        return;
    }

    return 1;
}

=pod

  Name:     chk_seq_acc
  Usage:    chk_seq_acc($acc, $dbh)
  Function: Check existance of given accession number in table 'genomeset'
  Args:     $acc    Accession number. A string
  Return:   id      - Record ID, an integer
            undef   - Any errors

=cut

sub chk_seq_acc {
    my ($acc, $dbh)   = @_;

    my $sql = "SELECT id FROM genomeset WHERE accession = " .
                $dbh->quote($acc) . ";";

    my $sth;

    eval {
        $sth = $dbh->prepare($sql);

        $sth->execute();
    };

    if ($@) {
        warn "[ERROR] Query genomeset with accession number '" .
            $acc . "' failed!\n$@\n";

        return;
    }

    my $rh_row  = $sth->fetchrow_hashref();
    return $rh_row->{'id'};
}

