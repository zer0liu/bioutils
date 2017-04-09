=head1 NAME
    
    Bio::KEGGI::gene - Parse KEGG gene file.
    
=head1 DESCRIPTION

    Parse KEGG gene entries file
    (e.g., ftp://ftp.genome.jp/pub/kegg/genes/organisms/eco/E.coli.ent).

=head1 METHODS

=head2 next_rec

    Name:   next_rec
    Desc:   Get next KEGG gene record
    Usage:  $o_keggi->next_rec()
    Args:   none
    Return: A Bio::KEGG::gene object

=head1 AUTHOR

    Haizhou Liu, zeroliu-at-gmail-dot-com

=head1 VERSION

    0.1.5
    
=cut

=begin NOTE
    
    Returned data structure
    
    $rh_rec = {
        'id'        => $id,             # ENTRY
        'type'      => $type,           # e.g., 'CDS'
        'name'      => [ $name, ... ],  # NAME
        'definit'   => $defin,          # DEFINITION
        'ko'        => [ $ko_id, ... ]  # ORTHOLOGY
        'ec'        => [ $ec, ... ],
        'pathway'   => [ $pathway_id, ... ],
        'class;     => [ $class, ... ],
        'position'  => $position,
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
                'entry' => [ $entry, ... ],
            },
            ...
        ],
        'structure' => {
            'db'    => $db,
            'entry' => [ $entry, ...],
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

use Bio::KEGG::gene;
use base qw(Bio::KEGGI);

our $VERSION = 'v0.1.5';

=begin next_rec
    Name:   next_rec
    Desc:   Get next KEGG gene record
    Usage:  $o_keggi->next_rec()
    Args:
    Return: A Bio::KEGG:gene object
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
    
        # DEBUG
        # $row
        
        # 'ENTRY       b0001             CDS       E.coli'
        if ( $row =~ /^ENTRY\s{7}(\S+)\s+(\S+)/ ) {
            $cur_section = 'ENTRY';
            
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
        # Fetch KO entry ONLY
        # elsif ( $row = /^ORTHOLOGY\s{3}(K\d{5})\s{2}(.+?)$/) {
        elsif ( $row =~ /^ORTHOLOGY\s{3}(K\d{5})/) {
            $cur_section = 'ORTHOLOGY';
            
            push @{ $rh_rec->{'ko'} }, $1;
            
            # In case there are more than ONE ko entries for a gene
            if ($row =~ /K\d{5}\s+[A-Z]\d5/) {
                ### Found multiple KO entries
                ### $row
            }
        }
        # pathway: fetch pathway entry ONLY
        # 'PATHWAY     eco00260  Glycine, serine and threonine metabolism'
        elsif ( $row =~ /^PATHWAY\s{5}(\w+\d{5})\s{2}/ ) {
            $cur_section = 'PATHWAY';
            
            push @{ $rh_rec->{'pathway'} }, $1;
        }
        # 'CLASS       Metabolism; Amino Acid Metabolism; Glycine, serine and threonine
        #    metabolism [PATH:eco00260]'
        elsif ( $row =~ /^CLASS\s{7}/ ) {
            $cur_section = 'CLASS';
        }
        # fetch DISEASE ENTRY ONLY
        # 'DISEASE     H00058  Amyotrophic lateral sclerosis (ALS)'
        elsif ( $row =~ /^DISEASE\s{5}(\w\d{5})\s/) {
            $cur_section = 'DISEASE';
            
            push @{ $rh_rec->{'disease'} }, $1;
        }
        # There are many possible POSITION expressions:
        # 'POSITION    337..2799'
        # 'POSITION    complement(5683..6459)'
        # 'POSITION    complement(1225861..>1225905)'
        # 'POSITION    join(812155..812564,812566..812751,812753..812952,812954..812980,
        #              812983..813019,813021..813445,813448..813591)'
        # So now only the complete POSITION expression would be saved.
        # NO more parser would be provided.
        elsif ( $row =~ /^POSITION\s{4}(.+?)$/ ) {
            $cur_section = 'POSITION';
            
            $rh_rec->{'position'} = $1;
            
=begin            
            # Store the complete POSTION expression
            $rh_rec->{'position'}->{'expr'} = $pos_str;
            
            # Chromosome or plasmid information in POSITION
            # 'POSITION    pAACI03:complement(6708..7310)'
            # 'POSITION    S25:complement(22229..22465)'
            if ( $pos_str =~ /^(\S+):/ ) {
                $rh_rec->{'position'}->{'chr'} = $1;
            }
            # 'POSITION    337..2799'
            elsif ( $pos_str =~ /(\d+)\.{2}(\d+)/ ) {
                $rh_rec->{'position'}->{'strand'} = '+';
                $rh_rec->{'position'}->{'min'} = $1;
                $rh_rec->{'position'}->{'max'} = $2;
            }
            # 'POSITION    complement(5683..6459)'
            elsif ( $pos_str =~ /complement\((\d+)\.{2}(\d+)\)/ ) {
                $rh_rec->{'position'}->{'strand'} = '-';
                $rh_rec->{'position'}->{'min'} = $1;
                $rh_rec->{'position'}->{'max'} = $2;
            }
            else {
                ### Unmatched POSITION
                ### $row
            }
=cut
        }
        # 'MOTIF       Pfam: PALP CPSase_L_D3 DUF2848'
        elsif ( $row =~ /^MOTIF\s{7}(\S+):\s(.+?)$/) {
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
        # 'DBLINKS     NCBI-GI: 16127995'
        # '            Ensembl: ENSG00000248465 ENSG00000249124 ENSG00000249450'
        elsif ( $row =~ /^DBLINKS\s{5}(\S+):\s(.+)$/) {
            $cur_section = 'DBLINKS';
            
            my @entries = split(/\s/, $2);
            
            push @{ $rh_rec->{'dblink'} }, { 'db' => $1, 'entry' => \@entries, };
        }
        elsif ( $row =~ /^STRUCTURE\s{3}(\S+):\s(.+)$/) {
            $cur_section = 'STRUCTURE';
            
            my $db = $1;
            my $entry_str = $2;
            
            my @entries = split(/\s/, $entry_str);
=begin
            # For future complex STRUCTURE entry, such as multi entries
            push @{ $rh_rec->{'structure'} }, { 'db' => $db, 'entry' => \@entries };
=cut
            # Current simpler STRUCTURE entry
            $rh_rec->{'structure'} = {
                'db'    => $db,
                'entry' => \@entries,
            };
        }
        elsif ( $row =~ /^AASEQ\s{7}(\d+)$/ ) {
            $cur_section = 'AASEQ';
            
            $rh_rec->{'aaseq'}->{'length'} = $1;
        }
        elsif ( $row =~ /^NTSEQ\s{7}(\d+)$/) {
            $cur_section = 'NTSEQ';
            
            $rh_rec->{'ntseq'}->{'length'} = $1;
        }
        # With 12 leading spaces
        # '            Ensembl: ENSG00000248465 ENSG00000249124 ENSG00000249450'
        # '            NCBI-GeneID: 944742'
        elsif ($row =~ /^\s{12}\S/) {
            switch ( $cur_section ) {
                case 'NAME' {
                    trim($row);
                    
                    my @names = split(/, /, $row);
                
                    push @{ $rh_rec->{'name'} }, @names;
                }
                case 'DEFINITION' {
                    trim( $row );
                    $rh_rec->{'definit'} .= " $row";
                }
                case 'POSITION' {
                    trim( $row );
                    $rh_rec->{'position'} .= $row;
                }
                case 'ORTHOLOGY' {
                    # Do nothing
                }
                # pathway: fetch pathway ENTRY ONLY
                case 'PATHWAY' {
                    if ( $row =~ /^\s{12}(\w+\d{5})/ ) {
                        push @{ $rh_rec->{'pathway'} }, $1;                        
                    }
                    else {
                        # Do nothing
                    }
                }
                # Fetch DISEASE entry only
                case 'DISEASE' {
                    if ( $row =~ /^\s{12}(\w\d{5})/) {
                        push @{ $rh_rec->{ 'disease' } }, $1;
                    }
                    else {
                        ### Unmatched DISEASE line
                        ### ROW: $row
                    }
                }
                case 'CLASS' {
                    # Do nothing
                }
                case 'MOTIF' {
                    if ( $row =~ /\s{12}(\S+):\s(.+?)$/ ) {
                        my $db= $1;
                        my $entry_str = $2;
                        
                        my @entries = split(/\s/, $entry_str);
                        
                        my $rh_motif = {
                            'db' => $db,
                            'entry' => \@entries,
                        };
                        
                        push @{ $rh_rec->{'motif'} }, $rh_motif;
                    }
                    else {
                        ### Unmatched MOTIF line
                        ### ROW: $row
                    }
                }
                case 'DBLINKS' {
                    if ( $row =~ /^\s{12}(\S+):\s(.+?)$/) {
                        my $db = $1;
                        my @entries = split(/\s/, $2);
                        
                        push @{ $rh_rec->{'dblink'} },
                            { 'db' => $db, 'entry' => \@entries, };
                    }
                    else {
                        ### Unmatched DBLINKS line
                        ### $row
                    }
                }
                case 'STRUCTURE' {
                    ### Unmatched STRUCTURE
                    ### $row
                }
                case 'AASEQ' {
                    trim($row);
                    
                    $rh_rec->{'aaseq'}->{'seq'} .= $row;
                }
                case 'NTSEQ' {
                    trim($row);
                    
                    $rh_rec->{'ntseq'}->{'seq'} .= $row;
                }
                else {
                    # Output unmatched line
                    ### Unmatched 12-space leading line
                    ### $row
                }
            }
        }
        # With at least 13 leading spaces
        # ORTHOLOGY   K01525  bis(5'-nucleosyl)-tetraphosphatase (symmetrical)
        #                     [EC:3.6.1.41]
        # MOTIF       Pfam: DAO FAD_binding_3 Pyr_redox_2 Thi4 FAD_binding_2 HI0933_like
        #                   GIDA Trp_halogenase GMC_oxred_N Lycopene_cycl Pyr_redox GDI
        #                   ApbA 3HCDH_N Shikimate_DH
        # STRUCTURE   PDB: 3DAU 1RA9 1RA2 4DFR 1RA8 1RA3 1RF7 1RX2 1DHJ 1DYJ 2D0K
        #                  1RC4 1RA1 1RX9 1JOM 1DYH 1DYI 1DHI 3DRC 2DRC 1DRA 3K74
        #                  1JOL 1DRB 1RG7 1RX1 1RX6 1RB2 2ANQ 2INQ 1RX3 1RX4 1DDS
        #                  1RB3 1RX7 1RX5 1DRH 5DFR 1RH3 6DFR 1DDR 1TDR 7DFR 1DRE
        #                  1RD7 1RE7 2ANO 1RX8
        elsif ( $row =~ /^\s{13,}\S/ ) {
            switch ( $cur_section ) {
                case 'ORTHOLOGY' {
                    # Do nothing
                }
                case 'MOTIF' {
                    trim($row);
                    
                    my @motifs = split(/\s/, $row);
                    
                    # Get current MOTIF record from the RECORD hash
                    my $rh_motif = pop @{ $rh_rec->{'motif'} };
                    
                    push @{ $rh_motif->{'entry'} }, @motifs;
                    
                    push @{ $rh_rec->{'motif'} }, $rh_motif;
                }
                case 'STRUCTURE' {
                    trim($row);
                    
                    my @entries = split(/\s/, $row);
=begin
                    # For future complex STRUCTURE entry
                    my $rh_struct = pop( @{ $rh_rec->{'structure'} } );
                    
                    push @{ $rh_struct->{'entry'} }, @structs;
                    
                    push @{ $rh_rec->{'structure'} }, $rh_struct;
=cut
                    
                    # Current simple STRUCTURE entry
                    push @{ $rh_rec->{'structure'}->{'entry'} }, @entries;
                }
                case 'DISEASE' {
                    # Do nothing
                }
                case 'DBLINKS' {
                    trim($row);
                    
                    my @entries = split(/\s/, $row);
                    
                    my $rh_dblink = pop( @{ $rh_rec->{'dblink'} } );
                    
                    push @{ $rh_dblink->{'entry'} }, @entries;
                    
                    push @{ $rh_rec->{'dblink'} }, $rh_dblink;
                }
                case 'PATHWAY' {
                    # Fetch pahtway ENTRY ONLY. So do nothing
                }
                else {
                    # Output unmatched row
                    ### Unmatched more than 12-spacing leading row
                    ### $row
                }
            }
        }
        else {
            ### Unmatched row
            ### $row
        }
    }
    
    return $rh_rec;
}

1;
