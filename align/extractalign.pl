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
    0.1.1   2020-03029  Attempt to create new alignments by removing multiple regions.
    0.1.2   2020-04-07  Merge alignments manually.
    0.1.3   2022-01-30  Keep gap-only columns in new created columns.

=cut

use 5.010;
use strict;
use warnings;

use 5.010;
use Bio::AlignIO;
use Bio::SeqIO;
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

# Parse region sets
my $rh_regions  = parse_regions( $region );

## $rh_regions

exit(1) unless ( defined $rh_regions );

# Operation alignment
my $o_alni  = Bio::AlignIO->new(
    -file   => $fin,
    -format => $ifmt,
);

# Assume there were only ONE alignmenet in the file
my $o_aln   = $o_alni->next_aln;

my $aln_length  = $o_aln->length;

say "[NOTE] Alignment length: $aln_length";

my $rh_aln_regions  = extract_aln_regions($o_aln, $rh_regions);

## $rh_aln_regions

my $o_extracted_rgns    = merge_aln_regions($rh_aln_regions);

$o_extracted_rgns->set_displayname_flat();

my $o_alno  = Bio::AlignIO->new(
    -file   => ">$fout",
    #-fh     => \*STDOUT,
    -format => $ofmt,
);

$o_alno->write_aln( $o_extracted_rgns );

say "[DONE] All regions extracted.";
say "[DONE] Extracted regions length: ", $o_extracted_rgns->length;

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
  Args:     $regions_str    - A string for region sets.
            Positions are integers, separated by non-digits.
  Returns:  A reference of hash

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

    my $i       = 0;
    my $rgn_num = 1;
    my %rgns;

    while ($i < $num_pos) {
        my $start   = shift @pos;
        my $end     = shift @pos;

        if ($start > $end) {
            warn "[ERROR] START position '$start' is greater than END position '$end' in region '$regions_str'.!\n";
            $i  += 2;
            next;
        }

        $rgns{ $rgn_num }->{'start'} = $start;
        $rgns{ $rgn_num }->{'end'}   = $end;

        $i  += 2;
        $rgn_num++;
    }
    
    return \%rgns;
}

=head2 extract_aln_regions

  Title:    extract_aln_regions
  Usage:    extract_aln_regions($o_aln, $rh_regions)
  Function: Extract regions from $o_aln according to $rh_regions
  Args:     $o_aln      - A Bio::SimpleAlign object
            $rh_regions - A hash reference
  Return:   A reference of hash

=cut

sub extract_aln_regions {
    my ($o_aln, $rh_rgns)   = @_;

    my %aln_rgns;

    for my $rgn (sort {$a<=>$b} keys %{$rh_rgns}) {
        my $start   = $rh_rgns->{ $rgn }->{'start'};
        my $end     = $rh_rgns->{ $rgn }->{'end'};

        my $o_aln_rgn   = $o_aln->slice($start, $end, 1);

        # $o_aln_rgn->set_displayname_flat();
        
        $aln_rgns{ $rgn }   = $o_aln_rgn;
    }

    ## %aln_rgns

    return \%aln_rgns;
}

=head2 merge_aln_regions

  Title:    merge_aln_regions
  Usage:    merge_aln_regions( $rh_aln_rgns )
  Fuction:  Merge each alignment regions
  Args:     A hash reference of Bio::SimpleAlign objects.
  Return:   A Bio::SimpleAlign object

=cut

sub merge_aln_regions {
    my ($rh_aln_rgns)   = @_;

    my $o_mg_aln;

    for my $rgn (sort {$a<=>$b} keys %{ $rh_aln_rgns}) {
        unless (defined $o_mg_aln) {    # Init object
            $o_mg_aln   = $rh_aln_rgns->{$rgn};
        }
        else {
            $o_mg_aln   = join_alns( $o_mg_aln, $rh_aln_rgns->{ $rgn } );
        }
    }

    return $o_mg_aln;
}

=head2 join_alns

  Title:    join_alns
  Usage:    join_alns($aln1, $aln2)
  Function: Join two Bio::SimpleAlign objects
  Args:     $aln1, $aln2    - Bio::SimpleAlign objects
  Return:   A Bio::SimpleAlign object

=cut

sub join_alns {
    my ($o_aln1, $o_aln2)   = @_;

    # Parse 1st Bio::SimpleAlign object into a hash
    my %o_aln1_seqs;

    for my $o_seq ( $o_aln1->each_seq) {
        my $seq_id  = $o_seq->id;
        $o_aln1_seqs{ $seq_id } = $o_seq;
    }

    # The Bio::SimpleAlign object to be returned
    my $o_aln_ret    = Bio::SimpleAlign->new();

    # Append Seq objects of $o_aln2 to $o_aln1
    for my $o_seq ( $o_aln2->each_seq ) {
        my $seq_id  = $o_seq->id;
        
        my $joined_seq_str = ( $o_aln1_seqs{ $seq_id }->seq ) . ( $o_seq->seq );

        # Update Seq object
        $o_seq->seq( $joined_seq_str );

        $o_aln_ret->add_seq( $o_seq );
    }

    return $o_aln_ret;
}

