=head1 NAME
    
    Bio::KEGGI::gene - Parse KEGG gene file.
    
=head1 DESCRIPTION

    Parse KEGG gene file
    (e.g., ftp://ftp.genome.jp/pub/kegg/genes/organisms/eco/E.coli.ent).

=head1 METHODS

=head2 next_rec
    Name:   next_rec
    Desc:   Get next KEGG gene record
    Usage:  $o_keggi->next_rec()
    Args:   none
    Return: A KEGG object
    
=head1 VERSION

    v0.1.2
    
=head1 AUTHOR

    zeroliu-at-gmail-dot-com
    
=cut

=begin NOTE
    
    Returned data structure
    
    $rh_rec = {
        'id'        => $id,             # ENTRY
        'type'      => $type,           # e.g., 'CDS'
        'name'      => [ $name, ... ],  # NAME
        'definit'   => $defin,          # DEFINITION
        'ko'        => {                # ORTHOLOGY
            'ko_id'         => $ko_id,
            'description'   => $desc,
        },
        'ec'        => [ $ec, ... ],
        'pathway'   => [ $pathway_id, ... ],
        'class;     => $class,
        'position'  => {
            'strand'    => '+' | '-'
            'min'   => $min,
            'max'   => $max,
        },
        'motif'     => [
            {
                'db'    => $db,
                'entry' => [ $entry, ... ],
            },
            ...
        ],
        'dblink'   => [
            {
                'db'    => $db,
                'entry' => $entry,
            },
            ...
        ],
        'structure' => {
            'db'    => $db,
            'entry' => $id,
        },
        'aaseq'     => {
            'length'    => $length,
            'seq'       => $seq,
        },
        'ntseq'     => {
            'length'    => $length,
            'seq'       => $seq,
        },
    }
    
=cut

package Bio::KEGGI::gene;

use strict;
use warnings;

use Switch;
use Text::Trim;

use Smart::Comments;

use base qw(Bio::KEGGI);

our $VERSION = 'v0.1.2';

=begin next_rec
    Name:   next_rec
    Desc:   Get next KEGG gene record
    Usage:  $o_keggi->next_rec()
    Args:
    Return: A Bio::KEGG object
=cut

sub next_rec {
    my $self = shift;
    
    my $ra_rec = _get_next_rec( $self->{'_FH'} );
    my $rh_rec = _parse_gene_rec( $ra_rec );
    
    bless $rh_rec, "Bio::KEGG::gene" if (defined $rh_rec);
    
    return $rh_rec;
}

=begin _get_next_rec
    Name:   _get_next_rec
    Desc:   Read a record form KEGG gene file.
    Usage:  _get_next_rec(FH)
    Args:   A filehandle of KEGG gene file
    Return: A reference of an array for a KEGG record
=cut

sub _get_next_rec {
    my $ifh = shift;
    
    {
        local $/ = "\/\/\/\n";
        
        my $rec;
        
        if ( $rec = <$ifh> ) {
            my @rec = split(/\n/, $rec);
            
            return \@rec;
        }
        else {
            return;
        }
    }
}

=begin _parse_gene_rec
    Name:   _parse_gene_rec
    Desc:   Parse KEGG gene record
    Usage:  _parse_gene_rec($ra_rec)
    Args:   A reference to an array.
    Return: A reference to a hash of KEGG gene record
=cut

sub _parse_gene_rec {
    my ($ra_rec) = @_;
    
    my $rh_rec;
    my $cur_section;
    
    for my $row ( @{ $ra_rec } ) {
        next if ( $row =~ /^\s*$/ );
        next if ( $row =~ /\/\/\// );
    
        # 'ENTRY       b0001             CDS       E.coli'
        if ( $row =~ /^ENTRY\s{7}(\w+)\s+(\s+)/ ) {
            $rh_rec->{'id'} = $1,
            $rh_rec->{'type'} = $2;
        }
        # 'NAME        thrL, ECK0001, JW4367'
        elsif ( $row =~ /^NAME\s{8}(.+?)$/) {
            $cur_section = 'NAME';
            
            my @names = split(/,\s/, $1);
            
            $rh_rec->{'name'} = \@names;
        }
        # 'DEFINITION  thr operon leader peptide'
        elsif ( $row =~ /^DEFINITION\s{2}(.+?)$/) {
            $cur_section = 'DEFINITION';
            
            $rh_rec->{'definit'} = $1;
        }
        # 'ORTHOLOGY   K12524  bifunctional aspartokinase/homoserine dehydrogenase 1'
        # '                    [EC:2.7.2.4 1.1.1.3]'
        elsif ( $row = /^ORTHOLOGY\s{3}(K\d{5})\s{2}(.+?)$/) {
            $cur_section = 'ORTHOLOGY';
            
            $rh_rec->{'ko'}->{'ko_id'} = $1;
            
        }
        # 'PATHWAY     eco00260  Glycine, serine and threonine metabolism'
        elsif ( $row =~ /^PATHWAY\s{5}(\w+\d{5})\s{2}/ ) {
            $cur_section = 'PATHWAY';
            
            push @{ $rh_rec->{'pathway'} }, $1;
        }
        # 'CLASS       Metabolism; Amino Acid Metabolism; Glycine, serine and threonine
        #    metabolism [PATH:eco00260]'
        elsif ( $row =~ /^CLASS\s(7)/ ) {
            $cur_section = 'CLASS';
        }
        # 'POSITION    337..2799'
        elsif ( $row =~ /^POSITION\s{4}(\d+)\.\.(\d+)$/ ) {
            $rh_rec->{'position'}->{'strand'} = '+';
            $rh_rec->{'position'}->{'min'} = $1;
            $rh_rec->{'position'}->{'max'} = $2;
        }
        # 'POSITION    complement(5683..6459)'
        elsif ( $row =~ /^POSITION\s{4}complement\((\d+)\.\.(\d+)\)$/ ) {
            $rh_rec->{'position'}->{'strand'} = '-';
            $rh_rec->{'position'}->{'min'} = $1;
            $rh_rec->{'position'}->{'max'} = $2;
        }
        # 'MOTIF       Pfam: PALP CPSase_L_D3 DUF2848'
        elsif ( $row =~ /^MOTIF\d(7)(\w+):\s(.+?)$/) {
            $cur_section = 'MOTIF';
            
            my $motif = $1;
            my $entry_str = $2;
            
            my @entries = split(/\s/, $entry_str);
            
            my $rh_motif = {
                'db'   => $motif,
                'entry' => \@entries,
            };
            
            push @{ $rh_rec->{'motif'} }, $rh_motif;
        }
        elsif ( $row =~ /^DBLINKS\s{5}(\w+):\s(\w+)$/) {
            $cur_section = 'DBLINKS';
            
            push @{ $rh_rec->{'dblink'} }, { 'db' => $1, 'entry' => $2, };
        }
        elsif ( $row =~ /^STRUCTURE\s{3}(\w+):\s(\w+)$/) {
            $cur_section = 'STRUCTURE';
            
            push @{ $rh_rec->{'structure'} }, { 'db' => $1, 'entry' => $2, };
        }
        elsif ( $row =~ /^AASEQ\s{7}(\d+)$/ ) {
            $cur_section = 'AASEQ';
            
            $rh_rec->{'aaseq'}->{'length'} = $1;
        }
        elsif ( $row =~ /^NTSEQ\s{7}(\d+)$/) {
            $cur_section = 'NTSEQ';
            
            $rh_rec->{'ntseq'}->{'length'} = $1;
        }
        elsif ($row =~ /^\s{12}\S/) {
            switch ( $cur_section ) {
                case 'DEFINITION' {
                    trim( $row );
                    $rh_rec->{'definit'} += $1;
                }
                case 'ORTHOLOGY' {
                    # Do nothing
                }
                case 'PATHWAY' {
                    if ( $row =~ /^\s{12}(\w+\d{5})/ ) {
                        push @{ $rh_rec->{'pathway'} }, $1;                        
                    }
                    else {
                        ### Unmatched line
                        ### $cur_section
                        ### $row
                    }
                }
                case 'CLASS' {
                    # Do nothing
                }
                case 'DBLINKS' {
                    if ( $row =~ /^\s{12}(\w+):\s(.+?)$/) {

                    }
                    else {
                        ### Unmatched line
                        ### $cur_section
                        ### $row
                    }
                }
            }
        }
        else {
            ### Unmatched row
            ### $row
        }
    }
}

=begin
    Name:   _parse_orth
    Desc:   Parse 'ORTHOLOGY' section to get ko, ecs and ko descriprion
    Usage:  _parse_org($str)
    Args:   A string
    Return: A reference to a hash.
=cut

sub _parse_orth {
    my ($str) = @_;
    
    
}