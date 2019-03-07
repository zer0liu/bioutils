#!/usr/bin/perl

=head1 NAME

    comb_alns.pl - Combine alignment files with the same format into
                   one alignment file, in FASTA format.

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2014-10-30
    0.1.0   2019-03-07  New output method, output FASTA only. 

=cut

use 5.010;
use strict;
use warnings;

use Bio::AlignIO;
use Getopt::Long;
use File::Basename;

use Smart::Comments;

my $usage = << "EOS";
Usage:
  comb_alns.pl [-t <format>] -o <outf> <file1> <file2> ...

Options:
  -t <format>   Input file format.
                Optional. Default 'fasta'.
  -o <outf>     Output filename.

Arguments:
  <file1> <file2> ... : Input alignment files

Note:
  1. All input alignment files MUST as the same formats.
  2. The combined sequence order according to the given input files.
  3. Supported alignment file formats are:
        clustalw
        fasta
        msf
        nexus
        phylip (interleaved)
        selex
EOS

my ($fmt_in, $fmt_out, $fout);

$fmt_in     = 'fasta';
$fmt_out    = 'fasta';

GetOptions(
    "t=s"   => \$fmt_in,
#    "m=s"   => \$fmt_out,
    "o=s"   => \$fout,
    "h"     => sub { die $usage }
);

die $usage unless ( $fmt_in && $fout );

# my %aln_seqs;
my %alns;    # Hash stores hash reference for each input flie
my %seq_ids; # Hash store all *unique* sequence ids in each input file
             # in case there were missing sequences in an alignment.
my %aln_len; # Hash store length of alignment in each input file

for my $fin ( @ARGV ) {
    say "Parsing '$fin' ...";

    # Parse filename
    my ($fname, $dir, $suffix)   = fileparse($fin, qr/\..*$/);

    my $aln_id  = $fname;

    my %seqs;

    my $o_alni  = Bio::AlignIO->new(
        -file   => $fin,
        -format => $fmt_in,
    ) or die "[ERROR] Parse file '$fin' as format '$fmt_in' failed!\n";

    my $o_aln   = $o_alni->next_aln;

    unless ($o_aln->is_flush) {
        die "[ERROR] Sequence length in alignment file '$fin' are NOT identical!\n";
    }

    # Get the length of alignment
    $aln_len{ $aln_id }  = $o_aln->length;

    for my $o_seq ( $o_aln->each_seq ) {
        my $id  = $o_seq->id;
        my $seq = $o_seq->seq;

        #$aln_seqs{ $id }    .= $seq;
        $seq_ids{ $id }++;
        
        $alns{ $aln_id }->{ $id }    = $seq;
    }
}

# {{{
=pod
# Output alignment
# Output Bio::Align::AlignO object
my $o_alno  = Bio::AlignIO->new(
    -file   => ">$fout",
    -format => $fmt_out,
);

# Output Bio::SimpleAlign object
my $o_aln   = Bio::SimpleAlign->new();

for my $id ( sort ( keys %aln_seqs ) ) {
    my $o_seq   = Bio::LocatableSeq->new(
        -id     => $id,
        -seq    => $aln_seqs{ $id },
    );

    $o_aln->add_seq( $o_seq );
}

$o_alno->write_aln( $o_aln );

say "[OK] All files combined and output as a FASTA alignment file!";

exit;
=cut
# }}}

# Output alignment if FASTA format
my %aln_out;


for my $seq_id ( sort keys %seq_ids ) {
    for my $aln_id ( sort keys %alns ) {
        my $seq;

        if ( exists $alns{ $aln_id }->{ $seq_id} ) {
            $seq    = $alns{ $aln_id }->{ $seq_id };
        }
        else {  # Sequence NOT exist in alignment
            warn "[WARN] '$seq_id' NOT exist in alignment '$aln_id'! Fill with '-'.";
            $seq    = '-' x $aln_len{ $aln_id };
        }

        $aln_out{ $seq_id } .= $seq;
    }
}

open my $fh_out, ">", $fout
    or die "[ERROR] Create output file '$fout' failed!\n\$!\n";

for my $seq_id ( sort keys %aln_out ) {
    say $fh_out '>', $seq_id;
    say $fh_out $aln_out{ $seq_id };
}

close $fh_out;
