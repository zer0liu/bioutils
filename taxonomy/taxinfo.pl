#!/usr/bin/perl
=head1 NAME

  taxinfo.pl - Query and show taxonomy information.
  
=head1 DESCRIPTION

=head1 AUTHORS

  zeroliu-at-gmail-dit-com

=HISTORY

  0.1   2008-11-20
  
=cut

use strict;
use warnings;

use lib "/home/zeroliu/lib/perl";
use Data::Dumper;
use DBI;
use Getopt::Long;
use General;

my $usage = << "EOS";
Query and show taxonomy information.\n
Usage: taxinfo.pl -i <name> | -f <list>\n
Options:
  -i <name>:  Taxonomy name
  -f <list>:  Taxonomy name list.
  -o <order>: 'asc' - ascend 
              'desc' - descend
              Optional, default 'asc'.
EOS

my ($name, $flist, $order);

$order = 'asc';

GetOptions(
    "i=s" => \$name,
    "f=s" => \$flist,
    "o=s" => \$order,
    "h" => sub {die $usage;}
);

die $usage unless ($name or $flist);

# Database connection
my $host = '159.226.126.177';
my $db = 'taxon';
my $user = 'browser';
my $passwd = 'brw0nly';

my $dbh = DBI->connect(
    "DBI:mysql:$db:$host",
    $user, $passwd,
    {
        RaiseError => 1,
        PrintError => 1,
    }
) or die "Fatal: Connect to database $db on $host failed!\n$DBI::errstr\n";

if (defined $name) {
    my $rh_taxinfo = getTaxInfo($name, $dbh);
    
    outputTaxTitle(*STDOUT, $order);
    outputTaxa(*STDOUT, $rh_taxinfo, $order);
}
elsif (defined $flist) {    # A list file
    open(IN, $flist) or
        warn "Fatal: Open list file $flist failed!\n$!\n",
        $dbh->disconnect,
        exit 1;
    
    outputTaxTitle(*STDOUT, $order);
    
    while (my $line = <IN>) {
        next if ($line =~ /^#/);
        next if ($line =~ /^\s*$/);
        
        chomp($line);
        
        my $rh_taxinfo = getTaxInfo($line, $dbh);
        
        outputTaxa(*STDOUT, $rh_taxinfo, $order);
    }
}
else {
    warn $usage, "\n";
}

$dbh->disconnect;

exit 0;

#=====================================================================
#
#                             Subroutines
#
#=====================================================================

=head2 getTaxInfo
  Name:     getTaxInfo
  Usage:    getTaxInfo($name, $dbh)
  Function: Get taxonomy information of $name.
  Args:
  Return:   A hash reference.
=cut

sub getTaxInfo {
    my ($name, $dbh) = @_;
    
    my $taxid = getTaxId($name, $dbh) or
        warn "Error: No matched record of '$name'.\n",
        return;
    
    $name = getTaxName($taxid, $dbh);
    
    # Hash,
    # 'rank' => 'name'
    my %taxinfo;
    my ($parent_id, $rank);
    $parent_id = 0;
    
    while ($parent_id != 1) {
        ($parent_id, $rank)= getTaxNode($taxid, $dbh);
        
        $taxinfo{$rank} = $name;
        
        $taxid = $parent_id;
        $name = getTaxName($taxid, $dbh);
    }
    
    return \%taxinfo;
}

=head2 getTaxId
  Name:     getTaxId
  Usage:    getTaxId($name, $dbh)
  Function: Get taxonomy id of $name
  Args:
  Return:   A scalar
            undef for all errors.
=cut

sub getTaxId {
    my ($name, $dbh) = @_;
    my $num = 0;
    my $taxid;
    
    my $sql = "SELECT tax_id From `names` WHERE " .
        " name = " . $dbh->quote($name) .
        ";";
    
    my $sth = $dbh->prepare($sql) or
        warn "Error: Prepare query '$sql' failed!\n$DBI::errstr\n",
        return;
    
    $sth->execute or
        warn "Error: Execute query '$sql' failed!\n$DBI::errstr\n",
        return;
    
    while (my $rh_row = $sth->fetchrow_hashref) {
        $taxid = $rh_row->{'tax_id'};
        $num++;
    }
    
    warn "Caution: Multiple entry in 'names' of name $name.\n" if ($num > 1);
    
    return $taxid;
}

=head2 getTaxName
  Name:     getTaxName
  Usage:    getTaxName($taxid, $dbh)
  Function: Get taxonomy name by $id
  Args:
  Return:   A string
            undef for all errors
=cut

sub getTaxName {
    my ($id, $dbh) = @_;
    my $num = 0;
    my ($name, $class);
    
    my $sql = "SELECT name, class From `names` WHERE " .
        " tax_id = " . $dbh->quote($id) .
        ";";
    
    my $sth = $dbh->prepare($sql) or
        warn "Error: Prepare query '$sql' failed!\n$DBI::errstr\n",
        return;
    
    $sth->execute or
        warn "Error: Execute query '$sql' failed!\n$DBI::errstr\n",
        return;
    
    while (my $rh_row = $sth->fetchrow_hashref) {
        $name = $rh_row->{'name'};
        $class = $rh_row->{'class'};
        
        return $name if ($class eq 'scientific name');
        
        $num++;
    }
    
    warn "Caution: Multiple entry in 'names' of taxonomy id $id.\n" if ($num > 1);
    
    return $name;
}

=head2 getTaxNode
  Name:     getTaxNode
  Usage:    getTaxNode($taxid, $dbh)
  Function: Get Taxonomy node 'parent_id', 'rank' by $taxid ('tax_id')
  Args:
  Return:   An reference of array: ('parent_id', 'rank')
=cut

sub getTaxNode {
    my ($taxid, $dbh) = @_;
    
    my $num = 0;
    my ($parent_id, $rank);
    
    my $sql = "SELECT parent_id, rank From `nodes` WHERE " .
        " tax_id = " . $dbh->quote($taxid) .
        ";";
    
    my $sth = $dbh->prepare($sql) or
        warn "Error: Prepare query '$sql' failed!\n$DBI::errstr\n",
        return;
    
    $sth->execute or
        warn "Error: Execute query '$sql' failed!\n$DBI::errstr\n",
        return;
    
    while (my $rh_row = $sth->fetchrow_hashref) {
        $parent_id = $rh_row->{'parent_id'};
        $rank = $rh_row->{'rank'};
        $num++;
    }
    
    warn "Caution: Multiple entry in 'nodes' of taxonomy id $taxid.\n"
        if ($num > 1);
    
    return ($parent_id, $rank);
}

=head2 outputTaxa
  Name:     outputTaxa
  Usage:    outputTaxa(FH, $rh_taxa, $order)
  Function: Output query result
  Args:
  Return:   none
            undef for any errors.
=cut

sub outputTaxa {
    my ($fh, $rh_taxa, $order) = @_;
    
    my @taxa = keys(%{$rh_taxa});
    my $str = '';
    
    my @asc_taxa = qw(
        species
        genus
        family
        order
        class
        phylum
        kingdom
        superkingdom
    );
    
    my @desc_taxa = qw(
        superkingdom
        kingdom
        phylum
        class
        order
        family
        genus
        species
    );
    
    if ($order eq 'asc') {
        for my $taxon (@asc_taxa) {
            if (isInArray(\@taxa, $taxon)) {
                $str = $str . "\t" . $rh_taxa->{$taxon};
            }
            else {
                $str = $str . "\t" . '-';
            }
        }
    }
    elsif ($order eq 'desc') {
        for my $taxon (@desc_taxa) {
            if (isInArray(\@taxa, $taxon)) {
                $str = $str . "\t" . $rh_taxa->{$taxon};
            }
            else {
                $str = $str . "\t" . '-';
            }
        }
    }
    else {
        warn "Error: Incorrect output oeder.\n";
        return;
    }

    $str =~ s/^\t//;
    
    print $fh $str, "\n";
}

=head2 outputTaxTitle
  Name:     outputTaxTitle
  Usage:    outputTaxTitle($fh, $order)
  Function: Output taxon title.
  Args:
  Return:   None.
            undef for all errors.
=cut

sub outputTaxTitle {
    my ($fh, $order) = @_;
    
    my @asc_taxa = qw(
        Species
        Genus
        Family
        Order
        Class
        Phylum
        Kingdom
        Superkingdom
    );
    
    my $title_asc = join("\t", @asc_taxa);
    
    my @desc_taxa = qw(
        Superkingdom
        Kingdom
        Phylum
        Class
        Order
        Family
        Genus
        Species
    );
    
    my $title_desc = join("\t", @desc_taxa);
    
    if ($order eq 'asc') {
        print $fh $title_asc, "\n";
    }
    elsif ($order eq 'desc') {
        print $fh $title_desc, "\n";
    }
    else {
        warn "Error: Incorrect output oeder.\n";
        return;
    }
}
# End of script
