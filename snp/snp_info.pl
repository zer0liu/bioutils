#!/usr/bin/perl

=head1 NAME

    snp_info.pl - Statistics and show SNP information of an alignment.

=SYNOPSIS

=DESCRIPTION

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   2019-01-07
    0.1.0   2021-05-17

=cut

use 5.12.1;
use strict;
use warnings;

use Bio::AlignIO;
use Bio::SeqIO;
use Getopt::Long;
use Scalar::Util qw(blessed);
use Smart::Comments;

my ($faln, $fmt, $fref, $fout);

$fmt    = 'fasta';  # Default format value

GetOptions(
    'i=s'   => \$faln,
    'f=s'   => \$fmt,
    'r=s'   => \$fref,
    'o=s'   => \$fout,
    'h'     => \&usage,
);

unless ($faln)  {
    warn "[ERROR] Input alignemt file is required!\n";
    usage();
    die;
}

if (defined $fref) {
    if (check_gbk_file($fref)   == 1) {
        say "[OK] Reference annotation file ok.";
    }
    else {
        warn "[ERROR] Input file '$fref' is NOT a GenBank flat file!\n";
        warn "Consider to re-run script without reference genome.\n";
        exit 1;
    }
}

# Parse gene/CDS name and range(s)
my $rh_gene_loc = parse_gbk_feature($fref);

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
Show SNP information of an alignment and their location in ORFs.
Usage:
  snp_info.pl -i <faln> -f <format> [-r <fref>] [-o <fout>]
Args:
  -i <faln>     Input alignment file.
  -f <format>   Alignment file format. Default: fasta.
                Optional.
  -r <fref>     Reference file, in Genbank flat file format.
                Optional.
  -o <fout>     Output text file.
                Optional.
Note:
  1. The first sequence of the alignment file would be used as the
     reference of the whole alignment.
  2. It will out put two SNP locations, one based on the alignment, 
     the other on the reference sequence.
  3. The <fref> file contains the annotation in GenBank flat file format
     of the first sequence of the alignment file.
  4. The range(s) of a gene/CDS was retrieved from "CDS" primary tag.
EOS
}

=pod

  Name:     parse_gbk_feature
  Usage:    parse_gbk_feature($fgbk)
  Function: Parse feature table of given GenBank flat file, return
            gene/CDS name and range.
  Args:     A GenBank flat file name.
  Returns:  A reference of a hash.
            undef - Any errors.

=cut

sub parse_gbk_feature {
    my ($fgbk)  = @_;

    my $o_seqi  = Bio::SeqIO->new(
        -file   => $fgbk,
        -format => 'genbank'
    );

    my $o_seq   = $o_seqi->next_seq;

    my %gene_locs;

    for my $o_feat ($o_seq->get_SeqFeatures) {
        if ($o_feat->primary_tag eq 'CDS') {
            my ($gene, $range);

            # Get 'gene'
            if ($o_feat->has_tag('gene')) {
                ($gene,)    = $o_feat->get_tag_values('gene');
            }
            # Use 'product' to represent 'gene'
            elsif ($o_feat->has_tag('product')) {  
                ($gene, )   = $o_feat->get_tag_values('product');
            }
            else {
                warn "[ERROR] Unable to identify gene/CDS name!\n";
                $gene   = 'Unknown';
            }

            # Get range

            # say "[TEST] ", $o_feat->location->to_FTstring;

=pod {{{
            if ($o_feat->location->isa('Bio::Location::Simple')) {
                $range  = $o_feat->location->start . '..' .
                    $o_feat->location->end;
            }
            elsif ($o_feat->location->isa('Bio::Location::Split')) {
                for my $location ($o_feat->location->sub_Location) {
                    $range  .= ',' if (defined $range);
                    $range  .= $location->start . '..' . $location->end;
                }
            }
            elsif ($o_feat->location->isa('Bio::Location::Fussy')) {
                #
            }
            elsif ($o_feat->location->isa('Bio::Location::Atomic')) {
                #
            }
            else {
                warn "[ERROR] Unidentified BioPerl Location object: '",
                    blessed( $o_feat->location ), "' on gene/CDS '" ,
                    $gene, "'\n";
            }
=cut }}}

            my $loc_str = $o_feat->location->to_FTstring;
            
            # 'complement' field, for future use
            if ($loc_str =~ /complement/) {
                $gene_locs{ $gene }->{ 'complement' }   = 1;
            }
            else {
                $gene_locs{ $gene }->{ 'complement' }   = 0;
            }

            # 'join' field, for future use
            if ($loc_str =~ /join/) {
                $gene_locs{ $gene }->{ 'join' } = 1;
            }
            else {
                $gene_locs{ $gene }->{ 'join' } = 0;
            }


            # 'range' field, store locations ONLY
            if ($loc_str =~ /([\d\.\,\s]+)/) {
                $gene_locs{ $gene }->{ 'range' }    = $1;
            }
            else {
                warn "[ERROR] Unidentified range: '", $loc_str, "'\n";
                $gene_locs{ $gene }->{ 'range' }    = undef;
            }
        }
    }

    ## %gene_locs

    return \%gene_locs;
}

=pod

  Name:     check_gbk_file
  Usage:    check_gbk_file($fgbk)
  Function: Check wether a file is in GenBank flat file format.
            It checks the starting 'LOCUS' and ending '//'.
  Args:     A file name.
  Returns:  1   - Is a GenBank flat file.
            0   - Not.

=cut

sub check_gbk_file {
    my ($fgbk)  = @_;

    my ($F_start, $F_end)   = (0, 0);

    open my $fh_in, "<", $fgbk;

    while (<$fh_in>) {
        next if /^#/;
        next if /^\s*$/;
        chomp;

        $F_start++ if /^LOCUS/; # Starting with 'LOCUS'
        $F_end++ if /\/\//;     # Ending with '//'
    }

    if ($F_start > 0 and $F_end > 0 and $F_start == $F_end) {
        return 1;   # Probably a (multiple) GenBank flat file
    }
    else {
        return 0;   # Not a (multiple) GenBank flat file
    }
}

=pod

  Name:     parse_aln
  Usage:    parse_aln( $faln )
  Function: Parse alignment file
  Args:     A string for alignment file
  Returns:  A referene of hash for nucleotide compsitions in each site.
            {
                $location   => {
                    isVar   => 1,   # BOOL, 
                    items   => {
                        A   => 1,
                        C   => 5,
                        G   => 3,
                        T   => 7,
                        ...
                    },
                },
            }
  Note:     It assumes there is ONLY one alignemt in the file.

=cut

sub parse_aln {
    my ($faln, $fmt)  = @_;

    my $o_alni  = Bio::SeqIO->new(
        -file   => $faln,
        -format => $fmt,
    );

    my $o_aln   = $o_alni->next_aln;

    my $aln_len = $o_aln->length;

    my %sites;

    for my $i (1 .. $aln_len)   {   # Aligment starts from '1'
        my $o_aln_slice = $o_aln->slice($i, $i, 1);

        my %items;

        for my $o_seq ($o_aln_slice->each_seq)  {
            my $item    = $o_seq->seq;  # Get single characters

            # Here works on any characters, including '-'

            $items{ $item } = ( defined $items{ $item } ) ?
                $items{ $item } + 1 : 1;

            if ( scalar ( keys %items ) >= 2 ) {
                $sites{ $i }->{ 'isVar' }   = 1;    # is variation site
                $sites{ $i }->{ 'items' }   = \%items;
            }
            else {
                $sites{ $i }->{ 'isVar' }   = 0;    # Stable site
                $sites{ $i }->{ 'items' }   = \%items;
            }
        }
    }

    return \%sites;
}

=pod

  Name:     parse_snps
  Usage:    parse_snps($rh_site, )
  Function: Parse SNP sites and related information
  Args:     $rh_site - Reference of hash for each site information
            $rh_feat - Reference of hash for 

=cut
