#!/usr/bin/perl

=head1 NAME

    rm_seq_by_kw.pl - Remove sequences from a huge multi-FASTA sequence 
                      files according to given key words in sequence 
                      id and description.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2016-04-28
    0.0.2   2016-07-26  Keywords provided in command line, rather in a
                        keyword file.
                        Updated script description and usage information.

=cut

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;
use Getopt::Long;

my $usage   = << "EOS";
Find and remove sequences from a multi-FASTA sequence file according to 
given keywords in sequence ID and description.
Usage:
  rm_seq_by_kw.pl -i <fin> -k <kwstr> [-o <fout>]
Note:
  Keywords should be sperated by a whitespace, and quoted by quotes (i.e., 
  "" or '')

EOS

my ($fin, $kwstr, $fout);

GetOptions(
    "i=s"   => \$fin,
    "k=s"   => \$kwstr,
    "o=s"   => \$fout,
    "h"     => sub { die $usage }
);

die $usage unless (defined $fin && defined $kwstr);

# Generate output filename
unless (defined $fout) {
    my ($basename, $dir, $suffix)   = fileparse($fin, qr{\..*});
    $fout   = $basename . '_rm.' . $suffix;
}

# Parse keywords string

my @keywords    = split /\s+/, $kwstr;

# my @keywords;
# 
# open(my $fh_kw, "<", $fkw)
#     or die "[ERROR] Open keywords file failed!\n$!\n";
# 
# while (<$fh_kw>) {
#     next if /^\#/;
#     next if /^\s*$/;
#     chomp;
# 
#     push @keywords, $_;
# }
# 
# close $fh_kw;

# Parse & output sequences
my $o_seqi  = Bio::SeqIO->new(
    -file   => $fin,
    -format => 'fasta',
);

my $o_seqo  = Bio::SeqIO->new(
    -file   => ">$fout",
    -format => 'fasta',
);

my $num_rm  = 0;

while (my $o_seq = $o_seqi->next_seq) {
    my $seq_id   = $o_seq->id;
    my $seq_desc    = $o_seq->desc;

    my $F_FindKW    = 0;

    for my $kw (@keywords) {
        if ( $seq_id =~ /$kw/) {
            $F_FindKW   = 1;    # Set FLAG
            last;
        }
        elsif ( $seq_desc =~ /$kw/ ) {
            $F_FindKW   = 1;    # Set FLAG
            last
        }
        else {
            #
        }
    }

    if ($F_FindKW) {
        $num_rm++;

        my $desc    = join(" ", ($seq_id, $seq_desc));
        $desc   =~ s/^\s+//;
        $desc   =~ s/\s+$//;

        say "[$num_rm] Sequence '$desc' removed!";

        next;
    }
    else {
        # Output sequence
        $o_seqo->write_seq($o_seq);
    }
}

say "\nTotal $num_rm sequences removed!\n";

exit 0;

__END__
