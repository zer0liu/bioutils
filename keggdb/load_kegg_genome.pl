#!/usr/bin/perl
=head1 NAME

    load_kegg_genome.pl - Load KEGG genome data into database.

=head1 SYNOPSIS

    load_kegg_genome.pl -i <file> -H <host> -U <user> -W <pwd>

=head1 DESCRIPTION

    Database: keggdb

    Data Source: ftp://ftp.genome.jp/pub/kegg/genes/genome

=head1 AUTHOR

    zeroliu-at-gmail-dot-dom

=head1 VERSION

    0.1     2010-07-19

=cut

use strict;
use warnings;

use Bio::KEGGI;
use DBI;
use Getopt::Long;
# use Smart::Comments;


my $usage = << "EOS";
Load KEGG genome data
Usage:
  load_kegg_genome.pl -i <file> -H <host> -D <db> -U <user> -W <pwd>
Options:
  -i <file>: KEGG Genome file.
  -H <host>: Database host.
             Default 'localhost'
  -D <db>:   Database name.
  -U <user>: Username
  -W <pwd>:  Password
EOS

my ($inf, $host, $db, $user, $pwd);

$host = 'localhost';

GetOptions(
    "i=s" => \$inf,
    "H=s" => \$host,
    "D=s" => \$db,
    "U=s" => \$user,
    "W=s" => \$pwd,
#    "h"   => sub {die $usage},
);

die $usage unless (defined $inf);
die $usage unless (defined $db);
die $usage unless (defined $user);
die $usage unless (defined $pwd);

# DEBUG 

my $o_keggi = Bio::KEGGI->new(
    -file => $inf,
    -type => 'genome',
);

# Connect to database

our $dbh;

eval {
    $dbh = DBI->connect(
        "dbi:Pg:dbname=$db",
        $user, $pwd,
        {
            AutoCommit => 1,
            RaiseError => 1,
            PrintError => 1,
        }
    );
};

if ($@) {
    warn "Fatal: Connect to database '$db' failed!\n", $DBI::errstr, "\n";
    exit 0;
}

# Main cycle
while (my $o_kegg = $o_keggi->next_rec) {
    my $genome_id = $o_kegg->id;
    
    # DEBUG

    
    # Dismiss genomes which ENTRY titled 'T3', because they're environmental samples
    next if ($genome_id =~ /^T3/);
    
    print $genome_id, ":\t", $o_kegg->name, "\n";
    
    eval {
        $dbh->begin_work;
    
    # Insert into table 'genome'
        ins_genome($o_kegg);
    
    # Insert into table 'genome_component'
        if (defined $o_kegg->component) {
            for my $rh_cpt ( @{ $o_kegg->component } ) {
                ins_genome_component($genome_id, $rh_cpt);
            }
        }
    
    # Insert into table 'genome_pub_xref'
        if (defined $o_kegg->pmid) {
            for my $pmid ( @{ $o_kegg->pmid } ) {
                ins_table_xref('genome_pub_xref', 'pmid', $genome_id, $pmid);
            }
        }
    
    # Insert into table 'genome_disease_xref'
        if (defined $o_kegg->disease) {
            for my $disease ( @{ $o_kegg->disease } ) {
                ins_table_xref('genome_disease_xref', 'disease_id', $genome_id, $disease);
            }
        }
        
        $dbh->commit;
    };
    
    if ($@) {
        warn "Error: Insert operation failed!\n$@\n";
        warn "Entry ", $genome_id, "\n";
        warn $dbh->errstr, "\n";
        
        $dbh->rollback;
        
        $dbh->disconnect;
        
        exit 1;
    }
}

$dbh->disconnect;

print "All done!\n";

exit 0;



#---------------------------------------------------------------------
#
#                             Subroutines
#
#---------------------------------------------------------------------

sub ins_genome {
    my ($rh_rec) = @_;
    
    my $sql = "INSERT INTO genome 
        (genome_id, org, description, taxid, taxonomy, 
        num_nt, num_prn, num_rna, comment) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    my $sth = $dbh->prepare($sql);
    
    my $genome_id = $rh_rec->id || '';
    my $name      = $rh_rec->name || '';
    my $desc      = $rh_rec->desc || '';
    my $taxid     = $rh_rec->taxid || '';
    my $taxonomy  = $rh_rec->taxonomy || '';
    my $num_nt    = $rh_rec->statistics->{'nt'} || 0;
    my $num_prn   = $rh_rec->statistics->{'prn'} || 0;
    my $num_rna   = $rh_rec->statistics->{'rna'} || 0;
    my $comment   = $rh_rec->comment || '';
    
    ### Table genome SQL: $sql
    $sth->execute( $genome_id, $name, $desc, $taxid, $taxonomy, $num_nt,
        $num_prn, $num_rna, $comment);
}

sub ins_genome_component {
    my ($genome_id, $rh_cpt) = (@_);
    
    my $category    = $rh_cpt->{'category'} || '';
    my $name        = $rh_cpt->{'name'} || '';
    my $is_circular = $rh_cpt->{'is_circular'} || 1;
    my $refseq      = $rh_cpt->{'refseq'} || '';
    
    $name =~ s/;$//;
    
    my $sql = 'INSERT INTO genome_component
        (genome_id, category, name, is_circular, refseq_id)
        VALUES (?, ?, ?, ?, ?)';
        
    my $sth = $dbh->prepare( $sql );
    
    $sth->execute( $genome_id, $category, $name, $is_circular, $refseq);
}

sub ins_table_xref {
    my ($table, $column2, $gid, $xref_id) = @_;
    
    my $sql = "INSERT INTO $table (genome_id, $column2) VALUES (?, ?);";
    
    my $sth = $dbh->prepare($sql);
    
    $sth->execute($gid, $xref_id);
}

