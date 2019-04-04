#!/usr/bin/perl

=head1 NAME

    stat_10xreads.pl - Statistics 10x reads in given MongoDB database by
                       Cell Barcodes and UMI.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   - 2019-04-04

=cut

use 5.12.1;
use strict;
use warnings;


use MongoDB;
use Smart::Comments;



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
Statistics 10x reads in given MongoDB database by Cell Barcodes and UMI.
Usage:
  stat_10xreads.pl -d <db> [--host <host>] [--port <port>] [--user <user>]
                        [--pwd <pwd>]
Arguments:
  -d <db>       MongoDB name.
  --host <host> Hostname or IP address to be connected. Optional.
                Default 127.0.0.1.
  --port <port> Port. Optional.
                Default 27017.
  --user <user> Username. Optional.
  --pwd <pwd>   Password. Optional.
EOS
}

=pod

  Name:     
  Usage:    
  Function: 
  Args:     
  Returns:  

=cut

