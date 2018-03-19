#! /usr/bin/env perl

=head1 NAME

    upd_fludb.pl - Revise the influenza virus sequence database parsed
                   and loaded by 'load_gbvirus.pl'

=SYNOPSIS

=DESCRIPTION

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2018-03-19

=cut

use 5.010;
use strict;
use warnings;

use DBI;

my $fdb = shift or die usage();


#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Print usage information
  Returns:  None
  Args:     None

=cut

sub usage {
    say << "EOS";
Revise the influenza virus sequence database created by script 
'load_gbvirus.pl'
Usage:
  upd_fludb.pl <db>
EOS
}
