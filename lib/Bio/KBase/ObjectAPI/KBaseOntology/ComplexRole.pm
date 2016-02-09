########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::ComplexRole - This is the moose object corresponding to the ComplexRole object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseOntology::DB::ComplexRole;
package Bio::KBase::ObjectAPI::KBaseOntology::ComplexRole;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProteinSubunit;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseOntology::DB::ComplexRole';

=head1 Bio::KBase::ObjectAPI::KBaseOntology::ComplexRole

=head2 METHODS

=head3 createProteinSubunit

    $cpxrole->createProteinSubunit({
        features => $f, note => $n
    });

Create L<Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProteinSubunit> object where
features is an array reference of Features, and note is
a string. Both features and note are optional.

=cut

sub createProteinSubunit {
    my ($self, $args) = @_;
    $args = Bio::KBase::ObjectAPI::utilities::ARGS(
        $args, [], { features => [], note => undef}
    );
    my $feature_uuids = [ map { $_->uuid } @{$args->{features}} ];
    my $hash = {
        optional   => $self->optional,
        triggering => $self->triggering,
        role_uuid  => $self->role_uuid,
        modelReactionProteinSubunitGenes => 
    };
    $hash->{note} = $args->{note} if defined $args->{note};
    return Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProteinSubunit->new($hash);

}


__PACKAGE__->meta->make_immutable;
1;
