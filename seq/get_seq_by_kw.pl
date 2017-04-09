#!/usr/bin/perl

=head1 NAME

    get_seq_by_kw.pl - Get sequences from a Multi-FASTA file according to
                       given keywords file.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-02-04

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
#use Smart::Comments;

my $usage = << "EOS";
Get sequences from a multi-FASTA file accroding to a keywords file, then
output to STDOUT.
Usage:
  get_seq_by_kw.pl <seq> <kw>
Arguments:
  <seq> FASTA format sequence file.
  <kw>  Keywords file. One keywords in each line.
EOS

my $fseq    = shift or die $usage;
my $fkw     = shift or die $usage;

# Parse keywords file
my @keywords;

open(my $fh_kw, "<", $fkw)
    or die "[ERROR] Open keyword file '$fkw' failed!\n$!\n\n";

while (<$fh_kw>) {
    next if /^#/;
    next if /^\s*$/;
    chomp;
    s/\r$//; # For Windows format text file, remove '\r'

    push @keywords, $_;
}

close $fh_kw;

# Check sequence ids one by one

# Input SeqIO object
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fseq,
    -format => 'fasta',
);

# Output SeqIO object
my $o_seqo  = Bio::SeqIO->new(
    -fh     => \*STDOUT,
    -format => 'fasta',
);

while (my $o_seq = $o_seqi->next_seq) {
    my $id  = $o_seq->id;

    for my $kw ( @keywords ) {
        $o_seqo->write_seq( $o_seq ) if ( $id =~ /$kw/ );
    }
}

exit 0;
