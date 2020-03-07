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
    0.1.0   2020-03-07  Do no need bioperl.

=cut

use 5.010;
use strict;
use warnings;

#use Smart::Comments;

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

# Read FASTA sequences from file
my ($seq_id, $seq_desc, $seq_str);

open my $fh_in, "<", $fin or
    die "[ERROR] Open file '$fin' failed!\n$!\n";

while (<$fh_in>) {
    next if /^#/;
    next if /^\s*$/;
    chomp;
    s/\r$//;

    if (/^>(.+?)\s+(.+?)$/) {
        $seq_id     = $1;
        $seq_desc   = $2;

        $seqs{$seq_id}->{'desc'}    = $seq_desc;
        $seqs{$seq_id}->{'seq'}     = '';
    }
    else {
        $seqs{$seq_id}->{'seq'}     .= $_;
    }
}

close $fh_in;

# Calculate sequence length
for my $seqid (keys %seqs) {
    $seqs{$seqid}->{'len'} = length $seqs{$seqid}->{'seq'};
}

# Sort 
my @sorted_sids;

if ( $opt eq 'asc' ) {
    @sorted_sids    
        = sort { $seqs{$a}->{'len'} <=> $seqs{$b}->{'len'} } 
            keys %seqs;
}
elsif ( $opt eq 'desc' ) {
    @sorted_sids    
        = sort { $seqs{$b}->{'len'} <=> $seqs{$a}->{'len'} } 
            keys %seqs;
}
else {
    warn "[ERROR] Unknow sort option '$opt'!\n";
}

for my $seqid ( @sorted_sids ) {
    say ">", $seqid. " ", $seqs{$seqid}->{'desc'}, " ", $seqs{$seqid}->{'len'};
    say $seqs{$seqid}->{'seq'};
    say "";
}

exit 0;

