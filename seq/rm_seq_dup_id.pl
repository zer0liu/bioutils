#!/usr/bin/perl

=head1 NAME

rm_seq_dup_id.pl - Remove sequence with duplicated IDs from a FASTA file.

=head1 VERSION

    0.0.1   2025-02-17

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;

my $usage = << "EOS";
Remove sequence with duplicated IDs from a FASTA file.
Usage:
  $0 <input FASTA file> <output FASTA file>\n
EOS

my $input = shift or die $usage;
my $output = shift or die $usage;

my $in = Bio::SeqIO->new(-file => $input, -format => 'fasta');
my $out = Bio::SeqIO->new(-file => ">$output", -format => 'fasta');

my %seen;

while (my $seq = $in->next_seq) {
    my $id = $seq->id;
    if (exists $seen{$id}) {
        warn "Duplicated ID: $id\n";
    }
    else {
        $seen{$id} = 1;
        $out->write_seq($seq);
    }
}

exit 0;

__END__

