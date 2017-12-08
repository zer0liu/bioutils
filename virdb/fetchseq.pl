#!/usr/bin/perl

=head1 NAME

    fetchseq.pl - Fetch CDS or protein sequences from a local SQLite3 
                  database, which was created by 'load_gbvirus.pl'.

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.01    2011-10-31

=cut

use strict;
use warnings;

use 5.010;
use Getopt::Long;
use DBI;

use Smart::Comments;

my $usage = << "EOS";
Fetch CDS or protein sequences from local SQLite3 database.
Usage:
  fetchseq.pl -d <db> [-t <cds|prn>] -g <gene> -o <file>
Options:
  -d <db>       SQLite3 database
  -t <cds|prn>  Get CDS or protein sequences. Optional.
                Default 'cds'.
  -g <gene>     Gene name.
  -o <file>     Output sequence file.
EOS

my ($fdb, $type, $gene, $fout);
$type = 'cds';

GetOptions(
    'd=s'   => \$fdb,
    't=s'   => \$type,
    'g=s'   => \$gene,
    'o=s'   => \$fout,
    'h'     => sub { die $usage }
);

die $usage unless ( $fdb and $fout and $gene);

# Connect to database
my $dbh;

eval {
    $dbh = DBI->connect(
        "dbi:SQLite:dbname=$fdb",
        "", "",
        {
            RaiseError  => 1,
            PrintError  => 1,
            AutoCommit  => 1,
        }
    );
};

if ($@) {
    die "Error: '$fdb' ", $DBI::errstr, "\n";
}

# Feature type: 'CDS', 'protein'
# Sequence type: 'seq', 'translation'
my ($feat_type, $seq_type);

if ($type eq 'cds') {
    $feat_type = 'CDS';
    $seq_type = 'seq';
}
elsif ($type eq 'prn') {
    $feat_type = 'CDS';
    $seq_type = 'translation';
}
else {
}

my $sql = << "EOS";
SELECT s.accession, v.strain, f.$seq_type
FROM sequence AS s, virus AS v, feature AS f
WHERE s.vir_id = v.id AND s.id = f.seq_id
AND f.ftype = '$feat_type'
AND gene = '$gene';
EOS

my $sth = $dbh->prepare($sql);
my $ret = $sth->execute();

# Create output FASTA file
open(OUT, ">$fout") or 
    die "Error: '$fout' $!\n"; 

while (my $rh_row = $sth->fetchrow_hashref) {
    my $acc     = $rh_row->{'accession'};
    my $strain  = $rh_row->{'strain'};
    my $seq     = $rh_row->{$seq_type};

    # Replace spaces in 'strain' with '_'
    $strain =~ s/\s/_/g;

    # Remove any contents in parentheses
    $strain =~ s/\(.+?\)//g;

    # Output FASTA format
    # print OUT '>', $acc, '-', $strain, "\n";
    print OUT '>', $acc, "\n";
    print OUT $seq, "\n";
    print OUT "\n";
}

close OUT;
$dbh->disconnect;

exit 0;

