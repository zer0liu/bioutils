#!/usr/bin/perl

=head1 NAME
  
  aln2phys.pl - Convert alignment files to PHYLIP sequential format.

=head1 AUTHORS

  zeroliu-at-gmail-dot-com

=head1 HISTORY

  0.0.1 2008-12-15
  0.0.2 2015-10-16  Default input file format: FASTA

=cut

use strict;
use warnings;

use lib "/home/zeroliu/lib/perl";
use Bio::AlignIO;
use Getopt::Long;
use General;

my $usage = << "EOS";
Convert alignment files to PHYLIP sequential format.\n
Usage: aln2phys.pl -i <infile> -f <format> -o <outfile>\n
Parameters:
  -i <infile>:  Input file;
  -f <format>:  Input format;
                Optional. Deafult FASTA
  -o <outfile>: Output file\n
Supported alignment formats:\n
   bl2seq      Bl2seq Blast output
   clustalw    clustalw (.aln) format
   emboss      EMBOSS water and needle format
   fasta       FASTA format
   maf         Multiple Alignment Format
   mega        MEGA format
   nexus       Swofford et al NEXUS format
   pfam        Pfam sequence alignment format
   phylip      Felsenstein's PHYLIP format
   psi         PSI-BLAST format
   selex       selex (hmmer) format
EOS

my ($inf, $outf);
my $infmt = 'fasta';

GetOptions(
    "i=s" => \$inf,
    "f=s" => \$infmt,
    "o=s" => \$outf,
);

die $usage unless ($inf);

$outf = $inf . '.phys' unless (defined $outf);

my $o_alni = Bio::AlignIO->new(
    -file => $inf,
    -format => $infmt,
) or die "Fatal: Create AlignIO object failed!\n$!\n";

open (OUT, ">$outf") or die "Fatal: Create output file failed!\n$!\n";

my %seqs;

# Read all sequences in alignment into a hash '%seqs'
while (my $o_aln = $o_alni->next_aln)  {
    for my $o_seq ($o_aln->each_seq) {
		my $seqid = $o_seq->id;
		my $seq = $o_seq->seq;

		$seqs{$seqid} = $seq;
    }
}

    my @seqids = keys( %seqs );
    my $num = @seqids;
    my $length = length( $seqs{"$seqids[0]"} );
	
#	print "Alignment length:\t$length";

# Output 
print OUT "$num $length\n";

for my $seqid (@seqids) {
    if ( length($seqid) < 10) {
		print OUT rFillStr($seqid, 10, ' '), $seqs{$seqid}, "\n";
    }
    else {  # Chop string to 9
		my $curid = substr($seqid, 0, 9);
		print OUT rFillStr($curid, 10, ' '), $seqs{$seqid}, "\n";
    }

	my $curlen = length( $seqs{$seqid} );
	
    print "Error: NO identical sequence length $curlen on $seqid.\n" 
		if ( $curlen != $length );
}

close(OUT);

exit 0;
