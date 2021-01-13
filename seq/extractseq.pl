#!/usr/bin/perl
=head1 NAME

    extractseq.pl - Extract sequences from a Multi-Fasta format file.
                    Subtract sequences also supported.

=head1 DESCRIPTION

    This script supports to extract (sub)sequences according to a "seqid 
    file". 
    
=head2 Seqid file format

    <seqid> <start> <end>

    Where <start> and <end> are optional. If both were not available, 
    simple get the whole sequence.

=head1 AUTHOT

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2014-04-07
    0.0.2   2014-04-07  Minor bug fix
    0.0.3   2014-11-07  Fix bug for "\r" at the line end.
    0.0.4   2015-01-08  Improve description.
    0.0.5   2017-03-03  Fix bug for output NOT found IDs.
    0.1.0   2021-01-13  Add new filed "Description".

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use Smart::Comments;

my $usage = << "EOS";
Extract and substract sequences from a multi-fasta format file and output
to the STDOUT.
Usage:
  extractseq.pl <fasta file> <seqid file>
Note:
  The format of <seqid file> is:
  "<Seqid>    <Start>    <End>  <Description>"
  - Fields have to be separated by a "\t".
  - Filed 'Description' is optional.
EOS

# Get sequence file
my $fseq = shift or die $usage;

# Get sequence ID file
my $fid = shift or die $usage;

# Parse seqid file '$fid'
my $rh_ids = parse_id( $fid );

# Hash for seq IDs: $rh_ids;

# Traverse sequence file
my $o_seqi = Bio::SeqIO->new(
    -file   => $fseq,
    -format => 'fasta',
);

my $o_seqo = Bio::SeqIO->new(
    -fh     => \*STDOUT,
    -format => 'fasta',
);

while (my $o_seq = $o_seqi->next_seq) {
    my $id  = $o_seq->id;
    # ID in sequence file: $id

    my $o_outseq;   # Output seq obj

    # Check whether '$id' exists in seqid file
    # 5.10.1 new featuer
    if ( defined( $rh_ids->{$id} ) ) {
        # Seq ID: $id

        my $start   = $rh_ids->{$id}->{"start"};
        my $end     = $rh_ids->{$id}->{"end"};

        if ( $start && $end ) { # Defined start and end, get a subseq
            if ( $start <= $end ) { # normal direction
                # $o_outseq = $o_seq->subseq($start, $end);

                $o_outseq = $o_seq->trunc($start, $end);
            }
            else {  # $end < $start, get reverse and complement sequence
                # subseq method returns a string
                # $subseq = $o_seq->subseq($end, $start);   

                $o_outseq = $o_seq->trunc($end, $start);
                $o_outseq = $o_outseq->revcom();
            }
        }
        else {  # Get the complete sequence
            $o_outseq = $o_seq;
        }
        
        if ($rh_ids->{$id}->{'desc'}) {
            $o_outseq->desc( $rh_ids->{$id}->{'desc'} );
        }

        # Output sequence to STDOUT
        $o_seqo->write_seq( $o_outseq );

        $rh_ids->{$id}->{'got'} = 1;
    }
    else {
        # warn "Get it: $id" if ($id eq 'comp78761_c0_seq2');
    }
}

# Check NOT found ids
for my $id (keys %{ $rh_ids }) {
    ## $id
    unless ( exists $rh_ids->{$id}->{'got'} ) {
        warn "[NOT FOUND] $id\n";
    }
}

exit 0;

#=====================================================================
#
#                             Subroutines
#
#=====================================================================

sub parse_id {
    my ( $fid ) = @_;

    my %ids;

    open(my $fh_id, "<", $fid) or die
        "Error: Open sequence id file '$fid' failed!\$!\n";

    while (<$fh_id>) {
        next if /^\s*$/;
        next if /^#/;
        chomp;
        s/\r$//;    # Remove possible "\r"

        my @items = split /\t/;

        my $seqid   = $items[0];
        my $start   = $items[1] || 0;
        my $end     = $items[2] || 0;
        my $desc    = $items[3] // '';

        $ids{ $seqid }->{ "start" } = $start;
        $ids{ $seqid }->{ "end" }   = $end;
        $ids{ $seqid }->{ "desc" }  = $desc;
    }
    close $fh_id;

    return \%ids;
}
