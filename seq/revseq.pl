#!/usr/bin/perl

=head1 NAME

    revseq.pl - Reverse and/or complement a nucleotide sequence.

=SYNOPSIS

=DESCRIPTION

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2019-03-08

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;
use Getopt::Long;

use Smart::Comments;

my ($F_rev, $F_com, $fin, $fout);

GetOptions(
    "r"     => \$F_rev,
    "c"     => \$F_com,
    "i=s"   => \$fin,
    "o=s"   => \$fout,
    "h"     => sub { usage() },
);

unless ($fin) {
    warn "[ERROR] An input FASTA file is required!\n";
    usage();
    exit 1;
}

# Deal with FLAGs
# If both $F_rev and $F_com were NOT set, assign them TRUE (1) for default
# behavor of the script.
unless ( $F_rev || $F_com) {
    $F_rev  = 1;
    $F_com  = 1;
}

## $F_rev
## $F_com

# Generate output filename
unless ( $fout ) {
    my ($basename, $dir, $suffix)   = fileparse($fin, qr/\..*$/);
    
    if ( $F_rev && $F_com ) {   # Reverse and complement
        $fout   = $basename . '_rc.fasta';
    }
    elsif ( $F_rev ) {           # Reverse only
        $fout   = $basename . '_r.fasta';
    }
    elsif ( $F_com ) {          # Complement only
        $fout   = $basename . '_c.fasta'
    }
    else {
        # Do nothing
    }
}

# Operate sequences
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

open my $fh_out, ">", $fout or
    die "[ERROR] Create output file '$fout' failed!\n$!\n";
    
while (my $o_seq = $o_seqi->next_seq) {
    my $seq_id      = $o_seq->id;
    my $seq_desc    = $o_seq->desc;
    my $seq_str     = $o_seq->seq;

    if ($o_seq->alphabet eq 'protein') {
        warn "[WARN] Can not do reverse/complement for a protein sequence: '$seq_id'!\n";
        
        next;
    }
    elsif ($o_seq->alphabet eq 'rna') {
        warn "[WARN] Can not do reverse/complement for a RNA sequence: '$seq_id'!\n";
        
        next;
    }
    else {
        # Do nothing
    }
    
    if ($F_rev && $F_com) { # Reverse and complement
        $seq_str    = reverse $seq_str;
        $seq_str    =~ tr/AGCTagct/TCGAtcga/;
        
        say $fh_out '>', $seq_id, ' ', $seq_desc, ' rc';
        say $fh_out $seq_str;
    }
    elsif ($F_rev) {        # Reverse only
        $seq_str    = reverse $seq_str;
        
        say $fh_out '>'. $seq_id, ' ', $seq_desc, ' r';
        say $fh_out $seq_str;
    }
    elsif ($F_com) {        # Complement only
        $seq_str    =~ tr/AGCTagct/TCGAtcga/;
        
        say $fh_out '>', $seq_id, ' ', $seq_desc, ' c';
        say $fh_out $seq_str;
    }
    else {
        # Do nothing
    }
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
  Args:     None
  Returns:  None

=cut

sub usage {
    say << 'EOS';
Reverse and/or complement a nucleotide sequence.
Usage:
  revseq.pl [-r] [-c] -i <fin> [-o <fout>]
Options:
  -r    Create reverse sequence only. Optional.
  -c    Create complement sequence only. Optional.
  -i <fin>  Input multi-FASTA sequence file.
  -o <fout> Output multi-FASTA sequence file. Optional.
Note:
  The default operation, i.e., without any options, is to create reverse-
  complement sequence. Just similar to option '-r -c'.
EOS
}

=pod

  Name:     
  Usage:    
  Function: 
  Args:     
  Returns:  

=cut

