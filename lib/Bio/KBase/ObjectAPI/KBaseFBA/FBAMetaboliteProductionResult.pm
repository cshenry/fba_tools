########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBAMetaboliteProductionResult - This is the moose object corresponding to the FBAMetaboliteProductionResult object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-06-29T06:00:13
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAMetaboliteProductionResult;
package Bio::KBase::ObjectAPI::KBaseFBA::FBAMetaboliteProductionResult;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAMetaboliteProductionResult';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has compoundID => ( is => 'rw', isa => 'Str',printOrder => '1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundID');
has compoundName => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundName');

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcompoundID {
	my ($self) = @_;
	return $self->modelCompound()->id();
}
sub _buildcompoundName {
	my ($self) = @_;
	return $self->modelCompound()->name();
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************


#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
