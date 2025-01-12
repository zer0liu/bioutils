#!/usr/bin/perl

=head1 NAME

    get_seq_by_kw.pl - Get sequences from a Multi-FASTA file according to
                       given keywords file.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-02-04
    0.1.0   2025-01-12  Switch to options

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use Getopt::Long;
use Smart::Comments;

my $usage = << "EOS";
Get sequences from a multi-FASTA file accroding to a keywords file, or 
a keywork, then output to STDOUT.
Usage:
  get_seq_by_kw.pl -i <fseq> -f <fkw> -k <kw>
Arguments:
  -i <fseq> Input FASTA format sequence file.
  -f <fkw>  A keywords file. One keywords in each line.
  -k <kw>   A keyword string. Quoted if necessary.
EOS

my ($fseq, $fkw, $kw);

GetOptions(
  "i=s" => \$fseq,
  "f=s" => \$fkw,
  "k=s" => \$kw,
  "h"   => sub { die $usage }
);

## $fseq
## $fkw
## $kw

unless ($fseq) { die "[ERROR] Need an input sequence file!\n\n$usage\n" }

unless ($fkw || $kw) { die "[ERROR] Need one of keyword file or keyword string!\n\n$usage\n" }

if ($fkw && $kw) { die "[ERROR] Only need one of keyword file or keyword string!\n\n$usage\n" }

my @keywords;

# Parse keywords file

if ($fkw) {
	open(my $fh_kw, "<", $fkw)
	    or die "[ERROR] Open keyword file '$fkw' failed!\n$!\n\n";
	
	while (<$fh_kw>) {
	    next if /^#/;
	    next if /^\s*$/;
	    chomp;
	    s/\r$//; # For Windows format text file, remove '\r'
	
	    push @keywords, $_;
	}
	
	close $fh_kw;
}
elsif ($kw) {
  @keywords = ($kw);
}

# Check sequence ids one by one

# Input SeqIO object
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fseq,
    -format => 'fasta',
);

# Output SeqIO object
my $o_seqo  = Bio::SeqIO->new(
    -fh     => \*STDOUT,
    -format => 'fasta',
);

while (my $o_seq = $o_seqi->next_seq) {
    my $id  = $o_seq->id;

    for my $kw ( @keywords ) {
        $o_seqo->write_seq( $o_seq ) if ( $id =~ /$kw/ );
    }
}

exit 0;

# DONE

