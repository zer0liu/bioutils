#!/usr/bin/perl

=head1 NAME

    fetch_10xreads.pl - Fetch 10x reads from a MongoDB database, then
                        export by Cell Barcodes and/or UMI.

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
Fetch reads by Cell Barcodes or UMIs from a 10x MongoDB.
Usage:
  fetch_10xreads.pl -d <db> [-l <cb|umi>] [--host <host>] [--port <port>]
                    [--user <user>] [--pwd <pwd>]
Arguments:
  -d <db>       MongoDB database name.
  -l <cb|umi>   Reads level, Cell Barcode (cb) or UMI (umi). Optional.
                Default umi.
  --host <host> Server hostname or IP address. Optional.
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

