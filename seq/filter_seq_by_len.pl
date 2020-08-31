#!/usr/bin/perl

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
  filter_seq_by_len.pl -i <fseq> -o <fseq> [--min <len> | --max <len>]
Note:
  Length: --------------------------------------------------------------->
                             ^                        ^
                            min                      max
  * <Min> and <max> must provide at least one.
  * If provided both, output sequences of which length between <min> and <max>.
  * If provided <min> only, output all sequences longer than <min>.
  * If provided <max> only, output all sequences shorter than <max>.
EOS

my ($fin, $fout, $min, $max);

GetOptions(
    "i=s"   => \$fin,
    "o=s"   => \$fout,
    "min=i" => \$min,
    "max=i" => \$max,
    "h"     => sub { warn $usage; }
);

die "[ERROR] An input multi-FASTA file name needed!\n\n$usage\n" unless (defined $fin);

die "[ERROR] <min> and <max> must provide at least one!\n\n$usage\n" 
    unless ( (defined $min) || (defined $max) );

if ( (defined $min) && (defined $max) ) {
    die "[ERROR] <min> must less than or equal to <max>!\n\n$usage\n" if ($min > $max)
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
        $o_seqo->write_seq( $o_seq ) if ( $seq_len >= $min && $seq_len <= $max );
        $get_num++;
    }
    elsif ( defined ($min) ) {
        $o_seqo->write_seq( $o_seq ) if ( $seq_len >= $min );
        $get_num++;
    }
    elsif ( defined ($max) ) {
        $o_seqo->write_seq( $o_seq ) if ( $seq_len <= $max );
        $get_num++;
    }
    else {
        warn "[ERROR] Why I'm here?!";
    }
}

say "[DONE]\nTotal:\t$total_num\nOutput:\t$get_num";

