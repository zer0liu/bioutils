#! /usr/bin/env perl

=head1 NAME

    upd_fludb.pl - Revise the influenza virus sequence database parsed
                   and loaded by 'load_gbvirus.pl'

=SYNOPSIS

=DESCRIPTION

    This script will revise/update these fileds:

    Table 'virus', fileds:
        'strain'
        'serotype'
        'collect_date'
        'isolate'   - if possible
        'country'   - if possible
        'host'      - if possible

    Table 'sequence', fields:
        'segment'

    Table 'feature', fields:
        'gene'

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2018-03-19

=cut

use 5.010;
use strict;
use warnings;

use DBI;
use Smart::Comments;

my $fdb = shift or die usage();

our $dbh;

die "[ERROR] Connect to SQLite3 database failed!\n" 
    unless ($dbh = conn_db($fdb));

upd_tab_virus();

$dbh->disconnect;

#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Print usage information
  Returns:  None
  Args:     None

=cut

sub usage {
    say << "EOS";
Revise the influenza virus sequence database created by script 
'load_gbvirus.pl'
Usage:
  upd_fludb.pl <db>
EOS
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

  Name:     upd_tab_virus
  Usage:    upd_tab_virus()
  Function: Update table 'virus'
  Args:     
  Returns:  The number of successfully updated records

=cut

sub upd_tab_virus {
    my $sql_str = << "EOS";
SELECT 
    id,
    organism, 
    strain, 
    isolate, 
    serotype,
    country,
    collect_date
FROM
    virus
EOS
    
    my $sth;

    eval {
        $sth    = $dbh->prepare($sql_str);
        $sth->execute;
    };

    if ($@) {
        warn "[ERROR] Query table 'virus' with SQL statement\n"
                , '$sql_str' , "\nfailed!\n", $@, "\n";
        return;
    }

    while (my $rh_row = $sth->fetchrow_hashref) {
        my $vir_id  = $rh_row->{'id'};
        my $org     = $rh_row->{'organism'};

        # Debug
        say '===> ', $org;

        my ($cur_str, $cur_stype, $cur_date);

        # 'Influenza A virus (A/mallard/Iran/C364/2007(H9N2))'
        if ($org =~ /^Influenza.+?\((.+?)\s*\((.+?)?\)\)$/) { # w/ serotype
            $cur_str     = $1;   # Strain name
            $cur_stype   = $2;    # Serotype, if possible
        }
        elsif ($org =~ /^Influenza.+?\(.+?\)/) { # w/o serotype
            $cur_str    = $1;
            $cur_stype  = '';
        }
        else {
            warn "[ERROR] Unmatched organism:\t '", $org, "'.\n";
            next;
        }

        $cur_date   = parse_str_date($cur_str);

        my $str     = $rh_row->{'strain'} // $cur_str;
        my $isolate = $rh_row->{'isolate'};
        my $stype   = $rh_row->{'serotype'} // $cur_stype;
        my $country = $rh_row->{'country'};
        my $cdate   = $rh_row->{'collect_date'} // $cur_date;

        # Debug
        # say join " | ", ($org, $str, $isolate, $stype, $country, $cdate);
        say '--+> ', $str;
        say '--+> ', $stype;
        say "--+> ", $cdate;

    }
}

=pod

  Name:     parse_str_date
  Usage:    parse_str_date($str)
  Function: Parse strain name and fetch collection date
  Args:     Strain name, a string
  Returns:  An string of digits.
            undef for all errors

=cut

sub parse_str_date {
    my ($str)   = @_;

    # Debug
    say '--+# ', $str;
    
    return unless $str;

    my $cdate;

    if ($str =~ /\/(\d{2,4})$/) {
        $cdate  = $1;    
    }
    else {
        return;
    }

    # For 2-digit year, in MySQL
    # 00 - 69   ==> 2000 - 2069
    # 70 - 99   ==> 1970 - 1999
    if (length($cdate) == 2) {
        if ($cdate >= 0 and $cdate <=20) { # i.e., 2000-2020
            $cdate  = '20' . $cdate;
        }
        else {  # i.e., 19xx
            $cdate  = '19' . $cdate;
        }
    }

    # Debug
    say '--+# ', $cdate;

    return $cdate;
}
