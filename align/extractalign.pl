#!/usr/bin/perl

=head1 NAME

    extractalign.pl - Extract regions from a sequence alignment according
                      to given locations.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-12-01
    0.0.2   2015-12-02  Bug fix

=cut

use 5.010;
use strict;
use warnings;


use Bio::AlignIO;
use File::Basename;
use Getopt::Long;

use Smart::Comments;

my $usage   = << "EOS";
Extract regions from a sequence alignment.
Usage:
  extractalign.pl -i <fin> [-f <fmt>] [-o <fout>] [-m <fmt>] -r <region>
Args:
  -i <fin>      Input file.
  -f <fmt>      Input file format. 
                Optional. Default 'fasta'.
  -o <fout>     Output file.
                Optional.
  -m <fmt>      Output file format.
                Optional. Default same as input format.
  -r <region>   Region to be extracted. 
                e.g., 4-57
EOS

my ($fin, $ifmt, $fout, $ofmt, $region);

# Default input file format: 'fasta'
$ifmt   = 'fasta';

GetOptions(
    "i=s"   => \$fin,       # Input file
    "f=s"   => \$ifmt,      # Input format
    "o=s"   => \$fout,      # Output file
    "m=s"   => \$ofmt,      # Output format
    "r=s"   => \$region,    # Region string
    "h"     => sub { die $usage }
);

die $usage unless ($fin && $region);

# Generate output filename
# Append '.out' to the $fin basename
unless (defined $fout) {
    my ($basename, $dir, $suffix)   = fileparse($fin, qr/\..*/);

    $fout   = $basename . '.out';
}

# Output file format
$ofmt   = $ifmt unless ( defined $ofmt );

# Parse region information
die "[ERROR] Wrong region format!\n" 
    unless ($region =~ /-/);

my ($start, $end)   = split /-/, $region;

die "[ERROR] Please input numeric values for region.\n"
    unless ($start =~ /^\d+$/ && $end =~ /^\d+$/);

die "[ERROR] The start location is greater than end location.\n"
    if ($start > $end);

my $o_alni  = Bio::AlignIO->new(
    -file   => $fin,
    -format => $ifmt,
);

my $o_alno  = Bio::AlignIO->new(
    -file   => ">$fout",
    -format => $ofmt,
);

my $o_aln   = $o_alni->next_aln;

my $o_slice = $o_aln->slice($start, $end);

$o_alno->write_aln($o_slice);

exit 0;

