#!/usr/bin/perl

=head1 NAME

    merge_count_file.pl - Merge multiple count files into one count data
                          file.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Count file format

Filename: sample01.count.txt

ID  count_number

=head2 Count data file format

    Sample01    Sample02    Sample03    ...
gene01  num num num ...
gene02  num num num ...
...

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   - 2019-07-11

=cut

use 5.12.1;
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Smart::Comments;

my ($fout);

GetOptions(
    "o=s"   => \$fout,
    "h"     => sub { usage() }
);

die "[ERROR] Need a output filename!\n" unless (defined $fout);

## $fout
## @ARGV

my @fcounts = @ARGV;    # count files
my %samples;            # store all gene/cds/exon/etc ids.
my %data;               # Store all count number of IDs in each sample

for my $fin (@fcounts) {
    # Parse filename
    say "[NOTE] Parsing cout file '$fin' ...";

    # Here $fname will be used as the sample name
    my ($fname, $dir, $suffix)  = fileparse($fin, qr/\..*$/);
    my $sample_name             = $fname;

    open my $fh_in, "<", $fin
        or die "[ERROR] Open count file '$fin' failed!\n$!\n";

    while (<$fh_in>) {
        next if /^#/;
        next if /^\s*$/;
        chomp;

        my ($id, $num)  = split /\s+/;

        $data{ $id }->{ $sample_name }  = $num;
        $samples{ $sample_name }       += 1;
    }

    close $fh_in;
}

# Output to count data file: $fout
say "";

say "[NOTE] Merging and creating output data file '$fout' ...";

open my $fh_out, ">", $fout
    or die "[ERROR] Create output file '$fout' failed!\n$!\n";

my @samples = sort keys %samples;

# Output file head
say $fh_out join "\t", ('', @samples);

for my $id ( sort keys %data ) {
    print $fh_out $id;

    for my $sample ( @samples ) {
        if (defined $data{ $id }->{ $sample }) {
            print $fh_out "\t", $data{ $id }->{ $sample };
        }
        else {
            print $fh_out "\t", 0;
        }
    }

    print $fh_out "\n";
}

close $fh_out;


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
Merge multiple count files into one count data file.
Usage:
merge_count_files.pl -o <output> countfile1 countfile2 ...
Args:
  -o <output>   Output count data filename.
EOS
}

=pod

  Name:     
  Usage:    
  Function: 
  Args:     
  Returns:  

=cut

