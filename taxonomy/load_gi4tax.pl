#!/usr/bin/perl

=head1 NAME

    load_gi4tax.pl - Load NCBI GI-taxid into a SQLite3 database.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHORS

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2014-07-18
    0.0.2   2014-08-01  Rename column 'taxid' to 'tax_id'

=cut

#use 5.010;
use strict;
use warnings;

use DBI;
use Smart::Comments;

my $usage = << "EOS";
Load NCBI GI-taxid into a SQLite3 database.
usage:
  load_gi4tax.pl <dir> <db>
Args:
  <dir> A directory where gi_taxid_nucl.dmp and gi_taxid_prot.dmp existed.
  <db>  A SQLite3 database to store GI-taxid data.
EOS

my $din = shift or die $usage;
my $db  = shift or die $usage;

$din .= '/' unless ($din =~ /\/$/);

my $dbh;

eval {
    $dbh = DBI->connect(
        "dbi:SQLite:dbname=$db",
        "", "",
        {
            RaiseError  => 1,
            PrintError  => 1,
            AutoCommit  => 1,
        }
    );
};

if ($@) {
    warn "[ERROR] Connect to SQLite3 database '$db' failed!\n",
            $DBI::errstr, "\n";

    exit 1;
}

# Load file 'gi_taxid_nucl.dmp'
my $fin = $din . 'gi_taxid_nucl.dmp';

print "Loading file '$fin'...\n";

my @fields = qw(gi tax_id);

bulkLoadFile($fin, 'gi4tax', \@fields, $dbh)
    or warn "[ERROR] Load file '$fin' failed!\n", exit 1;

print "File '$fin' was parsed and loaded success!\n";

print '=' x 60, "\n";

# Load file 'gi_taxid_prot.dmp'

$fin = $din . 'gi_taxid_prot.dmp';

print "Loading file '$fin'...\n";

# Here use the identical @fields

bulkLoadFile($fin, 'gi4tax', \@fields, $dbh)
    or warn "[ERROR] Load file '$fin' failed!\n", exit 1;

print "File '$fin' was parsed and loaded success!\n";

print '=' x 60, "\n";

print "All files were loaded OK!\n";

$dbh->disconnect;

exit 0;

#=====================================================================
#
#                             Subroutines
#
#=====================================================================

=head2 bulkLoadFile
  Name:     bulkLoadFile
  Usage:    bulkLoadFile($fin, $table, \@fields, $dbh, $inv)
  Function: Bulk load a file into a table
  Args:     $fin        Input file
            $table      Table to be operated
            \@fileds    Field (column) names of the table
            $dbh        $dbh for the database
            $inv        Commit interval. Default 10,000.
  Return:   undef for all errors
=cut

sub bulkLoadFile {
    my ($fin, $table, $ra_cols, $dbh, $inv) = @_;

    $inv = 10000 unless (defined $inv);

    # Set SQLite3 database PRAGMA for bulk load
    eval {
        $dbh->do("PRAGMA synchronous = OFF");
        $dbh->do("PRAGMA cache_size = 500000");
    };
    if ( $@ ) {
        warn "[ERROR] PRAGMA error:\n";
        warn $dbh->error;

        return;
    }

    # Columns in Table 'names'
    # my @cols = qw (tax_id name uniq_name class);
    # Number of columns
    my $num_cols = scalar ( @{ $ra_cols } );

    # Generate placeholders
    my $pholders = '?,' x $num_cols;
    $pholders =~ s/,$//;    # Remove the last ','

    # Prepare INSERT statement
    my $sql = "INSERT INTO $table" .
        "(" . join(",", @{ $ra_cols }) . ") " . 
        "VALUES (" . $pholders . ");";

    ## $sql

    my $sth;

    eval {
        $sth = $dbh->prepare($sql);
    };
    if ($@) {
        warn "[ERROR] Prepare SQL '$sql' failed!\n", 
        $dbh->errstr, "\n";

        return;
    }

    # Count for read lines
    my $count = 0;

    open(my $fh_in, "<", $fin) 
	    or warn "[ERROR] Cannot find input file $fin.\n$!\n", return;

    eval {
	    # Start transaction
	    $dbh->begin_work;
	
	    while (<$fh_in>) {
	        next if /^\s*$/;
	        next if /^#/;
	        chomp;
	
	        # my $ra_values = getValues($_);
            my @values = split /\t/;
	
	        # if (scalar( @{ $ra_values } ) != $num_cols) {
            if (scalar( @values ) != $num_cols) {
	            warn "[ERROR] Values and columns were not match!\n";
	            warn "[ERROR] Possible wrong line:\n'$_'\n";
	
	            next;
	        }
	        
            # Number of parameters (placeholders)
	        my $p_num = 1;
	
	        for my $value ( @values ) {
	            $sth->bind_param($p_num, $value);
	
	            $p_num++;
	        }
	
	        $sth->execute;

	        $count++;
	
	        if ( eof($fh_in) ) {    # End of file
	            $dbh->commit;
	        }
	        elsif ( $count == $inv ) { # Commit every 1000 lines
	            $dbh->commit;
	
	            # Reset counter
	            $count = 0;
	
	            # Start a new transaction
	            $dbh->begin_work;
	        }
	    }
    };
    if ($@) {
        warn "[ERROR] Database operation failed!\n", 
            $dbh->errstr, "\n";

        return;
    }

    close $fh_in;
}
