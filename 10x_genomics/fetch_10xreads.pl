#!/usr/bin/perl

=head1 NAME

    fetch_10xreads.pl - Fetch 10x reads from a MongoDB database, then
                        export by Cell Barcodes and/or UMI.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Output filename

It will create lots of output files. 

=over

=item C<cb> 

In Cell Barcode level, the output filename is:

    prefix_cb000000_R1.fq.gz

=item C<umi>

In UMI level, the output file name is:

    prefix_cb000000_umi00000_R1.fq.gz

=back

=head2 Filename details

=over

=item C<prefix>

The filename prefix. Default is the given database name.

=item C<cb000000>

Serial number of Cell Barcode. Range 0 - 999,999.

=item C<umi00000>

Serial number of UMI. Range 0 - 99,999.

=item C<R1>

Read number. 1 or 2.

=back

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   - 2019-04-17
    0.0.2   - 2019-04-18

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
my $socket_timeout_ms   = 1_800_000;  # i.e., 1800 s or 30 min

#===========================================================
#
#                   Main Program
#
#===========================================================

my $host    = '127.0.0.1';
my $port    = '27017';
my $level   = 'umi';
my $thold   = 100;  # Threshold value for reads number of cb/umi.

my ($db, $user, $pwd, $fout);

GetOptions(
    "d=s"       => \$db,
    "host=s"    => \$host,
    "port=s"    => \$port,
    "user=s"    => \$user,
    "pwd=s"     => \$pwd,
    "l=s"       => \$level, # 'cb' or 'umi'
    "n=i"       => \$thold, # Threshold value
    "o=s"       => \$fout,  # Prefix of output filename
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

$fout   = $db unless (defined $fout);

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

# Select operation by querying level: 'cb' / 'umi'
if ($level eq 'cb') {
    # 
}
elsif ($level eq 'umi') {
    # Aggregation to count & filter result set
    my @pipeline    = (
        { '$match' => { 'read_num' => 1, 'cb_exist' => 1 } },
        { '$group' => {
            '_id'       => { 'cb' => '$cell_barcode', 'umi' => '$umi' },
            'num_reads' => { '$sum' => 1 },
        }, },
        { '$match' => { 'num_reads' => { '$gt' => $thold } } },
        { '$sort'  => { 'num_reads': -1 } },
    );

    my %options     = (
        'allowDiskUse'  => true,
    );

    my $result  = $mongo_db->get_collection('reads')->aggregate(
        \@pipeline,
        \%options
    );

    my $cb_sn   = 0;    # a.k.a., cb ID
    my $umi_num = 1;    # a.k.a., umi ID, for each cb

    my %cbs;            # Hash to store cb information

    my $fout_R1 = $fout . 
        '_' . 'cb' . fprintf("%06d", $cb_num) .
        '_' . 'umi' . fprintf("%05d", $umi_num) .
        '_R1.fq.gz';

    while (my $doc = $result->next) {
        my $cb          = $doc->{'_id'}->{'cb'};
        my $umi         = $doc->{'_id'}->{'umi'};
        my $num_reads   = $doc->{'num_reads'};

        # Store umi by cb information into a hash: %cbs
        if (exists $cbs{$cb}) {
            $cbs{$cb}->{'num_umi'}  = $umi_num;

            $umi_num++;
        }
        else {
            $cbs{$cb}->{'sn'}       = $cb_sn;
            $cbs{$cb}->{'num_umi'}  = $num_umi;

            $cb_sn++;
            $num_umi++;
        }

        # Based on cb & umi, query to get seq_id, seq_desc,
        # seq_insert & insert_qual
    }
}
else {
    warn "[ERROR] Unsupported level: '$level'!\n";
    die usage();
}

exit 0;


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
  -n <num>      Threshold value for reads number of each cb/umi.
                i.e., reads number below this threshold value will NOT
                be returned. Optional.
                Default 100.
  -o <fout>     Output file name prefix. Optional.
                Default database name.
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

