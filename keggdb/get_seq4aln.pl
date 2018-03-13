#!/usr/bin/perl

=head1 NAME

    get_seq4aln.pl - Get sequences from 'keggdb' database for subsequente
                     Aligmnent.

=head1 DESCRIPTION

    This script could be used to fetch sequences for alignments, in which
    both amino acid and nucleotide sequences could be get.
    
    File name:
    
        KEGG orthology entry
        
    File suffix:
    
        faa: Amino acid sequence
        ffn: Nucleotide seuqence
    
    Sequence name:
    
        <gene entry>_<org>
    
=head1 AUTHOR

    zeroliu-at-gmail-dot-com
    
=head1 VERSION

    0.1     2011-01-08
    0.2     2011-01-14  Modified for NEW 'keggdb2' schema.
    
=cut

use strict;
use warnings;

use Getopt::Long;
use DBI;

use Smart::Comments;

my $usage = << "EOS";
Get sequences from 'keggdb' database for subsequent alignment.
Usage:
get_seq4aln.pl -i <org list> -k <ko list>
Options:
    -i <org list>:  A list of KEGG 3-character organism name.
    -k <ko list>:   A list of ko entries.
EOS

my ($olst, $klst);

GetOptions(
    "i=s" => \$olst,
    "k=s" => \$klst,
);

die $usage unless ($olst);

# Load org
my @orgs;

open(FH, $olst) or die "FATAL: Open file '$olst' failed!\n$!\n";

while (<FH>) {
    next if /^#/;
    next if /^\s*$/;
    chomp;
    
    my ($org) = split(/\t/, $_);
    
    push @orgs, $org;
}

close FH;

### Orgs: @orgs

# Load ko entries
my @kos;

open (FH, $klst) or die "FATAL: Open file '$klst' failed!\n$!\n";

while (<FH>) {
    next if /^#/;
    next if /^\s*$/;
    chomp;
    
    push @kos, $_;
}

close FH;

# Connect to database
my ($dbh, $sth);

eval {
    $dbh = DBI->connect(
        "dbi:Pg:dbname=keggdb2",
        'zeroliu', '466920@e',
        {
            AutoCommit => 1,
            RaiseError => 1,
            PrintError => 1,
        },
    );
};

if ($@) {
    warn "FATAL: connect to database 'keggdb' failed!\n", $DBI::errstr, "\n";
    exit 0;
}

# Main cycle
for my $ko ( @kos ) {
    # Output sequence files
    my $faa = $ko . '.faa';
    my $fnt = $ko . '.ffn';
    
    # open(FAA, ">$faa") or die "FATAL: Output to file '$faa' failed!\n$!\n";
    # open(FNT, ">$fnt") or die "FATAL: Output to file '$fnt' failed!\n$!\n";
    
    my $aastr = '';
    my $ntstr = '';
    
    # Query org related records
    for my $org ( @orgs ) {
        eval {
            my $sql = 'SELECT entry, description, aaseq, ntseq FROM gene
                        WHERE gene_id IN
                            (SELECT gene_id FROM ko_gene_xref
                                WHERE ko_id = ? AND gene_id ~ ?);';
        
            $sth = $dbh->prepare($sql);
            
            $sth->execute( $ko, "$org:" );
        };
        if ($@) {
            warn "Error: Query table 'gene' failed!\n", $dbh->errstr, "\n";
            $dbh->disconnect;
            exit 0;
        }
        
        # Fetch aa and nt sequences from database
        my ($seqid, $aaseq, $ntseq);
        
        while (my $row = $sth->fetchrow_hashref) {
            my $gene = $row->{'entry'};
            my $desc = $row->{'description'};
            my $aaseq = $row->{'aaseq'};
            my $ntseq = $row->{'ntseq'};
            
            # Dismiss if aa or nt seq not found
            next if ($aaseq eq '');
            next if ($ntseq eq '');
            
            $seqid = '>' . $org . '_' . $gene;
            
            # print FAA $seqid, "\n", $aaseq, "\n\n";
            # print FNT $seqid, "\n", $ntseq, "\n\n";
            
            $aastr = $aastr . $seqid . " $desc" . "\n" . $aaseq . "\n\n";
            $ntstr = $ntstr . $seqid . " $desc" . "\n" . $ntseq . "\n\n";
        }
    }
    
    next if ( length($aastr) == 0 );
    next if ( length($ntstr) == 0 );
    
    open(FAA, ">$faa") or die "FATAL: Output to file '$faa' failed!\n$!\n";
    open(FNT, ">$fnt") or die "FATAL: Output to file '$fnt' failed!\n$!\n";
    
    print FAA $aastr, "\n";
    print FNT $ntstr, "\n";
    
    close FAA;
    close FNT;
}

$dbh->disconnect;

exit 0;
