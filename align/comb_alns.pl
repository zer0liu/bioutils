#!/usr/bin/perl

=head1 NAME

    comb_alns.pl - Combine alignment files with the same format into
                   one alignment file, in FASTA format.

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2014-10-30

=cut

use 5.010;
use strict;
use warnings;

use Bio::AlignIO;
use Getopt::Long;

use Smart::Comments;

my $usage = << "EOS";
Usage:
  comb_alns.pl -t <format> [-m <format>] -o <outf> <file1> <file2> ...

Options:
  -t <format>   : Input file format
  -m <format>   : Output file format. Always FASTA.
  -o <outf>     : Output filename.

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

# $fmt_out    = 'fasta';

GetOptions(
    "t=s"   => \$fmt_in,
    "m=s"   => \$fmt_out,
    "o=s"   => \$fout,
    "h"     => sub { die $usage }
);

$fmt_out    = 'fasta';

die $usage unless ( $fmt_in && $fout );

my %aln_seqs;

for my $fin ( @ARGV ) {
    say "Parsing $fin ...";

    my $o_alni  = Bio::AlignIO->new(
        -file   => $fin,
        -format => $fmt_in,
    ) or die "[ERROR] Parse file '$fin' as format '$fmt_in' failed!\n";

    my $o_aln   = $o_alni->next_aln;

    for my $o_seq ( $o_aln->each_seq ) {
        my $id  = $o_seq->id;
        my $seq = $o_seq->seq;

        $aln_seqs{ $id }    .= $seq;
    }
}

# %aln_seqs

# Output alignment
# Output Bio::Align::AlignO object
my $o_alno  = Bio::AlignIO->new(
    -file   => ">$fout",
    -format => $fmt_out,
);

# Output Bio::SimpleAlign object
my $o_aln   = Bio::SimpleAlign->new();

for my $id ( sort ( keys %aln_seqs ) ) {
    my $o_seq   = Bio::LocatableSeq->new(
        -id     => $id,
        -seq    => $aln_seqs{ $id },
    );

    $o_aln->add_seq( $o_seq );
}

### $o_aln

$o_alno->write_aln( $o_aln );

say "[OK] All files combined and output as a FASTA alignment file!";

exit;

