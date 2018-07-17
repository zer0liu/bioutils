#! /usr/bin/env perl

=head1 NAME

    tbl2aln.pl - Generate sequence alignment according to given 
                 nucleotide number table.

=SYNOPSIS

=DESCRIPTION

    Input nucleotide proportation table format:

    site    A   G   C   T

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2018-07-17

=cut

use 5.010;
use strict;
use warnings;

use File::Basename;
use Smart::Comments;

my ($ftab, $faln);

unless ($ftab    = shift) {
    usage();
    exit 1;
}

unless ($faln = shift) {    # Generate output filename
    my ($basename, ,)   = fileparse($ftab, qr/\..*$/);

    $faln   = $basename . '.fa';
}

# Read input table file
say "[NOTE] Parsing input file ...";

open my $fh_tab, "<", $ftab
    or die "[ERROR] Open table file '$ftab' failed!\n$!\n";

my %site_info;      # Site composition information
my $max_len = 0;    # Maximum sequence length, i.e., sum of nucleotides    

while (<$fh_tab>) {
    next if /^#/;
    next if /^\s*$/;
    next if /[A-Za-z]/; # Dismiss character lines

    my ($loc, $num_a, $num_g, $num_c, $num_t)   = split /\t/;

    $site_info{$loc}->{'A'} = $num_a;
	$site_info{$loc}->{'G'} = $num_g;
	$site_info{$loc}->{'C'} = $num_c;
	$site_info{$loc}->{'T'} = $num_t;

    my $num_total           = $num_a + $num_g + $num_c + $num_t;
    $site_info{$loc}->{'total'}     = $num_total;

    ($num_total > $max_len) ? $max_len = $num_total : next;
}

close $fh_tab;

for my $site (sort keys %site_info) {
    $site_info{$site}->{'-'}   = $max_len - $site_info{$site}->{'total'};
}

### %site_info

# Output sequence hash
say "[NOTE] Generating output hash ...";

my %out_seq;

for my $site (sort {$a<=>$b} keys %site_info) {
    ### $site
    my $i   = 1;

    ## $i

    #if ($site_info{$site}->{'A'} > 0) {
    {
        my $j   = 0;
    #    $out_seq{$seq_id}   //= '';
	    while ( $j < $site_info{$site}->{'A'}) {
	        my $seq_id  = 'CT' . sprintf("%06s", $i);
            $out_seq{$seq_id}   //= '';
	        $out_seq{$seq_id}   = $out_seq{$seq_id} . 'A';
	        $j++;
	        $i++;
	    }
    }

    ### $i
    #if ($site_info{$site}->{'G'} > 0) {
    {
        my $j   = 0;
	    #for my $j (0..$site_info{$site}->{'G'}) {
        while ($j < $site_info{$site}->{'G'}) {
	        my $seq_id  = 'CT' . sprintf("%06s", $i);
	        $out_seq{$seq_id}   //= '';
	        $out_seq{$seq_id}   = $out_seq{$seq_id} . 'G';
	        $j++;
	        $i++;
	    }
    }
    ### $i
    # if ($site_info{$site}->{'C'} > 0) {   
    {
        my $j   = 0;
	    # for my $j (0..$site_info{$site}->{'C'}) {
        while ($j < $site_info{$site}->{'C'}) {
	        my $seq_id  = 'CT' . sprintf("%06s", $i);
	        $out_seq{$seq_id}   //= '';
	        $out_seq{$seq_id}   = $out_seq{$seq_id} . 'C';
	        $j++;
	        $i++;
	    }
    }
    ### $i
    # if ($site_info{$site}->{'T'} > 0) {
    {
        my $j   = 0;
	    # for my $j (0..$site_info{$site}->{'T'}) {
        while ($j < $site_info{$site}->{'T'}) {
	        my $seq_id  = 'CT' . sprintf("%06s", $i);
	        $out_seq{$seq_id}   //= '';
	        $out_seq{$seq_id}   = $out_seq{$seq_id} . 'T';
	        $j++;
	        $i++;
	    }
    }
    ### $i
    #if ($site_info{$site}->{'-'} > 0) {
    {
        my $j   = 0;
	    # for my $j (0..$site_info{$site}->{'-'}) {
        while ($j < $site_info{$site}->{'-'}) {
	        my $seq_id  = 'CT' . sprintf("%06s", $i);
	        $out_seq{$seq_id}   //= '';
	        $out_seq{$seq_id}   = $out_seq{$seq_id} . '-';
	        $j++;
	        $i++;
	    }
    }
    ### $i
}

# Output as FASTA file
say "[NOTE] Output file ...";

open my $fh_out, ">", $faln
    or die "[ERROR] Create output file '$faln' failed!\n$!\n";

for my $seq_id (sort keys %out_seq) {
    say $fh_out '>', $seq_id;
    say $fh_out $out_seq{$seq_id};
}

close $fh_out;

say "[DONE]";


#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Display usage information
  Returns:  None
  Args:     None

=cut

sub usage {
    say << 'EOS';
Generate sequence alignment according to given nucleotide number table.
The construncted alignment usually was used for WebLogo analysis.
Usage:
  tbl2aln.pl <ftable> [<faln>]
Arguments:
  ftable    Input tab-delimited nucleotide number file.
  faln      Output FASTA format alignment file.
Note:
  * Output FASTA format alignment file.
EOS
}
