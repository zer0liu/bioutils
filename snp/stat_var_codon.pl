#!/usr/bin/perl

=head1 NAME

    stat_var_codon.pl - Statistics codon usage of given SNP sites.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-coom

=head1 VERSION

    0.0.1   2018-04-25
    0.1.0   2018-07-20  New feature: Wether output stable sites

=cut

use 5.010;
use strict;
use warnings;

use Bio::AlignIO;
use File::Basename;
use Getopt::Long;
use Smart::Comments;

#===========================================================
#
#                   Predefined data
#
#===========================================================

# Hash for codon to amino acids
my %codon2aa  = (
    TTT => "F", TTC => "F", TTA => "L", TTG => "L",
    TCT => "S", TCC => "S", TCA => "S", TCG => "S",
    TAT => "Y", TAC => "Y", TAA => "*", TAG => "*",
    TGT => "C", TGC => "C", TGA => "*", TGG => "W",
    CTT => "L", CTC => "L", CTA => "L", CTG => "L",
    CCT => "P", CCC => "P", CCA => "P", CCG => "P",
    CAT => "H", CAC => "H", CAA => "Q", CAG => "Q",
    CGT => "R", CGC => "R", CGA => "R", CGG => "R",
    ATT => "I", ATC => "I", ATA => "I", ATG => "M",
    ACT => "T", ACC => "T", ACA => "T", ACG => "T",
    AAT => "N", AAC => "N", AAA => "K", AAG => "K",
    AGT => "S", AGC => "S", AGA => "R", AGG => "R",
    GTT => "V", GTC => "V", GTA => "V", GTG => "V",
    GCT => "A", GCC => "A", GCA => "A", GCG => "A",
    GAT => "D", GAC => "D", GAA => "E", GAG => "E",
    GGT => "G", GGC => "G", GGA => "G", GGG => "G",
);

#===========================================================
#
#                   Main program
#
#===========================================================

my ($faln, $fregion, $fout, $F_var);

GetOptions(
    'a=s'   => \$faln,
    'r=s'   => \$fregion,
    'o=s'   => \$fout,
    'v'     => \$F_var,
    'h'     => sub { usage(); exit 1 },
);

unless (defined $faln) {
    warn "[ERROR] Alignment file is required!\n";
    usage();
    exit 1;
}

# Parse genome regions
unless (defined $fregion) {
    warn "[ERROR] Genome region file is required!\n";
    usage();
    exit 1;
}

my $ra_regions  = load_regions( $fregion );

unless (defined $fout) {
    $fout   = out_filename($faln);

    die '[ERROR] Failed to generate output filename!\n'
        unless ($fout);
}

my $o_alni  = Bio::AlignIO->new(
    -file   => $faln,
    -format => 'fasta',
);

# Assume there is only ONE alignment
my $o_aln   = $o_alni->next_aln;

# Check wether the alignment is flush, i.e., all of the same length
unless ( $o_aln->is_flush) {
    die "[ERROR] All sequences in the alignment are NOT the same length!\n";
}

my $aln_len = $o_aln->length;

# Ordered sequence ids
my $ra_seqids   = get_seqids( $o_aln );

# Discard the first, i.e., reference, sequence
shift @{ $ra_seqids };

# Get all/variation sites information
say "[Note] Analysing variation sites ...";
my $rh_sites    = get_vsites($o_aln);

# Then output variation sites to a file 'vsites.txt'
say "[NOTE] Output variation sites to file 'vsites.txt.'";
out_vsites($rh_sites, "vsites.txt");

# Get all sequences in the alignment
my @o_seqs  = $o_aln->each_seq();

# First sequence in alignment as the Reference
# This sequence is REMOVED from result
my $o_refseq    = shift @o_seqs;

# Parse reference region information
my $rh_ref_regions  = parse_regions($o_refseq->seq, $ra_regions);
my @ref_sites       = split //, $o_refseq->seq;

my %result;

# Traverse all of the rest sequences
for my $o_seq ( @o_seqs ) {
    my $seq_id  = $o_seq->id;
    my $seq     = $o_seq->seq;

    my @seq_sites   = split //, $seq;

    $result{$seq_id}    //= '';

    my $rh_seq_regions  = parse_regions($seq);

    # Traverse all sites/locations of the seq in $rh_sites
    # for my $loc (sort {$a<=>$b} keys %{ $rh_sites } ) {

    for my $loc_idx (0 .. $aln_len-1) {
        if ($seq_sites[$loc_idx] eq '-') { # A gap ('-')
            $result{$seq_id}    .= ',-';
            next;
        }
        elsif ( $seq_sites[$loc_idx] eq $ref_sites[$loc_idx] ) {# Base not changed 
            if ($F_var) {   # Only output variation sites
                next;
            }
            else {          # Output all sites
                $result{$seq_id}    .= ',a';
                next;
            }
        }
        else {  # A variation site
            my $site_type;  # 1-char site type: u, s, n, i

            # Traverse regions to locate site
            for my $region (sort {$a<=>$b} %{ $rh_seq_regions }) {
                my $region_start    
                    = $rh_seq_regions->{$region}->{start};
                my $region_end
                    = $rh_seq_regions->{$region}->{end};
                my $region_type
                    = $rh_seq_regions->{$region}->{type};

                # Real location of this site, which is greater than
                # $loc_idx 1
                my $loc = $loc_idx + 1;

                if ($loc >= $region_start and $loc <= $region_end ) {
                    if ($region_type eq 'UTR') {    # UTR
                        $site_type  = 'u';
                    }
                    elsif ($region_type eq 'Inter-gene') {  # Inter
                        $site_type  = 'i';
                    }
                    elsif ($region_type eq 'CDS') { # CDS
                        my $cur_aa      
                            = $rh_seq_regions->{$region}->{aa};
                        my $cur_codon   
                            = $rh_seq_regions->{$region}->{codon};

                        my $ref_aa      
                            = $rh_ref_regions->{$region}->{aa};
                        my $ref_codon   
                            = $rh_ref_regions->{$region}->{codon};

                        # Synonymous/Non-synonymous
                        if ($cur_aa eq $ref_aa) {
                            $site_type  = 's';
                        }
                        else {
                            $site_type  = 'n';
                        }
                    }
                    else {
                        warn "[ERROR] Unknown region type: '", 
                            $region->{type}, "' on region '",
                            $region, "of location '",
                            $loc, "'\n";
                    }

                    last;   # Break cycle
                }
            }

            $result{$seq_id}    = $result{$seq_id} . ',' . $site_type;
        }
    }
}

## %result

# Output result to result file
open my $fh_out, ">", $fout or
    die "[ERROR] Create output file '$fout' failed!\n$!\n";

# Output file header
say $fh_out join "\t", qw(Strain Location Value);

#for my $seq_id ( sort keys %result ) {
for my $seq_id ( @{ $ra_seqids } ) {
    my $site_str    = $result{$seq_id};
    $site_str       =~ s/^,//;  # Remove possilbe leading ','

    #say $fh_out $seq_id, ',', $site_str;
    my @sites   = split /,/, $site_str;

    my $loc     = 1;

    for my $type ( @sites ) {
        say $fh_out join "\t", ($seq_id, $loc, $type);
        $loc++;
    }
}

close $fh_out;

say "[Done]";

exit 0;

#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod
  Name:     usage
  Function: Display usage information.
  Usage:    usage()
  Args:
  Return:   None
=cut

sub usage {
say << "EOS";
stat_var_codon.pl -a <faln> -r <fregion> [-o <fout>] [-v]
Args:
  -a <faln>     Alignment file. FASTA format.
  -r <fregion>  CDS region file.
  -o <fout>     Output filename. Optional.
  -v            Output variation sites only. Optional.
                Default output all sites.
Note:
  1. The First sequence of the Alignment was used as the Reference 
     sequence. And it will NOT be present in result.
  2. Genome region file is a Tab-delimited text file. Format:
     <Region>   <Start> <End>
  3. Double-Check CDS ranges first!
  4. Output characters:
    "u"  UTR, 5' and 3'
	"s"  Synonynous mutation in CDS region
	"n"  Non-synonymous mutation in CDS region
	"i"  Inter-gene region
	"a"  Stable/unchanged sites.
  5. Works on single stranded virus only.
EOS

}

=pod
  Name:     out_filename
  Function: Generate output filename according to given input filename
  Usage:    out_filename($fin)
  Args:     A string
  Return:   A string
=cut

sub out_filename {
    my ($fin)   = (@_);
    my ($basename, $dir, $suffix)   = fileparse($fin, qr/\..*$/);
    if ($basename) {
        my $fout    = $basename . '_var.txt';

        return $fout;
    }
    else {
        return;
    }
}

=pod

  Name:     get_seqids
  Usage:    get_seqids($o_aln)
  Function: Get sequence ids of alignment
  Args:     A Bio::SimpleAlign object
  Return:   A reference of array

=cut

sub get_seqids {
    my ($o_aln) = @_;

    my @seq_ids;

    for my $o_seq ( $o_aln->each_seq ) {
        push @seq_ids, $o_seq->id;
    }

    return \@seq_ids;
}

=pod

  Name:     load_regions
  Usage:    load_regions($fregion)
  Function: Load genome region information
  Args:     Region file name. A string.
  Return:   A reference of array
            undef for all errors.
=cut

## For NDV Type II, ref AY562991
#my @regions = (
#    { name => "5UTR",    start => 1,     end => 121 },
#    { name => "N",       start => 122,   end => 1591 },
#    { name => "Int1",    start => 1592,  end => 1886 },
#    { name => "P",       start => 1887,  end => 3074 },
#    { name => "Int2",    start => 3075,  end => 3289 },
#    { name => "M",       start => 3290,  end => 4384 },
#    { name => "Int3",    start => 4385,  end => 4543 },
#    { name => "F",       start => 4544,  end => 6205 },
#    { name => "Int4",    start => 6206,  end => 6411 },
#    { name => "HN",      start => 6412,  end => 8262 },
#    { name => "Int5",    start => 8263,  end => 8380 },
#    { name => "L",       start => 8381,  end => 14995 },
#    { name => "3UTR",    start => 14996, end => 15186 },
#);

sub load_regions {
    my ($fregion)   = @_;

    open my $fh_region, "<", $fregion
        or die "[ERROR] Open region file '$fregion' failed!\n$!\n";

    my @regions;

    while (<$fh_region>) {
        next if /^#/;
        next if /^\s*$/;
        chomp();

        my ($name, $start, $end)  = split /\t/;

        my %region;

        $region{'name'}     = $name;
        $region{'start'}    = $start;
        $region{'end'}      = $end;

        push @regions, \%region;
    }

    close $fh_region;

    return \@regions;
}

=pod 
  Name:     get_vsites
  Function: Parse alignment and return SNP/variatin site locations
  Usage:    get_snp_sites($o_aln)
  Args:     A Bio::SimpleAlign object
  Return:   An reference of hash for whole information of SNPs.
            (
                $location => {
                    isVar   => 1,   # Bool
                    items   => {    # Number of each items
                        A       => 1,
                        C       => 5,
                        ...
                    },
                }
            )
=cut

sub get_vsites {
    my ($o_aln)    = (@_);

    # Array to store SNP sites
    my @snp_sites;

    # Alignment length
    my $aln_len = $o_aln->length;

    ## $aln_len

    my %sites;

    for my $i (1..$aln_len) {
        my $o_slice_aln = $o_aln->slice($i, $i, 1); # 1-nt slice

        my %items;

        for my $o_seq ($o_slice_aln->each_seq) {
            my $item    = $o_seq->seq;
            next if ($item eq '-'); # Dismiss gaps ('-')

            $items{$item} = (defined $items{$item}) ?
                $items{$item} + 1 : 1;
        }
        
        ## %items

        if ( scalar (keys %items) >=2 ) {
            $sites{$i}->{'isVar'}   = 1;    # Variation site
            $sites{$i}->{'items'}   = \%items;
        }
        else {
            $sites{$i}->{'isVar'}   = 0;    # Stable site
            $sites{$i}->{'items'}   = \%items;
        }

    }

    ## %sites

    return \%sites;
}

=pod
  Name:     out_vsites
  Function: Output SNP/variation sites to a file
  Usage:    out_vsites{$rh_sites, $fout}
  Args:     $rh_sites   - A hash reference to all sites
            $fout       - A string, for output filename
  Return:   None
=cut

sub out_vsites {
    my ($rh_sites, $fout)  = @_;

    open my $fh_out, ">", $fout
        or return;

    for my $loc ( sort {$a<=>$b} keys %{ $rh_sites } ) {
        # Dismiss stable sites
        next unless ( $rh_sites->{$loc}->{'isVar'});

        print $fh_out $loc;

        while ( my ($k, $v) = each %{$rh_sites->{$loc}->{'items'}} ) {
            print $fh_out "\t", $v, $k;
        }

        print $fh_out "\n";
    }

    close $fh_out;
}

=pod
  Name:     parse_regions
  Function: Parse regions of a genome, mark 
  Usage:    parse_regions($seq, $ra_regions)
  Args:     $seq        - A string, genome sequence
            $ra_regions - A hash reference, for predefined %regions
  Return:   A reference of a hash
            {
                1    => {
                    region  => '5UTR',   
                    start   => 1,
                    end     => 121,
                },
                2      => {
                    region  => 'N',
                    start   => 122,
                    end     => 124,
                    codon   => 'ATG',
                    aa      => 'M',
                },
                ...
            }
=cut

sub parse_regions {
    # Here access the public hash %regions
    my ($seq, $ra_regions)  = @_;

    my %region_detail;
    my $id  = 1;    # Region ID, serial, start from 1.

    # for my $region ( keys %regions ) {
    for my $region ( @{ $ra_regions }) {
        if ($region->{name} =~ /UTR/) {    # UTR and Inter-gene regions
            $region_detail{$id}->{region}   = $region->{name};
            $region_detail{$id}->{start}    
                = $region->{start};
            $region_detail{$id}->{end}
                = $region->{end};
            $region_detail{$id}->{type} = "UTR";

            $id++;
        }
        elsif ($region->{name} =~ /Int/) {    # UTR and Inter-gene regions
            $region_detail{$id}->{region}   = $region->{name};
            $region_detail{$id}->{start}    
                = $region->{start};
            $region_detail{$id}->{end}
                = $region->{end};
            $region_detail{$id}->{type} = "Inter-gene";

            $id++;
        }
        else {  # CDS regions, use each CODON as a region
            my $cds_start   = $region->{start};
            my $cds_end     = $region->{end};

            my $cds_seq     = substr(
                $seq,
                $cds_start - 1,
                $cds_end - $cds_start + 1
            );

            die "[ERROR] CDS leng is NOT 3-folds on ", $region->{name}
                if (length($cds_seq) % 3);

            my @codons   = unpack("(A3)*", $cds_seq);
            
            my $num_cds = 0;

            for my $codon ( @codons ) {
                $region_detail{$id}->{region}   = $region->{name};
                $region_detail{$id}->{start}    
                    = $cds_start + $num_cds * 3;
                $region_detail{$id}->{end}
                    = $cds_start + $num_cds * 3 + 2;
                $region_detail{$id}->{codon}    = $codon;
                $region_detail{$id}->{aa}       = $codon2aa{$codon};
                $region_detail{$id}->{type} = "CDS";

                $id++;
                $num_cds++;
            }
        }
    }

    ## %region_detail

    return \%region_detail;
}
