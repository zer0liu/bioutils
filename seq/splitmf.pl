#!/usr/bin/perl

=head1 NAME

  splitmf.pl - Split multipl FASTA format sequence file into many smaller
               fasta files.

=head1 SYNOPSIS

  splitmf.pl -i <file> -n <num>

=head1 AUTHOR
  
  zeroliu-at-gmail-dot-com

=head1 HISTORY

  0.1    2009-04-07

=cut

use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;
use Getopt::Long;

my $usage = << "EOS";
splitmf.pl - Split multipl FASTA format sequence file into many smaller
             fasta files.
Usage:
splitmf.pl -i <inf> -n <num>\n
Options:
  -i <infile>: Input file name
  -n <num>:    Sequences number in one file. (Default 500)
EOS

my ($inf);
my $num = 500;

GetOptions(
    "i=s" => \$inf,
    "n=s" => \$num,
    "h" => sub { die $usage },
);

die $usage unless ($inf);

# Parse input filename
my ($infname, $infpath, $inftype) = fileparse($inf, qr{\..*});

# Create output file name
# e.g., 'inf_1-500.fasta'
my $curf = 0;	# Current file number: 0, 1, 2, ...
my $outf = $infname . '_' . ($curf * 500 +1) . '-' . (($curf+1)*500) . $inftype;

my $o_seqo = Bio::SeqIO->new(
    -file => ">$outf",
    -format => 'fasta',
) or die "Fatal: Create output object failed!\n";

# Calculate the number of all sequences by the number of '>'
my $total = `grep '>' $inf | wc -l`;

my $o_seqi = Bio::SeqIO->new(
    -file => $inf,
    -format => 'fasta',
) or die "Fatal: Create Bio::SeqIO object failed!\n$!\n";

# Counter
my $i = 0;

while (my $o_seq = $o_seqi->next_seq) {
    if ($i < $num) {	# Write into output file
	$o_seqo->write_seq($o_seq);
	$i++;
    }
    else {
	$curf++;
	# Create next output filename
	$outf =  $infname . '_' . ($curf * 500 +1) . '-' . (($curf+1)*500) . $inftype;
	# Create new output BioSeqO object
	$o_seqo = Bio::SeqIO->new(
	    -file => ">$outf",
	    -format => 'fasta',
	) or die "Fatal: Cannot create output object!\n$!\n";
	
	# Output current seq
	$o_seqo->write_seq($o_seq);

	
	$i = 1;
    }
}

print "Success: Split $total sequences into $curf files.\n";

