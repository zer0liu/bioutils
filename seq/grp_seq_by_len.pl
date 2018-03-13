#!/usr/bin/perl

=head1 NAME

    grp_seq_by_len.pl - Group sequence by length.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-12-11

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;
use Getopt::Long;

my $usage   = << "EOS";
Group sequences by length.
Usage:
  grp_seq_by_len.pl -i <file> [-m <format>] [-v <intval>]
Parms:
  -i <file> Input sequence file.
  -m <fmt>  Input sequence file format.
            Default 'fasta'.
  -v <int>  Length interval of each groups.
            Default 1000.
EOS

my ($fin, $fmt, $intv);

$fmt    = 'fasta';
$intv   = 1000;

GetOptions(
    "i=s"   => \$fin,
    "m=s"   => \$fmt,
    "v=i"   => \$intv,
    "h"     => sub { die $usage }
);

die $usage unless ( $fin );

my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => $fmt,
);

my %groups;

while (my $o_seq = $o_seqi->next_seq) {
    my $id  = $o_seq->id;
    my $len = $o_seq->length;

    my $grp_id  = int($len / $intv) + 1;

    push @{ $groups{$grp_id} }, $o_seq;
}

# Output file
my ($basename, $dir, $suffix)   = fileparse($fin, qr/\..*$/);

# Calculate sequence number
my $num = 0;

for my $grp_id (sort {$a <=> $b} keys( %groups)) {
    my $fout    = $basename . '_' . $grp_id . '.' . $fmt;

    my $o_seqo  = Bio::SeqIO->new(
        -file   => ">$fout",
        -format => $fmt,
    );

    for my $o_seq ( @{$groups{$grp_id}} ) {
        $o_seqo->write_seq( $o_seq );

        $num++;
    }

    # say $grp_id * $intv, "\t", $num;
    printf "%10d\t%12d\n", ($grp_id, $num);

    $num    = 0;
}

exit 0;

