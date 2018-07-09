#!/usr/bin/perl
# {{{ POD
=head1 NAME

  load_gbvirus.pl - Parse and import GenBank format virus sequences into
					database.

=head1 DESCRIPTION

  Database diagram described in file:
  '~/scripts/'

  Available functions:
  - Insert
  - Delete: Delete 'seq', 'virus', 'feature', 'xref_sr',
    'db_xref' and 'misc_qualif'.
    It won't touch tables 'reference', 'xref_ra' and 'author'.
  - Update: Delete relative records first and insert again.


=head1 AUTHOR

  zeroliu-at-gmail-dot-com

=head1 VERSION

  1.00      2008-10-29  Create database according to
            'bac_seq' database.
  1.01      2008-10-30  Minor modification.
  1.02      2008-10-31  Minor modification.
                        Almost completed.
  1.11      2008-11-04  Correct fuction 'chgGBDate'.
  1.21      2008-11-05  New function 'update' & 'delete' records.
  1.30      2008-11-26  Modified script for new database diagram V1.10.
                        Correct insert 'reference.pmid' problem.
  1.40	    2009-04-29	Modified from 'load_virseq.pl'.
  1.41	    2009-04-30	New field 'segment in table 'seq'.
  1.45	    2009-04-30	New code for GenBank date '10/12/2004'.
						Parse 'source' tag '/chromosome' as 'segment'
							into table 'seq'.
						Parse 'source' tag '/PCR_primers' into table 'seq'.
						parse 'source' tag '/collected_by' into table 'virus'.
  1.50	    2009-05-21	Correct parse CDS related spliced nucleotides sequences.
						Correct insert reference SQL secript.
  2.00		2009-06-26	Converted to PostgreSQL version.
  2.10      2009-07-16  Correct errors of insert reference records, where
                        - lack of a 'next' after chkRef()
                        - missing 'authors' field for 'Unpublished',
                          'Direct Submission' and 'Patent' record.
  3.00      2011-10-25  Branch for SQLite3 database
  3.01      2011-10-27  Fixed bugs.
  3.10      2011-10-28  Fix CDS nt sequence 'codon_start'.
  3.11      2011-11-04  Bug fix.
  3.12      2015-01-15  Fix bug: Error while parse date like '2015-01-15'.
                        Append a '#' to the unclear date:
                            '2005'      -> '2005-01-01##'
                            '2010-02'   -> '2010-02-01#'
  3.20      2018-03-12  Modified for updated database schema.
                            Table 'sequence', two more fileds
                                'mod_date'
                                'version'
                            Table 'feature':
                                'locus' -> 'locus_tag'
                        Fix bug: collection_date='Unknown'
  3.21      2018-03-15  Modified for updated database schema.
                            Table 'reference', one more field
                                'consortium' - 'CONSRTM' field
                        Still existing bug:
                            Serial consortium connected.
  3.22      2010-07-09  It will NOT check whether virus exists before
                        insert into table 'virus'. 
                        This means, 
                        one sequence has one related virus information

=cut
# }}} POD

use 5.010;
use strict;
use warnings;

use Bio::SeqIO;
# use Data::Dumper;
use DBI;
use Getopt::Long;
use Smart::Comments;

my ($fin, $fdb);
my $cmd = 'ins';

GetOptions(
    "i=s" => \$fin,
    "c=s" => \$cmd,
    "d=s" => \$fdb,
    "h" => sub { usage() },
);

usage() unless ($fin);

# {{{ connect db
# Database parameters.

# Connect to database
# my $dbh;
our $dbh;

eval {
	$dbh = DBI->connect(
	    "dbi:SQLite:dbname=$fdb",
        "", "",
	    {
	        RaiseError => 1,
	        PrintError => 1,
            AutoCommit => 1,
	    }
	) or die $DBI::errstr, "\n";
};

if ($@) {
    warn "Fatal: Connect to database '", $fdb, "' failed!\n";

    exit 1;
}
# }}} connect db

# Operation commands
#
# {{{ cmd 'Delete'
#
# command 'Delete'
if ($cmd eq 'del') {
    # The input file would be list of accession numbers
    open(IN, $fin)
        or die "Fatal: Open file $fin failed.\n$!\n";

    while (my $line = <IN>) {
        next if ($line =~ /^#/);
        next if ($line =~ /^\s*$/);

        chomp($line);

        if ( chkAccNum($line, $dbh) ) {   # accession exists
            delSeq($line, $dbh)
                or warn "Error: Delete seq '$line' failed.\n";
        }
        else {  # no this accession
            warn "Error: Accession Number '$line' does NOT exist!\n";
        }
    }

    close(IN);
}
# }}} cmd 'Delete'
# {{{ cmd 'Insert/Update'
# Operation 'INSERT' or 'UPDATE'
elsif ( ($cmd eq 'ins') or ($cmd eq 'upd') ) {
	# Create Bio::SeqIO object
    my $o_seqi = Bio::SeqIO->new(
        -file   => $fin,
        -format => 'genbank',
    )
    or die "Error: Cannot init SeqIO object with file '$fin'. $!\n";

    # Inserted seq id
    my $seq_id;

    # Number of inserted reords
    my %num = (
        'seq' => 0,
        'ref' => 0,
        'gene' => 0,
        'cds' => 0,
        'misc' => 0,
        'vir' => 0,
    );

    # Main cycle
    while (my $o_seq = $o_seqi->next_seq) {
#===================================================
#
# Begin transaction
#
#===================================================
        say "Working on:\t", $o_seq->accession_number;

		$dbh->begin_work;

        eval {{
		# Check whether this seq had already been imported
		if ( chkAccNum($o_seq->accession_number, $dbh) ) {
		    my $acc = $o_seq->accession_number;

			if ($cmd eq 'ins') {	# 'INSERT'
				warn "Genome '$acc' already eixsts.\n";

                $dbh->commit;

				next;
			}
			else {	# a fake 'Update': delete records first, then insert new.
			# Delete seq related records,
			# then insert seq as new records.
			delSeq($o_seq->accession_number, $dbh)
			    or warn "Error: Delete seq '$acc' failed.\nCannot continue update.\n",
			    exit 1;
			}
		}

		# Parse annotations.
		my $o_ann = $o_seq->annotation();

		# Parse Feature tables
		for my $o_feat ($o_seq->get_SeqFeatures()) {
# {{{ Primary tag 'source'
		    # Primary tag 'source'
		    # Parse & import for table 'virus' & 'seq'
			if ($o_feat->primary_tag eq 'source')  {
                #-------------------------------------------------
                # Check whether the organism/virus already exists
                # This violated the subsequent parse of LOCUS and feature
                my $mod_date    = ($o_seq->get_dates)[0];
                $mod_date       = chgGBDate( $mod_date );
                
                # Get taxon ID
                my $taxon_id    = '';

                if ($o_feat->has_tag('db_xref')) {
                    my @val = $o_feat->get_tag_values('db_xref');
                    $taxon_id = $1 if ($val[0] =~ /taxon:(\d+)/);
                }
                else {
                    die "ERROR: No taxon ID found in GenBank file!\n";
                }
                
                #-------------------------------------------------

                # Disabled to check whether virus already existed
                # in Table 'virus', since there were NO fileds
                # to sure the UNIQUE virus exists.
=pod
                # Field 'id' in Table 'virus', also referenced in
                # Table 'sequence' as 'vir_id'
                my $vir_id  = '';

                if ( $vir_id = chkVirId($taxon_id, $mod_date, $dbh) ) {
                    # Organism/virus already exists
                    # $vir_id
                }
		        else {  # Not exist, retrieve inserted virus record id.
				    $vir_id = insTableVir($o_feat, $dbh);

					unless ($vir_id) {
					    warn "Error: Insert table 'virus' failed.\n";
					    exit 1;
					}

                    $num{'vir'}++;
                }
=cut

                my $vir_id = insTableVir($o_feat, $dbh);

			    unless ($vir_id) {
				    warn "Error: Insert table 'virus' failed.\n";
					exit 1;
				}

                $num{'vir'}++;
 
		        # Prepare data for table 'seq'
		        # Because of its fields come from different segment of Genbank file,
		        # here is a dirty way to do this.

				my %seq;

				$seq{'definition'} = $o_seq->desc;
				$seq{'accession'} = $o_seq->accession_number;
				$seq{'vir_id'} = $vir_id;
				$seq{'seq_start'} = $o_feat->start;
				$seq{'seq_end'} = $o_feat->end;

                # In V3.2.0
                # 'version' and 'mod_date'
                $seq{'version'} = $o_seq->seq_version;
                my @seq_dates   = $o_seq->get_dates;
                $seq{'mod_date'}    = chgGBDate( $seq_dates[0] );

				if ($o_feat->has_tag('mol_type')) {
				    my @values = $o_feat->get_tag_values('mol_type');
				    $seq{'mol_type'} = array2str( \@values, ' ');
				}

				if ($o_feat->has_tag('segment')) {
				    my @values = $o_feat->get_tag_values('segment');
				    $seq{'segment'} = array2str( \@values, ' ');
				}

				if ($o_feat->has_tag('chromosome')) {
				    my @values = $o_feat->get_tag_values('chromosome');
				    my $chr = array2str( \@values, ' ' );

				    if ($chr =~ /^segment\s(\d+)/) {
						$seq{'segment'} = $1;
				    }
				    else {
						warn "Unmatched chromosome:\t'$chr'\n";
				    }
				}

				if ($o_feat->has_tag('PCR_primers')) {
					my @values = $o_feat->get_tag_values('PCR_primers');
					my $primers = array2str( \@values, ' ' );

					$seq{'pcr_primers'} = $primers;
				}
			# Get COMMENT
				my @comments = $o_ann->get_Annotations('comment');
				for my $val (@comments) {
					$seq{'comment'} = $val->text
					if ($val->tagname eq 'comment');
				}
				$seq{'seq'} = $o_seq->seq;

				unless ( $seq_id = insTableSeq(\%seq, $dbh) ) {
				    warn "Error: Insert into table 'seq'\n";
				    exit 1;
				}

		        # Next, insert records of table 'reference',
		        # since table 'reference' need 'seq.id'
				my $ra_refs = getSeqRefs($o_ann);

		        # Insert table reference and get inserted ids.

				unless ( my ($rh_refids, $num) = insTableRef($ra_refs, $dbh) )  {
				    warn "Error wihle parse & insert tables 'reference' & 'authors'.\n";
				    exit 1;
				}
				else {
                    # DEBUG
		            # Insert table 'xref_sr'
				    my %param = (
						'one' => 'seq_id',
						'one_val' => $seq_id,
						'multi' => 'ref_id',
						'multi_val' => $rh_refids,
				    );
                    # Parameters: %param

				    unless (insXrefTable('xref_sr', \%param, $dbh) ) {
					    warn "Error: Insert table 'xref_sr' failed.\n";
    					exit 1;
				    }

				    $num{'ref'} += $num;
				}
		    }
# }}} Primary tag 'source'

# {{{ Other: gene, CDS, RNA, etc.
		    else {  # Other features: gene, CDS, RNA, etc.
				my $type = $o_feat->primary_tag;

				my $rh_feat = parse_feat($o_feat, $type);
				unless ($rh_feat) { # Exit if parse failed
				    warn "Error: Parse feature $type failed.\n";
				    exit 1;
				}

		        # Add 'seq_id' and 'type'
				$rh_feat->{'common'}->{'seq_id'} = $seq_id;
				$rh_feat->{'common'}->{'ftype'} = $type;

		        # Insert into table 'feature'
				unless ( insFeatTable($rh_feat, $type, $dbh) ) {
				    warn "Error: Insert feature $type failed.\n";
				    exit 1;
				}

		        # Set counters
				if ($type eq 'gene') { $num{'gene'}++; }
				elsif ($type eq 'CDS') { $num{'cds'}++; }
				else { $num{'misc'}++; }
		    }
# }}} Other: gene, CDS, RNA, etc.

		}

#===================================================
#
# Commit
#
#===================================================
        $dbh->commit;
		}};

        if ($@) {
            warn "Error: Insert data failed!\n";
            # warn $DBI::errstr, "\n";
            # warn $dbh->errstr(), "\n";
            # warn "Rollbacking ...\n";

            warn '-' x 60, "\n";
            warn $@, "\n";
            warn '-' x 60, "\n";

            $dbh->rollback;

            exit 1;
        }

        # DEBUG
        # print "\n", '#'x70, "\n", "\n";

		$num{'seq'}++;
    }

   # Output insert results
    my $cmd_str;
    $cmd_str = "inserted" if ($cmd eq 'ins');
    $cmd_str = "updated" if ($cmd eq 'upd');

    print << "EOS";
==================================================
Parse & insert into database completed.
  $num{'seq'} sequences $cmd_str;
  $num{'vir'} viruses $cmd_str;
  $num{'ref'} references $cmd_str;\n
  $num{'gene'} genes $cmd_str;
  $num{'cds'} CDSes $cmd_str;
  $num{'misc'} misc features $cmd_str.
EOS

}
# }}} cmd 'Insert/Update'
else {
    print "Error: Wrong command of $cmd!\n\n";
    usage();
}

$dbh->disconnect;

exit 0;

# {{{ subroutine

#=====================================================================
#
#			      Subroutines
#
# usage - Show usage information.
# chkAccNum - Check the existance of an accession number.
# getSeqRef - Get reference information of a sequence.
# insTableRef - Insert records into table 'reference'.
# parse_location - Parse reference location information, fetch date,
#                  pages, journal, etc.
# chkRefPmid - Check the existance of a PUBMED id (pmid).
# chgGBDate - Convert GenBank format date to 'yyyy-mm-dd' format.
# insTableVir - Insert records into table 'virus'.
# chkVirId - Check whether organism already exists. (dismissed)
# insTableSeq - Insert records into table 'seq'.
# parse_feat - parse feature tag-qualifiers.
# insFeatTable - Insert records into table 'feature'.
# chkRef - Check whether a location of a refereoce record
#                  already exists.
# _chkAuthor - Chkeck the existance of author name.
# insXrefTable - Insert records for a cross reference table, which
#               is a one-multi mapping table.
# _version - Provide version of this script. (dismissed)
# delSeq - Delete genmoe records, dismiss reference and author.
#
#=====================================================================

# {{{ usage

=head2 usage

  Name:    usage
  Usage:   usage()
  Fuction: Show usage information.
  Args:    None.
  Returns: None.

=cut

sub usage {
    my $ver = "VERSION 2.10\t2009-6-26\n";

    warn << "EOS";
load_gbvirus.pl $ver
Import GenBank format virus seq into database.\n
Usage: load_gbvirus.pl -i <infile> [-c <ins|upd|del>] [-d <file>]
  -i <infile>: Input file, GenBank format sequence file,
  -c <cmd>:    Operate command, ins|upd|del
               ins: INSERT new records into database,
               upd: UPDATE database,
               del: DELETE records from database.
  -d <file>:   Database resource filename.
               Default is '.dbrc' file under current directory.\n
NOTE: For 'delete' function, the input file must be a list of Accession Numbers.
EOS

exit 0;
}

# }}} usage

# {{{ chkAccNum

=head2 chkAccNum
  Name:     chkAccNum
  Usage:    chkAccNum($acc, $dbh)
  Function: Check whether a accession number is already in database.
  Args:     $acc - Scalar. Accession Number;
            $dbh - Database handle.
  Return:   Scalar - Record id.
            undef for all errors.
=cut

sub chkAccNum {
    my ($acc, $dbh) = @_;

    my $seq_id;

#    my $qrystr = "SELECT id FROM `seq` " .
#        "WHERE accession = " . $dbh->quote($acc) . ";";
    my $qrystr = "SELECT id FROM sequence " .
#        "WHERE accession = " . $dbh->quote($acc) . ";";
        "WHERE accession = ?";

    my $sth = $dbh->prepare($qrystr);
    unless ($sth) {
        warn "Error: Prepare SQL $qrystr.\n$DBI::errstr.\n";
        return;
    }

    unless ($sth->execute( $acc ) ) {
        warn "Error: Execute SQL error.\n$DBI::errstr.\n";
        return;
    }

    while (my $rh_row = $sth->fetchrow_hashref) {
        $seq_id = $rh_row->{'id'};
    }

    return $seq_id;
}

# }}} chkAccNum

# {{{ getSeqRefs

=head2 getSeqRefs

  Name:    getSeqRefs
  Usage:   getSeqRefs($)
  Fuction: Get references information.
  Args:    Bio::AnnotationCollectionI object
  Return:  Reference to an array of refs.

=cut

sub getSeqRefs {
    my ($ann) = @_;

    my @refs;

    foreach my $o_ref ($ann->get_Annotations('reference')) {

        my $ref = {
            'start' => $o_ref->start // '',
            'end' => $o_ref->end // '',
            'authors' => $o_ref->authors // '',
            'title' => $o_ref->title // '',
            'medline' => $o_ref->medline // '',
            'pubmed' => $o_ref->pubmed // '',
            'publisher' => $o_ref->publisher // '',
            'location' => $o_ref->location // '',
            'db' => $o_ref->database // '',
            'consortium' => $o_ref->consortium // '',
        };

        push @refs, $ref;

        # say '---+> ', $o_ref->consortium;
        # DEBUG
        # print "Medline = ", $ref->{'medline'}, "\n"
        #    if (defined $ref->{'medline'});
    }

    return \@refs;
}

# }}} getSeqRefs

# {{{ insTableRef

=head2 insTableRef
  Name:     insTableRef
  Usage:    insTableRef($ra_refs, $dbh, $cmd)
  Function: Insert records into table 'reference', including table 'authors'.
            For repeated records, identical PMID will be checked.
  Args:     An array reference, and a DBI handle
  Return:   - Reference of array for inserted record ids of table 'reference'
            - Scalar, inserted records number.
            undef for any errors.
  Note:     There may be more than 1 records inserted!
=cut

sub insTableRef {
# Don't need $rh_tableids now.

    my ($ra_refs, $dbh) = @_;

    # Inserted table 'reference' IDs
    my @ref_ids;
    my $sql;        # SQL statement
    my $num = 0;    # Number of successfully inserted records.

    for my $ref ( @{$ra_refs} ) {
        # Initial reference title to '' if it was not defined
        $ref->{'title'} = '' unless ( $ref->{'title'} );

        # {{{ Ref: unpublished
        if ($ref->{'location'} =~ /^Unpublished/) { # is an unpublished reference
			# unless (defined $ref->{'title'}) {
			# 	$ref->{'title'} = '';
			# }

			if (my $ref_id = chkRef('title', $ref->{'title'}, $dbh)) {
                push @ref_ids, $ref_id;
                next;
            }

            my @ref_fields = qw{title authors location db consortium};
            my @ref_values = ($ref->{'title'}, $ref->{'authors'}, 
                                $ref->{'location'}, $ref->{'db'},
                                $ref->{'consortium'} );

            $sql = array2PgIns(\@ref_fields, \@ref_values, 'reference', $dbh);

        }
        # }}} Ref: unpublished
        # {{{ Ref: direct submission
        elsif ( $ref->{'title'}  eq 'Direct Submission' ) {    # is a Direct submission
            # Check whether this reference already exists
            # If exist, store it in array '@ref_ids'
            if (my $ref_id = chkRef('location', $ref->{'location'}, $dbh) ) {
                push @ref_ids, $ref_id;

                next;
            }

            # Parse location information first, get publish date
            my $loc_info = parse_location($ref->{'location'});

            $ref->{'authors'} = '' unless (defined $ref->{'authors'});

            my @ref_fields = qw{title authors location pub_date db 
                                consortium};
            my @ref_values = ( $ref->{'title'}, $ref->{'authors'}, $ref->{'location'}, $loc_info->{'date'}, $ref->{'db'}, $ref->{'consortium'} );

            $sql = array2PgIns(\@ref_fields, \@ref_values, 'reference', $dbh);
        }
        # }}} Ref: direct submission
        # {{{ Ref: patent
        elsif ($ref->{'location'} =~ /^Patent/) {   # is a patent
            # Check whether this reference already exists
            # If exist, store it in array '@ref_ids'
            if (my $ref_id = chkRef('location', $ref->{'location'}, $dbh) ) {
                push @ref_ids, $ref_id;

                next;
            }

            my $loc_info = parse_location($ref->{'location'});

            my @ref_fields = qw{title authors location pub_date db 
                                consortium};

            # my $title = $ref->{'title'} || '';

            my @ref_values = ($ref->{'title'}, $ref->{'authors'}, $ref->{'location'}, $loc_info->{'date'}, $ref->{'db'}, $ref->{'consortium'});

            $sql = array2PgIns(\@ref_fields, \@ref_values, 'reference', $dbh);
        }
        # }}} Ref: patent
        # {{{ Ref: journal
        else {  # is a normal journal
            # If already exists this PubMed id
            if (my $ref_id = chkRefPmid($ref->{'pmid'}, $dbh) ) {
                push @ref_ids, $ref_id;
                next;
            }
            # In case there is no PubMed id available,
            # check 'location'
            elsif ($ref_id = chkRef('location', $ref->{'location'}, $dbh)) {
                push @ref_ids, $ref_id;
                next;
            }
            else {
                # do nothing
            }

            my $loc_info = parse_location( ($ref->{'location'}) );

            my (@ref_fields, @ref_values);

            if ( defined $ref->{'title'} ) {
                push @ref_fields, 'title';
                push @ref_values, $ref->{'title'};
            }
            # else {
            #     push @ref_fields, "title";
            #     push @ref_values, "";
            # }

            if ( defined $ref->{'location'} ) {
                push @ref_fields, 'location';
                push @ref_values, $ref->{'location'};
            }
            if ( defined $ref->{'db'} ) {
                push @ref_fields, 'db';
                push @ref_values, $ref->{'db'};
            }
            if (defined $ref->{'authors'}) {
                push @ref_fields, 'authors';
                push @ref_values, $ref->{'authors'};
            }
            if (defined $ref->{'pubmed'}) {
                push @ref_fields, 'pmid';
                push @ref_values, $ref->{'pubmed'};
            }
            if (defined $loc_info->{'journal'}) {
                push @ref_fields, 'journal';
                push @ref_values, $loc_info->{'journal'};
            }
            if (defined $loc_info->{'volume'}) {
                push @ref_fields, 'volume';
                push @ref_values, $loc_info->{'volume'};
            }
            if (defined $loc_info->{'issue'}) {
                push @ref_fields, 'issue';
                push @ref_values, $loc_info->{'issue'};
            }
            if (defined $loc_info->{'start'}) {
                push @ref_fields, 'pg_start';
                push @ref_values, $loc_info->{'start'};
            }
            if (defined $loc_info->{'end'}) {
                push @ref_fields, 'pg_end';
                push @ref_values, $loc_info->{'end'};
            }
            if (defined $loc_info->{'date'}) {
                push @ref_fields, 'pub_date';
                push @ref_values, $loc_info->{'date'};
            }
            if (defined $ref->{'consortium'}) {
                push @ref_fields, 'consortium';
                push @ref_values, $ref->{'consortium'};
            }

            $sql = array2PgIns(\@ref_fields, \@ref_values, 'reference', $dbh);
        }
        # }}} Ref: journal

        # DEBUG
        # print '-'x20, 'insTableRef', '-'x20, "\n", $sql, "\n", '-'x50, "\n";

        # SQL: $sql

        $dbh->do($sql);

        $num++;

        # Get just inserted id of table 'reference'
        # which include both 'Direct submission' & normal journal records
        # my $ref_id = mysqlInsId($dbh);
		my $ref_id = $dbh->last_insert_id(undef, undef, 'reference', undef);

        # Store ids into an array to be returned.
        push @ref_ids, $ref_id;

    }

    return(\@ref_ids, $num);
}

# }}} insTableRef

# {{{ parse_location

=head2 parse_location

  Name:     parse_location
  Usage:    parse_location($)
  Function: Parse location information, fetch publish date, pages, journal,
            etc information.
            Parse 'pulished reference' and 'Direct submission',
            'unpublished' will be dissmissed.
  Args:     A string.
  Return:   Hash of array.

=cut

sub parse_location {
    my ($location) = @_;
    my %info;

    # For journals
    # Match 'Nature 390 (6657), 249-256 (1997)'
    # Acta Virol. 40 (5-6), 303-309 (1996)
    # J. Gen. Virol. 80 (Pt 7), 1665-1671 (1999)
    if ($location =~ /^([\w\.\s]+?)\s(\d+)\s\(([\w\s\-]+)\),\s(\d+)\-(\d+)\s\((\d+)\)/) {
        %info = (
            'journal' => $1,
            'volume' => $2,
            'issue' => $3,
            'start' => $4,
            'end' => $5,
            'date' => $6,    # To fit MySQL date format
        );
        $info{'date'} .= '-01-01';
    }
    # Match 'Virol. J. 5 (1), 16 (2008)'
    # Match 'PLoS Pathog. 5 (3), E1000350 (2009)'
    elsif ($location =~ /^([\w\.\s]+?)\s(\d+)\s\(([\w\s\-]+)\),\s([\w\d]+)\s\((\d+)\)/) {
        %info = (
            'journal' => $1,
            'volume' => $2,
            'issue' => $3,
            'start' => $4,
        #    'end' => $5,
            'date' => $5,    # To fit MySQL date format
        );
        $info{'date'} .= '-01-01';
    }
    # Match 'Virus Res. 124, 139-150 (2007)'
    elsif ($location =~ /^([\w\.\s]+?)\s(\d+),\s(\d+)\-(\d+)\s\((\d+)\)/) {
        %info = (
            'journal' => $1,
            'volume' => $2,
            'start' => $3,
            'end' => $4,
            'date' => $5,    # To fit MySQL date format
        );
        $info{'date'} .= '-01-01';
    }
    # Match '(er) Nucleic Acids Res. 34 (1), 1-9 (2006)'
    elsif ($location =~ /^(\(er\)[\w\.\s]+)\s(\d+)\s\((\d+)\),\s(\d+)\-(\d+)\s\((\d+)\)/) {
        %info = (
            'journal' => $1,
            'volume' => $2,
            'issue' => $3,
            'start' => $4,
            'end' => $5,
            'date' => $6 . '-01-01',    # Fit MySQL date format.
        );
    }
    # Match 'PLoS Pathog. 5 (3), E1000350 (2009)'
    # elsif ($location =~ /^([\w])/)
    # Direct submission, parse date. Other part looks as journal
    # 'Submitted (01-OCT-2007) National Center for Biotechnolog'
    elsif ($location =~ /^Submitted\s+\((\d{2}\-[A-Za-z]{3}\-\d{4})\)\s+(.+?)$/) {
        my $gbdate = $1;
        $info{'journal'} = $2;

        my $date;

        unless ( $date = chgGBDate($gbdate) ) {
            warn "Wrong month string!\n";
            return;
        }

        $info{'date'} = $date;
    }
    # Patent, parse date only
    # Patent: JP 2004089185-A 52 25-MAR-2004;
    elsif ($location =~ /^Patent.*?(\d{2}\-[A-Za-z]{3}\-\d{4})/) {
        my $gbdate = $1;
        my $date;

        unless ($date = chgGBDate($gbdate)) {
            warn "Wrong month string!\n";
            return;
        }

        $info{'date'} = $date;
    }
    # Published Only in Database
    # Published Only in Database (2008)
    elsif ($location =~ /^Published\sOnly\sin\sDatabase\s\((\d+)\)/) {
        my $gbdate = $1;
        my $date;

        unless ($date = chgGBDate($gbdate)) {
            warn "Wrong month string!\n";
            return;
        }

        $info{'date'} = $date;
    }
    # If contains 'Year' information, parse date and other parts as journal.
    elsif ($location =~ /(\d{4})/) {
		my $gbdate = $1;
		$info{'journal'} = $location;

		my $date;

		unless ($date = chgGBDate($gbdate)) {
		    warn "Wrong match string!\n";
		    return;
		}

        $info{'date'} = $date;
    }
    else {  # Not matched.
        #warn "DEBUG: Unmatched 'location' => '$location'\n\n";
		$info{'journal'} = $location;
        return;
    }

    return \%info;
}

# }}} parse_location

# {{{ chkRefPmid

=head2 chkRefPmid

  Name:     chkRefPmid
  Usage:    chkRefPmid($pmid, $dbh)
  Function: Check whether a pmid already exists.
            This subroutine assume there is ONLY ONE record for a PubMed ID.
  Args:     A string (PubMed id) and a database handle.
  Return:   A string (PMID), digits.
            undef for not found

=cut

sub chkRefPmid {
    my ($pmid, $dbh) = @_;
    my $ref_id;     # Reference id, in Table 'reference'

    my $qrystr = "SELECT id FROM reference " .
        "WHERE pmid = " . $dbh->quote($pmid) . ";";

    my $sth = $dbh->prepare($qrystr);
    unless ($sth) {
        warn "$DBI::errstr.\n";
        return;
    }

    unless ($sth->execute() ) {
        warn "$DBI::errstr.\n";
        return;
    }

    while (my $rh_row = $sth->fetchrow_hashref) {
        $ref_id = $rh_row->{'id'};

        print "Ref: PUBMED $pmid already exists int reference table with id: $ref_id\n";
    }

    return $ref_id;
}

# }}} chkRefPmid

# {{{ chgGBDate

=head2 chgGBDate
    Name:    chgGBDate
    Usage:   chgGBDate($)
    Func:    Convert GenBank format date 'DD-Mmm-YYYY' to MySQL format
             'YYY-MM-DD'.
             e.g., '01-OCT-2000' to '2000-10-01'
    Args:    A string.
    Return:  A string for success.
             undef for any errors.
=cut

sub chgGBDate{
    my ($str) = @_;
    my $date;

    if ($str =~ /^(\w+)\s(\d{4})/) {  # e.g., Autumn 2003
        my $month;
        my $year = $2;

        $month = '03' if ($1 =~ /Spring/);
        $month = '06' if ($1 =~ /Summer/);
        $month = '09' if ($1 =~ /Autumn/);
        $month = '12' if ($1 =~ /Winter/);

        $date = $year . '-' . $month;
    }
    elsif ($str =~ /[A-Za-z]{3}/) {   # 'DD-MMM-YYYY' or 'YYYY-MMM'
    # Replace month abbreviation to digits.
        SWITCH: {
            $str =~ s/JAN|Jan/01/ and last;
            $str =~ s/FEB|Feb/02/ and last;
            $str =~ s/MAR|Mar/03/ and last;
            $str =~ s/APR|Apr/04/ and last;
            $str =~ s/MAY|May/05/ and last;
            $str =~ s/JUN|Jun/06/ and last;
            $str =~ s/JUL|Jul/07/ and last;
            $str =~ s/AUG|Aug/08/ and last;
            $str =~ s/SEP|Sep/09/ and last;
            $str =~ s/OCT|Oct/10/ and last;
            $str =~ s/NOV|Nov/11/ and last;
            $str =~ s/DEC|Dec/12/ and last;
            return;     # return undef if not matched.
        }

        my @array = split(/-/, $str);

        @array = reverse( @array );

        $date= join('-', @array);
    }
    elsif ($str =~ /^\d+$/) {   # Year ONLY: e.g., 1986
        $date = $str;
    }
    elsif ($str =~ /^(\d+)\/(\d+)\/(\d+)$/) {   # e.g., 10/12/2004
        $date = join("-", ($3, $1, $2));
    }
    elsif ($str =~ /^[\d\-]+$/) {   # e.g., 2014-04, or 2014-05-12
        $date   = $str;
    }
    elsif ($str =~ /Unknown/) {
        $date   = '';
    }
    else {
        warn "[Warning] Unidentified date format: '$str'!\n\n";

        $date   = '';
        #exit 1;
        # return;
    }

    # In V3.2.0
    # Commented for simplication
    #
    # Fill incomplete date, such as 'YYYY' and 'YYYY-MM'
    # with '0'
#    if ($date =~ /^\d{4}$/) {    # 'YYYY'
#        # $date .= '-01-01';
#        $date .= '-01-01##';
#    }
#    elsif ($date =~ /^\d{4}\-\d{2}$/) { # 'YYYY-MM'
#        # $date .= '-01';
#        $date .= '-01#';
#    }
#    else {
#    }

    # DEBUG
    # print "NCBI date ", $str, " => ", $date, "\n";

    return $date;
}

# }}} chgGBDate

# {{{ insTableVir

=head2 insTableVir

  Name:     insTableVir
  Usage:    insTableVir($o_feat, $dbh)
  Function: Insert records into Table 'virus'
  Args:     A Bio::SeqFeatureI object,
            A database handle.
  Return:   An string, digits.
            undef for all errors.

=cut

sub insTableVir {
    my ($o_feat, $dbh) = @_;

    unless ($o_feat->primary_tag eq 'source') { # Not primary tag 'source'
        warn "Primary tag 'source' required!\n";
        return;
    }

    my %feat;
    # Parse tags
    # Invoke 'array2str' for get_tag_values() return an array.
    for my $tag ($o_feat->get_all_tags) {
        if ($tag eq 'organism') {   # Parse organism
            my @values = $o_feat->get_tag_values($tag);
            my $org = array2str( \@values, ' ' );
            $feat{'organism'} = $org;
        }
        elsif ($tag eq 'mol_type') {    # '\mol_type'
            # This tag will be parsed & imported into table 'seq'.
            next;
        }
		elsif ($tag eq 'segment') { # '\segment'
		    # This tag will be parsed & imported into table 'seq'
		    next;
		}
        elsif ($tag eq 'strain') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'strain'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'sub_strain') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'sub_strain'} = array2str( \@values, ' ' );
        }
        elsif ($tag eq 'clone') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'clone'} = array2str( \@values, ' ' );
        }
        elsif ($tag eq 'isolate') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'isolate'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'genotype') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'genotype'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'serovar') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'serovar'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'serotype') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'serotype'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'country') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'country'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'host') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'host'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'lab_host') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'lab_host'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'specific_host') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'spec_host'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'isolation_source') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'isolate_src'} = array2str( \@values, ' ');
        }
        elsif ($tag eq 'collection_date') {
            my @values = $o_feat->get_tag_values($tag);
            my $gb_date = array2str( \@values, ' ');

            # Date: $date

            # $feat{'collect_date'} = chgGBDate($date);
            my $date    = chgGBDate($gb_date);

            if ($date) {
                $feat{'collect_date'} = $date;
            }
        }
        elsif ($tag eq 'note') {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'note'} = array2str( \@values, ' ');
		}
        elsif ($tag eq 'db_xref') {
            my @values = $o_feat->get_tag_values($tag);
            my $db_xref = array2str( \@values, ' ' );
            if ($db_xref =~ /taxon\:(\d+)/) {
                $feat{'taxon_id'} = $1;
            }
            else {
                warn "DEBUG: Unmatched source db_xref: $db_xref\n";
            }
        }
        elsif ($tag eq 'virion') {      # '/virion'
            # $feat{'virion'} = 1;
            $feat{'virion'} = 'true';
        }
        elsif ($tag eq 'tissue_type') { # '/tissue_type'
            my @values = $o_feat->get_tag_values('tissue_type');
            $feat{'tissue_type'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'map') {         # '/map'
            my @values = $o_feat->get_tag_values('map');
            $feat{'map'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'ecotype') {     # '/ecotype'
            my @values = $o_feat->get_tag_values('ecotype');
            $feat{'ecotype'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'cell_line') {   # '/cell_line'
            my @values = $o_feat->get_tag_values('cell_line');
            $feat{'cell_line'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'cell_type') {   # '/cell_type'
            my @values = $o_feat->get_tag_values('cell_type');
            $feat{'cell_type'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'proviral') {    # '/proviral'
            # $feat{'proviral'} = 1;
            $feat{'proviral'} = 'true';
        }
        elsif ($tag eq 'focus') {       # '/focus'
            # $feat{'focus'} = 1;
            $feat{'focus'} = 'true';
        }
		elsif ($tag eq 'PCR_primers') {	# '/PCR_primers', combined into 'note'
            # This tag will be parsed & imported into table 'seq'
		    next;

#	    my @values = $o_feat->get_tag_values($tag);
#	    my $pcr_primers = array2str( \@values, ' ' );
#
#	    $feat{'note'} .= $pcr_primers;
		}
		elsif ($tag eq 'chromosome') {
            # This tag will be parsed & imported into table 'seq'
		    next;
		}
		elsif ($tag eq 'collected_by') {
            my @values = $o_feat->get_tag_values('collected_by');
            $feat{'collected_by'} = array2str(\@values, ' ');		}
        else {  # Display unmatched tags.
            my @values = $o_feat->get_tag_values($tag);
            my $val = array2str( \@values, ' ');
            warn "DEBUG: Unmatched source qualifiers: $tag => $val\n";
        }
    }

    # Check whether this organism exists.
    # This is COMMON especially a virus seq has plasmids.
    # If organism/virus id already exists, return its virus id.

    # This script is not necessary for virus.

    # HASH Feaet: %feat

    my $sql = hash2PgIns(\%feat, 'virus', $dbh);

    unless ($sql) {  # if is an empty string
        return;
    }

    # DEBUG
    # print '-'x20, 'insTableVir', '-'x20, "\n", $sql, "\n", '-'x50, "\n";
    # TABLE virus: $sql

    # SQL for virus: $sql

    $dbh->do($sql);

    # Insert success, return inserted record id.
    # return( mysqlInsId($dbh) );
	my $insert_id = $dbh->last_insert_id(undef, 'public', 'virus', undef);

	return $insert_id;
}

# }}} insTableVir

# {{{ chkVirId

=head2 chkVirId
  Name:     chkVirId
  Usage:    chkVirId($taxon_id, $mod_date, $dbh)
  Function: Check whether the organism already exists in table 'virus'.
  Args:     $taxon_id   - An integer. 
                          In 'source', the /db_xref="taxon:0000"
            $mod_date   - A string.
                          Modification date in LOCUS field.
            $dbh        - Database handle.
  return:   A scalar, the organism/virus id for success.
            undef for no match record.
=cut

sub chkVirId {
    my ($taxon_id, $mod_date, $dbh) = @_;
    my $vir_id;

    my $sql = 'SELECT vir.id FROM virus AS vir, sequence AS seq
                WHERE vir.taxon_id = ' . $dbh->quote($taxon_id) . 
                ' AND seq.mod_date = ' . $dbh->quote($mod_date) .
                ' AND seq.vir_id = vir.id';

    my $sth = $dbh->prepare($sql);

    unless ($sth) {
        warn "Error: Prepare query organism/virus id.\n$DBI::errstr.\n";
        return;
    }

    unless ( $sth->execute() ) {
        warn "Error: Execute query organism/virus id.\n$DBI::errstr\n";
        return;
    }

    while (my $rh_row = $sth->fetchrow_hashref) {
        $vir_id = $rh_row->{'id'};
    }

    return $vir_id;
}

# }}} chkVirId

# {{{ insTableSeq

=head2 insTableSeq

  Name:     insTableSeq
  Usage:    insTableSeq($rh, $dbh)
  Function: Parse & instert record into table 'seq'
  Args:     A hash reference to seq information.
            and database handle.
  Return:   A string, inserted record id
            undef for all errors.

=cut

sub insTableSeq {
    my ($rh_seq, $dbh) = @_;

    # Create SQL query string. return undef if no string created.
    my $sql = hash2PgIns($rh_seq, 'sequence', $dbh) or return;

    # DEBUG
    # print '-'x20, 'insTableSeq', '-'x20, "\n", $sql, "\n", '-'x50, "\n";

    $dbh->do($sql);

    # Success. return inserted record id
    # return($dbh->{'mysql_insertid'});
    # return( mysqlInsId($dbh) );
	my $insert_id = $dbh->last_insert_id(undef, undef, 'sequence', undef);

	return $insert_id;
}

# }}} insTableSeq

# {{{ parse_feat

=head2 parse_feat
  Name:     parse_feat
  Usage:    parse_feat($feat, $type)
  Function: Parse feature '$tag' in object $o_feat.
  Args:     $feat - Bio::SeqFeatureI object;
            $type - Feature type, primary tags:
                    'gene', 'CDS', 'rRNA' etc.
  Return:   A reference of hash: parsed feature.
                $rh->{'common'}: hash reference for common qualifiers;
                $rh->{'db_xref'}: hash reference for qualifier '/db_xref';
                $rh->{'misc_qualif'}: hash reference for other qualifiers.
            undef    - all errors.
=cut

sub parse_feat{
    my ($o_feat, $type) = @_;

    my %feat;           # Parse general qualifiers

    # Parse location
    # If it is simple location, parse 'start', 'end' and 'strand'
    # e.g., '123..456' or 'complement(123..456)'
    if ( $o_feat->location->isa('Bio::Location::Simple') ) {
        $feat{'common'}->{'feat_start'} = $o_feat->start;
        $feat{'common'}->{'feat_end'} = $o_feat->end;
        # Change BioPerl strand '1', '-1', '0' to general '+', '-', '0'
        my $strand = '+' if ($o_feat->strand eq '1');
        $strand = '-' if ($o_feat->strand eq '-1');
        $strand = '.' if ($o_feat->strand eq '0');
        $feat{'common'}->{'strand'} = $strand;

		# Here get simple sequence
		$feat{'common'}->{'seq'} = $o_feat->seq->seq;
    }
    # If it is Not simple location: Split, Fuzzy, etc.
    # Will NOT parse 'start', 'end', use 'location' and 'strand' directly
    # e.g., 'join(58474..59052,59052..59228,59228..59269)'
    else {
        $feat{'common'}->{'location'} = $o_feat->location->to_FTstring;
        if ( $feat{'common'}->{'location'} =~ /complement/ ) {
            $feat{'common'}->{'strand'} = '-';
        }
        else {
            $feat{'common'}->{'strand'} = '+';
        }

		# Here get spliced sequence
		# Most of spliced sequences are CDS related DNA sequences.
		$feat{'common'}->{'seq'} = $o_feat->spliced_seq->seq;
    }

    # Retrieve seq
    # Not for 'CDS', which already has 'translation'
    # the formal primary key is 'CDS'
    # if ($type ne 'CDS') {
    #     $feat{'common'}->{'seq'} = $o_feat->seq->seq;
    # }

    # Parse tags
    for my $tag ($o_feat->get_all_tags) {
        if ($tag eq 'gene') {                   # '/gene'
            my @values = $o_feat->get_tag_values('gene');
            $feat{'common'}->{'gene'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'locus_tag') {           # '/locus_tag'
            my @values = $o_feat->get_tag_values('locus_tag');
            $feat{'common'}->{'locus_tag'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'function') {            # '/function'
            my @values = $o_feat->get_tag_values('function');
            $feat{'common'}->{'func'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'pseudo') {              # '/pseudo'
            $feat{'common'}->{'pseudo'} = 1;
        }
        elsif ($tag eq 'product') {             # '/product'
            my @values = $o_feat->get_tag_values('product');
            $feat{'common'}->{'product'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'note') {                # '/note'
            my @values = $o_feat->get_tag_values('note');
            $feat{'common'}->{'note'} = array2str(\@values, ' ');
        }
        # CDS special tags
        elsif ($tag eq 'codon_start') {   # '/codon_start'
            my @values = $o_feat->get_tag_values('codon_start');
            $feat{'common'}->{'codon_start'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'EC_number') {     # '/EC_number'
            my @values = $o_feat->get_tag_values('EC_number');
            $feat{'common'}->{'ec_num'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'transl_table') {  # '/transl_table'
            my @values = $o_feat->get_tag_values('transl_table');
            $feat{'common'}->{'transl_table'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'protein_id') {    # '/protein_id'
            my @values = $o_feat->get_tag_values('protein_id');
            $feat{'common'}->{'prn_id'} = array2str(\@values, ' ');
        }
        elsif ($tag eq 'translation') {   # '/translation'
            my @values = $o_feat->get_tag_values('translation');
            $feat{'common'}->{'translation'} = array2str(\@values, ' ');
        }
        # tag '/db_xref'
        elsif ($tag eq 'db_xref') {
            # Format 'GeneID:944776', 'UniProtKB/Swiss-Prot:P39220'
            my @values = $o_feat->get_tag_values('db_xref');

            # Store in a hash '%db_xref'
            for my $value (@values) {
                my ($db, $id) = split(/:/, $value);
                $feat{'db_xref'}->{$db} = $id;
            }
        }

        # All other tags
        else {
            my @values = $o_feat->get_tag_values($tag);
            $feat{'misc_qualif'}->{$tag} = array2str(\@values, ' ');
        }
    }

    # Adjust CDS sequence of which 'codon_start' is NOT '1'
    if ( defined $feat{'common'}->{'codon_start'} ) {
        if ( $feat{'common'}->{'codon_start'} > 1 ) {
            my $start_pos = $feat{'common'}->{'codon_start'} - 1;
            my $seq_str = substr( $feat{'common'}->{'seq'}, $start_pos );

            $feat{'common'}->{'seq'} = $seq_str;
        }
    }

    return \%feat;
}

# }}} parse_feat

# {{{ insFeatTable

=head2 insFeatTabe
  Name:     insFeatTable
  Usage:    insFeatTable($rh_feat, $table, $dbh)
  Function: Insert parsed feature into relative table.
  Args:     $rh_feat - Hash reference of parsed feature;
            $table   - Table name to be inserted;
            $dbh     - Database handle.
  Return:   A scalar, which is inserted record id;
            undef for all errors.
=cut

sub insFeatTable {
    my ($rh, $type, $dbh) = @_;

    # Create SQL query string
    # return undef if creation error.
    my $sql = hash2PgIns($rh->{'common'}, 'feature', $dbh) or return;

    # DEBUG
    # print '-'x20, 'insFeatTable', '-'x20, "\n", $sql, "\n", '-'x50, "\n";

    $dbh->do($sql);

    # my $ins_tblid = $dbh->{'mysql_insertid'};
    # my $ins_tblid = mysqlInsId($dbh);
	my $insert_id = $dbh->last_insert_id(undef, undef, 'feature', undef);

    # Insert into table 'db_xref'
    if (defined $rh->{'db_xref'}) {
        for my $key ( keys( %{$rh->{'db_xref'}} ) ) {
            my @fields = qw(feat_id db value);
            my @values = ($insert_id, $key, $rh->{'db_xref'}->{$key});

            my $sql = array2PgIns(\@fields, \@values, 'db_xref', $dbh);

            # DEBUG
            # print '-'x20, 'db_xref', '-'x20, "\n", $sql, "\n", '-'x50, "\n";

            $dbh->do($sql);
        }
    }

    if (defined $rh->{'misc_qualif'}) {
        for my $key ( keys( %{$rh->{'misc_qualif'}} ) ) {
            my @fields = qw(feat_id qualif value);
            my @values = ($insert_id, $key, $rh->{'misc_qualif'}->{$key});

            my $sql = array2PgIns(\@fields, \@values, 'misc_qualif', $dbh);

            # DEBUG
            # print '-'x20, 'misc_qualif', '-'x20, "\n", $sql, "\n", '-'x50, "\n";

            $dbh->do($sql);
        }
    }

    return $insert_id;
}

# }}} insFeatTable

# {{{ chkRef

=head2 chkRef
  Name:     chkRef
  Usage:    chkRef($field, $value, $dbh)
  Function: Check whether a record in refereoce table exists by
            given value of desired field.
            This function could be used for 'Direct Submission' and
            normal journal.
  Args:     $filed - Field to be checked,
            $value - Given value of field,
            $sbh     - Database handle.
  Return:   A scalar - Reference record id.
            undef    - For no matched record or all errors.
=cut

sub chkRef {
    my ($field, $value, $dbh) = @_;
    my $ref_id;

    my $sql = "SELECT id FROM reference " .
        "WHERE $field = " . $dbh->quote($value) . ';';

    my $sth = $dbh->prepare($sql);

    unless ($sth) {
        warn "Error: Prepare query Direct Submission.\n$DBI::errstr.\n";
        return;
    }

    unless ($sth->execute()) {
        warn "Error: Execute query Direction Submission.\n$DBI::errstr.\n";
        return;
    }

    while (my $rh_row = $sth->fetchrow_hashref) {
        $ref_id = $rh_row->{'id'};
        # print "Ref: Reference \n'$value'\n already exists.\n";
    }

    return $ref_id;
}

# }}} chkRef

# {{{ insXrefTable

=head2 insXrefTable
  Name:     insXrefTable
  Usage:    insXrefTable($tbl_name, $rh_param, $dbh)
  Function: Insert records for a cross reference table, which is a one-multi
            mapping table.
  Args:     $tbl_name - Cross reference table name;
            $rh_param - Hash reference parameters;
            $dbh      - Database handle.
  Return:   A scalar - Number of inserted records;
            undef    - All errors.
=cut

sub insXrefTable {
    my ($tbl_name, $rh_param, $dbh) = @_;
    my $sql;
    my $num = 0;

    for my $mid (@{$rh_param->{'multi_val'} }) {

        my @fields = ($rh_param->{'one'}, $rh_param->{'multi'});
        my @values = ($rh_param->{'one_val'}, $mid);

        $sql = array2PgIns(\@fields, \@values, $tbl_name, $dbh);

        # DEBUG
        # print '-'x20, 'insXrefTable', '-'x20, "\n", $sql, "\n", '-'x50, "\n";
        # insXrefTable: $sql

        $dbh->do($sql);
        $num++;
    }

    return $num;
}

# }}} insXrefTable

# {{{ delSeq

=head2 delSeq
  Name:     delSeq
  Usage:    delSeq($acc, $dbh)
  Function: Delete seq by accession number.
            It will change tables 'seq', 'virus', 'feature',
            'xref_sr', 'db_xref' and 'misc_qualif'.
  Args:     $acc - A string, accession number.
            $dbh - Database handle
  Reutrn:   1 for success.
            undef for all errors.
=cut

sub delSeq {
    my ($acc, $dbh) = @_;
    my ($gid, $vir_id);

    print "Deleting seq $acc\n";

    # Query seq id 'gid' and virus id 'vir_id'
    my $sql = "SELECT id AS gid, vir_id FROM sequence " .
        "WHERE accession = " . $dbh->quote($acc) . ";";

    my $sth = $dbh->prepare($sql)
        or warn "Error: Cannot prepare query \n$sql\n$DBI::errstr\n",
        return;

    $sth->execute()
        or warn "Error: Cannot execute query \n$sql\n$DBI::errstr\n",
        return;

    # There must be only ONE reocrd for an accession number
    while (my $rh_row = $sth->fetchrow_hashref) {
        $gid = $rh_row->{'gid'};
        $vir_id = $rh_row->{'vir_id'};
    }

    # Delete records by transaction
    # eval {
        # Query feature ids, for delete records in tables 'db_xref'
        # and 'misc_qualif'
        $sql = "SELECT id AS feat_id FROM feature " .
            "WHERE seq_id = " . $dbh->quote($gid) . ";";

        $sth = $dbh->prepare($sql)
            or warn "Error: Cannot prepare query \n$sql\n$DBI::errstr\n",
            return;
        $sth->execute()
            or warn "Error: Cannot execute query \n$sql\n$DBI::errstr\n",
            return;

        while (my $rh_row = $sth->fetchrow_hashref) {
            my $feat_id = $rh_row->{'feat_id'};

            # Delect records in table 'db_xref' according to $feat_id
            $sql = "DELETE FROM db_xref " .
                "WHERE feat_id = " . $dbh->quote($feat_id) . ";";
            $dbh->do($sql);

            # Delete records in table 'misc_qualif' according to
            # $feat_id
            $sql = "DELETE FROM misc_qualif " .
                "WHERE feat_id = " . $dbh->quote($feat_id) . ";";
            $dbh->do($sql);
        }

        # Delete features
        $sql = "DELETE FROM feature " .
            "WHERE seq_id = " . $dbh->quote($gid) . ";";
        $dbh->do($sql);

        # Delete records in table 'xref_sr'
        $sql = "DELETE FROM xref_sr " .
            "WHERE seq_id = " . $dbh->quote($gid) . ";";
        $dbh->do($sql);

        # Delete record in table 'virus'
        $sql = "DELETE FROM virus " .
            "WHERE id = " . $dbh->quote($vir_id) . ";";
        $dbh->do($sql);

        # Delete records in table 'seq'
        $sql = "DELETE FROM sequence " .
            "WHERE accession = " . $dbh->quote($acc) . ";";
        $dbh->do($sql);
#    };

    print "Genome $acc deleted success.\n";
    return 1;
}

# }}} delSeq

# {{{ parse_dbrc

=head2 parse_dbrc
  Name:     parse_dbrc
  Usage:    parse_dbrc($filename)
  Function: Parse database resource file.
  Args:     $filename - Database resource filename
  Return:   Reference to a hash: Success
            null: failed
=cut

sub parse_dbrc {
	my ($inf) = @_;
	my %dbrc;

    unless (-e $inf) {
        warn "Fatal: Database resource file '$inf' does not exist!\n";
        return;
    }

    open(RC, $inf) or
        warn "Fatal: Open database resource file '$inf': $!\n", return;

	while (<RC>) {
		next if (/^#/);
		next if (/^\s*$/);
		chomp;

		my ($key, $val) = split(/\s+=\s+/, $_);

		$dbrc{$key} = $val;
	}

	return \%dbrc;
}

# }}} parse_dbrc

=head2 array2str

 Title   : array2str
 Usage   : array2str($rf_array, $str)
 Function: Combine strings in array into a string, which were delimited
           by $str.
 Returns : A string.
 Args    : $rf_array - Reference to an array,
           $str - a string.

=cut

sub array2str {
    my ($rf_array, $dstr) = @_;

    my $out_str = '';

    for my $str ( @{$rf_array} ) {
	$out_str .= $str;
	$out_str .= $dstr;
    }

# Remove tailing delimiter.
    $out_str =~ s/$dstr$//;

    return $out_str;
}

=head2 array2PgIns
  Name:     array2PgIns
  Usage:    array2PgIns($ra_fileds, $ra_values, $table, $dbh)
  Function: Create a PostgreSQL 'INSERT' SQL statement according to given
            array of table fileds and values.
  Args:	    $ra_fields - Array reference to fields of table,
            $ra_values - Array reference to fields values,
            $table     - Table name,
            $dbh       - Database handle
  Return:   A string,
            undef for all errors.
=cut

sub array2PgIns {
    my ($ra_fields, $ra_values, $table, $dbh) = @_;

    # If fields and values array don't have identical items
    return if ( scalar( @{$ra_fields} ) ne scalar( @{$ra_values} ) );

    my $num = scalar( @{$ra_fields} );

    # Create SQL query string
    my $sql = "INSERT INTO $table (";

    # Fields list
    $sql = $sql . join(', ', @{$ra_fields});

    $sql = $sql . ') VALUES (';

    # Values list
    # $sql = $sql . join(', ', @{$ra_values});
    for my $val ( @{$ra_values} ) {
        $sql = $sql . $dbh->quote($val) . ', ';
    }

    $sql =~ s/, $/);/;

#    $sql = $sql . ');';

    return $sql;
}

=head2 hash2PgIns
  Name:     hash2PgIns
  Usage:    hash2PgIns($rh, $table, $dbh)
  Function: Create a PostgreSQL 'INSERT' statement according to a given hash.
  Args:     $rh - A reference to an array;
            $table - MySQL table name;
            $dbh - Database handle. For DBI method 'quote'.
  Return:   A string.
            undef for all errors.
  NOTE:     1. Be sure hash keys are identical with PostgreSQL table field names,
               or this query will NEVER be succeed.
            2. Remember define 'DEFAULT' vaule for all fields.
=cut

sub hash2PgIns {
    my ($rh, $table, $dbh) = @_;

    # Return undef if it's an empty hash
#    return unless ( scalar(keys(%{$rh})) == 0 );

    my $sql = "INSERT INTO $table (";

    # Fields list
    for my $key ( sort( keys( %{$rh}) ) ) {
        $sql = $sql . "$key, ";
    }

    # Remove tailing ', '
    $sql =~ s/, $//;

    $sql = $sql . ") VALUES (";

    # Values list
    for my $key ( sort( keys( %{$rh} ) ) ) {
        $sql = $sql . $dbh->quote($rh->{$key}) . ", ";
    }

    # Replace tailing ', ' by ');'
    $sql =~ s/, $/);/;

    return $sql;
}

# }}} subroutine

__END__
