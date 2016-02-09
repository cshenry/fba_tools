########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompCompound - This is the moose object corresponding to the KBaseFBA.TemplateCompCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-10-16T03:20:25
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompCompound;
package Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompCompound;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompCompound';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has isBiomassCompound  => ( is => 'rw', isa => 'Bool',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisBiomassCompound' );


#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildisBiomassCompound {
	my ($self) = @_;
	$self->parent()->labelBiomassCompounds();
	return $self->isBiomassCompound();
}


#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
