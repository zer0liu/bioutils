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
    0.1.1   2018-07-20  Add progress bar.
    0.2.0   2018-12-20  Deal with degenerate codon.
    0.2.1   2020-02-19  Deal with base 'N' in alignment.
    0.2.2   2020-02-19  Convert sequences in alignment to uppercase first.
    0.3.0   2020-03-12  New region file format.
    0.3.1   2020-03-15  Output region name of variation site.
    0.4.0   2023-07-09  Add note: Remove 'N's in aligned sequences first, 
                        to avoid synonymous/non-synonymous analysis errors.
=cut

use 5.010;
use strict;
use warnings;

use Bio::AlignIO;
use File::Basename;
use Getopt::Long;
use Smart::Comments;
use Switch;
use Term::ProgressBar;

#===========================================================
#
#                   Main program
#
#===========================================================

my ($faln, $fregion, $fout, $F_var, $F_noN);

GetOptions(
    'a=s'   => \$faln,          # Input alignment file
    'r=s'   => \$fregion,       # Input region file
    'o=s'   => \$fout,          # Output files basename
    'v'     => \$F_var,         # Flag, whether output variation sites only
    'N'     => \$F_noN,         # Flag, whether dismiss N in sequence
    'h'     => sub { usage(); exit 1 },
);

## $F_var

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

## $ra_regions

# Parse output file basename if necessary
unless (defined $fout) {
    $fout   = out_filename($faln);

    die '[ERROR] Failed to generate output filename!\n'
        unless ($fout);
}

# Output variation filename
my $fout_var     = $fout . '_var.txt';

# Output variation sites name
my $fout_vsites  = $fout . '_vsites.txt';

my $o_alni  = Bio::AlignIO->new(
    -file   => $faln,
    -format => 'fasta',
);

# Assume there is only ONE alignment, which contains multiple sequences
my $o_aln   = $o_alni->next_aln;

# Check wether the alignment is flush, i.e., all of the same length
unless ( $o_aln->is_flush) {
    die "[ERROR] All sequences in the alignment are NOT the same length!\n";
}

# Set all the sequences in alignment to UPPER case
unless ($o_aln->uppercase) {
    die "[ERROR] Convert sequences to uppercase failed!\n";
}

my $aln_len = $o_aln->length;

# Get ordered sequence ids
my $ra_seqids   = get_seqids( $o_aln );

# Discard the first, i.e., reference, sequence
shift @{ $ra_seqids };

# Traverse each site/column of the alignment to find out 
# stable and variation sites 
say "[NOTE] Analysing variation sites ...";

my $rh_all_sites    = parse_sites($o_aln);

# Location of stable sites
my $rh_stable_sites   = get_stable_sites($rh_all_sites);

# Then output variation sites to a file 'vsites.txt'
say "[NOTE] Output variation sites to file '$fout_vsites'.";

out_vsites($rh_all_sites, $ra_regions, $fout_vsites);

# Get all sequences in the alignment
my @o_seqs  = $o_aln->each_seq();

# First sequence in alignment as the Reference
# This sequence is REMOVED from result
my $o_refseq    = shift @o_seqs;

say "[NOTE] Parsing variation status of each site in each sequence ...";

# Parse reference region information
my $rh_ref_regions  = parse_regions($o_refseq->seq, $ ra_regions);
my @ref_sites       = split //, $o_refseq->seq;

my %result;

# Launch a progress bar
my $prog_bar_var    = 0;
my $prog_bar_max    = scalar( @o_seqs );

my $prog_bar    = Term::ProgressBar->new({
    name    => 'Sequence:',
    count   => $prog_bar_max,
    ETA     => 'linear',
});

# Traverse all sequences in alignment, except the reference (1st) sequence
for my $o_seq ( @o_seqs ) {
    my $seq_id  = $o_seq->id;
    my $seq     = $o_seq->seq;

    my @seq_sites   = split //, $seq;

    $result{$seq_id}    = '';

    my $rh_seq_regions  = parse_regions($seq, $ra_regions);
    
    ## $rh_seq_regions

    # Traverse all sites/locations of the seq in $rh_sites
    # for my $loc (sort {$a<=>$b} keys %{ $rh_sites } ) {

    for my $loc_idx (0 .. $aln_len-1) {
        my $cur_loc = $loc_idx + 1;
        
        # If output variation sites ONLY
        next if ($F_var and $rh_stable_sites->{$cur_loc});
        
        if ($seq_sites[$loc_idx] eq '-') { # A gap ('-')
            $result{$seq_id}    .= ',-';
            next;
        }
        elsif ( $seq_sites[$loc_idx] eq $ref_sites[$loc_idx] ) {# Base not changed 
            $result{$seq_id}    .= ',a';
            next;
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
                    elsif ($region_type eq 'IGR') {  # Inter
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
                            #$region->{type}, "' on region '",
                            $region_type, "' on region '",
                            $region, "of location '",
                            $loc, "'\n";
                    }

                    last;   # Break cycle
                }
                ## $site_type
            }

            $result{$seq_id}    = $result{$seq_id} . ',' . $site_type;
        }
    }
    
    $prog_bar->update( $prog_bar_var );
    $prog_bar_var++;
}

$prog_bar->update($prog_bar_max);

## %result
say "[NOTE] Output result file '$fout_var' ...\n";

# Output result to result file
open my $fh_out, ">", $fout_var or
    die "[ERROR] Create output file '$fout_var' failed!\n$!\n";

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
  -o <fout>     Output files basename. Optional.
  -v            Output variation sites only. Optional.
                Default output all sites.
  -N            Base 'N' is not considered as a variation. Optional.
                Default 'N' is considered as a normal base.
Note:
  0. !!IMPORTANT!! Replace all 'N' or 'n' with '-' before use!
  1. The First sequence of the Alignment was used as the Reference 
     sequence. And it will NOT be present in result.
  2. Genome region file is a Tab-delimited text file. 
     See *regions.template* file for more details.
  3. Be sure to Double-Check CDS ranges first!
  4. Output characters:
      "u"  UTR, 5' and 3'
      "s"  Synonynous mutation in CDS region
      "n"  Non-synonymous mutation in CDS region
	    "i"  Inter-gene region
	    "a"  Stable/unchanged sites.
  5. Works on single stranded virus only.
  6. Degenerate codon accepted.
  7. If output file basename not provided, will generate one according to
     input alignment filename.
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
  Name:     out_basename
  Function: Generate output file basename according to given input filename
  Usage:    out_filename($fin)
  Args:     A string
  Return:   A string
=cut

sub out_filename {
    my ($fin)   = (@_);
    my ($basename, $dir, $suffix)   = fileparse($fin, qr/\..*$/);

    if ($basename) {
        return $basename;
    }
    else {
        return "";
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
  Note:     It assumes the regions in the file would be at the genome order.

=cut

## For NDV Type II, ref AY562991
#my @regions = (
#    { name => "5UTR",    type => 'UTR',    start => 1,     end => 121 },
#    { name => "N",       type => 'CDS',    start => 122,   end => 1591 },
#    { name => "Int1",    type => 'IGR',    start => 1592,  end => 1886 },
#    { name => "P",       type => 'CDS',    start => 1887,  end => 3074 },
#    { name => "Int2",    type => 'IGR',    start => 3075,  end => 3289 },
#    { name => "M",       type => 'CDS',    start => 3290,  end => 4384 },
#    { name => "Int3",    type => 'IGR',    start => 4385,  end => 4543 },
#    { name => "F",       type => 'CDS',    start => 4544,  end => 6205 },
#    { name => "Int4",    type => 'IGR',    start => 6206,  end => 6411 },
#    { name => "HN",      type => 'CDS',    start => 6412,  end => 8262 },
#    { name => "Int5",    type => 'IGR',    start => 8263,  end => 8380 },
#    { name => "L",       type => 'CDS',    start => 8381,  end => 14995 },
#    { name => "3UTR",    type => 'UTR',    start => 14996, end => 15186 },
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

        my ($name, $type, $start, $end)  = split /\s+/;

        my %region;

        $region{'name'}     = $name;
        $region{'type'}     = $type;
        $region{'start'}    = $start;
        $region{'end'}      = $end;

        push @regions, \%region;
    }

    close $fh_region;

    return \@regions;
}

=pod 
  Name:     parse_sites
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

sub parse_sites {
    my ($o_aln)    = (@_);

    # Array to store SNP sites
    my @snp_sites;

    # Alignment length
    my $aln_len = $o_aln->length;

    my $prog_bar    = Term::ProgressBar->new({
        name    => 'Sites:',
        count   => $aln_len,
        ETA     => 'linear',
    });

    my %sites;

    for my $i (1..$aln_len) {
        # Get a 1-nt slice of alignment
        my $o_slice_aln = $o_aln->slice($i, $i, 1); 

        my %items;

        for my $o_seq ($o_slice_aln->each_seq) {
            my $item    = $o_seq->seq;

            # Gap ('-') is NOT looked as variation 
            next if ($item eq '-'); 

            # Base 'N' is Not looked as a variation if '-N' option is *set*
            next if ( (defined $F_noN) && ($item eq 'N') ); 

            # Also calculate the number of item
            $items{$item} = ( defined $items{$item} ) ?
                ( $items{$item} + 1 ) : 1;
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
        
        $prog_bar->update($_);
    }

    $prog_bar->update($aln_len);
    ## %sites

    return \%sites;
}

=pod

  Name:     get_stable_sites
  Function: Get location of stable sites.
  Usage:    get_stable_sites($rh_sites)
  Args:     $rh_sites   - A hash reference of all sites
  Return:   A reference of hash.
            $rh = {
                $location   => 1,
            }
  
=cut

sub get_stable_sites {
    my ($rh_sites)  = @_;
    
    my %stable_sites;
    
    for my $loc ( sort {$a<=>$b} keys %{ $rh_sites } ) {
        # Dismiss stable sites
        next if ( $rh_sites->{$loc}->{'isVar'} );

        $stable_sites{$loc}   = 1;
    }
    
    return \%stable_sites;
}

=pod
  Name:     region4site
  Function: Find out the region name of a given site location
  Usage:    region4site($loc, $ra_regions)
  Args:     $loc        - Location (integer) of a site
            $ra_regions - A reference to an array of region information
=cut 

sub region4site {
    my ($loc, $ra_regs) = @_;

    for my $rh_reg ( @{ $ra_regs } ) {
        return $rh_reg->{'name'}
            if ( $loc >= $rh_reg->{'start'} && $loc <= $rh_reg->{'end'} );
    }

    return;
}

=pod
  Name:     out_vsites
  Function: Output SNP/variation sites to a file
  Usage:    out_vsites{$rh_sites, $ra_regs, $fout}
  Args:     $rh_sites   - A hash reference to all sites
            $ra_regs    - An array reference for all regions
            $fout       - A string, for output filename
  Return:   None
=cut

sub out_vsites {
    my ($rh_sites, $ra_regs, $fout)  = @_;

    open my $fh_out, ">", $fout
        or return;

    # Output heading
    say $fh_out join("\t", qw(#Location Region SNP));

    for my $loc ( sort {$a<=>$b} keys %{ $rh_sites } ) {
        # Dismiss stable sites
        next unless ( $rh_sites->{$loc}->{'isVar'});

        print $fh_out $loc, "\t";

        # Get and output related region name
        my $rel_region_name = region4site($loc, $ra_regs);

        print $fh_out $rel_region_name, "\t";

        my $snp_info    = '';

        for my $nt ( sort keys %{$rh_sites->{$loc}->{'items'}} ) {
            #print $fh_out "\t", $rh_sites->{$loc}->{'items'}->{$nt}, $nt;
            my $num_nt  = $rh_sites->{$loc}->{'items'}->{$nt};
            $snp_info   = $snp_info . $num_nt . $nt . ', ';
        }
        
        $snp_info   =~ s/, $//;

        print $fh_out $snp_info, "\n";
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
                    type    => 'UTR',
                    start   => 1,
                    end     => 121,
                },
                2      => {
                    region  => 'N',
                    type    => 'CDS',
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
        if ($region->{type} eq 'UTR') {    # UTR 
            $region_detail{$id}->{region}   = $region->{name};
            $region_detail{$id}->{start}    
                = $region->{start};
            $region_detail{$id}->{end}
                = $region->{end};
            $region_detail{$id}->{type} = "UTR";

            $id++;
        }
        elsif ($region->{type} eq 'IGR') {    # Intergenic Region
            $region_detail{$id}->{region}   = $region->{name};
            $region_detail{$id}->{start}    
                = $region->{start};
            $region_detail{$id}->{end}
                = $region->{end};
            $region_detail{$id}->{type} = "IGR";

            $id++;
        }
        elsif ($region->{type} eq 'CDS') {  # CDS regions, use each CODON as a region
            my $cds_start   = $region->{start};
            my $cds_end     = $region->{end};

            my $cds_seq     = substr(
                $seq,
                $cds_start - 1,
                $cds_end - $cds_start + 1
            );

            die "[ERROR] CDS leng is NOT 3-folds on CDS '", $region->{name}, "' with length ", 
                    length($cds_seq), "nt.\n"
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
                # $region_detail{$id}->{aa}       = $codon2aa{$codon};
                $region_detail{$id}->{aa}       = degnr_codon2aa($codon);
                $region_detail{$id}->{type} = "CDS";

                $id++;
                $num_cds++;
            }
        }
        else {
            warn "[ERROR] Unidentified region type: ", $region->{type}, "\n";
        }
    }

    ## %region_detail

    return \%region_detail;
}

=pod

  Name:     degnr_codon2aa
  Usage:    degnr_codon2aa( $codon )
  Function: Convert degenerated codon to related single-character
            amino acid
  Args:     A string
  Return:   A character
            undef for all errors

=cut

sub degnr_codon2aa {
    my ($codon) = @_;

    switch ( $codon ) {
        case /GC./              { return 'A' }
        case /CG.|AG(?:A|G|R)/  { return 'R' }
        case /AA(?:T|C|Y)/      { return 'N' }
        case /GA(?:T|C|Y)/      { return 'D' }
        case /TG(?:T|C|Y)/      { return 'C' }
        case /CA(?:A|G|R)/      { return 'Q' }
        case /GA(?:A|G|R)/      { return 'E' }
        case /GG./              { return 'G' }
        case /CA(?:T|C|Y)/      { return 'H' }
        case /AT(?:T|C|A|H)/    { return 'I' }
        case /ATG/              { return 'M' }
        case /TT(?:A|G|R)|CT./  { return 'L' }
        case /AA(?:A|G|R)/      { return 'K' }
        case /TT(?:T|C|Y)/      { return 'F' }
        case /CC./              { return 'P' }
        case /TC.|AG(?:T|C|Y)/  { return 'S' }
        case /AC./              { return 'T' }
        case /TGG/              { return 'W' }
        case /TA(?:T|C|Y)/      { return 'Y' }
        case /GT./              { return 'V' }
        case /TAA|TGA|TAG/      { return '*' }
        else                    { return 'X' }
    }
}

