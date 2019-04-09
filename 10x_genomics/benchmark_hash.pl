#!/usr/bin/perl

=head1 NAME

    benchmark_grep.pl - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   - 2019-04-09

=cut

use 5.12.1;
use strict;
use warnings;

my $f_qry   = shift or die "[ERROR] Input file not found!\n$!\n";

my $f_cb    = "737K-august-2016.txt";   # 10x cell barcode file

# Load barcodes into an array
# my @cbs;
my %cbs;

open my $fh_cb, "<", $f_cb or
    die "[ERROR] Open Cell Barcode file '$f_cb' failed!\n$!";

while (<$fh_cb>) {
    next if /^#/;
    next if /%\s*$/;
    chomp;

    $cbs{$_}++;
}

close $fh_cb;

# Load query strings.
my @queries;

open my $fh_qry, "<", $f_qry or
    die "[ERROR] Open query file '$f_qry'!\n$!\n";

while (<$fh_qry>) {
    next if /^#/;
    next if /^\s*$/;
    chomp;

    push @queries, $_;
}

close $fh_qry;

my $f_found = 0;

for my $qry ( @queries ) {
    $f_found++ if ($cbs{$qry});
}

say "[DONE] Found $f_found!";

#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Display usage information
  Args:     None
  Returns:  None

=cut

sub usage {
    say << 'EOS';

EOS
}

=pod

  Name:     
  Usage:    
  Function: 
  Args:     
  Returns:  

=cut

