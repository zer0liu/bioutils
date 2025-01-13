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
    0.1.0   2025-01-12  New feature: deal with keyword file or 
                        keyword string.
    0.1.1   2025-01-13  Recover feature: look up seqeunce description.

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
  get_seq_by_kw.pl -i <fseq> -f <fkw> -k <kw> [-a]
Arguments:
  -i <fseq> Input FASTA format sequence file.
  -f <fkw>  A keywords file. One keywords in each line.
  -k <kw>   A keyword string. Quoted if necessary.
  -a        Optional. In default, this script look up sequence ID only.
            With this option, it will ALL sequence name, including
            both sequence ID and description.
Note:
- Output to STDOUT.
Attention:
- Because of the highly complex, please use double back slash ('\\')
  to escape characters if necessary. e.g.,
  '[' => '\\[', ']' => '\\]', '-' => '\\-'. '.' => '\\.', etc.
EOS

my ($fseq, $fkw, $kw, $F_a);

GetOptions(
  "i=s" => \$fseq,
  "f=s" => \$fkw,
  "k=s" => \$kw,
  "a"   => \$F_a,
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
    my $id      = $o_seq->id;
    my $desc    = $o_seq->desc;

    for my $kw ( @keywords ) {
        # $o_seqo->write_seq( $o_seq ) if ( $id =~ /$kw/ );

        unless ($F_a) {
            for my $kw (@keywords) {
                if ($id =~ /$kw/) {
                    $o_seqo->write_seq($o_seq);
                }
            }
        }
        else {
            for my $kw (@keywords) {
                if ($id =~ /$kw/) {
                    $o_seqo->write_seq($o_seq);
                    next;
                }
                elsif ($desc =~ /$kw/) {
                    $o_seqo->write_seq($o_seq);
                }
                else {
                    next;
                }
            }
        }
    }
}

exit 0;

# DONE

