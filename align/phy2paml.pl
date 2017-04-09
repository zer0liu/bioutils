#!/usr/bin/perl

=head1 NAME

phy2paml.pl - Convert PHYLIP non-interleaved alignment file to 'sequence' 
alignment format for PAML.

=head1 SYNOPSIS

phy2paml.pl -i <file> | -n <orf list>

=head1 AUTHOR

zeroliu@gmail.com

=head1 VERSION

0.1 2008-3-20

=cut

use strict;
use warnings;

use Getopt::Long;

my $usage = "
Convert PHYLIP non-interleaved alignment file to 'sequence' alignment format for PAML.
Default file extension of input file is '.phyn' and output file '.phys'.

Usage: phy2paml.pl -i <file> | -n <orf list>
  -i <flie> PHYLIP non-interleaved alignment file.
  -n <orf list> A file contains orfs list. Orf format: 'orf00000'.
  
";

my ($infile, $orflist);

GetOptions(
    "i=s" => \$infile,
    "n=s" => \$orflist,
    "h" => sub{die $usage},
);

die $usage unless ($infile or $orflist);

if (defined $infile) {
    convert($infile);
}
elsif (defined $orflist) {
    open (IN, $orflist) or die "Error in open orf list file: $orflist.\n";
    
    while (my $line = <IN>) {
        chomp($line);
        
        my $phyfile = $line . '.phyn';
        convert($phyfile);
    }
}
else {}

0;

#=====================================================================
# Usage:    convert($infile)
# Return:   None
# Example
# 161 1293
# porB2-131 ------GAAG TTTCTCGCGT AAAAAATGCT GGTACATATA AAGCTCAAGG
#           CGGAAAATCT AAAACTGCAA CCCAAATTGC CGACTTCGGT TCTAAAATCG
#=====================================================================
sub convert {
    my ($infile) = @_;
    
    open (IN, $infile) or die "Error in open file $infile.\n";
    
    my $outfile = $infile;
    $outfile =~ s/\.phyn/\.phys/;
    
    open(OUT, ">$outfile") or die "Error in creat output file $outfile.\n";
    
    while (my $line = <IN>) {
        chomp($line);
        if ($line =~ /\d+\s\d+/) {  # Match the head line of PHYLIP file: '161 1293'
            print OUT $line, "\n";
        }
        elsif ($line =~ /^\S+/) {   # 'porB2-131 ------GAAG TT...'
            my $taxa = substr($line, 0, 10);
            my $seq = substr($line, 10);
=begin DEBUG
            print '-'x50, "\n";
            print $line, "\n";
            print $taxa, $seq, "\n";
            print '='x50, "\n";
=end
=cut
            print OUT $taxa, "\n", $seq, "\n";
        }
        elsif ($line =~ /^\s{10}.*/) {  # '          CGGAAA...'
            $line =~ s/^\s{10}//;   # Remove the leading 10 spaces
            print OUT $line, "\n";
        }
        else {
            print OUT $line, "\n";
        }
    }
    
    close OUT;
    close IN;
}