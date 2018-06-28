#!/usr/bin/perl

=head1 NAME

    dn_flu_gbk.pl - Download GenBank influenza virus sequence data,
                    in GenBank flat file format.
=head1 SYNOPSIS

=head1 DESCRIPTION

    This script will download a data file from NCBI ftp:

    ftp://ftp.ncbi.nih.gov/genomes/INFLUENZA/influenza_na.dat.gz

=head1 AUTHORS

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2018-03-08
    0.0.2   2018-03-12  Bug fix.

=cut

use 5.010;
use strict;
use warnings;

use Array::Utils qw(array_diff);
use Bio::DB::EUtilities;
use Bio::SeqIO;
use Getopt::Long;
use LWP::Simple;
use PerlIO::gzip;
use POSIX qw(strftime);
use Smart::Comments;

# Global variables
our $intvl      = 20;   # Download interval, in seconds
our $block_size = 1_000;  # Block size. i.e., Sequences number to be 
                        # downloaded each time.

my $usage = << "EOS";
Download Genbank influenza virus sequence data.
Usage:
  1. Initial mode: Download *ALL* data from GenBank.

        dn_flu_gbk.pl --init

  2. Update mode: Only download *NEW* data from GenBank.

        dn_flu_gbk.pl --update -l|--list <acc> 

Args:
  <acc> A GenBank Accession Number file.
EOS

my ($mode, $facc, $fout);

GetOptions(
    "init"          => sub { $mode = "init"},
    "update"        => sub { $mode = "update" },
    "l|list=s"      => \$facc,
    "h|help"        => sub { die $usage }
);

unless (defined $mode ) {
    warn "[ERROR] Please specify 'init' or 'update' mode!\n";
    die $usage;
}

if ($mode eq 'update' and !defined $facc) {
    warn "[ERROR] An accession number file is required in 'update' mode!\n";
    die $usage;
}
elsif (-f $facc and -r $facc) {
    die "[ERROR] Accession Number file '$facc' is NOT accessible!";
}
else {
    #
}
    
# unless( defined $fout) {
#     $fout   = output_filename();
# 
#     say "[NOTE] Output filename: '$fout'";
# }

say "[NOTE] Getting all influenza viruses accession number from GenBank.";
my $fdat    = get_nt_dat();

say "[NOTE] Parsing 'na dat' file and get all accession numbers...";
my $ra_all_accs = parse_acc( $fdat );

say "[NOTE] Total ", scalar( @{$ra_all_accs} ),  " nucleotide sequences in GenBank.";

if ($mode eq 'init') {
    fetch_gb_seq( $ra_all_accs );
}
elsif ($mode eq 'update') {
    # Get known accession numbers from file
    open my $fh_acc, "<", $facc
        or die "[ERROR] Open Accession Number file '$facc' failed!\n$!\n";

    my @known_accs;

    while (<$fh_acc>) {
        next if /^#/;
        next if /^\s*$/;
        chomp;

        push @known_accs, $_;
    }

    close $fh_acc;

    say "[NOTE] Already got ", scalar(@known_accs), " nucleotide sequences.";

    my @diff_accs = array_diff(@{ $ra_all_accs}, @known_accs );

    say "[NOTE] Need to download ", scalar(@diff_accs), " nucleotide sequences from GenBank.";

    #
    # DEBUG
    #
    open my $fh_diff, ">", "diff_accs.txt"
        or die "[ERROR] 'diff_accs.txt' $!\n";

    say $fh_diff join "\n", @diff_accs;

    close $fh_diff;

    fetch_gb_seq( \@diff_accs );
}


#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod
    Name:   output_filename
    Desc:   Generate output filename according to currnet datetime
    Args:   None
    Ret:    A string
=cut

sub output_filename {
    my $curdate = strftime '%Y%m%d', localtime;
    my $f       = 'flu_gb_' . $curdate . '_' . int(rand(10_000)) . '.gb';

    return $f;
}

=pod
    Name:   get_na_dat
    Desc:   Download file 'influenza_na.dat.gz' from NCBI ftp server.
    Args:   None
    Ret:    A filename
            undef for any errors
=cut

sub get_nt_dat {
    my $na_dat_url  
        = "ftp://ftp.ncbi.nih.gov/genomes/INFLUENZA/influenza_na.dat.gz";

    my $file    = 'na_dat.gz';

    my $rc      = getstore($na_dat_url, $file);

    if ( is_error($rc) ) {
        die "[ERROR] Failed to download 'na.dat.gz' from NCBI ftp.\n";
    }
    else {
        say "[OK] Download 'na.dat.gz' file completed.";
    }

    return $file;
}

=pod
    Name:   parse_acc($fdat)
    Desc:   Parse dat file and extract accessin numbers.
    Args:   $fdat   - A string
    Ret:    A hash of an array
=cut

sub parse_acc{
    my ($fdat)  = @_;
    my @accs;

    # Whether dat file available
    unless (-f $fdat and -r $fdat) {
        die "[ERROR] Dat file '$fdat' is not accessable!\n";
    }

    # Operate gzip file
    open(my $fh_dat, "<:gzip", $fdat)
        or die "[ERROR] Failed to uncompress file '$fdat'!\n$!\n";

    while (<$fh_dat>) {
        my ($acc, ) = split /\t/, $_;
        push @accs, $acc;
    }

    return \@accs;
}

=pod
    Name:   fetch_gb_seq
    Desc:   Fetch sequence from GenBank
    Args:   A hash reference of IDs array
    Ret:    None
=cut

sub fetch_gb_seq{
    my ($ra_ids)    = @_;
    my $num_ids     = scalar( @{ $ra_ids } );

    my $num_blocks  = int( $num_ids / $block_size ) + 1;
    
    for (my $i=0; $i < $num_blocks; $i++) {
        # Get start and end of array slice
        my $start   = $block_size * $i;
        my $end     = $block_size * ($i + 1) - 1;
        
        # Get an array silce of ids
        my @sub     = @{ $ra_ids }[$start..$end];

	    my $o_factory   = Bio::DB::EUtilities->new(
	        -eutil      => 'efetch',
	        -db         => 'nucleotide',
	        -rettype    => 'gbwithparts',
	        -email      => 'foo@mail.com',
	        -id         => \@sub,
        );

        # Output GenBank filename of current block
        my $curdate = strftime '%Y%m%d', localtime;
        my $fout    = 'flu_gb_' . $curdate . '_' . sprintf("%04s", $i) . '.gbk';

        say "[NOTE] Getting $start .. $end ...";

        # Output to file
        $o_factory->get_Response( -file => $fout );

        # Pause $intvl seconds
        sleep $intvl;
    }

    return;
}

