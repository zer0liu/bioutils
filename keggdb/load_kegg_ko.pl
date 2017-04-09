#!/usr/bin/perl

=head1 NAME

    load_kegg_ko.pl - Load KEGG file ko into a database.
    
=head1 DESCRIPTION

=item genes

    Sample GENE entries
    
    ----------------------------------------------------------------------------
    
    GENES       HSA: 127(ADH4)
                PTR: 461394(ADH4)
                ...
                DME: Dmel_CG18814 Dmel_CG3481(Adh) Dmel_CG3763(Fbp2) Dmel_CG4842
                     Dmel_CG4899(Pdh)
                DPO: Dpse_GA14399 Dpse_GA17670
                ...
                
    ----------------------------------------------------------------------------
    
    HSA: 127(ADH4)
    ---  --- ----
     \     \    \______ name
      \     \__________ entry
       \_______________ organism
       
    This script work on these gene realted tables:
    'gene':         gene entry information
    'gene_name':    gene names for a gene entry
    'ko_gene_xref': cross reference of tables 'ko' and 'gene'
    
    This script inserts gene name as the rank '0' if exists.

=head1 AUTHOR

    zeroliu-at-gmail-dot-com
    
=head1 VERSION

    0.1     2010-09-01  Initial
    0.2     2010-09-20  Modify codes for 'ko_gene_xref' and 'gene' because
                        database schema changed.
    
=cut

use strict;
use warnings;

use Bio::KEGGI;
use DBI;
use Getopt::Long;

use Smart::Comments;

my $usage = << "EOS";
Load KEGG Orthology data
Usage:
  load_kegg_ko.pl -i <file> -H <host> -D <db> -U <user> -W <pwd>
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


my $o_keggi = Bio::KEGGI->new(
    -file => $inf,
    -type => 'ko',
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
    my $koid = $o_kegg->id;
    
    # DEBUG
    print $koid, "\n";
    
    eval {
        $dbh->begin_work;
        
        # Insert into table 'ko'
        ins_ko($o_kegg);
        
        # Insert into table ko_pathway_xref
        if (defined $o_kegg->pathway) {
            for my $pathway_id (@{$o_kegg->pathway}) {
                ins_table_xref('ko_pathway_xref', 'pathway_id', $koid, $pathway_id);
            }
        }
        
        # Insert into table ko_module_xref
        if (defined $o_kegg->module) {
            for my $module_id (@{$o_kegg->module}) {
                ins_table_xref('ko_module_xref', 'module_id', $koid, $module_id);
            }
        }
        
        # Insert into table ko_class_xref
        if (defined $o_kegg->class) {
            for my $class_id (@{$o_kegg->class}) {
                ins_table_xref('ko_class_xref', 'class_desc', $koid, $class_id);
            }
        }

        # Insert into table ko_ec_xref
        if (defined $o_kegg->ec) {
            for my $ec_id (@{$o_kegg->ec}) {
                ins_table_xref('ko_ec_xref', 'ec', $koid, $ec_id);
            }
        }

        # Insert into table ko_dbxref
        
            ins_ko_dbxref($o_kegg);
        
        # Insert into tables 'ko_gene_xref' and 'gene'
        if (defined $o_kegg->gene) {
            for my $rh_gene ( @{ $o_kegg->gene } ) {
                ins_ko_genes($koid, $rh_gene);
            }
        }
        
        # Insert into table ko_disease_xref
        if (defined $o_kegg->disease) {
            for my $disease_id ( @{$o_kegg->disease} ) {
                ins_table_xref('ko_disease_xref', 'disease_id', $koid, $disease_id);
            }
        }
        
        $dbh->commit;
    };
    
    if ($@) {
        warn "Error: Insert operation failed!\n$@\n";
        warn "Entry ", $koid, "\n";
        warn $dbh->errstr, "\n";
        
        $dbh->rollback;
        
        $dbh->disconnect;
        
        exit 1; 
    }
}

print "All done!\n";

exit 0;

#=====================================================================
#
#                             Subroutines
#
#=====================================================================

sub ins_ko {
    my ($rh_rec) = @_;
    
    my $ko_id = $rh_rec->id || '';
    my $name  = $rh_rec->name || '';
    my $desc  = $rh_rec->desc || '';
    
    my $sth = $dbh->prepare("INSERT INTO ko (ko_id, name, description)
        VALUES (?, ?, ?)");

    $sth->execute($ko_id, $name, $desc);
}

sub ins_table_xref {
    my ($table, $column2, $koid, $xref_id) = @_;
    
    my $sql = "INSERT INTO $table (ko_id, $column2) VALUES (?, ?);";
    
    my $sth = $dbh->prepare($sql);
    
    $sth->execute($koid, $xref_id);
}

sub ins_ko_dbxref {
    my ($rh_rec) = @_;
    
    my $koid = $rh_rec->id;
    
    if (defined $rh_rec->dblink) {
        for my $rh_db ( @{$rh_rec->dblink} ) {
            my $db = $rh_db->{'db'};
            my $ra_links = $rh_db->{'link'};
            
            for my $link ( @{$ra_links} ) {
                my $sql = 'INSERT INTO ko_dbxref (ko_id, db, entry)
                    VALUES (?, ?, ?)';
                
                my $sth = $dbh->prepare($sql);
                
                $sth->execute($koid, $db, $link);
            }
        }
    }
}

#
# Insert tables 'gene' and 'ko_gene_xref'
#

sub ins_ko_genes {
    my ($koid, $rh_gene) = @_;
    
    my $org = $rh_gene->{'org'};
    
    # Org: $org
    
    for my $org_gene ( @{ $rh_gene->{'org_gene'} } ) {
        my $entry = $org_gene->{'entry'} || '';
        my $name  = $org_gene->{'name'} || '';
        
        # Insert into table 'gene'
        my $sql = 'INSERT INTO gene (org, entry, name)
            VALUES (?, ?, ?);';
            
        my $sth = $dbh->prepare($sql);
        
        $sth->execute($org, $entry, $name);
        
        # Last inserted id of table 'gene'
        my $gene_id = $dbh->last_insert_id(undef, undef, 'gene', undef);
        
        # Insert into table 'ko_gene_xref'
        $sql = 'INSERT INTO ko_gene_xref (ko_id, gene_id)
            VALUES (?, ?)';
        
        $sth = $dbh->prepare($sql);
        
        $sth->execute($koid, $gene_id);
        
        # Also insert into table 'gene_name' with 'rank=0' if exists
        # gene name
        if ($name ne '') {
            $sql = 'INSERT INTO gene_name (gene_id, name, rank)
                VALUES (?, ?, ?)';
            
            $sth = $dbh->prepare($sql);
            
            $sth->execute($gene_id, $name, 0);
        }
    }
}