#!/usr/bin/perl

=head1 NAME

    10xreads2db.pl - Parse and import 10x reads into a MongoDB.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Structure of V(D)J Enriched Library reads

=head3 Read 1

* Length:   150 bp

* Barcode:  16 bp
* UMI:      10 bp
* Switch:   13 bp
* Insert:   111 bp

=head3 Read 2

* Length:   150 bp

* Insert:   111 bp

=head2 Structure of 5' Gene Expression Library reads

=head3 Read 1

* Length:   26 bp

* Barcode:  16 bp
* UMI:      10 bp
* Insert:   NA

=head3 Read 2

* Length:   98 bp

* Insert:   98 bp

=head2 Structure of collections

=head3 Collection "reads"

    Filed           Description
    ----            ----
    _id             ObjectId
    cell_barcode    A string. Cell barcode of 10x sequencing.
    cb_exist        An integer. Based on 10x '737K-august-2016.txt'.
                    0   Not found.
                    1   Only 1 match.
                    >=2 Multiple match.
    read            A string. Raw read sequence.
    sample_idx      A string. Illumina sequencing sample index.
    read_desc       A string. Read sequence description.
    read_id         A string. Unique read sequence ID.
    umi             A string. Unique molecular identifiers.
    read_qual       A string. Quality scores for read sequence.
    insert          A string. Insert sequence.
    ins_qual        A string. Quality scores for insert sequence.
    read_num        An integer. Read number for Illumina sequencing.
                    must be 1 or 2.

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   - 2019-03-26
    0.0.2   - 2019-03-28    Support host, port, user and pwd.
                            Bug fix.
    0.0.3   - 2019-03-29    New field, 'qual_insert', for quality string
                            of insert.
                            Remove 'switch' field.
                            Insert in bulk mode (insert_many)
    0.0.4   - 2019-04-01    More details.
    0.0.5   - 2019-04-03    Able to setup default values of:
                            - connectTimeoutMS (connect_timeout_ms)
                            - socketTimeoutMS (socket_timeout_ms)
    0.1.0   - 2019-04-08    Bug fix:
                            - Cell barcode string not inserted
                            - Optimize detect cell barcode in 10x 
                              repository.
    0.1.1   - 2019-04-09    Optimize barcode search.
                            Now use hash, instead of grep an array.
    0.1.2   - 2019-04-10    Use connection string uri, instead of 
                            attributes in MongoDB::MongoClient->new()

=cut

use 5.12.1;
use strict;
use warnings;

use Getopt::Long;
use IO::Zlib;
use MongoDB;
use Smart::Comments;

#===========================================================
#
#                   Predefined Variables
#
#===========================================================

my $f_cb        = "737K-august-2016.txt";   # 10x cell barcode file
my $pool_size   = 20_000;   # Insert $buffer_size documents at one time

# The amount of time in milliseconds to wait for a new connection to 
# a server.
# Default: 10,000 ms
my $connect_timeout_ms  = 10_000;   # i.e., 10 s

# the amount of time in milliseconds to wait for a reply from the 
# server before issuing a network exception.
# Default: 30,000 ms
my $socket_timeout_ms   = 120_000;  # i.e., 120 s

#===========================================================
#
#                   Main Program
#
#===========================================================

my ($fread1, $fread2, $db);

my $host    = '127.0.0.1';
my $port    = '27017';
my ($user, $pwd);

GetOptions(
    "i=s"       => \$fread1,
    "j=s"       => \$fread2,
    "d=s"       => \$db,
    "host=s"    => \$host,
    "port=s"    => \$port,
    "user"      => \$user,
    "pwd"       => \$pwd,
    "h"         => sub { die usage() },
);

unless ( $fread1 and $fread2 and $db) {
    warn "[ERROR] All arguments are required!\n\n";
    die usage();
}

# Load 10x cell barcodes into a hash
warn "[NOTE] Loading 10x cell barcodes ...\n";

my $rh_cbs  = load_cbs($f_cb);

# All cell barcodes into an array
my @cbs     = sort keys %{ $rh_cbs };

# Connect to local MongoDB w/ default port
say "[NOTE] Connecting to '$host:$port'.";

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

### $conn_uri

# Connect to database
#my $mongo_client    = MongoDB::MongoClient->new(
    #host                => "mongodb://$host",
#    host                => $host,
#    port                => $port,
#    connect_timeout_ms  => $connect_timeout_ms,
#    socket_timeout_ms   => $socket_timeout_ms,
#);

my $mongo_client    = MongoDB->connect($conn_uri);

# Create database
my $mongo_db    = $mongo_client->get_database( $db );

# Create collection 'read'
my $coll_reads  = $mongo_db->get_collection( 'reads' );

# Rarse read files and insert into collection 'read'
# Read 1
warn "[NOTE] Working on read file: '", $fread1, "'\n";
operate_reads($coll_reads, $fread1);

# Read 2
warn "[NOTE] Working on read file: '", $fread2, "'\n";
operate_reads($coll_reads, $fread2);

# Create index
my $indexes = $coll_reads->indexes;

my @idx_names  = $indexes->create_many(
    { keys => [ 'read_id' => 1 ] },
    { keys => [ 'cb' => 1 ] },
    { keys => [ 'umi' => 1 ] },
    { keys => [ 'cb_exist' => 1 ] },
    { keys => [ 'read_num' => 1 ] },
);

say "Created indexes:\n", join "\n", @idx_names;

# Close connection
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
Parse and import 10x reads into a MongoDB database.
Usage:
  10xreads2db.pl -i <R1> -j <R2> -d <db> [--host <host>] [--port <port>]
                    [--user <user>] [--pwd <pwd>]
Args:
  -i <R1>:  Read1 file
  -j <R2>:  Read2 file
  -d <db>:  MongoDB name to be created.
  --host:   MongoDB server hostname or IP address. Default 127.0.0.1.
  --port:   MongoDB server port. Default 27017.
  --user:   MongoDB server user account. Optional.
  --pwd:    MongoDB server user password. Optional.
Note:
  Both plain text and gzipped FASTQ format were supported.
EOS
}

=pod

  Name:     load_cbs
  Usage:    load_cbs($fcbs)
  Function: Load cell barcodes into a hash from cell barcode file.
  Args:     $fcbs:  A string for 10x cell barcode filename
  Returns:  A hash reference for all barcodes

=cut

sub load_cbs {
    my ($fcbs)  = @_;
    
    my %cbs;
    
    open my $fh_cbs, "<", $fcbs or
        die "[ERROR] Open 10x Cell Barcodes file '$fcbs' failed!\n$!\n";
        
    while (<$fh_cbs>) {
        next if /^#/;
        next if /^\s*$/;
        chomp;
        
        my $cb = $_;
        
        $cbs{$cb}++;
    }
        
    close $fh_cbs;
    
    return \%cbs;
}

#{{{
#sub load_cbs {
#    my ($fcbs)  = @_;
#    
#    my @cbs;
#
#    open my $fh_cbs, "<", $fcbs or
#        die "[ERROR] Open 10x Cell Barcodes file '$fcbs' failed!\n$!\n";
#        
#    while (<$fh_cbs>) {
#        next if /^#/;
#        next if /^\s*$/;
#        chomp;
#        
#        my $cb = $_;
#        
#        push @cbs, $cb;
#    }
#        
#    close $fh_cbs;
#    
#    return \@cbs;
#}
#}}}

=pod

  Name:     correct_cb
  Usage:    correct_cb($cb, $ra_cbs)
  Function: Correct a cell barcode ($cb) with unknown bases (i.e., except 
            ACGT) if necessary, and identify whether this cell barcode is 
            10x certified.
  Args:     $cb     A string, cell barcode to be corrected
            $ra_cbs An array reference, for all pre-defined barcodes
  Return:   A list of 2 items:
            1st item:   An integer, number of found cell barcodes.
                        0:  Not found, or w/ 2 or more mismatches
                        1:  Found 1 and only 1
                        2 or more:  Number of found barcodes
            2nd item:   A string, for cell barcode.
                        - If there were 2 or more 'N' found, here is the 
                          original string (i.e., not corrected).
                        - Otherwise, original or corrected barcode string.

=cut

sub correct_cb {
    my ($cb, $ra_cbs)   = @_;

    my $raw_cb  = $cb;
    my $num_cbs = 0;    # Number of found cell barcodes

#    if ($cb =~ /[^ACGT]/) { # Found mismatch base, typically 'N'
#	    my $num_mis = $cb =~ s/[^ACGT]/\./; # Convert cb to a regex
#	
#	    if ($num_mis > 1) { # If mismatch bases number > 1
#	        return (0, $raw_cb); # No cell barcode available,
#	                                    # return raw cell barcode string
#	    }
#    }

    # Replace non-ACGT bases to '.'.
    # It creates a regex pattern.
    my $num_mis = $cb =~ s/[^ACGT]/\./g; 

    # More than 1 wrong bases, return original cell barcode string.
    return (0, $raw_cb) if ($num_mis > 1);

    # Search $cb in given 10x cell barcodes repository
    # It may need quite a LONG time and get multiple results
    my @results = grep /$cb/, @{ $ra_cbs };

    $num_cbs    = scalar @results;

    if ($num_cbs == 1) {    # Match only one cell barcode
        my $corr_cb = $results[0];  # Get the 1st one, and the only one

        return ($num_cbs, $corr_cb);    # Return corrected cb
    }
    else {  # Otherwise, 0, 2 or more, return original cb
        return ($num_cbs, $raw_cb);
    }
}

=pod

  Name:     operate_reads
  Usage:    operate_reads($collection, $fread)
  Function: Parse read file and insert into record/document into 
            given collection.
  Args:     $collection:    A MongoDB::Collection instance
            $fread:         A filename
  Returns:  Number of inserted reads.

=cut

sub operate_reads {
    my ($coll, $freads) = @_;
    my $num_total_reads = 0;    # Number of total reads
    my $num_ins_reads   = 0;    # Number of inserted reads
    my $num_corr_cbs    = 0;    # Number of corrected barcode

    my $fh_reads;

    my @docs_pool;              # Buffer for insert_many
    my $num_docs_in_pool= 0;    # Number of docs in pool

    if ($freads =~ /\.(?:fq|fastq)$/) {    # A FASTQ file
        open $fh_reads, "<", $freads or
            die "[ERROR] Open reads file '$freads' failed!\n$!\n";
    }
    elsif ($freads =~ /\.(?:fq|fastq)\.gz$/) { # gzippd file
        #open $fh_reads, "<", "gzcat $freads |" or
        #    die "[ERROR] Open reads file '$freads' failed!\n$!\n";

        $fh_reads   = IO::Zlib->new($freads, 'rb') or
            die "[ERROR] Open reads file '$freads' failed!\n$!|n";
    }
    else {
        die "[ERROR] Unsupported file type for '$freads'!\n";
    }
    
    while ( <$fh_reads> ) {
        next if /^#/;
        next if /^\s*$/;
        chomp;
        
        if (/^@(\S+?)\s+(\S+?)$/) { # Seq ID line
            my $read_id      = $1;
            my $read_desc    = $2;

            ## $read_id

            $num_total_reads++;

            # Parse sequence description, get:
            # Read number:  $read_num
            # Sample index: $sample_idx
            my ($read_num, $is_filtered, $ctl_num, $sample_idx)
                = split /:/, $read_desc;
            
            my $read_str     = <$fh_reads>;
            chomp($read_str);

            $read_str        = uc $read_str;  # Convert to uppercase

            my $read_len    = length($read_str);
            
            my $opt_read_id  = <$fh_reads>; # Optional read ID
            chomp($opt_read_id);
            
            unless ($opt_read_id =~ /^\+/) {
                warn "[WARNING] May be not FASTQ format for '$read_id'\n";
                next;
            }
                                
            my $read_qual    = <$fh_reads>;
            chomp($read_qual);

            if ($read_len >= 150) {  # V(D)J Enriched Library
                if ($read_num == 1) {   # Read #1
                    my $cb      = substr $read_str, 0, 16;
                    my $umi     = substr $read_str, 16, 10;
                    my $switch  = substr $read_str, 26, 13;
                    my $insert  = substr $read_str, 39;

                    # Insert quality
                    my $ins_qual= substr $read_qual, 39;

                    my $cb_exist=0;
                    my $corr_cb = '';

                    if ($cb =~ /[^ACGT]/) { # non-ACGT bases found
                        # say "Found misc base: '$cb'";

                        ($cb_exist, $corr_cb)
                            = correct_cb($cb, \@cbs);

                        $num_corr_cbs++ if ($cb_exist == 1);
                    }
                    else {
                        #($rh_cbs->{$cb}) ? 
                        #    ($cb_exist = 1) : ($cb_exist = 0);
                        $corr_cb    = $cb;  # Do not need correction
                        $cb_exist   = ($rh_cbs->{$cb}) ? 1 : 0;
                    }
                    
                    push @docs_pool, {
                        'read_id'       => $read_id,
                        'read_desc'     => $read_desc,
                        'read'          => $read_str,
                        'cell_barcode'  => $corr_cb,
                      # 'cell_barcode'  => $cb,
                        'cb_exist'      => $cb_exist,
                        'umi'           => $umi,
                      # 'switch'        => $switch,
                        'insert'        => $insert,
                        'read_num'      => $read_num,
                        'sample_idx'    => $sample_idx,
                        'read_qual'     => $read_qual,
                        'ins_qual'      => $ins_qual,                   
                    };

                    $num_docs_in_pool++;
                }
                elsif ($read_num == 2)  {   # Read #2
                    push @docs_pool, {
                        'read_id'       => $read_id,
                        'read_desc'     => $read_desc,
                        'read'          => $read_str,
                        'insert'        => $read_str,
                        'read_num'      => $read_num,
                        'sample_idx'    => $sample_idx,
                        'read_qual'     => $read_qual,
                        'ins_qual'      => $read_qual,                   
                    };

                    $num_docs_in_pool++;
                }
                else {
                    warn "[ERROR] Impossible read number: '$read_num'",
                        "for '$read_id'\n";
                    next;
                }
            }
            elsif ($read_len >= 98 and $read_num == 2) {
                # 5' Gene Expression Library, Read #2

                push @docs_pool, {
                    'read_id'       => $read_id,
                    'read_desc'     => $read_desc,
                    'read'          => $read_str,
                    'insert'        => $read_str,
                    'read_num'      => $read_num,
                    'sample_idx'    => $sample_idx,
                    'read_qual'     => $read_qual,
                    'ins_qual'      => $read_qual,
                };

                $num_docs_in_pool++;

            }
            elsif ($read_len >= 26 and $read_num == 1) {
                # 5' Gene Expression Library, Read #1
                # $read_str    =~ s/^N*//;

                my $cb  = substr $read_str, 0, 16;
                my $umi = substr $read_str, 16;
                # There is NO switch Oligo available

                $cb             = uc $cb;

                my $cb_exist    = 0;
                my $corr_cb     = '';

                # ($cb_exist, $corr_cb)   = correct_cb($cb, $ra_cbs);

                if ($cb =~ /[^ACGT]/) { # Other base except ACGT found
                    ($cb_exist, $corr_cb)
                        = correct_cb($cb, \@cbs);

                    $num_corr_cbs++ if ($cb_exist == 1);
                }
                else {
                    $corr_cb        = $cb;
                    $cb_exist       = ($rh_cbs->{$cb}) ? 1 : 0;
                }
 
                push @docs_pool, {
                    'read_id'       => $read_id,
                    'read_desc'     => $read_desc,
                    'read'          => $read_str,
                    'cell_barcode'  => $corr_cb,
                    'cb_exist'      => $cb_exist,
                    'umi'           => $umi,
                    'read_num'      => $read_num,
                    'sample_idx'    => $sample_idx,
                    'read_qual'     => $read_qual,               
                };

                $num_docs_in_pool++;
            }
            else {
                warn "[WARNING] Unidentified read '$read_id' ",
                    "in Read #", $read_num, "\n",
                    "with length: ", $read_len, "\n";
            }
        }
        else {
            next;
        }

        ## $num_docs_in_pool

        # Pool full, insert into collection
        if ($num_docs_in_pool == $pool_size) {
            $coll_reads->insert_many(\@docs_pool);

            $num_ins_reads      += $num_docs_in_pool;

            $num_docs_in_pool   = 0;    # Reset counter
            @docs_pool          = ();   # Reset pool
        }
    }

    # If there are data in pool after EOF
    # Insert them into collection
    if ($num_docs_in_pool > 0) {
        $coll_reads->insert_many(\@docs_pool);

        $num_ins_reads      += $num_docs_in_pool;

        $num_docs_in_pool   = 0;
        @docs_pool          = ();
    }
    
    close $fh_reads;

    say "Total reads number:\t", $num_total_reads;
    say "Inserted reads number:\t", $num_ins_reads;
    say "Corrected cell barcode:\t", $num_corr_cbs;

    return 1;
}
