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
use IO::Zlib;
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
    say "[NOTE] Querying '$db' for reads number of a UMI ",
        "greater than '$thold' ...";
    
    my @pipeline    = (
        { '$match' => { 'read_num' => 1, 'cb_exist' => 1 } },
        { '$group' => {
            '_id'       => { 'cb' => '$cell_barcode', 'umi' => '$umi' },
            'num_reads' => { '$sum' => 1 },
        }, },
        { '$match' => { 'num_reads' => { '$gt' => $thold } } },
        { '$sort'  => { 'num_reads' => -1 } },
    );

    my %options     = (
        'allowDiskUse'  => true,    # In case the result set is too large
    );

    my $result  = $mongo_db->get_collection('reads')->aggregate(
        \@pipeline,
        \%options
    );

    # Init count variables
    my $cb_sn   = 0;    # a.k.a., cb ID
    my $umi_sn  = 0;    # a.k.a., umi ID, for each cb

    # Hash to store cb information
    # It would be used to 
    # - Statistics of UMIs per Cell Barcode
    # - Store Cell Barcodes for query the *Read 2*
    # Structure
    # %cbs = (
    #   $cb => (
    #      'sn'        => $sn,         #
    #      'num_umi'   => $num_umi,
    #   ),
    # );
    my %cbs;
    
    # Traverse aggregate result set
    while (my $doc = $result->next) {
        my $cb          = $doc->{'_id'}->{'cb'};
        my $umi         = $doc->{'_id'}->{'umi'};
        my $num_reads   = $doc->{'num_reads'};

        say "[NOTE] Working on cb ", sprintf("%06d", $cb_sn), ":\t", $cb,
            ", umi ", sprintf("%05d", $umi_sn), ":\t", $umi;
        
        # Read 1 output filename
        my $fout_R1 = $fout . 
            '_cb' . sprintf("%06d", $cb_sn) .
            '_umi' . sprintf("%05d", $umi_sn) .
            '_R1.fq.gz';

        # Read 2 output filename
        my $fout_R2 = $fout . 
            '_cb' . fprintf("%06d", $cb_sn) .
            '_umi' . fprintf("%05d", $umi_sn) .
            '_R2.fq.gz';        
        
        # Store umi by cb information into a hash: %cbs
        if (exists $cbs{$cb}) { # Cell Barcode already exists
            $cbs{$cb}->{'num_umi'}  = $umi_sn;

            $umi_sn++;
        }
        else {  # Cell Barcode NOT exists
            $cbs{$cb}->{'sn'}       = $cb_sn;
            $cbs{$cb}->{'num_umi'}  = $umi_sn;

            $cb_sn++;
            $umi_sn++;
        }
        
        # Create output Read 1 gz file
        my $fh_R1   = IO::Zlib->new($fout_R1, "wb");
        my $fh_R2   = IO::Zlib->new($fout_R2, "wb");
        
        # Based on cb & umi, query to get Read 1: 
        # read_id, read_desc, insert & insert_qual
        my $read1_result    = $mongo_db->get_collection('reads')->find(
            { 'cell_barcode'  => $cb, 'umi' => $umi, 
              'read_num' => 1, 'cb_exist' => 1,
            },                                          # WHERE-clause
            { 'read_id' => 1, 'read_desc' => 1, 
              'insert' => 1, 'ins_qual' => 1,
              '_id' => 0,
            }                                           # SELECT-clause
        );
        
        while (my $read1_doc = $read1_result->next) {
            my $read_id     = $read1_doc->{'read_id'};
            my $read_desc   = $read1_doc->{'read_desc'};
            my $insert      = $read1_doc->{'insert'};
            my $ins_qual    = $read1_doc->{'ins_qual'};
            
            say $fh_R1 '@', join " ", ($read_id, $read_desc, $cb, $umi);
            say $fh_R1 $insert;
            say $fh_R1 '+';
            say $fh_R1 $ins_qual;
            
            # Query Read 2
            my $read2_result    = $mongo_db->get_collection('reads')->find(
                { 'read_id' => $read_id, 
                  'read_num' => 2, 'cb_exist' => 1,
                },
                { 'read_id' => 1, 'read_desc' => 1, 
                  'insert' => 1, 'ins_qual' => 1,
                  '_id' => 0,
                }
            );
            
            while (my $read2_doc = $read2_result->next) {
                my $read_id     = $read2_doc->{'read_id'};
                my $read_desc   = $read2_doc->{'read_desc'};
                my $insert      = $read2_doc->{'insert'};
                my $ins_qual    = $read2_doc->{'ins_qual'};
                
                say $fh_R2 '@', join " ", ($read_id, $read_desc, $cb, $umi);
                say $fh_R2 $insert;
                say $fh_R2 '+';
                say $fh_R2 $ins_qual;
            }
        }
        
        $fh_R1->close();
        $fh_R2->close();
    }
}
else {
    warn "[ERROR] Unsupported level: '$level'!\n";
    die usage();
}

$mongo_client->disconnect;

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

