#!/usr/bin/perl

=head1 NAME

    filter_seq_by_len.pl - Return sequences which length in given range.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2020-07-01
    0.1.0   2021-03-17  Modified for better comprehensive.

=cut

use 5.12.1;
use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;
use Getopt::Long;
use Smart::Comments;

my $usage = << "EOS";
Filter sequences in a multi-FASTA file by length.
Usage:
  filter_seq_by_len.pl -i <fseq> -o <fseq> [--gt <len> | --lt <len>]
Note:
  * <gt> and <lt> must provide at least one.
  * If provided <gt> only, output all sequences longer than <len>.
  * If provided <lt> only, output all sequences shorter than <len>.
EOS

my ($fin, $fout, $min, $max);

GetOptions(
    "i=s"   => \$fin,
    "o=s"   => \$fout,
    "gt=i" => \$min,
    "lt=i" => \$max,
    "h"     => sub { warn $usage; }
);

die "[ERROR] An input multi-FASTA file name needed!\n\n$usage\n" unless (defined $fin);

die "[ERROR] <gt> and <lt> must provide at least one!\n\n$usage\n" 
    unless ( (defined $min) || (defined $max) );

if ( (defined $min) && (defined $max) ) {
    die "[ERROR] <gt> must less than or equal to <lt>!\n\n$usage\n" if ($min > $max)
}

# Generate output filename if necessary
unless (defined $fout) {
    my ($fname, $dir, $suffix)  = fileparse($fin, qr/\..*/);

    $fout   = $fname . '_out.fasta';
}

# Operate sequences
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

my $o_seqo  = Bio::SeqIO->new(
    -file   => ">$fout",
    -format => 'fasta',
);

my $total_num   = 0;    # Number of total sequences
my $get_num     = 0;    # Number of output sequences

while (my $o_seq = $o_seqi->next_seq) {
    $total_num++;

    my $seq_len = $o_seq->length;

    if ( (defined $max) && (defined $min) ) {
        if ( $seq_len >= $min && $seq_len <= $max ) {
            $o_seqo->write_seq( $o_seq );
            $get_num++;
        }
    }
    elsif ( defined ($min) ) {
        if ( $seq_len >= $min ) {
            $o_seqo->write_seq( $o_seq );
            $get_num++;
        }
    }
    elsif ( defined ($max) ) {
        if ( $seq_len <= $max ) {
            $o_seqo->write_seq( $o_seq );
            $get_num++;
        }
    }
    else {
        warn "[ERROR] Why I'm here?!";
    }
}

say "[DONE]\nTotal:\t$total_num\nOutput:\t$get_num";

