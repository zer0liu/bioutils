#!/usr/bin/perl

=head1 NAME

    t_hd_mce.pl - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   - 2019-05-14

=cut

use 5.12.1;
use strict;
use warnings;

use MCE;
use Smart::Comments;

#
# Sample cell barcodes
# 


# Get cell barcodes repository
say "[NOTE] Loading cell barcodes ...";

my $f_cb    = '737K-august-2016.txt';

open my $fh_cb, "<", $f_cb or
    die "[ERROR] Open Cell Barcodes file '$f_cb' failed!\n";

my @cbs;

while (<$fh_cb>) {
    next if /^#/;
    next if /^\s*$/;
    chomp;

    push @cbs, $_;
}

close $fh_cbs;





#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Display usage information
  Args:     None
  Returns:  None

=cut

sub usage {
    say << 'EOS';
Test calculate Hamming Distance by MCE.
Usage:
  t_hd_mce.pl
EOS
}

=pod

  Name:     
  Usage:    
  Function: 
  Args:     
  Returns:  

=cut

