#!/usr/bin/perl

=head1 NAME

    sort_seq_by_len.pl - Sort sequences in a multi-FASTA format file
                         by length. Default descend.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2016-06-20

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;

my $usage   = << "EOS";
Sort sequences in a multi-Fasta format file by length.
Usage:
  sort_seq_by_len.pl <file> [<asc|desc>]
Note:
  Output to STDOUT.
EOS

my $fin = shift 
    or die $usage;

my $opt = shift // 'desc';

my %seqs;

# Read sequences into a hash
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

my $sid = 0;

while ( my $o_seq = $o_seqi->next_seq ) {
    #$seqs{ $sid }->{'seq_id'}   = $o_seq->id;
    #$seqs{ $sid }->{'seq_desc'} = $o_seq->desc;
    #$seqs{ $sid }->{'seq_str'}  = $o_seq->seq;
    $seqs{ $sid }->{'seq_len'}  = $o_seq->length;
    $seqs{ $sid }->{'seq_obj'}  = $o_seq;

    $sid++;
}

# Sort 
my @sorted_sids;

if ( $opt eq 'asc' ) {
    @sorted_sids    
        = sort { $seqs{$a}->{'seq_len'} <=> $seqs{$b}->{'seq_len'} } 
            keys %seqs;
}
elsif ( $opt eq 'desc' ) {
    @sorted_sids    
        = sort { $seqs{$b}->{'seq_len'} <=> $seqs{$a}->{'seq_len'} } 
            keys %seqs;
}
else {
    warn "[ERROR] Unknow sort option '$opt'!\n";
}

# Output
my $o_seqo  = Bio::SeqIO->new(
    -fh     => \*STDOUT,
    -format => 'fasta',
);

for my $id ( @sorted_sids ) {
    $o_seqo->write_seq( $seqs{$id}->{'seq_obj'} );
}

exit 0;

