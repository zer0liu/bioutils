#!/usr/bin/perl

=head1 NAME
  
  alnscore.pl - Score an alignment.

=head1 SYNOPSIS

=head1 DESCRIPTION

  Try to score a nucleotide or amino aicd alignment.

=head1 AUTHORS

  zeroliu-at-gmail-dot-com

=head1 HISTORY

  0.1    2009-02-71

=cut

use strict;
use warnings;

use Bio::AlignIO;
use Getopt::Long;

my $usage = << "EOS";
Score a nucleotide or amino aicd alienment.\n
Usage:
  alnscore.pl -i <inf> [-t <type>] [-o <outf>]
Options:
  -i <inf>:  Input alignment file.
  -t <type>: Alignment format: 
             bl2seq, clustalw, emboss, fasta, maf, mase, mega, meme, msf, 
	     nexus, pfam, phylip, prodom, psi, selex and stockholm.
	     Optional. Default clustalw.
  -o <outf>: Output file.
             Optional. Default output to STDOUT.
EOS

my ($inf, $outf, $format);

$outf = *STDOUT;
$format = 'clustalw';

GetOptions(
    "i=s" => \$inf,
    "t=s" => \$format,
    #"o=s" => \$outf,
    "h" => sub { die $usage},
);

die $usage unless ($inf);

my $o_alni = Bio::AlignIO->new(
    -file => $inf,
    -format => $format,
) or die "Error: Create Bio::AlignIO object failed!\n";

my $o_aln = $o_alni->next_aln;

print "Alignment length:\t", $o_aln->length, "\n";

=begin
my $o_slice = o_aln->slice(1,2);

for my $seq ( $o_slice->each_seq ) {
    print $seq, "\n";
}
=end
=cut

my $o_sel = $o_aln->slice(100,103);

print "Alignment slice 100..103:\n";

for my $o_seq ( $o_sel->each_seq ) {
    print $o_seq->seq, "\n";
}

print "ID:\t", $o_aln->id, "\n";

print "Identity:\t", $o_aln->percentage_identity, "\n";
print "Overall identity:\t", $o_aln->overall_percentage_identity, "\n";
print "Average identity:\t", $o_aln->average_percentage_identity, "\n";

exit 0;

# End of script
