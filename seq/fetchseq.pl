#!/usr/bin/perl

=head1 NAME

    fetchseq.pl - Fetch sequences according to given sequence ids file,
                  and output in the same order.

=SYNOPSIS

=DESCRIPTION

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2018-12-11

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use Smart::Comments;

my $fseq    = shift or die usage();
my $fid     = shift or die usage();

# Parse sequence ids
my $ra_ids  = parse_id( $fid );

# Parse sequence file
my $rh_seqs = parse_seq($fseq);

for my $id ( @{$ra_ids} ) {
    if ( defined $rh_seqs->{$id} ) {
        say '>', $id;
        say $rh_seqs->{$id};
    }
    else {
        warn "[ERROR] Sequence id '$id' NOT found!\n";
    }
}

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
  Args:     None
  Returns:  None

=cut

sub usage {
    say << 'EOS';
Fetch sequences according to given sequence ids file, and output in the
same order.
Usage:
  fetchseq.pl <fasta file> <seqid file>
Note:
  - Output in the order of ids in <seqid file>.
  - Lines begins with '#' are comments,
  - Any characters after spaces in the <seqid file> will be discarded.
EOS
}

=pod

  Name:     parse_id
  Usage:    parse_id( $fid )
  Function: Parse input id file
  Args:     A string
  Returns:  Reference of an array

=cut

sub parse_id {
    my ($fid) = @_;

    my @ids;

    open( my $fh_id, "<", $fid) or 
        die "[ERROR] Open sequence id file '$fid' failed!\n$!\n";

    while (<$fh_id>) {
        next if /^\s*$/;
        next if /^#/;
        chomp;
        s/\r$//;

        my @items   = split /\s+/;

        push @ids, $items[0];
    }

    close $fh_id;

    ## @ids

    return \@ids;
}

=pod

  Name:     parse_seq
  Usage:    parse_seq( $fseq )
  Function: Parse input sequence file
  Args:     A string
  Returns:  Reference of a hash

=cut

sub parse_seq {
    my ($seq)   = @_;
    my %seqs;

    my $o_seqi  = Bio::SeqIO->new(
        -file   => $fseq,
        -format => 'fasta',
    );

    while (my $o_seq = $o_seqi->next_seq) {
        my $id  = $o_seq->id;

        $seqs{ $id } = $o_seq->seq;
    }

    ## %seqs

    return \%seqs;
}

