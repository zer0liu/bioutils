#!/usr/bin/perl

=head1 NAME
  
  aln2nex.pl - Convert alignment files to PHYLIP sequential format.

=head1 DESCRIPTION

  Most alignment files could be converted easily by Bioperl except
  the PHYLIP sequential format alignment file.

  Here a subroutine "phys2nex" was created to fulfill this job.

=head2 PHYLIP sequential format

  The PHYLIP sequential format file could be:

=over 4

=item * Type I

<seq id> and <seq string> were seperated by white spaces

=begin text

<seq num> <aln length>
<seq id> <seq string>
...

=end text

  or

=item * Type II

<seq id> and <seq string> were seperated by an new line ("\n")

=begin text

<seq num> <aln length>
<seq id>
<seq string>
...

=end text

=back

=head2

=head2 NOTE

Here assumed that there were NO white spaces in the sequence names of the
PHYLIP sequencial file.

=head1 AUTHORS

  zeroliu-at-gmail-dot-com

=head1 HISTORY

  0.1.0     2008-12-15
  0.2.0     2011-10-20
  0.3.0     2014-10-29  New subroutine to convert PHYLIP sequential format
                        file into NEXUS file.
  0.3.1     2015-01-14  Bug fix.
  0.3.2     2015-12-01  Bug fix.
                        

=cut

use strict;
use warnings;

use Bio::AlignIO;
use File::Basename;
use Getopt::Long;

use Smart::Comments;

my $usage = << "EOS";
Convert alignment files to PHYLIP sequential format.\n
Usage: aln2nex.pl -i <infile> -t <format> -o <outfile>\n
Parameters:
  -i <infile>:  Input file;
  -t <format>:  Input format; Optional.
                Deafult fasta.
  -o <outfile>: Output file (Optional)
Supported alignment formats:\n
   bl2seq      Bl2seq Blast output
   clustalw    clustalw (.aln) format
   emboss      EMBOSS water and needle format
   fasta       FASTA format
   maf         Multiple Alignment Format
   mega        MEGA format
   nexus       Swofford et al NEXUS format
   pfam        Pfam sequence alignment format
   phylip      Felsenstein's PHYLIP interleaved format
   phys        Felsenstern's PHYLIP sequential format
   psi         PSI-BLAST format
   selex       selex (hmmer) format
EOS

my ($inf, $outf);
my $infmt = 'fasta';

GetOptions(
    "i=s"   => \$inf,
    "t=s"   => \$infmt,
    "o=s"   => \$outf,
    "h"     => sub { die $usage },
);

die $usage unless ($inf);

unless (defined $outf) {
    my ($basename, $dir, $suffix) = fileparse( $inf, qr{\..*$});
    $outf = $basename . '.nex';
}

# Output Align object
my $o_alno = Bio::AlignIO->new(
    -file   => ">$outf",
    -format => 'nexus',
);

if ( $infmt eq 'phys' ) {
    my $o_aln = phys2nex( $inf );

    if ( $o_aln ) {
        $o_alno->write_aln( $o_aln );
    }
    else {
        warn "[ERROR] Convertion failed!\n";
    }
}
else {
	my $o_alni = Bio::AlignIO->new(
	    -file => $inf,
	    -format => $infmt,
	) or die "Fatal: Create AlignIO object failed!\n$!\n";
	
	while (my $o_aln = $o_alni->next_aln) {
	    $o_alno->write_aln( $o_aln );
	}
}

exit;

#=====================================================================
#
#                             Subroutines
#
#=====================================================================

=head2 phys2nex
  Name:     phys2nex
  Usage:    phys2nex( $fin)
  Params:   $fin  - Input PHYLIP sequential format file
  Ret:      A Bio::SimpleAlign object
            I<undef> for all errors
=cut

sub phys2nex {
    my ($fin) = @_;

    # File: $fin

    open( my $fh_in, "<", $fin ) 
        or die "[ERROR] Open input file '$fin' failed!\n$!\n\n";

    # Read the first row
    my $row = <$fh_in>;

    my ($num_seq, $aln_len);    # Sequence number and alignment length

    if ( $row =~ /^\s*(\d+)\s+(\d+)/ ) {
        $num_seq    = $1;
        $aln_len    = $2;
    }
    else {
        warn "[ERROR] NOT a PHYLIP format file!\n";
        close $fh_in;

        return;
    }

    # Seq num: $num_seq
    # Aln len: $aln_len

    # Output alignment object
    my $o_aln = Bio::SimpleAlign->new();

    # Read all rest rows into an array
    my @rows = <$fh_in>;

    # Total row number
    my $num_row = @rows;
    # Row number: $num_row

    # $num_row could NOT be divided (整除) by $num_seq
    # the file might be broken
    if ( $num_row % $num_seq) {
        warn "[ERROR] Broken PHYLIP sequential format file!\n";

        return;
    }

    # Number of rows for a sequence record
    my $num_row4seq = int( $num_row / $num_seq );

    # Start and end row indices of a sequence record.
    my $idx_start_row   = 0;

    my $idx_end_row     = $idx_start_row + $num_row4seq - 1;

    while ( $idx_end_row < $num_row ) {
        my @seq_rows = @rows[ $idx_start_row .. $idx_end_row ];

        # Rows for seq: @seq_rows

        # For each record, the 1st row contains the sequence ID, 
        # and with of without sequence string
        my $row = shift @seq_rows;

        chomp( $row );
        $row    =~ s/\r$//;

        # 1st row: $row

        my ($seq_id, $seq_str);
        
        if ($row =~ /^(\S+)\s+(.+)$/) { 
            # w/ spaces, there might be both seq ID and string
            # ($seq_id, $seq_str) = split( /\s+/, $row);
            $seq_id     = $1;
            $seq_str    = $2;

            $seq_str = '' unless ($seq_str);

            # $seq_str =~ s/\s//g;
        }
        else {  # w/o space, the whole row is the seq ID
            $seq_id     = $row;

            $seq_str    = '';
        }

        # The rest rows were sequence strings, of course
        for $row ( @seq_rows ) {
            chomp( $row );
            $row    =~ s/\r$//;

            $seq_str .= $row;
        }

        # Remove spaces in $seq_str
        $seq_str    =~ s/\s//g;

        # $eq ID: $seq_id
        # Seq str: $seq_str

        my $o_seq   = Bio::LocatableSeq->new(
            -id     => $seq_id,
            -seq    => $seq_str,
        );

        # The current sequence length is NOT equal to the alignment
        # length given by PHYLIP file
        if ( $o_seq->length != $aln_len ) {
            warn "Insufficient current  length for sequence ",
                    $o_seq->id, " with the alignment length ",
                    $aln_len, "\n";

            return;
        }

        $o_aln->add_seq( $o_seq );

        $idx_start_row  = $idx_end_row + 1;
        $idx_end_row     = $idx_start_row + $num_row4seq - 1;
    }


    close $fh_in;

    return $o_aln;
}
