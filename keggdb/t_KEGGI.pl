#!/usr/bin/perl

=head1 NAME

    t_KEGGI.pl - Test module KEGGI

=cut

use strict;
use warnings;

use Data::Dumper;
#use Smart::Comments;

use Bio::KEGG;
use Bio::KEGGI;

# my $inf = "genome";
# my $inf = "ko.sample";
my $inf = "/data/db/kegg/pathway/pathway";

my $o_keggi = Bio::KEGGI->new(
    -file => $inf,
#    -type => 'genome',
#    -type => 'ko',
    -type => 'pathway',
);

# DEBUG
# Object KEGGI: $o_keggi

while (my $o_kegg = $o_keggi->next_rec) {
    #print '='x60, "\n", Dumper($o_kegg), "\n", '='x60, "\n";
    
}

exit;
