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
    0.1.0   2020-03-27  Accept multiple regions
    0.1.1   2020-03029  Finishing the new feature.

=cut

use 5.010;
use strict;
use warnings;

use 5.010;
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
  -r <region>   A set of regions to be extracted. 
                A regions is a pair of integers, separared by any non-digit character.
                e.g., 
                4-57, 80-100
                1:55, 67=123; 756..902
                1,5, 8, 10,23,45,67,200
Note:
* Positions have to be pairs.
* For a region, the start position should be lesser than end position.
* Regions could not be overlapped.
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
# Default identical to input format
$ofmt   = $ifmt unless ( defined $ofmt );

# Parse region information
#die "[ERROR] Wrong region format!\n" 
#    unless ($region =~ /-/);

#my ($start, $end)   = split /-/, $region;
#
#die "[ERROR] Please input numeric values for region.\n"
#    unless ($start =~ /^\d+$/ && $end =~ /^\d+$/);
#
#die "[ERROR] The start location is greater than end location.\n"
#    if ($start > $end);

# Parse region sets
my $ra_regions  = parse_regions( $region );

### $ra_regions

exit(1) unless ( defined $ra_regions );

# Operation alignment
my $o_alni  = Bio::AlignIO->new(
    -file   => $fin,
    -format => $ifmt,
);

my $o_alno  = Bio::AlignIO->new(
    -file   => ">$fout",
    -format => $ofmt,
);

my $o_aln   = $o_alni->next_aln;

#
# User Bio::SimpleAlign method 'remove_columns' to remove columns
#
# Note: 
#   The first column is 0
#
#

my $aln_length  = $o_aln->length;

say "[NOTE] Alignment length: $aln_length";

# Convert region to region-to-be-removed
my $ra_rm_cols = convert_regions( $ra_regions );

### $ra_rm_cols

# say scalar @{ $ra_rm_cols };

my $o_aln_rm    = $o_aln->remove_columns( @{$ra_rm_cols} );

$o_alno->write_aln( $o_aln_rm );

say "[DONE] All regions extracted.";

exit 0;

#===========================================================
#
#               Subroutines
#
#===========================================================

=head2 parse_regions

  Title:    parse_regions
  Usage:    parse_regions($regions_str)
  Funtion:  Parse region string to position pairs
  Args:     A string for region sets.
            Positions are integers, separated by non-digits.
  Returns:  A reference of array

=cut

sub parse_regions {
    my ($regions_str)  = @_;

    my @pos = split /\D+/, $regions_str;

    my $num_pos = scalar( @pos );

    # Whether number of positions is odd
    if ( $num_pos % 2 == 1) {
        warn "[ERROR] Odd number of positions for regions: '$regions_str'.!\n";
        return;
    }
    
    return \@pos;

#    my @regions;
#    
#    for (my $i=0; $i<$num_pos; $i++) {
#        my $start   = $pos[$i];
#        my $end     = $pos[$i+1];
#
#        if ($start >= $end ) {
#            warn "[ERROR] Start position '$start' >= End position '$end'!\n";
#            return;
#        }
#
#        push @regions, [$start, $end];
#
#        $i++;
#    }
#
#    return \@regions;
}

=head2

  Title:    convert_regions
  usage:    convert_regions($ra_regions)
  Function: Convert keep regions to remove column regions
  Args:     An array reference
  Return:   An array reference
=cut

sub convert_regions {
    my ($ra_rgns)   = (@_);

    my ($start, $end);
    
    my $num_positions   = scalar( @{ $ra_rgns } );
    
    # Excluding regions
    my @excl_rgns;
    
    my $i   = 0;
    
    $start  = 0;
    
    while ($i < $num_positions) {
        $end    = shift @{ $ra_rgns };    
        $end    = $end - 2;     # -1 -1
    
        push @excl_rgns, [$start, $end];
        $i++;
    
        $start  = shift @{ $ra_rgns };
        $start  = $start;       # -1 +1
        $i++;
    }
    
    $end    = $aln_length - 1;
    
    push @excl_rgns, [$start, $end];

    return \@excl_rgns;
}


