#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Bio::KEGGI;

my $inf = "samples/ko.sample";

my $o_keggi = Bio::KEGGI->new(
    -file => $inf,
    -type => 'ko',
);

my $o_kegg = $o_keggi->next_rec;

# print '-'x50, "\n", Dumper($o_kegg), "\n", '-'x50, "\n";

print '='x60, "\n";

print "ID:\t", $o_kegg->id, "\n";
print "Name:\t", $o_kegg->name, "\n";
print "Description:\t", $o_kegg->desc, "\n";
print "EC:\t", Dumper( $o_kegg->ec ), "\n";
print "Pathway", Dumper( $o_kegg->pathway ), "\n";
print "Module:\t", Dumper( $o_kegg->module ), "\n";
print "Class:\t", Dumper( $o_kegg->class ), "\n";
print "DBLINK:\t", Dumper( $o_kegg->dblink ), "\n";
print "Gene:\t", Dumper( $o_kegg->gene ), "\n";
print "PMID:\t", Dumper( $o_kegg->pmid ), "\n";

exit;
