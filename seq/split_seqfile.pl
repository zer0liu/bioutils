#!/usr/bin/perl

=head1 NAME

    split_seqfile.pl - Split a FASTA format sequence file into many
                       files according to given key words exist in
                       sequence id.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-02-03

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;

my $usage = << "EOS";
Split FASTA format sequence file into many files.
Usage:
  split_seqfile <fin> <keys>
Args:
  <fin>     Input FASTA format sequence file.
  <keys>    Desired keywords for splitting the file.
            Multi-keywords should be quoted by (""), and separated
            by white-space.
Note:
  - The key would be used as the prefix of each output filename.
EOS

my $fin     = shift or die $usage;
my $kws    = shift or die $usage;   # Keywords

my @kws    = split /\s+/, $kws;

# Parse input filename
my ($basename, $dir, $suffix)   = fileparse($fin, qr{\..*});

# Output SeqIO objects
my %o_seqos;

for my $kw ( @kws ) {
    my $fout    = $kw . '_' . $basename . $suffix;

    my $o_seqo  = Bio::SeqIO->new(
        -file   => ">$fout",
        -format => 'fasta',
    );

    $o_seqos{ $kw }    = $o_seqo;
}

# Parse input sequence file
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

while ( my $o_seq = $o_seqi->next_seq ) {
    my $id  = $o_seq->id;

    for my $kw ( @kws ) {
        if ( $id =~ /\|$kw\|/ ) {
            my $o_cur_seqo  = $o_seqos{ $kw };

            $o_cur_seqo->write_seq($o_seq);
        }
    }
}

exit 0;

