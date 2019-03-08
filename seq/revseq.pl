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

