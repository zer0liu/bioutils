#! /usr/bin/env perl

=head1 NAME

    upd_fludb.pl - Revise the influenza virus sequence database parsed
                   and loaded by 'load_gbvirus.pl'

=SYNOPSIS

=DESCRIPTION

    This script will revise/update these fileds:

    Table 'virus', fileds:
        'strain'
        'serotype'
        'collect_date'
        'isolate'   - if possible
        'country'   - if possible
        'host'      - if possible

    Table 'sequence', fields:
        'segment'

    Table 'feature', fields:
        'gene'

=AUTHOR

    zeroliu-at-gmail-dot-com

=VERSION

    0.0.1   - 2018-03-19

=cut

use 5.010;
use strict;
use warnings;

use DBI;
use Smart::Comments;
use Switch;

my $fdb = shift or die usage();

our $dbh;

die "[ERROR] Connect to SQLite3 database failed!\n" 
    unless ($dbh = conn_db($fdb));

die "[ERROR] Set database bulk mode failed!\n"
    unless ( en_db_bulk() );

# my $num_upd_virus   = upd_tab_virus();
my $num_upd_seq     = upd_tab_seq();

# say "[DONE] Total ", $num_upd_virus, " virus records updated.";

$dbh->disconnect;

#===========================================================
#
#                   Subroutines
#
#===========================================================

=pod

  Name:     usage
  Usage:    usage()
  Function: Print usage information
  Returns:  None
  Args:     None

=cut

sub usage {
    say << "EOS";
Revise the influenza virus sequence database created by script 
'load_gbvirus.pl'
Usage:
  upd_fludb.pl <db>
EOS
}

=pod

  Name:     conn_db
  Usage:    conn_db($fdb)
  Function: Connect to given SQLite3 database file
  Returns:  A database handle
  Args:     A string

=cut

sub conn_db {
    my ($fdb)   = @_;

    my $dbh;

    unless (-f $fdb) {   # Whether is a plain file
        say "[ERROR] SQLite3 file '$fdb' error!";
        return;
    }

    eval {
	    $dbh = DBI->connect(
            "dbi:SQLite:dbname=$fdb", 
	        "", "",
	        {
	            RaiseError  => 1,
	            PrintError  => 1,
	            AutoCommit  => 1,
	        }
	    ) or die $DBI::errstr, "\n";
    };

    if ($@) {
        warn "[FATAL] Connect to SQLite3 database '$fdb' failed!\n";

        return;
    }

    return $dbh;
}

=pod

  Name:     en_db_bulk
  Usage:    en_db_bulk()
  Function: Enable bulk INSERT or UPDATE operation
  Args:     None
  Returns:  None
            undef for any errors

=cut

sub en_db_bulk {
    return unless (defined $dbh);

    eval {
        $dbh->do("PRAGMA synchronous = OFF");
        $dbh->do("PRAGMA cache_size  = 100000");    # Cache siez 100M
    };
    if ($@) {
        warn "[ERROR] Setup database PRAGMA failed!\n$@\n";
        return;
    }

    return 1;
}

# {{{ upd_tab_virus
=pod

  Name:     upd_tab_virus
  Usage:    upd_tab_virus()
  Function: Update table 'virus', fields:
                'genotype', 
                'strain',
                'serotype',
                'collect_date'
            ToDo:
                'country',
                'isolate'
  Args:     None
  Returns:  The number of successfully updated records

=cut

sub upd_tab_virus {
    my $sql_str = << "EOS";
SELECT 
    id,
    organism, 
    strain, 
    isolate, 
    serotype,
    country,
    collect_date
FROM
    virus
EOS
    
    my $sth;
    my $num_upd_vir = 0;

    eval {
        $sth    = $dbh->prepare($sql_str);
        $sth->execute;
    };

    if ($@) {
        warn "[ERROR] Query table 'virus' with SQL statement\n"
                , '$sql_str' , "\nfailed!\n", $@, "\n";
        return;
    }

    while (my $rh_row = $sth->fetchrow_hashref) {
        my $vir_id  = $rh_row->{'id'};
        my $org     = $rh_row->{'organism'};

        # If there was NO filed need to be updated
        # next if ( $rh_row->{'strain'} 
        #             and $rh_row->{'serotype'}
        #             and $rh_row->{'collect_date'} );

        # Debug
        say '=' x 60;
        say "Org\t===> ", $org;

        my ($cur_str, $cur_stype, $cur_date, $cur_gtype) = ('', '', '', '');

        # 'Influenza A virus (A/mallard/Iran/C364/2007(H9N2))'
        # 'Influenza B virus (B/Vienna/1/99)'
        if ($org =~ /\s(A|B|C|D)\s/) { # A|B|C|D type of flu virus
            $cur_gtype  = $1;
        }

        if ($org =~ /^Influenza.+?\((.+?)\s*\((.+?)?\)\)$/) { # w/ serotype
            $cur_str    = $1;   # Strain name
            $cur_stype  = $1;    # Serotype, if possible
        }
        elsif ($org =~ /^Influenza.+?\((.+?)\)/) { # w/o serotype
            $cur_str    = $1;
            # $cur_stype  = '';
        }
        else {
            warn "[ERROR] Unmatched organism:\t '", $org, "'.\n";
            # next;
        }

        # Debug
        # say "cur_str\t--+> ", $cur_str;

        $cur_date   = parse_str_date($cur_str) // '';

        # If there already were values of these fileds, do not touch it
        # The 'genotype' field is ALWAYS blank, 
        # so use 'genotype' field for A, B, C or D TYPE
        my $sql_str = 'UPDATE virus SET genotype = ' . 
            $dbh->quote( $cur_gtype ) . ', ';

        if ( ! $rh_row->{'strain'} ) {  # No 'strain' value
            $sql_str = $sql_str . ' strain = ' . 
                        $dbh->quote( $cur_str ) . ', ';
        }
        if ( ! $rh_row->{'serotype'} ) { # No 'serotype' value
            $sql_str = $sql_str . ' serotype = ' . 
                        $dbh->quote( $cur_stype ) . ', ';
        }
        if ( ! $rh_row->{'collect_date'} ) {# No 'collect_date' value
            $sql_str = $sql_str . ' collect_date = ' . 
                        $dbh->quote( $cur_date ) . ', ';
        }

        $sql_str    =~ s/,\s*$//;  # Remove tailing ','

        $sql_str    = $sql_str . ' WHERE id = ' . $dbh->quote( $vir_id );

        # Debug
        # say "Virus SQL --+> ", $sql_str;

        eval {
            my $sth = $dbh->prepare($sql_str);
            $sth->execute();
        };
        if ($@) {
            warn "[ERROR] Update table 'virus' in id '$vir_id' failed!\n";
            warn "[ERROR] ", $@, "\n";

            next;
        }
        else {
            $num_upd_vir++;
        }
    }

    return $num_upd_vir;
}
# }}}

# {{{ parse_str_date
=pod

  Name:     parse_str_date
  Usage:    parse_str_date($str)
  Function: Parse strain name and fetch collection date
  Args:     Strain name, a string
  Returns:  An string of digits.
            An empty string ('') for no date information.
            undef for any errors.
=cut

sub parse_str_date {
    my ($str)   = @_;

    return unless $str;

    my $cdate;

    if ($str =~ /\/(\d{2,4})$/) {
        $cdate  = $1;    
    }
    else {
        return '';
    }

    # For 2-digit year, in MySQL
    # 00 - 69   ==> 2000 - 2069
    # 70 - 99   ==> 1970 - 1999
    if (length($cdate) == 2) {
        if ($cdate >= 0 and $cdate <=20) { # i.e., 2000-2020
            $cdate  = '20' . $cdate;
        }
        else {  # i.e., 19xx
            $cdate  = '19' . $cdate;
        }
    }
    elsif (length($cdate) == 3) {   # 3-digits ?
        return '';
    }
    else {
        #
    }

    return $cdate;
}
# }}}

=pod

  Name:     upd_tab_seq
  Usage:    upd_tab_seq()
  Function: Update table 'sequence', filed:
                'segment'   - Segment PB2, PB1, PA, HA, NP, NA, MP, NS
  Args:     None
  Returns:  Number of successfully updated records

=cut

sub upd_tab_seq {
    my $sql_str = << "EOS";
SELECT
    id,
    definition,
    segment
FROM
    sequence
EOS

    my $sth;
    my $num_upd_seq = 0;

    eval {
        $sth    = $dbh->prepare($sql_str);
        $sth->execute();
    };
    if ($@) {
        warn "[ERROR] Query table 'sequence' with SQL statement\n'",
                "$sql_str", "'\nfailed!\n", $@, "\n";
        return;
    };

    while (my $rh_row = $sth->fetchrow_hashref) {
        my $seq_id  = $rh_row->{'id'};
        my $defn    = $rh_row->{'definition'};
        my $seg     = $rh_row->{'segment'};

        my $cur_seg = '';

        switch ($defn) {
            case /(?: A | A\/)/ { $cur_seg = seg4flu_A($defn, $seg) }
            case /(?: B | B\/)/ { $cur_seg = seg4flu_B($defn, $seg) }
            case /(?: C | C\/)/ { $cur_seg = seg4flu_C($defn, $seg) }
            case /(?: D | D\/)/ { $cur_seg = seg4flu_D($defn, $seg) }
            else        { warn "[ERROR] Unidentified definition '$defn'!\n" }
        }
        
        my $sql_str = "UPDATE sequence SET segment = " . 
                        $dbh->quote($cur_seg) .
                        " WHERE id = " . $dbh->quote($seq_id);
        
        # Debug
        # say "Seq SQL --+>", $sql_str;
        
        eval {
            my $sth = $dbh->prepare($sql_str);
            $sth->execute();
        };
        if ($@) {
            warn "[ERROR] Update table 'sequence' in id '$seq_id' failed!\n";
            warn "[ERROR] ", $@, "\n";
        }
        else {
            $num_upd_seq++;
        }
    }
    
    return $num_upd_seq;
}

# {{{ seg4flu_A
=pod

  Name:     seg4flu_A
  Usage:    seg4flu_A($defn, $seg)
  Function: Parse segment information for influenza A virus
  Args:     $defn   - Definition of sequence
            $$seg   - Segment information, if available
  Returns:  A string

=cut

sub seg4flu_A {
    my ($defn, $seg)    = @_;

    my $cur_seg = '';

    if ($seg ne '') {
        switch ($seg) {
            case ['1', 'PB2']               { $cur_seg = 'PB2' }
            case ['2', 'PB1']               { $cur_seg = 'PB1' }
            case ['3', 'PA']                { $cur_seg = 'PA' }
            case ['4', 'segment 4', 'RNA 4', 'HA']   { $cur_seg = 'HA' }
            case ['5', 'NP']                { $cur_seg = 'NP' }
            case ['6', 'segment 6', 'NA']   { $cur_seg = 'NA' }
            case ['7', 'segment 7', 'M', 'MA']      { $cur_seg = 'M' }
            case ['8', 'NS']                { $cur_seg = 'NS' }
            else { warn "[ERROR] Unmatched segment '$seg'!\n" }
        }
    }
    else { # No segment information
        switch ($defn) {
            case /PB2
                    | polymerase\ basic\ protein\ 2
                    | polymerase\ 2
                    | polymerase\ protein\ 2
                    | segment\ 1/x { $cur_seg = 'PB2' }
            case /PB1
                    | polymerase\ basic\ subunit\ 1
                    | polymerase\ basic\ protein\ 1
                    | polymerase\ 1
                    | segment\ 2/x { $cur_seg = 'PB1' }
            case /PA 
                    | polymerase\ acidic
                    | polymerase\ protein\ A
                    | polymerase\ protein
                    | polymerase\ acid\ protein
                    | segment\ 3/x { $cur_seg = 'PA' }
            case /HA
                    | hemagglutinin
                    | heamagglutinin
                    | hemmaglutinin
                    | haemagglutinin
                    | Hemagglutinin
                    | Haemagglutinin
                    | hemegglutinin
                    | polyprotein\ precursor
                    | H\ gene
                    | segment\ 4/x { $cur_seg = 'HA' }
            case /NP
                    | nucleoprotein
                    | nucleocapsid
                    | segment\ 5/x { $cur_seg = 'NP' }
            case /NA
                    | neuraminidase
                    | neuramidase
                    | segment\ 6/x { $cur_seg = 'NA' }
            case /matrix
                    | matix
                    | martix
                    | M1
                    | M2
                    | M\ protein
                    | membrane\ protein
                    | MA\ gene
                    | segment\ 7/x { $cur_seg = 'M' }
            case /NS
                    | nonstructural
                    | non\-structural
                    | segment\ 8/x { $cur_seg = 'NS' }
            else { warn "[ERROR] Unmatched definition '$defn'!\n" }
        }
    }
    return $cur_seg;
}
# }}}

# {{{ seg4flu_B
=pod

  Name:     seg4flu_B
  Usage:    seg4flu_B($defn, $seg)
  Function: Parse segment information for influenza B virus
  Args:     $defn   - Definition of sequence
            $$seg   - Segment information, if available
  Returns:  A string

=cut

sub seg4flu_B {
    my ($defn, $seg)    = @_;

    my $cur_seg = '';

    if ($seg ne '') {
        switch ($seg) {
            case ['1', 'PB1']       { $cur_seg = 'PB1' }
            case ['2', 'PB2']       { $cur_seg = 'PB2' }
            case ['3', 'PA']        { $cur_seg = 'PA' }
            case ['4', 'HA']        { $cur_seg = 'HA' }
            case ['5', 'NP']        { $cur_seg = 'NP' }
            case ['6', 'NA/NB']     { $cur_seg = 'NA/NB' }
            case ['7', 'M1/BM2']    { $cur_seg = 'M1/BM2' }
            case ['8', 'NS']        { $cur_seg = 'NS' }
            else { warn "[ERROR] Unmatched segment '$seg'!\n" }
        }
    }
    else { # No segment information
        switch ($defn) {
            case /PB2
                    /x { $cur_seg = 'PB2' }
            case /PB1
                    /x { $cur_seg = 'PB1' }
            case /PA 
                    | polymerase\ acidic\ protein/x { $cur_seg = 'PA' }
            case /HA
                    | hemagglutinin
                    /x { $cur_seg = 'HA' }
            case /NP
                    | nucleoprotein\ gene/x { $cur_seg = 'NP' }
            case /NA
                    | NB/x  { $cur_seg = 'NA/NB' }
            case /matrix
                    | M1
                    | BM2
                    | M\ gene/x { $cur_seg = 'M1/BM2' }
            case /NS
                    | nonstructural\ protein/x  { $cur_seg = 'NS' }
            else { warn "[ERROR] Unmatched definition '$defn'!\n" }
        }
    }
    return $cur_seg;
}
# }}}

# {{{ seg4flu_C
=pod

  Name:     seg4flu_C
  Usage:    seg4flu_C($defn, $seg)
  Function: Parse segment information for influenza C virus
  Args:     $defn   - Definition of sequence
            $$seg   - Segment information, if available
  Returns:  A string

=cut

sub seg4flu_C {
    my ($defn, $seg)    = @_;

    my $cur_seg = '';

    if ($seg ne '') {
        switch ($seg) {
            case ['1', 'PB2']           { $cur_seg = 'PB2' }
            case ['2', 'PB1']           { $cur_seg = 'PB1' }
            case ['3', 'P3']            { $cur_seg = 'P3' }
            case ['4', 'RNA4', 'HE']    { $cur_seg = 'HE' }
            case ['5', 'NP']            { $cur_seg = 'NP' }
            case ['6', 'M1/CM2']        { $cur_seg = 'M1/CM2' }
            case ['7', 'NS']            { $cur_seg = 'NS' }
            else { warn "[ERROR] Unmatched segment '$seg'!\n" }
        }
    }
    else { # No segment information
        switch ($defn) {
            case /PB2
                    | polymerase\ 2
                    | polymerase\ protein\ 2
                    /x { $cur_seg = 'PB2' }
            case /PB1
                    | polymerase\ 1
                    | polymerase\ protein\ 1
                    /x { $cur_seg = 'PB1' }
            case /P3 
                    | p3
                    | polymerase\ 3
                    /x { $cur_seg = 'P3' }
            case /HE
                    | hemagglutinin\-esterase
                    /x { $cur_seg = 'HE' }
            case /NP
                    | nucleocapsid
                    | nucleoprotein
                    /x { $cur_seg = 'NP' }
            case /matrix
                    | M1
                    | CM2
                    | M\ gene
                    | M\ RNA
                    /x { $cur_seg = 'M1/CM2' }
            case /NS
                    | nonstructural
                    | segment\ 7
                    /x  { $cur_seg = 'NS' }
            else { warn "[ERROR] Unmatched definition '$defn'!\n" }
        }
    }
    return $cur_seg;
}
# }}}

# {{{ seg4flu_D
=pod

  Name:     seg4flu_D
  Usage:    seg4flu_D($defn, $seg)
  Function: Parse segment information for influenza D virus
  Args:     $defn   - Definition of sequence
            $$seg   - Segment information, if available
  Returns:  A string

=cut

sub seg4flu_D {
    my ($defn, $seg)    = @_;

    my $cur_seg = '';

    if ($seg ne '') {
        switch ($seg) {
            case ['1', 'PB2']   { $cur_seg = 'PB2' }
            case ['2', 'PB1']   { $cur_seg = 'PB1' }
            case ['3', 'P3']    { $cur_seg = 'P3' }
            case ['4', 'HE']    { $cur_seg = 'HE' }
            case ['5', 'NP']    { $cur_seg = 'NP' }
            case ['6', 'P42']   { $cur_seg = 'P42' }
            case ['7', 'NS']    { $cur_seg = 'NS' }
            else { warn "[ERROR] Unmatched segment '$seg'!\n" }
        }
    }
    else { # No segment information
        switch ($defn) {
            case /PB2
                    /x { $cur_seg = 'PB2' }
            case /PB1
                    /x { $cur_seg = 'PB1' }
            case /P3 
                    | polymerase\ 3
                    /x { $cur_seg = 'P3' }
            case /HE
                    | hemagglutinin\-esterase
                    /x { $cur_seg = 'HE' }
            case /NP
                    | nucleoprotein
                    /x { $cur_seg = 'NP' }
            case /P42
                    /x { $cur_seg = 'P42' }
            case /NS
                    | nonstructural
                    /x  { $cur_seg = 'NS' }
            else { warn "[ERROR] Unmatched definition '$defn'!\n" }
        }
    }
    return $cur_seg;
}
# }}}

