=head1 NAME

    Bio::KEGG::gene - Perl module to fetch details of KEGG gene file.

=head1 DESCRIPTION

    Fetch data from Bio::KEGGI::gene object.

=head1 AUTHOR

    Haizhou Liu, zeroliu-at-gmail-dot-com

=head1 VERSION

    0.1.5
    
=head1 METHODS

=head2 ko

    Name:   ko
    Desc:   Get GENE entry ko entries.
            
            $ra_ko = [ $ko_id, ... ]
            
    Usage:  $ra_ko = $o_kegg->ko()
    Args:
    Return: A reference to an array

=head2 name

    Name:   name
    Desc:   Get GENE names.
            
            $ra_name = [ $name, ... ];
            
    Usage:  $ra_name = $o_kegg->name()
    Args:
    Return: A reference to an array
    
=head2 type

    Name:   type
    Desc:   Get gene type: 'CDS', 'gene', 'misc_RNA', 'ncRNA', 'rRNA', 'tmRNA'
            or 'tRNA'.
    Usage:  $type = $o_kegg->type()
    Args:
    Return: A string

=head2 pathway

    Name:   pathway
    Desc:   Get GENE pathway entries.
    
            $ra_pathway = [ $pathway_id, ... ];
            
    Usage:  $ra_pathway = $o_kegg->pathway()
    Args:
    Return: A reference to an array.

=head2 position

    Name:   position
    Desc:   Get gene position in a genome.
    Usage:  $rh_pos = $o_kegg->position()
    Args:
    Return: A string.

=head2 motif

    Name:   motif
    Desc:   Get gene MOTIF information.
            
            $rh_motif = [
                {
                    'db'    => $db,
                    'entry' => [$entry, ... ],
                },
                ...
            ]
    
    Usage:  $rh_motif = $o_kegg->motif()
    Args:
    Return: A reference to an array.
    
=head2 struct

    Name:   struct
    Desc:   Get gene STRUCTURE information
    
            $rh_struct = {
                'db'   => $db,
                'entry' => [ $entry, ... ],
            }
            
    Usage:  $rh_struct = $o_kegg->struct()
    Args:
    Return: A reference to a hash

=head2 aalen

    Name:   aalen
    Desc:   Get gene amino acid length.
    Usage:  $rh_aalen = $o_kegg->aalen();
    Args:
    Return: An integer
    
=head2 aaseq

    Name:   aaseq
    Desc:   Get gene amino acid sequence information
    Usage:  $rh_aaseq = $o_kegg->aaseq();
    Args:
    Return: A string.
    
=head2 ntlen

    Name:   ntlen
    Desc:   Get gene nucleotide length.
    Usage:  $nt_len = $o_kegg->ntlen
    Args:
    Return: An integer.
    
=head2 ntseq

    Name:   ntseq
    Desc:   Get gene nucleotide sequence information.
            
            $rh_ntseq = {
                'length' => $length,
                'seq'    => $seq,
            }
    
    Usage:  $rh_ntseq = $o_kegg->ntseq;
    Args:
    Return: A reference to a hash
    
=cut

package Bio::KEGG::gene;

use strict;
use warnings;

use base qw(Bio::KEGG);

use Smart::Comments;

our $VERSION = 'v0.1.5';

=begin new
    Name:   new
    Desc:   Constuctor for Bio::KEGG::gene object
    Usage:  
    Args:
    Return: A Bio::KEGG::gene object

sub new {
    my $class = shift;
    
    warn "Sorry, construct $class object is not supported now.\n";
    
    return;
}
=cut

=begin name
    Name:   name
    Desc:   Get GENE names.
            
            $ra_name = [ $name, ... ];
            
    Usage:  $ra_name = $o_kegg->name()
    Args:
    Return: A reference to an array
=cut

sub name {
    my $self = shift;
    
    return $self->{'name'};
}

=begin type

=cut

sub type {
    my $self = shift;
    
    return $self->{'type'};
}

=begin ko
    Name:   ko
    Desc:   Get GENE entry ko entries.
            
            $ra_ko = [ $ko_id, ... ]
            
    Usage:  $ra_ko = $o_kegg->ko()
    Args:
    Return: A reference to an array
=cut

sub ko {
    my $self = shift;
    
    return $self->{'ko'};
}

sub pathway {
    my $self = shift;
    
    return $self->{'pathway'};
}

=begin position
    Name:   position
    Desc:   Get gene position in a genome.
    Usage:  $rh_pos = $o_kegg->position()
    Args:
    Return: A string
=cut

sub position {
    my $self = shift;
    
    return $self->{'position'},
}

=begin motif
    Name:   motif
    Desc:   Get gene MOTIF information.
            
            $rh_motif = [
                {
                    'db'    => $db,
                    'entry' => [$entry, ... ],
                },
                ...
            ]
    
    Usage:  $rh_motif = $o_kegg->motif()
    Args:
    Return: A reference to an array.
=cut

sub motif {
    my $self = shift;
    
    return $self->{'motif'};
}

=begin struct
    Name:   struct
    Desc:   Get gene STRUCTURE information
    
            $rh_struct = {
                'db'   => $db,
                'entry' => [ $entry, ... ],
            }
            
    Usage:  $rh_struct = $o_kegg->struct()
    Args:
    Return: A reference to a hash
=cut

sub struct {
    my $self = shift;
    
    return $self->{'structure'};
}

=begin
    Name:   aalen
    Desc:   Get gene amino acid length.
    Usage:  $rh_aalen = $o_kegg->aalen();
    Args:
    Return: An integer
=cut

sub aalen {
    my $self = shift;
    
    return $self->{'aaseq'}->{'length'};
}

=begin aaseq
    Name:   aaseq
    Desc:   Get gene amino acid sequence information
    Usage:  $rh_aaseq = $o_kegg->aaseq();
    Args:
    Return: A string
=cut

sub aaseq {
    my $self = shift;
    
    return $self->{'aaseq'}->{'seq'};
}

=begin ntlen
    Name:   ntlen
    Desc:   Get gene nucleotide length.
    Usage:  $nt_len = $o_kegg->ntlen
    Args:
    Return: An integer.
=cut

sub ntlen {
    my $self = shift;
    
    return $self->{'ntseq'}->{'length'};
}
    
=begin ntseq
    Name:   ntseq
    Desc:   Get gene nucleotide sequence information.
    Usage:  $ntseq = $o_kegg->ntseq;
    Args:
    Return: A string.
=cut

sub ntseq {
    my $self = shift;
    
    return $self->{'ntseq'}->{'seq'};
}

1;