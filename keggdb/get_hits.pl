#!/usr/bin/perl

=head1 NAME

=head1 DESCRIPTION

    Get blast hit information from a blast output and store in a sqlite
    database. Then Output needed hits.

=head1 VERSION

    0.1     2011-01-24
    
=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=cut

use strict;
use warnings;

use 5.10.1;

use Bio::SearchIO;
use DBI;
use File::Basename;
use Getopt::Long;

my $usage = << "EOS";
Get sequences information from a BLAST report and store into an SQLite database.
Output selected sequence id to a text file according to given options if
necessary.
get_hits.pl -i <file> -d <db> -o <file> -e <eval> -c <cover> -p <postive>
Options:
  -i <file>     Input BLAST report.
  -d <db>       Output SQLite3 database file.
                Default use 'input_filename.db'.
  -o <file>     Output sequence ids file.
                Default 'input_filename.out'.
  Threshold:
    -e <eval>   E-value.
                Default '1e-100'.
    -c <cover>  Cover percentage of query and subject sequences.
                Default 90.
    -p <pos>    Postive rate of hits.
                Default 80.
EOS

my ($inf, $db, $outf, $eval, $cover, $post);

$eval = 1e-100;
$cover = 90;
$post = 80;

GetOptions(
    "i=s" => \$inf,
    "d=s" => \$db,
    "o=s" => \$outf,
    "e=f" => \$eval,
    "c=i" => \$cover,
    "p=i" => \$post,
    "h"   => sub {die $usage}
);

die $usage unless (defined $inf);

$db = basename($inf) . '.db' unless (defined $db);
$outf = basename($inf) . '.out' unless (defined $db);

our $dbh;

# Create database
print "Creating database '$db' and tables ...\n";

eval {
    $dbh = DBI->connect("dbi:SQLite:dbname=$db",
                "","",
                {
                    RaiseError => 1,
                    PrintError => 1,
                    AutoCommit => 1,
                }
            );
};

if ($@) {
    die "FATAL: Create database '$db' failed!\n$@\n";
}

die "Create table failed!\n" unless createdb($db);

# Parse BLAST file
my $o_rpt = Bio::SearchIO->new(
    -format => 'blast',
    -file   => $inf,
);

while (my $o_result = $o_rpt->next_result) {
    load_result($o_result);
}

$dbh->disconnect;

exit 0;

#---------------------------------------------------------------------
#
#                             Subroutines
#
#---------------------------------------------------------------------

=head1 createdb
    : Create an SQLite database
    : createdb($db)
    : null for any errors
=cut

sub createdb {
    my $db = shift;
    
    my $sql = << 'EOS';
        CREATE TABLE blast (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            program     TEXT NOT NULL DEFAULT '',
            db          TEXT NOT NULL DEFAULT ''
        );
        CREATE INDEX idx_blast_prog ON blast (program);
        CREATE INDEX idx_blast_db ON blast (db);
        --
        CREATE TABLE query (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT NOT NULL DEFAULT '',
            descript    TEXT NOT NULL DEFAULT '',
            length      TEXT NOT NULL DEFAULT ''
        );
        CREATE INDEX idx_query_name ON query (name);
        CREATE INDEX idx_query_desc ON query (descript);
        CREATE INDEX idx_query_len ON query (length);
        --
        CREATE TABLE hit (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT NOT NULL DEFAULT '',
            descript    TEXT NOT NULL DEFAULT '',
            length      INTEGER NOT NULL DEFAULT 0,
            score       REAL NOT NULL DEFAULT 0,
            eval        REAL NOT NULL DEFAULT 0
        );
        CREATE INDEX idx_hit_name ON hit (name);
        CREATE INDEX idx_hit_desc ON hit (descript);
        CREATE INDEX idx_hit_len ON hit (length);
        CREATE INDEX idx_hit_score ON hit (score);
        CREATE INDEX idx_hit_eval ON hit (evak);
        --
        CREATE TABLE xref (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            blast_id    INTEGER NOT NULL DEFAULT 0,
            query_id    INTEGER NOT NULL DEFAULT 0,
            hit_id      INTEGER NOT NULL DEFAULT 0
        );
        CREATE idx_xref_blastid ON xref (blast_id);
        CREATE idx_xref_queryid ON xref (query_id);
        CREATE idx_xref_hitid ON xref (hit_id);
        --
        CREATE TABLE hsp (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            hit_id      INTEGER NOT NULL DEFAULT 0,         -- Reference hit.id
            eval        REAL NOT NULL DEFAULT 0,
            ident       REAL NOT NULL DEFAULT 0,
            posit       REAL NOT NULL DEFAULT 0
        );
        CREATE INDEX idx_hsp_hitid  ON hsp (hit_id);
        CREATE INDEX idx_hsp_eval ON hsp (eval);
        CREATE INDEX idx_hsp_ident ON hsp (ident);
        CREATE INDEX idx_hsp_posit ON hsp (posit);
EOS

    eval {
        $dbh->do($sql);
    };
    
    if ($@) {
        warn "Create table 'hit' and indices failed!\n$@\n";
        
        return;
    }
    
    return 1;
}

=begin load_result
    : Load a blast result into database
    : load_result($o_result)
    : A Bio::Search::Result::ResultI object
    : null for errors
=cut

sub load_result {
    my $o_result = shift;
    
    my $sql;
    
    my $qry_name = $o_result->query_name;
    my $qry_desc = $o_result->query_description;
    my $qry_len  = $o_result->query_length;
    my $blast    = $o_result->algorithm;
    my $blastdb  = $o_result->database_name;
    
    eval {
        $dbh->begin_work;
        
        # Insert into table 'blast'
        $sql = "INSERT INTO blast (program, db) VALUES (?, ?);";
        my $sth = $dbh->prepare($sql);
        $sth->execute($blast, $blastdb);
        
        my $blast_id = $dbh->last_insert_id(undef, undef, 'blast', undef);
        
        # Insert into table 'query'
        $sql = "INSERT INTO query (name, descript, length) VALUES (?, ?, ?);";
        $sth = $dbh->prepare($sql);
        $sth->execute($qry_name, $qry_desc, $qry_len);
        
        my $query_id = last_insert_id(undef, undef, 'query', undef);
        
        # Parse hit tables
        while (my $o_hit = $o_result->next_hit) {
            my $hit_name = $o_hit->name;
            my $hit_len  = $o_hit->length;
            my $hit_desc = $o_hit->description;
            my $score    = $o_hit->raw_score;
            my $eval     = $o_hit->significance;
            
            $sql = "INSERT INTO hit (name, descript, length, score, eval)
                    VALUES (?, ?, ?, ?, ?);";
            my $sth = $dbh->prepare($sql);
            $sth->execute($hit_name, $hit_len, $hit_desc, $score, $eval);
            
            my $hit_id = last_insert_id(undef, undef, 'hit', undef);
            
            # Insert into table xref
            $sql = "INSERT INTO xref (blast_id, query_id, hit_id)
                    VALUES (?, ?, ?);";
            $sth = $dbh->prepare($sql);
            $sth->execute($blast_id, $query_id, $hit_id);
            
            # Parse HSPs
            while (my $o_hsp = $o_hit->next_hsp) {
                my $eval = $o_hsp->evalue;
                my $ident = $o_hsp->frac_identical;
                my $posit = $o_hsp->frac_conserved // 0;
                
                # Insert into table 'hsp'
                my $sql = "INSERT INTO hsp (hit_id, eval, ident, posit)
                            VALUES (?, ?, ?, ?);";
                my $sth = $dbh->prepare($sql);
                $sth->execute($hit_id, $eval, $ident, $posit);
            }
        }
        
        $dbh->commit;
    };
    
    if ($@) {
        warn "Error: Load result for '$qry_name' failed!\n$@\n";
        
        return;
    }
}

__END__