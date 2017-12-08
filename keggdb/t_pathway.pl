#!/usr/bin/perl

use strict;
use warnings;

use Bio::KEGG;
use Bio::KEGGI;

use Data::Dumper;
use Smart::Comments;

my $inf = "samples/eco_pathway";

my $o_keggi = Bio::KEGGI->new(
    -file => $inf,
    -type => 'pathway',
);

# while (my $o_kegg = $o_keggi->next_rec) {
    my $o_kegg = $o_keggi->next_rec;
    
    print '-'x50, "\n", Dumper($o_kegg), "\n", '-'x50, "\n";
    
    print "ID:\t", $o_kegg->id(), "\n";
    print "Name:\t", $o_kegg->name, "\n";
    print "Description:\t", $o_kegg->desc, "\n";
    print "Class:\t", Dumper( $o_kegg->class ), "\n";
    print "Map:\t", Dumper($o_kegg->map ), "\n";
    print "Module:\t", Dumper($o_kegg->module), "\n";
    print "Disease:\t", Dumper($o_kegg->disease), "\n";
    print "Organism:\t", $o_kegg->organism, "\n";
    print "Org:\t", $o_kegg->org, "\n";
    print "DBLink:\t", Dumper( $o_kegg->dblink ), "\n";
    print "Gene:\t", Dumper( $o_kegg->gene ), "\n";
    print "Orthology", Dumper( $o_kegg->orthology ), "\n";
    print "Compound:\t", Dumper( $o_kegg->compound ), "\n";
    print "Rel_pathway:\t", Dumper( $o_kegg->rel_pathway), "\n";
    print "KO pathway:\t", $o_kegg->ko_pathway, "\n";
# }

exit;
