#!/usr/bin/perl

=head1 NAME

    rm_seq_by_id.pl - Remove sequences according to seq IDs given in
                      a text file.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2016-04-22

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;

use Smart::Comments;

my $usage = << "EOS";
Remove sequences according to seq IDs given by a text file.
Usage:
  rm_seq_by_id.pl <fin> <fids> <fout>
Note:
  It assumes both input and output sequence format are FASTA.
EOS

my $fin     = shift or die $usage;
my $fids    = shift or die $usage;
my $fout    = shift;

# Generate output file name of necessaru
unless (defined $fout) {
    my ($basename, $dir, $suffix)   = fileparse($fin, qr/\..*/);

    $fout   = $basename . '_out.ffn';
}

# Read ids into a hash
my %ids;

open(my $fh_ids, "<", $fids)
    or die "[ERROR] Open sequence ID file '$fids' failed!\n$!\n";

while (<$fh_ids>) {
    next if /^#/;
    next if /^\s*$/;
    chomp;

    # Get first column ONLY, if there were multi columns
    my ($id,)   = split /\s+/;

    # Remove leading '>' if necessary
    $id =~ s/^>//;

    $ids{$id}   = 1;
}

# %ids;

# Parse and remove desired sequences
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

my $o_seqo  = Bio::SeqIO->new(
    -file   => ">$fout",
    -format => 'fasta',
);

while (my $o_seq = $o_seqi->next_seq) {
    my $cur_id  = $o_seq->id;

    # Dismiss desired sequences
    next if $ids{ $cur_id };

    $o_seqo->write_seq($o_seq);
}

say "Done!";
