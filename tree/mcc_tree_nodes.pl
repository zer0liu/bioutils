#! /usr/bin/env perl

=head1 NAME

    mcc_tree_nodes.pl - Read and parse MCC tree node information.

=SYNOPSIS

=DESCRIPTION

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2018-06-22

=cut

use 5.010;
use strict;
use warnings;

use Bio::TreeIO;

my $ftree   = shift or die usage();
my $fmt     = shift // 'nexus';

my $o_treei = Bio::TreeIO->new(
    -file   => $ftree,
    -format => $fmt,
);

while (my $o_tree = $o_treei->next_tree) {
    
}


#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Display usage information
  Returns:  None
  Args:     None

=cut

sub usage {
    say << 'EOS';
Read and parse MCC tree node information.
Usage:
  mcc_tree_nodes.pl <ftree> <fromat>
Args:
  <ftree>   Input tree(s) file.
  <format>  Tree format. One of:
                newick
                nexus
                nexml
                phyloxml
            Default 'nexus'.
EOS
}
