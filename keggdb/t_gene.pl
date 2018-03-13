#!/usr/bin/perl

=head1 NAME

    t_gene.pl - Test Bio::KEGGI::gene and Bio::KEGG::gene modules.

=head1 DESCRIPTION

=head1 AUTHORS

    zeroliu-at-gmail-dot-com

=cut

use strict;
use warnings;

use Bio::KEGGI;
use Data::Dumper;
# use Term::ANSIColor;

my $usage = << "EOS";
Test Bio::KEGGI::gene and BIO::KEGG::gene modules.
Usage: t_gene.pl <infile>
EOS

my $inf = shift;

die $usage unless $inf;

my $o_keggi = Bio::KEGGI->new(
    -file => $inf,
    -type => 'gene',
);

while (my $o_kegg = $o_keggi->next_rec() ) {
     print '='x50, "\n";
     print Dumper($o_kegg);
     print '='x50, "\n";
}

exit 0;