########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelCompartment - This is the moose object corresponding to the ModelCompartment object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelCompartment;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelCompartment;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelCompartment';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has name  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildname' );

has compartment => (is => 'rw', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_compartment', isa => 'Ref', weak_ref => 1);

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildname {
	my ($self) = @_;
	return $self->compartment()->name().$self->compartmentIndex();
}
sub _build_compartment {
	 my ($self) = @_;
	 my $array = [split(/\//,$self->compartment_ref())];
	 my $compid = pop(@{$array});
	 $self->compartment_ref($self->parent()->template()->_reference()."/compartments/id/".$compid);
	 return $self->getLinkedObject($self->compartment_ref());
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
