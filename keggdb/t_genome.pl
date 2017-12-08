#!/usr/bin/perl

use strict;
use warnings;

use Bio::KEGGI;
use Data::Dumper;

# my $inf = "samples/genome";
my $inf = shift;

my $o_keggi = Bio::KEGGI->new(
    -file => $inf,
    -type => 'genome',
);

my $o_kegg = $o_keggi->next_rec();

print '-'x50, "\n", Dumper($o_kegg), "\n", '-'x50, "\n";
print "ID:\t", $o_kegg->id, "\n";
print "Name:\t", $o_kegg->name, "\n";
print "Description:\t", $o_kegg->desc, "\n";
print "Annotation:\t", $o_kegg->anno, "\n";
print "taxid:\t", $o_kegg->taxid, "\n";
print "Taxonomy:\t", $o_kegg->taxonomy, "\n";
print "Data source:\t", $o_kegg->data_src, "\n";
print "Original DB:\t", $o_kegg->origin_db, "\n";
print "Comment:\t", $o_kegg->comment, "\n";
print "Diseases:\t", Dumper( $o_kegg->disease ), "\n";
print "Component:\t", Dumper( $o_kegg->component ), "\n";
print "Statistics:\t", Dumper( $o_kegg->statistics ), "\n";


exit;

