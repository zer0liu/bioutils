#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Bio::TreeIO;

my $usage = << "EOS";
Convert (multiple) NEXUS tree file to (multiple) newick tree file.
Usage:
  nex2newick.pl <in> [<out>]
Note:
  Default output file name: "trees.nwk".
EOS

my $fin = shift or die "[ERROR] Need input NEXUS tree file.!\n";

my $fout    = shift // "trees.nwk";

my $o_treei = Bio::TreeIO->new(
    -file   => $fin,
    -format => 'nexus',
);

#my $o_treeo = Bio::TreeIO->new(
#    -file   => ">$fout",
#    -format => 'newick',
#);

open my $fh_out, ">", $fout
    or die "[ERROR] Create output file '$fout' failed!\n$!\n";

my $i   = 0;

while (my $o_tree = $o_treei->next_tree) {
    #$o_treeo->write_tree($o_tree);
    my $nwk_str = $o_tree->as_text('newick');
    
    say $fh_out $nwk_str;
    say $fh_out ""; # Append a blank line

    $i++;
}

close $fh_out;

say "[OK] Total $i trees converted!";

