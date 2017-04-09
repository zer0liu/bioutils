#!/usr/bin/perl

=head1 NAME

    get_seqlen.pl - Get sequence length for each sequence in a file.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-12-11

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;

my $usage   = << "EOS";
Get sequence length of a file.
Usage:
  get_seqlen.pl <file> [<format>]
Args:
  <file>    Input sequence file.
  <format>  Input sequence file format.
            Default 'fasta'.
Note:
  Output to STDOUT
EOS

my $fin = shift or die $usage;
my $fmt = shift // 'fasta';

my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

while (my $o_seq = $o_seqi->next_seq) {
    # Output seq length directly.
    say $o_seq->length;
}

exit 0;
