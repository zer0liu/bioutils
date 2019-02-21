#!/usr/bin/perl

=head1 NAME

    fastq2fasta.pl - Convert FASTQ file to FASTA format.

=SYNOPSIS

=DESCRIPTION

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2019-02-20
    0.0.2   - 2019-02-21    Bug fix

=cut

use 5.010;
use strict;
use warnings;

use Getopt::Long;
use File::Basename;
use Smart::Comments;

my $F_nodesc    = 0;
my ($fq, $fa);

GetOptions(
    'nd'    => \$F_nodesc,
    'i=s'  => \$fq,
    'o=s'  => \$fa,
    'h'     => sub { usage() },
);

unless (defined $fq) {
    warn "[ERROR] Input FASTQ file is required!\n";
    usage();
    exit 1;
}

# Create output filename if necessary
unless (defined $fa) {
    my ($filename, $dir, $suffix)   = fileparse($fq, qr{\..*});

    $fa = $filename . '.fa';
}

open my $fh_fq, "<", $fq
    or die "[ERROR] Open FASTQ file failed!\n$!\n";

open my $fh_fa, ">", $fa
    or die "[ERROR] Create output FASTA file failed!\n$!\n";

while ( <$fh_fq> ) {
    next if /^#/;
    next if /^\s*$/;
    chomp;

    if (/^@(\S+)\s*?(.*?)$/) { # An ID line
        # Output sequence ID and/or description
        if ( $F_nodesc ) {
            say $fh_fa '>', $1;
        }
        else {
            say $fh_fa '>', $1, ' ', $2;
        }

        my $seq = <$fh_fq>; # Read sequence line
        chomp($seq);

        say $fh_fa $seq;
    }
}

close $fh_fa;
close $fh_fq;

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
Convert FASTQ to FASTA.
Usage:
  fastq2fasta.pl [<--nd>] -i <fastq> -o [<fasta>]
Arguments:
  --nd:     Dismiss sequence description, i.e., contents after the first
            space.
            Optional. Default FALSE.
  fastq:    Input FASTQ filename.
  fasta:    Output FASTA filename. Optional.
EOS
}

