#!/usr/bin/perl

=head1 NAME

    aln4phyml.pl - Convert FASTA format alignment to PhyML PHYLIP 
                   sequential format alignment.

=head1 DESCRIPTION

    For the most recent PhyML version (Version 3.0, Sep. 19, 2011), the
    input PHYLIP format supports up to 100 characters sequence name.

=head1 AUTHORS

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.01    2011-10-31

=cut

use strict;
use warnings;

use 5.010;

use Bio::SeqIO;

my $usage = << "EOS";
Convert FASTA format alignment file into PhyML PHYLIP format file, which 
allows 100-character sequence name.
Usage:
  aln4phyml.pl <in> <out>
EOS

my ($fin, $fout) = @ARGV;

die $usage unless ($fin or $fout);

my $o_seqi = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

open(OUT, ">", $fout) or die "Error: '$fout' $!\n";

my %seqs;
my $seq_len;

while (my $o_seq = $o_seqi->next_seq) {
    my $id = $o_seq->display_id;

    # Remove sequence position information, which were appended by
    # Bio::AlignIO
    $id =~ s/\/\d+\-\d+$//;
    #chomp( $id );

    # Trunctuate id longer than 100 characters
    if ( length($id) > 100 ) {
        $id = substr( $id, 0, 100 );
    }

    my $seq = $o_seq->seq;

    $seqs{$id} = $seq;

    $seq_len = length( $seq );
}

my $num_seqs = scalar( keys %seqs );

say OUT ' ' x 2, $num_seqs, ' ', $seq_len;

for my $id ( keys %seqs ) {
    say OUT $id, ' ' x2, $seqs{$id};
}

close OUT;

exit 0;
