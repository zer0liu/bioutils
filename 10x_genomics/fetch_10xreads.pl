#!/usr/bin/perl

=head1 NAME

    fetch_10xreads.pl - Fetch 10x reads from a MongoDB database, then
                        export by Cell Barcodes and/or UMI.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   - 2019-04-17

=cut

use 5.12.1;
use strict;
use warnings;

use boolean;
use Getopt::Long;
use MongoDB;
use Smart::Comments;

#===========================================================
#
#                   Predefined Variables
#
#===========================================================

# The amount of time in milliseconds to wait for a new connection to 
# a server.
# Default: 10,000 ms
my $connect_timeout_ms  = 10_000;   # i.e., 10 s

# the amount of time in milliseconds to wait for a reply from the 
# server before issuing a network exception.
# Default: 30,000 ms
my $socket_timeout_ms   = 1_800_000;  # i.e., 120 s

#===========================================================
#
#                   Main Program
#
#===========================================================

my $host    = '127.0.0.1';
my $port    = '27017';
my $level   = 'umi';

my ($db, $user, $pwd);

GetOptions(
    "d=s"       => \$db,
    "host=s"    => \$host,
    "port=s"    => \$port,
    "user=s"    => \$user,
    "pwd=s"     => \$pwd,
    "h"         => sub { die usage() },
);

unless ($db) {
    warn "[ERROR] Database name is required!\n";
    die usage();
}

unless ($level eq 'cb' || $level eq 'umi') {
    warn "[ERROR] Only level 'cb' or 'umi' supported!\n";
    die usage();
}

# Generate connection string URI
my $conn_uri= 'mongodb://';

# Append user & pwd
$conn_uri   = $conn_uri . $user . ':' . $pwd . '@'
    if ($user && $pwd);

# Append host & ip
$conn_uri   = $conn_uri . $host . ':' . $port . '/';

# Append connection options
$conn_uri   = $conn_uri . '?' . 
    'connectTimeoutMS=' . $connect_timeout_ms .
    '&' . 'socketTimeoutMS=' . $socket_timeout_ms;

# Connect to database
my $mongo_client    = MongoDB->connect($conn_uri);

# Get given database
my $mongo_db  = $mongo_client->get_database( $db );




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

