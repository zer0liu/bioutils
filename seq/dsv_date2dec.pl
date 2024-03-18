#!/usr/bin/perl

=head1 NAME

    sv_date2dec.pl - Convert `date` column of a tsv or csv file to decimal.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2024-03-18

=cut

use 5.010;
use strict;
# use warnings;

use Date::Calc qw(Day_of_Year leap_year);
use File::Basename;
use Getopt::Long;
use Smart::Comments;
use Time::Piece;

my $usage   = << "EOS";
Convert `date` column to decimal.
Usage:
  cv_date2dec.pl -i <fin> [-c <column>] [-o <fout>]
Args:
  -i <fin>     Input filename
  -c <column>   Date column name.
                Optional. Default 'date'.
  -o <fout>     Output filename.
                Optional. Default output to stdout.
NOTE:
  - Input file type, `tsv` or `csv` would be determined by its file extension.
  - There have to be a header line.
EOS

my ($fin, $col_name, $fout);

$col_name   = "date";

GetOptions(
    "i=s"   => \$fin,
    "c=s"   => \$col_name,
    "o=s"   => \$fout,
);

# Determin separator of column according to file extension
# csv: ','
# tsv: '\t'

die $usage unless (defined $fin);

my ($fname, $path, $suffix) = fileparse($fin, qr/\.[^.]*/);

my $sep;

if ($suffix eq '.csv') {
    $sep    = ",";
}
elsif ($suffix eq ".tsv") {
    $sep    = "\t";
}
else {
    die "[ERROR] Unsupported file type: '$sep'!\n";
}

my $fh_in;

open($fh_in, "<", $fin) or
    die "[ERROR] Open input file failed!\n$!\n";

my $fh_out;

if (defined $fout) {
    open($fh_out, ">", $fout) or
        die "[ERROR] Create output file failed!\n$!\n";
    }
else {
    $fh_out = *STDOUT;
}

# Read the header line
my $header_line = <$fh_in> or
    die "[ERROR] Read header line failed!\n$!\n";

chomp($header_line);

unless ($header_line =~ /$col_name/) {
    die "[ERROR] Date column `$col_name` not found!\n";
}

# Output header line
say $fh_out $header_line;

my @headers = split "$sep", $header_line;

while (<$fh_in>) {
    next if /^\s*$/;

    chomp;

    my @values  = split "$sep", $_;

    my %record;

    @record{@headers}  = @values;

    # Convert date to dec
    $record{$col_name}  = date2dec($record{$col_name});

    die "[ERROR]\n" unless ($record{$col_name});

    say $fh_out join("$sep", @record{@headers});
}

close $fh_out;
close $fh_in;

#===========================================================
#
#   Subroutines
#
#===========================================================

sub date2dec {
    my ($date_str)  = @_;

    # Remove any possible spaces
    $date_str   =~ s/\s//g;

    my ($year, $month, $day);

    my $date    = Time::Piece->strptime($date_str, '%Y-%m-%d');

    # Day of year
    my $doy     = $date->yday();

    # Whether a leap year
    my $total_days_in_year;

    if ($date->is_leap_year) {
        $total_days_in_year = 366;
    }
    else {
        $total_days_in_year = 365;
    }

    # Calculate the fraction of the year
    my $ydec = $date->year() + sprintf("%.4f", $doy / $total_days_in_year);

    # Output
    return($ydec);
}

