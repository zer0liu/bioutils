#!/usr/bin/perl

=head1 NAME

    rnd_pick_seq.pl - Randomly pick sequences/reads from a huge FASTA file.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2016-01-11  Parsed by BioPerl
    0.0.2   2016-01-12  Parsed as text directly
    0.0.3   2021-01-14  Bug fix.

=cut

use 5.010;
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use List::Util qw/shuffle/;
use Switch;

use Smart::Comments;

my $usage = << "EOS";
Pick random sequences/reads from a huge FASTA file.
Usage:
  rnd_pick_seq.pl -i <file> [-f <format>]
                  [-n <num>|-c <percent>|-s <size>] 
                  [-o <file>]
Params:
  -i <file>     Input sequnece file.
  -f <format>   Input sequence format, 'fasta' or 'fastq'. 
                Optional. Default 'fasta'.
  -n <num>      Pick <num> number of sequences.
  -c <percent>  Pick <percent> of sequences.
                Unit %.
  -s <size>     Pick <size> of sequences.
                Size unit could be k|K, m|M or g|G.
  -o <file>     Output file. Optional.
Note:
  1. The parameters -n, -c and -s must choose one.
  2. For the percent, do NOT input '%'.
  3. For the size, if NO unit given, the size worked as it.
  4. Output file format is identical with input file format.
EOS

my ($fin, $fmt, $num, $pct, $size, $fout);

GetOptions(
    "i=s"   => \$fin,
    "f=s"   => \$fmt,
    "n=i"   => \$num,
    "c=i"   => \$pct,
    "s=s"   => \$size,
    "o=s"   => \$fout,
);

die $usage unless (defined $fin);

$fmt    = 'fasta' unless (defined $fmt);

die $usage unless ( defined $num || defined $pct || defined $size);

$fout   = genr_out_filename($fin, $fmt) unless (defined $fout);

# {{{ Ver 0.0.1

=pod

my $o_seqo  = Bio::SeqIO->new(
    -file   => ">$fout",
    -format => $fmt,
);

if (defined $num) {
    # Parse sequence file
    my ($rh_seqs, $total) = parse_seqfile($fin);

    say "Getting $num sequences ...";

    my @rnd_seqids  = (shuffle(1..$total+1))[0..$num];

    # Output 
    for my $seqid ( @rnd_seqids ) {
        $o_seqo->write_seq($rh_seqs->{ $seqid });
    }
}
elsif (defined $pct) {
    # Parse sequence file
    my ($rh_seqs, $total) = parse_seqfile($fin);

    # Get the number of sequences/reads to be picked    
    my $num = sprintf "%.0f", $total * $pct / 100;

    say "Getting $pct % ($num) sequences ...";

    my @rnd_seqids  = (shuffle(1..$total+1))[0..$num];

    # Output 
    for my $seqid ( @rnd_seqids ) {
        $o_seqo->write_seq($rh_seqs->{ $seqid });
    }
}
elsif (defined $size) {
    # Parse sequence file
    my ($rh_seqs, $total) = parse_seqfile($fin);

    # Convert size letter (K, M or G) into number
    my $size    = conv_size( $size );

    # Init random seqid list
    my @rnd_seqids  = shuffle(1..$total+1);

    # Output
    my $output_len  = 0; # Total length of output sequences

    for my $seqid ( @rnd_seqids ) {
        $o_seqo->write_seq( $rh_seqs->{ $seqid });

        $output_len  += $rh_seqs->{$seqid}->length;

        last if ($output_len >= $size);
    }
}
else {
    die "[ERROR] Input at least one of -n, -c or -s parameters!\n";
}

=cut

# }}} Ver 0.0.1

say "Calculating sequences/reads number ...";

my $total_num   = num_seqs($fin, $fmt);

say "Total $total_num sequences/reads.";

# Get the number of sequences to be get.
if (defined $num) {
    die "[ERROR] Not enough sequences/reads.\n
            Total:\t$total_num\n
            Need:\t$num\n"
        if ($num > $total_num);

    say "Getting $num sequences/reads ...";
}
elsif (defined $pct) {
    $num    = sprintf "%.0f", $total_num * $pct / 100;

    say "Getting $pct %, i.e., $num sequences/reads ...";
}
elsif (defined $size) {
    # Get the size of input file
    my $real_size   = conv_size($size);

    my $file_size   = -s $fin;

    die "[ERROR] Exceed the size of input file!\n
            File size:\t$file_size\n
            Need:\t$size ($real_size)\n"
        if ($real_size > $file_size);

    $num    = sprintf "%.0f", $total_num * $real_size / $file_size;

    say "Getting $size, i.e., $num sequences/reads ...";
}
else {
    warn "[ERROR] Unknown operation!\n
            Provide one of -n, -c or -s parameters.\n";
}

# Get randomized seqids
say "Generatiing random sequence ids ...";

my @rnd_seqids  = (shuffle(1..$total_num))[0..$num-1];

### @rnd_seqids

# Convert seqids array to a hash
my %pick_seqids;

for my $id ( @rnd_seqids) {
	$pick_seqids{$id}	= 1;
}

say "Getting sequences and creating output files ...";

if ($fmt eq 'fasta') {
	pick_fa_seqs($fin, $fout, \%pick_seqids);
}
elsif ($fmt eq 'fastq') {
	pick_fq_seqs($fin, $fout, \%pick_seqids);
}
else {
	die "[ERROR] Un-supported file format: '$fmt'\n";
}

say "Done.";

exit 0;

#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod
  Name  genr_out_filename($file, $fmt)
  Desc  Generate an output filename according to given filename.
  Args  $file   - A string.
        $fmt    - A string. Default 'fasta'.
  Ret   A string.
=cut

sub genr_out_filename {
    my ($file, $fmt)  = @_;

    return unless (defined $file);

    $fmt    = 'fasta' unless (defined $fmt);

    my ($basename, $dir, $siffix)   = fileparse($file, qr/\..*/);

    my $fout;   # Output file name

    if ($fmt eq 'fasta') {
        $fout   = $basename . '_sub.fa';
    }
    elsif ($fmt =~ /^fastq/) {
        $fout   = $basename . '_sub.fq'; 
    }
    else {
        $fout   = $basename . '_sub.txt';
    }

    return $fout;
}

=pod
  Name  conv_size($size)
  Desc  Convert size letter, k|K, m|M or g|G into number.
        Here
            1 k = 1000
            1 m = 1000000
            1 g = 1000000000
  Args  $size   - A string
  Ret   An integer.
=cut

sub conv_size {
    my ($str)   = @_;

    return unless (defined $str);

    ## $str

    my $size;

#    switch ($str) {
#        case /^\d+$/            { $size = sprintf("%d", $str) }
#        case /^(\d+)(?:k|K)$/   { $size = $1 * 1000 }
#        case /^(\d+)(?:m|M)$/   { $size = $1 * 1000000 }
#        case /^(\d+)(?:g|G)$/   { $size = $1 * 1000000000 }
#        else                    { die "[ERROR] Wrong size '$str'!\n" }
#    }

    if ($str =~ /^\d+$/) {
        $size   = sprintf "%d", $str;
    }
    elsif ($str =~ /^(\d+\.??\d*)(?:k|K)/) {
        $size   = $1 * 1000;
    }
    elsif ($str =~ /^(\d+\.??\d*)(?:m|M)/) {
        $size   = $1 * 1000000;
    }
    elsif ($str =~ /^(\d+\.??\d*)(?:g|G)/) {
        $size   = $1 * 1000000000;
    }
    else {
        die "[ERROR] Wrong size '$str'.\n"
    }

    return $size;
}

=pod
  Name  parse_seqfile($file, $fmt)
  Desc  Parse sequences/reads file
  Args  $file   - Input filename
        $fmt    - File format. Default 'fasta'.
  Ret   A hash reference
        Total number of sequences.
=cut

sub parse_seqfile {
    my ($fin, $fmt) = @_;

    return unless (defined $fin);

    $fmt    = 'fasta' unless (defined $fmt);

    say "Parsing sequence file in '$fmt' format ...";

    my $o_seqi;

    eval {
        $o_seqi = Bio::SeqIO->new(
            -file   => $fin,
            -format => $fmt,
        );   
    };

    if ($@) {
        die "[ERROR] Access '$fin' as '$fmt' failed!\n$!\n";
    }

    # A hash to store all sequences
    my %seqs;

    my $i   = 1;

    while (my $o_seq = $o_seqi->next_seq) {
        # $seqs{$i}->{'seq'}  = $o_seq;
        $seqs{ $i } = $o_seq;
        $i++;
    }

    return (\%seqs, $i);
}

=pod
  Name  num_seqs($fin, $fmt)
  Desc  Calculate the total number of sequences/reads.
  Args  $fin    - Input file name
        $fmt    - Input file format
  Ret   An integer
=cut

sub num_seqs {
    my ($fin, $fmt) = @_;

    open(my $fh_in, "<", $fin)
        or die "[ERROR] Open input file '$fin' failed!\n$!\n";

    # say "Calculating line number ...";

    my $num = 0;

    if ($fmt eq 'fasta') {
	    while (<$fh_in>) {
	        # next if /^\s*$/;    # Dismiss empty lines
	        # chomp;
	
            $num++ if /^>/;
	    }
    }
    elsif ($fmt eq 'fastq') {
        while (<$fh_in>) {
            # next if /^\s*$/;
            # chomp;

            $num++ if /^@/;
        }
    }
    else {
        die "[ERROR] Not supported file format: '$fmt'\n";
    }

    close $fh_in;

    # say "Total $num sequences/reads.";

    return $num;
}

=pod
  Name  pick_fa_seqs($fin, $fout, $rh_ids)
  Desc  Pick sequences in $rh_ids from $fin, output to $fout
  Args  $fin    - Input file name
        $fout   - Output file name
        $rh_ids   - A hash of sequence ids to be picked
  Ret   undef   - Any errors
=cut

sub pick_fa_seqs {
	my ($fin, $fout, $rh_ids)	= @_;
	
    my $num_output  = 0;

	# Open input file
	open my $fh_in, "<", $fin
		or die "[ERROR] Open input file '$fin' failed!\n$!\n";

	# Create output file handle
	open my $fh_out, ">", $fout
		or die "[ERROR] Create output file '$fout' failed!\n$!\n";

	# Previous sequence record
	#my $pre_seq		= '';
	
	# Current seqid
	my $cur_seqid	= 0;
	
	# Current sequence record
	my $cur_seq		= '';
	
	# FLAG, whether save to output file
	my $F_OUTPUT	= 0;
	
	# Main cycle
	while (<$fh_in>) {
		next if /^#/;		# Dismiss comment lines
		next if /^\s*$/;	# Dismiss empty lines

        # Here do NOT remove tailing "\n"
		
		if (/^>/) {	# FASTA head line
			if ($F_OUTPUT) {	# FLAG is SET, output record
				print $fh_out $cur_seq;

                $num_output++;
				
				$cur_seq	= '';	# Re-init current record
				
				$F_OUTPUT	= 0;	# Reset FLAG
			}
			
			$cur_seqid++;	# "$cur_seqid" always increasing
			
			if (defined $rh_ids->{$cur_seqid}) {
				$cur_seq	= $_;
				
				$F_OUTPUT	= 1;	# Set FLAG
			}
			else {
				# Do nothing
			}
		}
		else {
			if (defined $rh_ids->{$cur_seqid}) {
				$cur_seq	.= $_;	# Append current line to "$cur_seq"
			}
			else {
				# Do nothing
			}
		}
	}
	
	close $fh_in;

	close $fh_out;

    #say '---+> ', $num_output;
	
	return 1;
}

=pod
  Name	pick_fq_seqs($fin, $fout, $rh_ids)
  Desc	Pick sequences in $rh_ids from $fin, then output to $fout
  Args  $fin    - Input file name
        $fout   - Output file name
        $rh_ids   - A hash of sequence ids to be picked
  Ret   None
        undef   - Any errors
=cut

sub pick_fq_seqs {
	my ($fin, $fout, $rh_ids)	= @_;
	
	# Open input file
	open my $fh_in, "<", $fin
		or die "[ERROR] Open input file '$fin' failed!\n$!\n";

	# Create output file handle
	open my $fh_out, ">", $fout
		or die "[ERROR] Create output file '$fout' failed!\n$!\n";
	
	my $cur_seqid	= 0;
	
	my $cur_seq		= "";
	
	while (<$fh_in>) {
		next if /^#/;
		next if /^\s*$/;
		
		$cur_seqid++ if /^@/;
		
		if (defined $rh_ids->{$cur_seqid}) {
			my $fq_desc	= $_;
			my $fq_seq	= <$fh_in>;
			my $fq_opt	= <$fh_in>;
			my $fq_qual	= <$fh_in>;
			
			# Output
			print $fh_out $fq_desc, $fq_seq, $fq_opt, $fq_qual;
		}
		else {
			# Do nothing
		}
	}
	
	close $fh_in;

	close $fh_out;
	
	return 1;
}
