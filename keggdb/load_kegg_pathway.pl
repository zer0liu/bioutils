#!/usr/bin/perl

=head1 NAME

    load_kegg_pathway.pl = Load KEGG file pathway into database.
    
=head1 SYNOPSIS

=head1 DESCRIPTION

    Table 'ko_gene_xref', 'ko_ec_xref and 'gene_name' were also operated here.
    
=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.2     2010-09-20  Modified for new 'keggdb' schema
    0.3     2010-10-06  Update operation for 'gene' and 'gene_name' tables.

=cut

use strict;
use warnings;

use Bio::KEGGI;
use DBI;
use Getopt::Long;
use Text::Trim;
use Switch;

use Smart::Comments;

my $usage = << "EOS";
Load KEGG pathway data.
Usage:
  load_kegg_pathway.pl -i <file> -H <host> -D <db> -U <user> -W <pwd>
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

# Create object
my $o_keggi = Bio::KEGGI->new(
    -file => $inf,
    -type => 'pathway',
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

while (my $o_kegg = $o_keggi->next_rec) {
    # DEBUG
    # KEGG rec: $o_kegg
    
    my $pw_id = $o_kegg->id;
    
    # DEBUG
    print $pw_id, "\n";
    
    eval {
        $dbh->begin_work;
        
        # Table pathway
        ins_pathway($o_kegg);
        
        # Table pathway_pub_xref
        if (defined $o_kegg->pmid) {
            for my $pmid ( @{$o_kegg->pmid} ) {
                ins_table_xref('pathway_pub_xref', 'pmid', $pw_id, $pmid);
            }
        }
        
        # Table pathway_module_xref
        if (defined $o_kegg->module) {
            for my $mod_id ( @{$o_kegg->module} ) {
                ins_table_xref('pathway_module_xref', 'module_id', $pw_id, $mod_id);
            }
        }        
        
        # Table pathway_drug_xref
        if (defined $o_kegg->drug) {
            for my $drug_id ( @{$o_kegg->drug} ) {
                ins_table_xref('pathway_drug_xref', 'drug_id', $pw_id, $drug_id);
            }
        }
        
        # Table pathway_reaction_xref
        if (defined $o_kegg->reaction) {
            for my $rn_id ( @{$o_kegg->reaction} ) {
                ins_table_xref('pathway_reaction_xref', 'reaction_id', $pw_id, $rn_id);
            }
        }
        
        # Table pathway_compound_xref
        if (defined $o_kegg->compound) {
            for my $cpd_id ( @{$o_kegg->compound} ) {
                ins_table_xref('pathway_compound_xref', 'compound_id', $pw_id, $cpd_id);
            }
        }        
        
        # Table pathway_class_xref
        if (defined $o_kegg->class) {
            for my $class_desc ( @{$o_kegg->class} ) {
                ins_table_xref('pathway_class_xref', 'class_desc', $pw_id, $class_desc);
            }
        }
        
        # Table pathway_rel_xref
        if (defined $o_kegg->rel_pathway) {
            for my $rel_id ( @{$o_kegg->rel_pathway} ) {
                ins_table_xref('pathway_rel_xref', 'rel_pathway_id', $pw_id, $rel_id);
            }
        }
        
        # Table pathway_ec_xref
        if (defined $o_kegg->ec) {
            for my $ec ( @{ $o_kegg->ec } ) {
                ins_table_xref('pathway_ec_xref', 'ec', $pw_id, $ec);
            }
        }
        
        # Table pathway_disease_xref
        if (defined $o_kegg->disease) {
            for my $disease_id ( @{$o_kegg->disease} ) {
                ins_table_xref('pathway_disease_xref', 'disease_id', $pw_id, $disease_id);
            }
        }
        
        # Table pathway_dbxref
        ins_pw_dbxref($o_kegg);
        
        # Table pathway_gene_xref, gene and gene_name
        if (defined $o_kegg->gene) {
            for my $rh_gene ( @{ $o_kegg->gene } ) {
                ins_pathway_genes($pw_id, $o_kegg->org, $rh_gene);
            }
        }
        
        $dbh->commit;
    };
    
    if ($@) {
        warn "Error: Insert operation failed!\n$@\n";
        warn "Entry ", $pw_id, "\n";
#        warn $dbh->errstr, "\n";
        warn $DBI::errstr, "\n";
        
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

sub ins_pathway {
    my ($rh_rec) = @_;
    
    my $pw_id    = $rh_rec->id || '';
    my $name     = $rh_rec->name || '';
    my $desc     = $rh_rec->desc || '';
    my $map      = $rh_rec->map || '';
    my $organism = $rh_rec->organism || '';
    my $org      = $rh_rec->org || '';
    my $ko_pw    = $rh_rec->ko_pathway || '';
    
    my $sql = 'INSERT INTO pathway
        (pathway_id, name, description, map_id, organism, org, ko_pathway)
        VALUES (?, ?, ?, ?, ?, ?, ?)';
    
    my $sth = $dbh->prepare($sql);
    
    $sth->execute($pw_id, $name, $desc, $map, $organism, $org, $ko_pw);
}

sub ins_table_xref {
    my ($table, $column2, $pwid, $xref_id) = @_;
    
    my $sql = "INSERT INTO $table (pathway_id, $column2) VALUES (?, ?);";
    
    my $sth = $dbh->prepare($sql);
    
    $sth->execute($pwid, $xref_id);
}

sub ins_pw_dbxref {
    my ($rh_rec) = @_;
    
    my $pwid = $rh_rec->id;
    
    if (defined $rh_rec->dblink) {
        for my $rh_db ( @{$rh_rec->dblink} ) {
            my $db = $rh_db->{'db'};
            my $ra_links = $rh_db->{'link'};
            
            for my $link ( @{$ra_links} ) {
                my $sql = 'INSERT INTO pathway_dbxref (pathway_id, db, entry)
                    VALUES (?, ?, ?)';
                
                my $sth = $dbh->prepare($sql);
                
                $sth->execute($pwid, $db, $link);
            }
        }
    }
}

=head2 ins_pathway_genes
    Name:   ins_pathway_genes
    Desc:   Insert pathway related genes into tables 'gene', 'gene_name' and
            'pathway_gene_xref'
    
            In the 'ko' file, each gene has an entry, and maight have one
            name. Whereas in the 'pahtway' file, there might be multiple names
            for a gene entry.
    
            such as:
            ====================================================================
            - In the 'ko' file,
            
            ENTRY       K00845                      KO
            NAME        glk
            DEFINITION  glucokinase [EC:2.7.1.2]
            PATHWAY     ko00010  Glycolysis / Gluconeogenesis
            ...
            GENES       CME: CMO276C
                        ECO: b2388(glk)
                        ...
            
            --------------------------------------------------------------------
            
            - In the 'pathway' file
            
            ENTRY       eco00010                    Pathway
            ...
            ORGANISM    Escherichia coli K-12 MG1655 [GN:eco]
            GENE        b2388  glk, ECK2384, JW2385 [KO:K00845] [EC:2.7.1.2]
            
            --------------------------------------------------------------------
            
            Example for multiple ko and ec entries
            
            b1817  manX, ECK1815, gptB, JW1806, mpt, ptsL, ptsX [KO:K02793 K02794] [EC:2.7.1.69 2.7.1.69]
            
            ====================================================================
            
    Usage:  ins_pathway_genes($pw_id, $org, $rh_gene)
    Args:   $pw_id: Pathway entry, a string
            $org: Organism, a string
            $rh_gene: Gene details, a reference to a hash
            ----------------------------------------------------------
                $rh_gene = {
                    'entry' => $entry,
                    'name'  => [ $name, ... ],  # Multiple name entries
                    'ko'    => [ $ko, ... ],    # Multiple ko entries
                    'ec'    => [ $ec, ... ],    # Multiple ec entries
                }
            ----------------------------------------------------------
    Return: None
=cut

sub ins_pathway_genes {
    my ($pw_id, $org, $rh_gene) = @_;
    
    # DEBUG
    # Pathway: $pw_id
    # Organism: $org
    # Gene info: $rh_gene
    
    # Gene entry
    my $entry = $rh_gene->{'entry'};
    
    # Check whether gene entry already exists
    my $rh_para = {
        'org'   => $org,    # organism
        'entry' => $entry,  # gene entry
    };
    
    # Query table 'gene' to check whether record exists
    if ( my $ra_gene_ids = chk_gene($rh_para) ) {    # gene entry exists in table 'gene'
        
        for my $gene_id ( @{$ra_gene_ids} ) {
            # Update table 'pathway_gene_xref'
            ins_table_xref('pathway_gene_xref', 'gene_id', $pw_id, $gene_id);
            
            # Also update table 'gene_name'
            if ( defined $rh_gene->{'name'}) {
                my $i = 0;
                
                for my $gene_name ( @{$rh_gene->{'name'} } ) {
                    if ( chk_gene_name($gene_id, $gene_name) ) { # 'name' already exists in table 'gene_name'
                        $i++;
                        next;
                    }
                    else {  # not exists this gene name
                        switch ( $i ) {
                            case 0  { ins_gene_name($gene_id, $gene_name, 0); $i++; }
                            else    { ins_gene_name($gene_id, $gene_name, 1); $i++; }
                        }
                    }
                }
            }
        }
    }
    else {  # entry not exist in table 'gene'
        # Insert into table 'gene' first
        # if there are names for this entry, use $name[0] for field 'gene.name'
        # in table 'gene'
        my $name = $rh_gene->{'name'}->[0] if ( defined $rh_gene->{'name'} );
        
        if ( my $gene_id = ins_gene($org, $entry, $name ) ) { # Insert success
            # Also update table 'pathway_gene_xref'
            ins_table_xref('pathway_gene_xref', 'gene_id', $pw_id, $gene_id);
            
            # Then update table 'gene_name'
            if ( defined $rh_gene->{'name'}) {
                my $i = 0;
                
                for my $gene_name ( @{$rh_gene->{'name'} } ) {
#                    if ( chk_gene_name($gene_id, $gene_name) ) { # 'name' already exists in table 'gene_name'
#                        $i++;
#                        next;
#                    }
#                    else {  # not exists this gene name
                        switch ( $i ) {
                            case 0  { ins_gene_name($gene_id, $gene_name, 0); $i++; }
                            else    { ins_gene_name($gene_id, $gene_name, 1); $i++; }
                        }
#                    }
                }
            }
        }
        else {
            warn "Error: Insert gene '$entry|$name' of organism '$org' failed!\n";
            return;
        }
    }
    

}

=head2 chk_record
    Name:   chk_record
    Desc:   Check whether a record exists in a table
    Usage:  chk_record($table, $rh_row)
    Args:   $table  - table name
            $rh_row - a hash reference of parameters
                    $rh_row = {
                        $row => $value,
                        ...
                    }
    Return: Exist - Number of record
            None  - null
=cut

sub chk_record {
    my ($table, $rh_row ) =@_;
    
    my $sql = 'SELECT * FROM $table WHERE ';
    my $where;
    
    if (defined $rh_row) {
        for my $key (keys %{ $rh_row }) {
            $where = 'AND ' . $key . '=' . $dbh->quote( $rh_row->{$key} ) . ' ';
        }
        $where = s/^AND //; # Remove leading 'AND '
        trim($where);       # Remove trailing space
        
        my $sth = $dbh->prepare($sql);
        my $ret = $sth->execute;
        
        return $ret;
    }
    else {
        warn "Undefined query data!\n";
        
        return;
    }
}

=head2 chk_gene
    Name:   chk_gene
    Desc:   Check whether a gene record exists in table 'gene'
    Usage:  chk_gene($rh_para)
    Args:   A reference of a hash
    Return: A reference of array for gene_ids.
            undef if not exists.
=cut

sub chk_gene {
    my ($rh_para) = @_;
    
    my $sql = 'SELECT gene_id FROM gene WHERE ';
    my $where = '';  # WHERE clause
    
    my @gene_ids;
    
    if (defined $rh_para) {
        for my $key (keys %{ $rh_para}) {
            $where = $where . 'AND ' . $key . '=' . $dbh->quote( $rh_para->{$key} ) . ' ';
        }
        $where =~ s/^AND //; # Remove leading 'AND '
        trim($where);       # Remove trailing space
        
        $sql .= $where;
        
        my $sth = $dbh->prepare($sql);
        my $ret = $sth->execute;    # Return the number of hit records
        
        if ( $ret ) {   # Fetch gene_ids
            while (my $rh_row = $sth->fetchrow_hashref) {
                push @gene_ids, $rh_row->{'gene_id'};
            }
            
            return \@gene_ids;
        }
        else {  # No results
            return;
        }
    }
    else {
        warn "Undefined query data!\n";
        
        return;
    }
}

=head2 ins_gene
    Name:   ins_gene
    Desc:   Insert into table 'gene'
    Usage:  ins_gene($org, $entry, $name)
    Args:   $org   - Organism. A string.
            $entry - Gene entry. A string
            $name  - Gene name. Optional. A string
    Return: Success - Last inserted id
            Fail    - undef
=cut

sub ins_gene {
    my ($org, $entry, $name) = @_;
    
    unless ($org) { warn "Undefined organism.\n"; return; }
    unless ($entry) { warn "Undefined gene entry.\n"; return; }
    
    my $sql = "INSERT INTO gene (org, entry, name)
        VALUES (?, ?, ?);";
    
    my $sth = $dbh->prepare($sql);
    
    my $ret = $sth->execute($org, $entry, $name);
    
    if ( $ret ) {
        return lasert_insert_id(undef, undef, 'gene', undef);
    }
    else {  # Insert failed
        return;
    }
}

=head2 chk_gene_name
    Name:   chk_gene_name
    Desc:   Check whether a gene name exists in table 'gene_name'.
    Usage:  chk_gene_name($gene_id)
    Args:   A string
    Return: Exist     - Number of gene_name records
            Not exist - 0
=cut

sub chk_gene_name {
    my ($gene_id, $gene_name) = @_;
    
    my $sql = 'SELECT gene_name_id FROM gene_name
        WHERE gene_id = ? AND name = ?';
    
    my $sth = $dbh->prepare($sql);
    
    my $ret = $sth->execute($gene_id, $gene_name);
    
    # my $ra_row = $sth->fetchrow_arrayref();
    
    if ( $ret eq '0E0' ) {  # If no record
        return 0;
    }
    else {
        return $ret;
    }
}

=head2 ins_gene_name
    Desc:   Insert records into table 'gene_name'
=cut

sub ins_gene_name {
    my ($entry, $name, $rank) = @_;
    
    my $sql = 'INSERT INTO gene_name (gene_id, name, rank)
        VALUES (?, ?, ?)';
        
    my $sth = $dbh->prepare($sql);
      
    my $ret = $sth->execute($entry, $name, $rank);
    
    return $ret;
}

__END__
