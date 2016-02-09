########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBACompoundBound - This is the moose object corresponding to the FBACompoundBound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-06-29T06:00:13
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBACompoundBound;
package Bio::KBase::ObjectAPI::KBaseFBA::FBACompoundBound;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBACompoundBound';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has readableString => ( is => 'rw', isa => 'Str',printOrder => '0', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreadableString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildreadableString {
	my ($self) = @_;
	my $string = $self->lowerBound()." < ".$self->modelCompound()->id()."_".$self->variableType()." < ".$self->upperBound();
	return $string;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************



__PACKAGE__->meta->make_immutable;
1;
