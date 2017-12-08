#!/usr/bin/perl

=head1 NAME

    transeq.pl - Translate nucleic acid sequences into protein sequences.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-01-08

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;
use Getopt::Long;

use Smart::Comments;

my $usage = << "EOS";
Translate nucleic acid sequences into protein sequences.
Usage:
  transeq.pl -i <in> [-o <out>] [-frame 1] [-codon 1]
Options:
  -i <in>   Input nucleic acid sequence file.
  -o <out>  Output protein sequences file. Optional. 
            Default suffix '.faa'.
  -frame    The frame of translation. Optional. 
            Values -3, -2, -1, 1, 2, 3. Default 1.
  -codon    Codon table to be used. Optional.
            Values 1-16. Default 1.
NOTE:
  1. Character for terminator: '*', unknown amino acid: 'X';
  2. Only FASTA format file supported.
EOS

my ($fin, $fout);
my $frame       = 1;    # Frame
my $codon       = 1;    # Codon table

GetOptions(
    'i=s'           => \$fin,
    'o=s'           => \$fout,
    'frame=i'       => \$frame,
    'codon=i'       => \$codon,
    'h'             => sub { say $usage, "\n"; }
);

die $usage unless ( defined $fin );

# Generate output filename
unless ( defined $fout ) {
    my ($basename, $dir, $suffix) = fileparse( $fin, qr{\..*} );

    $fout   = $basename . '.faa';
}

# Convert BLAST style frame into GFF style, which was used by BioPerl.
my $F_revcom    = 0;    # Default NO reverse complement.

# GFF/BioPerl frame starts at 0
if ( $frame > 0 ) { # Positive strand
    $frame--;
}
else {
    $frame  = abs( $frame ) - 1;
    $F_revcom   = 1;
}

# Process sequences
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

my $o_seqo  = Bio::SeqIO->new(
    -file   => ">$fout",
    -format => 'fasta',
);

while ( my $o_seq = $o_seqi->next_seq ) {
    my $o_prn;  # Translated protein sequence object

    if ( $o_seq->alphabet eq 'protein' ) {
        warn "[ERROR] Sequence '$o_seq->id' is a protein sequence!\n";
        next;
    }

    unless ( $F_revcom ) {
        $o_prn  = $o_seq->translate(
            -frame          => $frame,
            -codontable_id  => $codon,
        );
    }
    else {
        my $o_rc    = $o_seq->revcom(); # Reverse complement seq object
        $o_prn      = $o_rc->translate(
            -frame          => $frame,
            -codontable_id  => $codon,
        );
    }

    # Remove terminator '*' at the sequence end
    my $prn_seq = $o_prn->seq();
    $prn_seq    =~ s/\*$//;
    $o_prn->seq( $prn_seq );

    $o_seqo->write_seq( $o_prn );
}

say "[OK] All nucleic sequences translated.";
