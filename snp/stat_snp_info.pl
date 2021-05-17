#!/usr/bin/perl

=head1 NAME

    stat_snp_info.pl - Statistics SNP information of an alignment.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot=com

=head1 VERSION

    0.0.1   2021-05-17

=cut

use 5.12.1;
use strict;
use warnings;

use Bio::AlignIO;
use File::Basename;
use Getopt::Long;
use Smart::Comments;
use Term::ProgressBar;

my ($faln, $fmt, $refid, $fout, $F_VAR_ONLY);

$fmt        = 'fasta';
$F_VAR_ONLY = 0;        # Default output all location/sites

GetOptions(
    "i=s"   => \$faln,
    "f=s"   => \$fmt,
    "r=s"   => \$refid,
    "o=s"   => \$fout,
    "v"     => \$F_VAR_ONLY,
    "h"     => sub { usage() },
);

die usage() unless (defined $faln);

my $o_alni  = Bio::AlignIO->new(
    -file   => $faln,
    -format => $fmt,
);

# Assume there were only 1 alignment in the file
my $o_aln   = $o_alni->next_aln;

# Check whether the alignment is flush, i.e., all of the same length
unless ($o_aln->is_flush) {
    die "[ERROR] Sequences in the alignment are NOT in the same length!\n";
}

# Set to upper case
unless ($o_aln->uppercase) {
    die "[ERROR] Convert sequences to uppercase failed!\n";
}

# Alignment length
my $aln_len = $o_aln->length;

# Get reference sequence object.
my $o_refseq    = get_ref_seq($o_aln, $refid);

die "[ERROR] Get reference sequence failed!\n" 
    unless (defined $o_refseq);

my $refseq_str  = $o_refseq->seq;

my @ref_items   = split(//, $refseq_str);

# Parse alignment variation
my $rh_all_sites    = parse_sites($o_aln);

# Output to file
$fout   = generate_output_file_name($faln) 
    unless (defined $fout);

open(my $fh_out, ">", $fout)
    or die("[ERROR] Create output file '$fout' failed!\n$!\n");

say $fh_out join("\t", ("#Location", "Reference", "Variations"));

for my $i (1 .. $aln_len) {
    if ( $F_VAR_ONLY ) {    # Only output variation location/sites
        next if ( $rh_all_sites->{$i}->{'isVar'} == 0 );

        print $i, "\t", \           # Location
            $ref_items[$i-1], "\t"; # Reference item

        # $i  = "$i";     # Convert to string

        my $rh_items    = $rh_all_sites->{$i}->{'items'};

        my $item_str    = '';

        for my $item (sort keys %{ $rh_items }) {
            $item_str   = $item_str . ', ' . \
                $rh_items->{$item}  . $item;
        }

        $item_str   =~  s/^,//;

        print $fh_out $item_str, "\n";
    }
    else {
        print $i, "\t", \           # Location
            $ref_items[$i-1], "\t"; # Reference item

        #$i  = "$i";

        my $rh_items    = $rh_all_sites->{$i}->{'items'};

        my $item_str    = '';

        for my $item (sort keys %{ $rh_items }) {
            $item_str   = $item_str . ', ' . \
                $rh_items->{$item}  . $item;
        }

        $item_str   =~  s/^,//;

        print $fh_out $item_str, "\n";
    }
}

close($fh_out);

exit 0;


#===========================================================
#
#               Subroutines
#
#===========================================================

#
# usage
#

sub usage {
    warn << "EOS";
Statistics SNP information of a sequence alignment.
Usage:
  stat_snp_info.pl -i <MSA> [-f <format>] [-r <refid>] [-o <output>] [-v]
Arguments:
  -i <MSA>:     Input multiple sequence alignment file.
  -f <format>:  MSA file format. Default 'fasta'.
                Other supported file format include: 
                    clustalw, mega, nexus, etc.
                More formats and details, see:
                    https://metacpan.org/pod/Bio::AlignIO
  -r <refid>:   A string for reference sequence id. Optional.
  -o <output>:  Output SNP infomation file. Optional.
  -v:           Output variation/SNP sites only. 
                Default output all sites.
Note:
  1. There must be only ONE alignment in the file.
  2. If reference sequence were not given, the FIRST sequence of the 
     alignment file is used as the reference.
  3. The reference sequence is also used in statistics.
EOS
}

#
# generate_output_file_name
#

sub generate_output_file_name {
    my ($fname) = @_;

    my ($basename, $dir, $suffix)   = fileparse($fname, qr/\..*$/);

    my $fout_name   = $basename . '.' . 'snp.txt';

    return($fout_name);
}

#
# get_ref_seq
#
# This subroutine accepts 1 or 2 arguments.

sub get_ref_seq {
    my ($o_aln, $seqid) = @_;

    my $o_ref;

	if (defined $seqid) {   # If given sequence id
	    $o_ref  = $o_aln->get_seq_by_id( $seqid );
	}
	else {  # No seq id given, use the first seq as the reference
	    $o_ref  = $o_aln->get_seq_by_pos(1);
	}

    return($o_ref);
}

#
# parse_sites
#

sub parse_sites {
    my ($o_aln) = @_;

    my $prog_bar    = Term::ProgressBar->new({
        name    => 'Sites:',
        count   => $aln_len,
        ETA     => 'linear',
    });

    my %sites;

    my $aln_len = $o_aln->length;

    for my $i (1 .. $aln_len) {
        my $o_slice_aln = $o_aln->slice($i, $i, 1);

        my %items;

        for my $o_seq ($o_slice_aln->each_seq) {
            my $item    = $o_seq->seq;

            $items{ $item } = (defined $items{$item}) ?
                ( $items{$item} + 1) : 1;
        }

        # $i  = "$i";

        if ( scalar (keys %items) >= 2 ) {
            $sites{$i}->{'isVar'}   = 1;
            $sites{$i}->{'items'}   = \%items;
        }
        else {
            $sites{$i}->{'isVar'}   = 0;
            $sites{$i}->{'items'}   = \%items;
        }

        $prog_bar->update($_);
    }

    $prog_bar->update($aln_len);

    return(\%sites);
}

