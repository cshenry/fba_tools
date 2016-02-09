########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::Compartment - This is the moose object corresponding to the Compartment object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::Compartment;
package Bio::KBase::ObjectAPI::KBaseBiochem::Compartment;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::Compartment';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has mapped_uuid  => ( is => 'rw', isa => 'ModelSEED::uuid',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmapped_uuid' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildmapped_uuid {
	my ($self) = @_;
	return "00000000-0000-0000-0000-000000000000";
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
