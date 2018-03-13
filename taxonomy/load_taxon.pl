#!/usr/bin/perl

=head1 NAME

    load_taxon.pl - Load NCBI taxonomy data into local database.

=head1 SYNOPSIS

=head1 DESCRIPTION

    NCBI taxonomy data were downloaded from:

    ftp://ftp.ncbi.nih.gov/pub/taxonomy/

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 HISTORY

    0.1	2008-10-27
    0.2 2014-06-23  Adapetd fpr SQLite3 version.
    0.3 2014-06-25  Improve bulk INSERT performance for 'names.dmp' and 
                    'nodes.dmp' files.

=cut

use 5.010;
use strict;
use warnings;

use DBI;
use Smart::Comments;

my $usage = << "EOS";
Import NCBI taxonomy files into local database.
Usage:
  load_taxon.pl <taxon dump dir> <db file>
Parameters:
  <taxon dump dir>: Directory stores taxdump files
  <db file>:        A SQLite3 database file
EOS

my $din = shift or die $usage;
my $fdb = shift or die $usage;

# Append a '/' to dir if it's not present
$din .= '/' unless ($din =~ /\/$/);

my $dbh;

eval {
	$dbh = DBI->connect(
	    "dbi:SQLite:dbname=$fdb",
	    "", "",
	    {
	        RaiseError  => 1,
	        PrintError  => 1,
	        AutoCommit  => 1,
	    }
	);
};

if ( $@ ) {
    warn "[ERROR] Connect to database file '$fdb' failed!\n", 
            $DBI::errstr;
    exit 1;
}

#my $fin;
#my @fields;

# Load file 'citation'
my $fin = $din . 'citations.dmp';

print "Loading file $fin\n";

my @fields = qw(cit_id cit_key pmid medline_id url cit_text taxids);

bulkLoadFile($fin, 'citations', \@fields, $dbh)
	or warn "Error: Load file $fin failed.\n", exit 1;

print "File '$fin' was parsed and loaded successfully.\n";
say '=' x 60, "\n";

# Load file 'division.dmp'
$fin = $din . 'division.dmp';

print "Loading file $fin\n";

@fields = qw(div_id div_code name comment);

bulkLoadFile($fin, 'division', \@fields, $dbh)
	or warn "Error: Load file $fin failed.\n", exit 1;

print "File '$fin' was parsed and loaded successfully.\n";
say '=' x 60, "\n";

# Load file 'gencode.dmp'
$fin = $din . 'gencode.dmp';

print "Loading file $fin\n";

@fields = qw(gc_id abbr name cde starts);

bulkLoadFile($fin, 'gencode', \@fields, $dbh)
	or warn "Error: Load file $fin failed.\n", exit 1;

print "File 'gencode.dmp' was parsed and loaded successfully.\n";
say '=' x 60, "\n";

# Load file 'names.dmp'
$fin = $din . 'names.dmp';

print "Loading file $fin\n";

@fields = qw(tax_id name uniq_name class);

bulkLoadFile($fin, 'names', \@fields, $dbh, 5000)
	or warn "Error: Load file $fin failed.\n", exit 1;

print "File 'names.dmp' was parsed and loaded successfully.\n";
say '=' x 60, "\n";

# Load file 'nodes.dmp'
$fin = $din . 'nodes.dmp';
 
print "Loading file $fin\n";
 
@fields = qw(tax_id parent_tax_id rank embl_code div_id inh_div_flag
 	gc_id inh_gc_flag mgc_id inh_mgc_flag gb_hid_flag
 	hid_sub_root_flag comment);
 
bulkLoadFile($fin, 'nodes', \@fields, $dbh, 5000)
 	or warn "Error: Load file $fin failed.\n", exit 1;
 
print "File '$fin' was parsed and loaded successfully.\n\n";
say '=' x 60, "\n";
 
print "All files have been loaded.\n";
 
$dbh->disconnect;

exit 0;

#=====================================================================
#
#			                  Subroutines
#
#=====================================================================

=head2 getValues
  Name:     getValues
  Usage:    GetValues($str)
  Function: Parse a row of NCBI taxonomy files, which was terminated by
            '\t|\n' and delimited by '\t|\t'.
  Args:     A string
  Return:   Reference of A array for all fields in the row.
            undef for all errors.
=cut

sub getValues {
    my ($str) = @_;
    
    # Remove terminal '\t|\n'
    $str =~ s/\|$//;

    my @values = split(/\t\|\t/, $str);
	$values[-1] =~ s/\t//;

    return \@values;
}

=begin
  Name:     bulkLoadFile
  Usage:    bulkLoadFile($fin, $table, \@fields, $dbh, $inv)
  Function: Bulk load a file into a table
  Args:     $fin        Input file
            $table      Table to be operated
            \@fileds    Field (column) names of the table
            $dbh        $dbh for the database
            $inv        Commit interval. Default 2,000.
  Return:   undef for all errors
=cut

sub bulkLoadFile {
    my ($fin, $table, $ra_cols, $dbh, $inv) = @_;

    $inv = 2000 unless (defined $inv);

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
	
	        my $ra_values = getValues($_);
	
	        if (scalar( @{ $ra_values } ) != $num_cols) {
	            warn "[ERROR] Values and columns were not match!\n";
	            warn "[ERROR] Possible wrong line:\n'$_'\n";
	
	            next;
	        }
	        
            # Number of parameters (placeholders)
	        my $p_num = 1;
	
	        for my $value ( @{$ra_values} ) {
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
