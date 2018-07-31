#!/usr/bin/perl

=head1 NAME

    subset_codon.pl - Extract desired codon positions from given sequence.

=SYNOPSIS

=DESCRIPTION

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2018-07-31

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;
use Getopt::Long;
#use Smart::Comments;
use Switch;

my ($fin, $fout, $codon_pos_str);

GetOptions(
    "i=s"   => \$fin,
    "o=s"   => \$fout,
    "c=s"   => \$codon_pos_str,
    "h"     => sub { usage(); exit 1 }
);

unless (defined $fin and defined $codon_pos_str) {
    usage();
    exit 1;
}

unless (defined $fout) {
    my ($basename, ,)  = fileparse($fin, qr/\..*$/);

    $fout   = $basename . '_codon_' . $codon_pos_str . '.fa';
}

my $codon_regex = genr_codon_regex( $codon_pos_str );

unless (defined $codon_regex) {
    die "[ERROR] Wrong codon postion: '", $codon_pos_str . "'\n";
}

## $codon_regex

my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

open my $fh_out, '>', $fout
    or die "[ERROR] Create output file '$fout' failed!\n$!\n";

while (my $o_seq = $o_seqi->next_seq) {
    my $seq_id  = $o_seq->id;
    my $seq_str = $o_seq->seq;

    if ($o_seq->alphabet eq 'protein') {
        warn "[WARN] '$seq_id' is a protein sequence!\n";
    }

    my $seq_len = length($seq_str);

    if ($seq_len % 3) {
        warn "[WARN] Sequence '$seq_id' with length '$seq_len' is NOT multiples of 3!\n";
        next;
    }

    my @sub_codons  = ($seq_str =~ /$codon_regex/g);

    my $sub_seq_str = join '', @sub_codons;

    say $fh_out '>', $seq_id, ' codon:' . $codon_pos_str;
    say $fh_out $sub_seq_str;
}

close $fh_out;

exit 0;

#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Display usage information
  Returns:  None
  Args:     None

=cut

sub usage {
    say << 'EOS';
Extract subset of desired codon positions from given fasta file.
Usage:
  subset_codon -i <fin> [-o <fout>] -c <codon position>
Args:
  -i <fin>              A multi-FASTA format sequence file.
  -o <$fout>            Output FASTA file. Optional.
  -c <codon position>   One or combination of number 1, 2, 3.
                        e.g., 1, 2, 3, 12 or 23.
EOS
}

=pod

  Name:     genr_codon_regex
  Usage:    genr_codon_regex($codon_pos)
  Function: Create a codon regex string
  Args:     A string composed with 1, 2, or 3
  Returns:  A string
            undef for any errors

=cut

sub genr_codon_regex {
    my ($codon_str) = @_;
    
    # Whether contains other characters except 1, 2 and 3
    return unless ($codon_str =~ /^[123]+$/g);

    my $regex_str;

    switch ($codon_str) {
        case '1'    { $regex_str = '(.).{2}' }
        case '2'    { $regex_str = '.(.).' }
        case '3'    { $regex_str = '.{2}(.)' }    
        case '12'   { $regex_str = '(.{2}).' }
        case '23'   { $regex_str = '.(.{2})' }
    }

    return $regex_str;
}
