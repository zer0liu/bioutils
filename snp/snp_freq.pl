#!/usr/bin/perl

#
# Parse and calaulcate SNP frequencies of each element (nt or aa)
# of each position.
# 
# Note:
# Elements in the first sequence as the reference.
#

use 5.010;
use strict;
use warnings;

use Bio::AlignIO;
use Bio::SeqIO;
use Smart::Comments;

my $usage = << "EOS";
Parse and calculate SNP frequencies of each postion for a sequene 
alignment file.
Usage:
snp_freq.pl <faln> <fout>
Note:
- Only accept FASTA format alignment file.
- The first sequence in alignment file is used as reference sequence.
EOS

my $faln  = shift or die "[ERROR] Need an input alignment filename!\n$usage\n";
my $fout  = shift or die "[ERROR] Need an output filename!\n$usage\n";

open(my $fh_out, ">", $fout) or
  die "[ERROR] Create output file '$fout' failed!\n$!\n";

# Output header line
say $fh_out join("\t", qw(Position Ref Alt Num Freq));

my $o_alni  = Bio::AlignIO->new(
  -file   => $faln,
  -format => 'fasta',
);

my $o_aln   = $o_alni->next_aln;

# Check whether the alignment is flush, i.e., all of the same length
unless ($o_aln->is_flush) {
    die "[ERROR] Sequences in the alignment are NOT in the same length!\n";
}

# Set to upper case
unless ($o_aln->uppercase) {
    die "[ERROR] Convert sequences to uppercase failed!\n";
}

# Alignment length
my $aln_len = $o_aln->length;

my $total_seq_num = $o_aln->num_sequences;

## $total_seq_num

# Fetch alignment of each position
for my $pos (1 .. $aln_len) {
  ## $pos
  my $o_slice_aln = $o_aln->slice($pos, $pos, 1);

  my $seq_num = 0;  # Sequence number in alignment, start from 1.

  my %elements;
  my $ref_elem;

  for my $o_seq ($o_slice_aln->each_seq) {
    $seq_num++;

    if ($seq_num == 1) {  # Reference
      $ref_elem         = $o_seq->seq;
      $elements{'ref'}  = $ref_elem;
    }
    else {
      my $elem  = $o_seq->seq;

      if ($elem eq $ref_elem) { # Identical to reference
        next;
      }
      elsif ($elem eq '-') { # Dissmiss alignment gaps: "-"
        next;
      }
      elsif ($elem eq 'X') { # Dismiss translation error: "X"
        next;
      }
      else {  # Variation
        $elements{'var'}->{ $elem }++; # Sum the number of this variation
      }
    }
  }

  ## %elements
  ## $seq_num
  ## ==================================================
  # Parse hash %elements
  # Output variation ONLY
  #
  # Columns
  # Pos Ref Alt Num Pct

  if (exists $elements{"var"}) {
    for my $var (keys %{ $elements{"var"} }) {
      my $var_num  = $elements{"var"}->{$var};
      my $var_freq = $var_num / ($total_seq_num - 1);

      say $fh_out join "\t", 
                  ($pos,
                  $elements{"ref"},
                  $var,
                  $var_num,
                  sprintf("%.4f", $var_freq) );
    }
  }
}

close $fh_out;

# DONE
