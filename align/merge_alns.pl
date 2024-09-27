#!/usr/bin/perl

=head1 NAME

    merge_alns.pl - Combine alignment files with the same format into
                   one alignment file, in FASTA format.

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2014-10-30
    0.1.0   2019-03-07  New output method, output FASTA only. 
    0.2.0   2024-09-26  Rename script to 'merge_alns.pl'.
                        Re-write the algorithm, place the input alignments 
                        in order.

=cut

use 5.010;
use strict;
use warnings;

use Bio::AlignIO;
use Getopt::Long;
use File::Basename;

use Smart::Comments;

my $usage = << "EOS";
Usage:
  comb_alns.pl [-t <format>] -o <outf> <file1> <file2> ...

Options:
  -t <format>   Input file format.
                Optional. Default 'fasta'.
  -o <outf>     Output filename.

Arguments:
  <file1> <file2> ... : Input alignment files

Note:
  1. All input alignment files MUST as the same formats.
  2. The combined sequence order according to the given input files.
  3. Supported alignment file formats are:
        clustalw
        fasta
        msf
        nexus
        phylip (interleaved)
        selex
EOS

my ($fmt_in, $fmt_out, $fout);

$fmt_in     = 'fasta';
$fmt_out    = 'fasta';

GetOptions(
    "t=s"   => \$fmt_in,
#    "m=s"   => \$fmt_out,
    "o=s"   => \$fout,
    "h"     => sub { die $usage }
);

die $usage unless ( $fmt_in && $fout );

my $n_aln = scalar(@ARGV);

say "[NOTE] '$n_aln' alignment files to be merged:";

## @ARGV

die "[ERROR] Please give 2 or more input alignment files!\n!" 
  if ($n_aln < 2);

# Hash to store merged alignment
# Structure
# {
#   "id",           # Sequence ID
#   "seq",          # Sequence string
#   "pos",          # Position of the sequence, start from '1'.
#                   # Used to keep the order of the first alignment.
#   "amount"        # Number of merged sequences under this ID.
# }

my %merged_aln;

#
# Parse the 1st input alignment file
#

say "[NOTE] Parsing alignment file: '$ARGV[0]' ...";

# Current working alignment file
my $f_cur_aln = shift @ARGV;

my $o_alni  = Bio::AlignIO->new(
  -file   => $f_cur_aln,
  -format => $fmt_in,
);

my $o_aln = $o_alni->next_aln;

my $seq_pos = 1;  # Current sequence position. Start from '1'

# my $merged_amount = 1;

die "[ERROR] Input file '$f_cur_aln' is NOT a proper alignment file!\n
    Please check!\n"
  unless($o_aln->is_flush);

for my $o_seq ($o_aln->each_seq) {
  $merged_aln{ $seq_pos }->{ "id" }     = $o_seq->id;
  $merged_aln{ $seq_pos }->{ "seq" }    = $o_seq->seq;
  $merged_aln{ $seq_pos }->{ "amount" } = 1;

  $seq_pos++;
}

## %merged_aln

#
# Parse & merge remaining alignment files
#

for my $f_cur_aln ( @ARGV ) {
  say "[NOTE] Parsing alignment file: '$f_cur_aln' ...";

  my $o_alni  = Bio::AlignIO->new(
    -file   => $f_cur_aln,
    -format => $fmt_in,
  );

  my $o_aln = $o_alni->next_aln;

	die "[ERROR] Input file '$f_cur_aln' is NOT a proper alignment file!\n
	    Please check!\n"
	  unless($o_aln->is_flush);

  my $seq_pos = 1;

  for my $o_seq ( $o_aln->each_seq ) {
    my $id      = $o_seq->id;
    my $seq_str = $o_seq->seq;

    # Check whether current seq ID were identical to merged_aln
    my $merged_id = $merged_aln{ $seq_pos }->{ "id" };
    die "
[ERROR] Sequence IDs are NOT identical at the position '$seq_pos':
[ERROR] Need '$merged_id', but '$id' is found in file '$f_cur_aln'.\n"
        if ( $id ne $merged_aln{ $seq_pos }->{"id"});
    
    $merged_aln{ $seq_pos }->{ "seq" }  =
      $merged_aln{ $seq_pos }->{ "seq" } . $seq_str;
    $merged_aln{ $seq_pos }->{ "amount" }++;

    $seq_pos++;
  }

  # Verify the merged amount of each position
  my $check_amount  = $merged_aln{1}->{"amount"};

  for my $seq_pos (keys %merged_aln) {
    my $cur_amount  = $merged_aln{ $seq_pos }->{"amount"};

    die "
[ERROR] Merged amounts are NOT consistent in the '$seq_pos' with 
[ERROR] sequence ID '$merged_aln{$seq_pos}->{\"id\"}'
[ERROR] Please check.\n"
      if ($check_amount != $cur_amount);
  }
}

#
# Output to fasta file
#
open(my $fh_out, ">", $fout) or
  die "[ERROR] Create output file '$fout' failed!\n$!\n";

for my $pos (sort { $a <=> $b } keys %merged_aln) {
  say $fh_out ">", $merged_aln{ $pos }->{ "id" };
  say $fh_out $merged_aln{ $pos }->{ "seq" };
}

close $fh_out;

say "[DONE] Merged alignment file '", $fout, "' created.";

# END