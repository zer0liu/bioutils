#!/usr/bin/perl
=head1 NAME
    
    load_kegg_gene2.pl - Load KEGG gene entries into database 'keggdb2'.

=head1 SYNOPSIS

    load_kegg_gene.pl -i <file>  -l <list> -H <host> -D <db> -U <user> -W <pwd>
    
=head1 DESCRIPTION

    Load KEGG gene entries into the database 'keggdb2'.
    
    Affected tables:
        * gene
        * gene_name
        * gene_dbxref
        * gene_motid_xref
        * gene_struct_xref
    
    And
        * pathway_gene_xref
        * ko_gene_xref
    
    In this version, Gene related tables would be loaded before 'KO' and
    'Pathway' related tables.
    
    
=head1 AUTHOR

    zeroliu-at-gmail-dot-dom

=head1 VERSION

    0.1     2010-12-08
    0.2     2011-01-05  Fix bugs.
    0.21    2011-01-06  New feature: organism name.
    1.00    2011-01-10  Derived from script 'load_kegg_gene.pl'. This script
            works for the new 'kegg2' database schema, in which the GENE entry
            is used as 'gene_id' for the Primary Key of table 'gene', and the
            column 'entry' is removed.

=cut

use strict;
use warnings;
use 5.10.1;

use Bio::KEGGI;
use DBI;
use Getopt::Long;
use Switch;
use Text::Trim;

use Smart::Comments;

my $usage = << "EOS";
Load KEGG gene data into a database.
Usage:
  load_kegg_gene.pl -i <file> -o <org> -l <list>
                    -H <host> -D <db> -U <user> -W <pwd>
Options:
  -i <file>: KEGG gene file.
  -o <org>:  3-character KEGG organism name.
  -l <list>: A list of KEGG gene file.
  -H <host>: Database host. Optional.
             Default 'localhost'
  -D <db>:   Database name.
  -U <user>: Username
  -W <pwd>:  Password
\nNote: Input file list format:
<org>\t<filename>
* Column is delimited by a {tab};
* Line starts with '#' is looked as comments;
* Contents after 2 columns are also looked as comments.
EOS

my ($inf, $org, $inlst, $host, $db, $user, $pwd);

$host = 'localhost';
$db   = 'keggdb2';
$user = 'zeroliu';
$pwd  = '466920@e';

GetOptions(
    "i=s" => \$inf,
    "o=s" => \$org,
    "l=s" => \$inlst,
    "H=s" => \$host,
    "D=s" => \$db,
    "U=s" => \$user,
    "W=s" => \$pwd,
#    "h"   => sub {die $usage},
);

die $usage if ( !(defined $inf) and !(defined $inlst) );
die $usage if ( (defined $inf) and !(defined $org) );
die $usage unless (defined $db);
die $usage unless (defined $user);
die $usage unless (defined $pwd);

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

if ( defined $inf ) {
    load_gene_file($org, $inf);
}
elsif ( defined $inlst ) {
    eval {
        open(LST, $inlst) or die;
    };
    if ( $@ ) {
        warn "Fatal: Open file '$inlst' failed!\n$!\n";
        $dbh->disconnect;
    }
    
    while ( <LST> ) {
        next if /^#/;
        next if /^\s*$/;
        chomp;
        
        my ($org, $inf) = split(/\t/, $_);
        trim($org);
        trim($inf);
        
        # DEBUG
        print '='x60, "\n", "Start loading '$org' from file '$inf' ...\n";
        
        load_gene_file( $org, $inf );
    }
    
    close LST;
}

$dbh->disconnect;

exit 0;

#---------------------------------------------------------------------
#
#                             Subroutines
#
#---------------------------------------------------------------------

=begin load_gene_file
  Name:   load_gene_file
  Desc:   load a KEGG gene file into database.
  Usage:  load_gene($org, $file)
  Args:   $file: KEGG gene file
          $dbh:  Database handle
  Return: none
=cut

sub load_gene_file {
    my ($org, $file) = @_;
#     my ($file, $dbh) = @_;
    
    my $o_keggi = Bio::KEGGI->new(
        -file => $file,
        -type => 'gene',
    );

    while (my $o_kegg = $o_keggi->next_rec) {
        print $o_kegg->id, "\n";
        
        my $gene_entry = $o_kegg->id;
        
        eval {
            $dbh->begin_work;       # BEGIN transaction
            
            # Now the 'gene_id' is the PRIMARY KEY for table 'gene'
            # this would also be used directly for other tables
            
            my $gene_id = $org . ':' . $o_kegg->id;    
            
            # INSERT table 'gene'
            ins_gene($org, $o_kegg);
            
            # INSERT table 'gene_name'
            ins_gene_name( $gene_id, $o_kegg->name);

=begin Dismissed
            if ( $gene_id = get_gene_id($gene_entry) ) {    # GENE exists
                upd_gene($org, $gene_id, $o_kegg);
            }
            else {
                $gene_id = ins_gene( $org, $o_kegg );
                
                # Then INSERT INTO table 'gene_name'
                ins_gene_name( $gene_id, $o_kegg->name );
            }
=cut
           
            # INSERT 'DBLINKS' information into table 'gene_dbxref'
            ins_dbxref( 'dblink', $gene_id, $o_kegg->dblink )
                if ( defined $o_kegg->dblink );
            
            # Insert 'MOTIF' into table 'gene_dbxref'
            ins_dbxref( 'motif', $gene_id, $o_kegg->motif )
                if ( defined $o_kegg->motif );
                
            # Insert 'STRUCTURE' into table 'gene_dbxref'
            ins_dbxref( 'structure', $gene_id, $o_kegg->struct)
                if ( defined $o_kegg->struct );
            
=begin Dismissed
            # Table ko_gene_xref
            if ( defined $o_kegg->ko ) {
                for my $ko_id ( @{ $o_kegg->ko } ) {
                    unless ( chk_gene_ko($gene_id, $ko_id) ) {
                        warn "NOTE: GENE '$gene_entry' do NOT match KO '$ko_id'.\n";
                        warn ' 'x6, "Updating table 'ko_gene_xref'\n";
                        ins_gene_ko($gene_id, $ko_id);
                    }
                }
            }
            
            # Table pathway_gene_xref
            if ( defined $o_kegg->pathway ) {
                for my $pw_id ( @{ $o_kegg->pathway } ) {
                    unless ( chk_gene_pw($gene_id, $pw_id) ) {
                        warn "NOTE: GENE '$gene_entry' do NOT match pathway '$pw_id'.\n";
                        warn ' 'x6, "Updating table 'pathway_gene_xref'\n";
                        ins_gene_pw($gene_id, $pw_id);
                    }
                }
            }
=cut

            $dbh->commit;
        };
        
        if ( $@ ) {
            warn "Operation failed on entry '$gene_entry'.\n$@\n";
            # warn $DBI::errstr, "\n";
            warn $dbh->errstr, "\n";
            
            $dbh->rollback;
            
            $dbh->disconnect;
            
            exit 1;
        }
    }
    
    return;
}

=begin get_gene_id # Subroutine dismissed
    Name:   get_gene_id
    Desc:   Query gene_id from table 'gene'.
    Usage:  get_gene_id($entry)
    Args:   $entry - Gene entry.
    Return: Gene id if exists record.
            '0' for no records.
            undef for errors.
=cut

=begin Dismissed
sub get_gene_id {
#    my ( $dbh, $entry ) = @_;
    my $entry = shift;
    
    my $sql = 'SELECT gene_id FROM gene WHERE entry = ?';
    
    my $sth = $dbh->prepare($sql);
    my $ret = $sth->execute( $entry );
    
    if ( $ret eq '0E0' ) {  # No record exists
        return 0;
    }
    else {                  # Fetch gene_id
        my $rh_row = $sth->fetchrow_hashref();
        $sth->finish;
        
        return $rh_row->{'gene_id'};
    }
}
=cut

=begin upd_gene # Subroutine dismissed
    Name:   upd_gene
    Desc:   Update table 'gene'.
    Usage:  upd_gene_id( $org, $gene_id, $o_kegg )
    Args:   A Bio::KEGG::gene object
    Return: none.
            undef for errors.
=cut

=begin Dismissed
sub upd_gene {
    my ( $org, $gene_id, $o_kegg ) = @_;
    
    
    my $sql = 'UPDATE gene SET
                org         = ?,
                type        = ?,
                description = ?,
                position    = ?,
                aalen       = ?,
                aaseq       = ?,
                ntlen       = ?,
                ntseq       = ?
                WHERE gene_id = ?;';
                        
    my $type  = ( $o_kegg->type ) // '';
    my $desc  = ( $o_kegg->desc ) // '';
    my $pos   = ( $o_kegg->position ) // '';
    my $aalen = ( $o_kegg->aalen ) // 0;
    my $aaseq = ( $o_kegg->aaseq ) // '';
    my $ntlen = ( $o_kegg->ntlen ) // 0;
    my $ntseq = ( $o_kegg->ntseq ) // '';
    
    my $sth = $dbh->prepare( $sql );
    my $ret = $sth->execute( $org, $type, $desc, $pos, $aalen, $aaseq,
                        $ntlen, $ntseq, $gene_id);
    
    return $ret;
}
=cut

=begin ins_gene
    Name:   ins_gene
    Desc:   INSERT a GENE record
    Usage:  ins_gene( $org, $o_kegg )
    Args:   A Bio::KEGG::gene object
    Return: Last inserted id.
            undef - Errors.
=cut

sub ins_gene {
    my ($org, $o_kegg) = @_;
    
    my $sql = 'INSERT INTO gene
        (gene_id, org, entry, name, type, description, position,
            aalen, aaseq, ntlen, ntseq)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);';
    
    # gene_id format: 'org:entry'
    my $gene_id = $org . ':' . $o_kegg->id;
    
    my $entry = $o_kegg->id;
    
    # my $name  = ( @{ $o_kegg->name }[0] ) // '';
    my $name = '';
    $name = @{ $o_kegg->name }[0] if defined ( $o_kegg->name );
    
    my $type  = ( $o_kegg->type ) // '';
    my $desc  = ( $o_kegg->desc ) // '';
    my $pos   = ( $o_kegg->position ) // '';
    my $aalen = ( $o_kegg->aalen ) // 0;
    my $aaseq = ( $o_kegg->aaseq ) // '';
    my $ntlen = ( $o_kegg->ntlen ) // 0;
    my $ntseq = ( $o_kegg->ntseq ) // '';
    
    my $sth = $dbh->prepare( $sql );
    my $ret = $sth->execute( $gene_id, $org, $entry, $name, $type, $desc, $pos,
                        $aalen, $aaseq, $ntlen, $ntseq );
    
=begin
    if ( $ret ) {
        return $dbh->last_insert_id(undef, undef, 'gene', undef);
    }
    else {
        return;
    }
=cut
}

=begin in_gene_name
    Name:   ins_gene_name
    Desc:   INSERT INTO table 'gene_name' for genes 
    Usage:  ins_gene_name($gene_id, $ra_names)
    Args:   $gene_id
            $ra_names - A reference to an array of GENE names
    Return: undef for errors.
=cut

sub ins_gene_name {
    my ( $gene_id, $ra_names ) = @_;
    
    # my $rank = 0;
    my $i = 0;
    
    for my $name ( @{ $ra_names } ) {
        my $sql = 'INSERT INTO gene_name
                (gene_id, name, rank)
                VALUES (?, ?, ?);';
        
        my $rank = ( $i == 0 ) ? 0 : 1;
        
        my $sth = $dbh->prepare($sql);
        my $ret = $sth->execute($gene_id, $name, $rank);
        
        $i++;
    }
}

=begin ins_dbxref
    Name:   ins_dbxref
    Desc:   INSERT into table 'gene_dbxref'
    Usage:  ins_gene_dbxref( $gene_id, $ra_dblinks )
    Args:   $gene_id
            $ra_dblinks - A reference to an array.
    Return: undef for errors
=cut

sub ins_dbxref {
    my ( $type, $gene_id, $r_dbxrefs ) = @_;
    
    switch ( $type ) {
        case /dblink|motif/ {
            for my $rh_db ( @{ $r_dbxrefs } ) {
                my $db = $rh_db->{'db'};
                my $ra_entries = $rh_db->{'entry'};
            
                for my $entry ( @{$ra_entries} ) {
                    my $sql = 'INSERT INTO gene_dbxref (gene_id, type, db, entry)
                            VALUES (?, ?, ?, ?)';
                    
                    my $sth = $dbh->prepare($sql);
                
                    $sth->execute($gene_id, $type, $db, $entry);
                }
            }
        }
        case 'structure' {
            my $db = $r_dbxrefs->{'db'};
            my $ra_entries = $r_dbxrefs->{'entry'};
    
            for my $entry ( @{ $ra_entries } ) {
                my $sql = 'INSERT INTO gene_dbxref (gene_id, type, db, entry)
                            VALUES (?, ?, ?, ?);';
                my $sth = $dbh->prepare($sql);
            
                $sth->execute($gene_id, $type, $db, $entry);
            }
        }
        default {
            ### Unmatched dbxref type: $type
        }
    }
}

=begin ins_motif
    Name:   ins_motif
    Desc:   Insert into tables gene_motif_xref.
    Usage:  ins_table_xref($gene_id, $ra_motif)
    Args:
    Return:
=cut

=begin
sub ins_motif {
    my ( $gene_id, $ra_motifs ) = @_;
    
    for my $rh_db ( @{ $ra_motifs } ) {
        my $db = $rh_db->{'db'};
        my $ra_entries = $rh_db->{'entry'};
        
        for my $entry ( @{ $ra_entries } ) {
            my $sql = 'INSERT INTO gene_motif_xref ( gene_id, db, entry )
                    VALUES (?, ?, ?);';
            my $sth = $dbh->prepare( $sql );
            
            $sth->execute( $gene_id, $db, $entry );
        }
    }
}
=cut

=begin ins_struct
    Name:   ins_struct;
    Usage:  ins_struct( $gene_id, $rh_struct )
=cut

=begin
sub ins_struct {
    my ( $gene_id, $rh_struct) = @_;
    
    my $db = $rh_struct->{'db'};
    my $ra_entries = $rh_struct->{'entry'};
    
    for my $entry ( @{ $ra_entries } ) {
        my $sql = 'INSERT INTO gene_struct_xref (gene_id, db, entry)
                VALUES (?, ?, ?);';
        my $sth = $dbh->prepare($sql);
        
        $sth->execute($gene_id, $db, $entry);
    }
}
=cut

=begin chk_gene_ko
    Name:   chk_gene_ko
    Desc:   Check whether a gene-ko record exists.
    Usage:  chk_gene_ko($gene_id, $ko_id)
    Args:
    Return: Number of records.
            0 for no record.
            undef for errors.
=cut

=begin
sub chk_gene_ko {
    my ($gene_id, $ko_id) = @_;
    
    my $sql = 'SELECT ko_gene_id FROM ko_gene_xref
            WHERE ko_id = ? AND gene_id = ?;';
            
    my $sth = $dbh->prepare($sql);
    my $ret = $sth->execute($ko_id, $gene_id);
    
    ( $ret eq '0E0') ? return 0 : return $ret;
}
=cut

=begin ins_gene_ko
    Name:   ins_gene_ko
    Usage:  Insert into table ko_gene_xref

=begin
sub ins_gene_ko {
    my ($gene_id, $ko_id) = @_;
    
    my $sql = 'INSERT INTO ko_gene_xref (ko_id, gene_id)
            VALUES (?, ?);';
    my $sth = $dbh->prepare( $sql );
    my $ret = $sth->execute($ko_id, $gene_id);
}
=cut

=begin chk_gene_pw
    Name:   chk_gene_pw
    Desc:   Check gene-pathway in table pathway_gene_xref

sub chk_gene_pw {
    my ( $gene_id, $pw_id ) = @_;
    
    my $sql = 'SELECT pathway_gene_id FROM pathway_gene_xref
            WHERE pathway_id = ? AND gene_id = ?;';
    
    my $sth = $dbh->prepare($sql);
    
    my $ret = $sth->execute($pw_id, $gene_id);
    
    ( $ret eq '0E0' ) ? return 0 : return $ret;
}
=cut

=begin ins_gene_pw

sub ins_gene_pw {
    my ($gene_id, $pw_id) = @_;
    
    my $sql = 'INSERT INTO pathway_gene_xref (pathway_id, gene_id)
            VALUES (?, ?);';
    my $sth = $dbh->prepare( $sql );
    my $ret = $sth->execute($pw_id, $gene_id);    
}
=cut

__END__