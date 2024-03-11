#!/usr/bin/perl

=head1 NAME

  rm_aln_sites.pl - Remove sites from an alignment.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

  zeroliu-at-gmail-dot-com

=head1 VERSION

  0.0.1 2024-03-08
  0.0.2 2024-03-11  Minor modification.

=cut

use 5.010;
use strict;
use warnings;

use Bio::AlignIO;
use Getopt::Long;
use Smart::Comments;

my $usage = << "EOS";
Remove given sites from an alignment file.
[NOTE] This script do NOT output sites-removed alignment file directily,
[NOTE] but generate a REGION LIST for the input for the script:
[NOTE] `extractalign.pl`

Usage:
  rm_sites_aln.pl -i <faln> -f <fmt> -l <length> -s <sites>
Args:
  -i <faln>   Input alignment file.
              Do not need if `-l` option is given.
  -f <fmt>    Input alignment format.
              Optional. Default 'fasta'.
  -l <length> Alignment length.
              Do not need if `-i` option is given.
  -s <sites>  A list of sites, seperated by a ','. A region of sites can be
              expressed as `1-10`. No space or other characters allowed.
              e.g.,
              '1-10,15,20,50-70,100'
              Note that the list must be quoted.
EOS

my ($faln, $fmt, $aln_length, $sites);

$fmt  = 'fasta';

GetOptions(
  "i=s"   => \$faln,
  "f=s"   => \$fmt,
  "l=i"   => \$aln_length,
  "s=s"   => \$sites,
  "h"     => sub {die $usage}
);

unless ($faln || $aln_length) {
  warn "[ERROR] Please provide alignment filename ('-i') or alignment length (-l).";
  die $usage;
}

unless (defined $sites) {
  warn "[ERROR] Please provide sites to be removed ('-s')!";
  die $usage;
}

if (defined $faln) {
  my $o_alni  = Bio::AlignIO->new(
    -file   => $faln,
    -format => $fmt,
  );

  my $o_aln = $o_alni->next_aln;

  # Alignment length
  $aln_length  = $o_aln->length;
}

warn "[NOTE] Alignment length: ", $aln_length, "\n\n";

# Parse sites list
if ($sites =~ /[^,-1234567890]/) {
  die "[ERROR] Only 0-9, ',' or '-' allowed!\n";
}

my @sites = split /,/, $sites;

## @sites

# Convert array to hash
# All regions/sites will be treated as the hash format:
# {strat => $start, end => $end}

my @paired_regions;

for my $site ( @sites ) {
  if ($site =~ /^(\d+)\-(\d+)$/) { # e.g., '1-10'
    my $start = $1;
    my $end   = $2;

    if ($start > $end) {
      warn "[ERROR] Wrong site start and end value: '$site'\n";
      exit 1;
    }

    if ($start > $aln_length or $end > $aln_length) {
      warn "[ERROR] Site position beyond the alignment length: ",
        "'", $site, "'.\n";
      exit 1;
    }

    my %site  = (
      start => $1,
      end   => $2,
    );

    push @paired_regions, \%site;
  }
  elsif ($site =~ /^\d+$/) {  # e.g., '5' or '20'
    if ($site > $aln_length) {
      warn "[ERROR] Site position beyond the alignment length: ",
        "'", $site, "'.\n";
      exit 1;
    }

    my %site  = (
      start => $site,
      end   => $site,
    );

    push @paired_regions, \%site;
  }
  else {
    warn "[ERROR] Unrecognized site: '$site'!\n";
    exit 1;
  }
}

## @paired_regions

#
# Preprocessing 1: Sort sites by start value
#
my @sorted_regions  = sort {$a->{start} <=> $b->{start}} @paired_regions;

## @sorted_regions

#
# Preprocessing 2: Check overlapped regions
#
# e.g., (1,5) and (3,7) or (1,5) and (5,7)
#
# Here will NOT modify the content of array `@sorted_regions`.
# If overlapped regions were found, it will exit with an error.
#

my @test_regions  = @sorted_regions;

my $rh_prior_region = shift @test_regions;

for my $rh_cur_region (@test_regions) {
  if ($rh_prior_region->{end} >= $rh_cur_region->{start}) {
    warn "[ERROR] Found overlapped regions at: ", 
        "'", $rh_prior_region->{start}, "-", $rh_prior_region->{end}, "'",
        " and ",
        "'", $rh_cur_region->{start}, "-", $rh_cur_region->{end}, "'\n";
    
    exit 1;
  }
  else {
    $rh_prior_region  = $rh_cur_region;
  }
}

#
# Preprocessing 3: merge neighbor regions
#
# Still working on `@sorted_regions`
#
# e.g., (1, 3) and (4, 6) ==> (1, 6)
#

my @merged_regions;

$rh_prior_region = shift @sorted_regions;

for my $rh_cur_region (@sorted_regions) {
  if ($rh_prior_region->{end} +1 == $rh_cur_region->{start}) { # is neighbor
    my %merged_region  = (
      start => $rh_prior_region->{start},
      end   => $rh_cur_region->{end},
    );

    $rh_prior_region  = \%merged_region;
  }
  else {  # Not neighbor
    push @merged_regions, $rh_prior_region;

    $rh_prior_region  = $rh_cur_region;
  }

  # push @merged_regions, $rh_cur_region;
}

push @merged_regions, $rh_prior_region;

## @merged_regions

#
# Generate regions list to be extracted.
#

my @extract_regions;
# my %extract_region;

$rh_prior_region  = shift @merged_regions;

# 
# If given regions not started with positon `1`
#

if ($rh_prior_region->{start} > 1) {
  my %extract_region  = (
    start => 1,
    end   => $rh_prior_region->{start} - 1,
  );

  push @extract_regions, \%extract_region;
}

## @extract_regions

for my $rh_cur_region (@merged_regions) {
  my %extract_region  = (
    start => $rh_prior_region->{end} + 1,
    end   => $rh_cur_region->{start} - 1,
  );

  push @extract_regions, \%extract_region;

  $rh_prior_region  = $rh_cur_region;
}

if ($rh_prior_region->{end} < $aln_length) {
  my %extract_region  = (
    start => $rh_prior_region->{end} + 1,
    end   => $aln_length,
  );

  push @extract_regions, \%extract_region;
}

## @extract_regions

#
# Generate `-r` region strings and output to STDOUT.
#

my $region_str = "";

for my $rh_cur_region (@extract_regions) {
  $region_str  .= $rh_cur_region->{start} . "-" . $rh_cur_region->{end} . ",";
}

#
# Remove tailing `,`
#
$region_str =~ s/,$//;

say "Regions to be extracted are:\n", "'", $region_str, "'\n";

say "Add parameter: \n\n", '=' x 50, "\n\n-r '", $region_str, "'\n\n", 
  '='x50, "\n\nto the script `extractalign.pl`";

