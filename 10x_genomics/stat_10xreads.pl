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
    0.0.2   - 2019-04-15    More complex aggragation.
    0.1.0   - 2019-04-25    Statistics of UMIs per cb.
                            Sort by numbers of UMIs.

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
#my $mongo_client    = MongoDB::MongoClient->new(
#    host                => $host,
#    port                => $port,
#    connect_timeout_ms  => $connect_timeout_ms,
#    socket_timeout_ms   => $socket_timeout_ms,
#);

my $mongo_client    = MongoDB->connect($conn_uri);

# Get given database
my $mongo_db  = $mongo_client->get_database( $db );

#
# Number of reads by Cell barcode
#
say "[NOTE] Statistics of reads number per Cell Barcode ...";

my $cb_out  = $mongo_db->get_collection('reads')->aggregate(
    [
        { '$match' => { 'read_num' => 1, 'cb_exist' => 1 } },
        { '$group' => { '_id' => '$cell_barcode', 
                        'num_reads' => { '$sum' => 1 } },
        },
        { '$sort' => { 'num_reads'=> -1 } }
    ], { 'allowDiskUse' => true }
);

# Output result to txt file.
my $f_out   = $db . '_reads-cb_stat.txt';

open my $fh_out, ">", $f_out or
    die "[ERROR] Create output file '$f_out' failed!\n$!\n";

say $fh_out join "\t", qw(Cell_Barcode Reads_number);

while (my $doc = $cb_out->next) {
    say $fh_out join "\t", ( $doc->{'_id'}, $doc->{'num_reads'} );
}

close $fh_out;

#
# Number of reads by umi of cell barcode
#

say "[NOTE] Statistics of reads number per UMI of Cell Barcodes ...";

my $umi_cb_out  = $mongo_db->get_collection('reads')->aggregate(
    [
        { '$match' => { 'read_num' => 1, 'cb_exist' => 1 } },
        { '$group' => { '_id' => { 'cb' => '$cell_barcode', 'umi' => '$umi' },
                        'num_reads' => { '$sum' => 1 } },
        },
        { '$sort' => { 'num_reads'=> -1 } },
    ], { 'allowDiskUse' => true }
);

# A hash to store cb and related umi numbers
# %umi_cb = (
#   $cb => $umi_number;
# );

my %umi_cb;

# Output result to txt file.
$f_out   = $db . '_reads-umi_cb_stat.txt';

open $fh_out, ">", $f_out or
    die "[ERROR] Create output file '$f_out' failed!\n$!\n";

say $fh_out join "\t", qw(Cell_Barcode UMI Reads_number);

while (my $doc = $umi_cb_out->next) {
    say $fh_out join "\t", ( $doc->{'_id'}->{'cb'}, $doc->{'_id'}->{'umi'},
    $doc->{'num_reads'} );
    
    # Statistics umis per cb
    my $cb  = $doc->{'_id'}->{'cb'};
    
    if (exists $umi_cb{$cb}) {
        $umi_cb{$cb}++;
    }
    else {
        $umi_cb{$cb}    = 1;
    }
}

close $fh_out;

#
# Number of umi by cell barcode
#
say "[NOTE] Statistics of UMI number per Cell Barcode ...";

$f_out  = $db . '_umi-cb_stat.txt';

open $fh_out, ">", $f_out or
    die "[ERROR] Create output file '$f_out' failed!\n$!\n";

say $fh_out join "\t", qw#Cell_Barcode UMI_Number#;

for my $cb (sort { $umi_cb{$b} <=> $umi_cb{$a} } keys %umi_cb) {
    say $fh_out join "\t", ($cb, $umi_cb{$cb} );
}

close $fh_out;

# Disconnect
$mongo_client->disconnect();

say "[OK] Database disconnected.";

exit 0;

# Find orphan reads. i.e., read with Read #1 or Read #2 ONLY.

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
Statistics 10x reads in given MongoDB database by Cell Barcodes and UMIs.
Usage:
  stat_10xreads.pl -d <db> [--host <host>] [--port <port>] [--user <user>]
                        [--pwd <pwd>]
Arguments:
  -d <db>       MongoDB database name.
  --host <host> Server hostname or IP address to be connected. Optional.
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

