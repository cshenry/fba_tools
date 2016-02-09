########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBAMinimalMediaResult - This is the moose object corresponding to the FBAMinimalMediaResult object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-06-29T06:00:13
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAMinimalMediaResult;
package Bio::KBase::ObjectAPI::KBaseFBA::FBAMinimalMediaResult;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAMinimalMediaResult';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has essentialNutrientList => ( is => 'rw', isa => 'Str',printOrder => '1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildessentialNutrientList');
has optionalNutrientList => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildoptionalNutrientList');

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildessentialNutrientList {
	my ($self) = @_;
	my $string = "";
	my $essnuts = $self->essentialNutrients();
	for (my $i=0; $i < @{$essnuts}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $essnuts->[$i]->id();
	}
	return $string;
}
sub _buildoptionalNutrientList {
	my ($self) = @_;
	my $string = "";
	my $optnuts = $self->optionalNutrients();
	for (my $i=0; $i < @{$optnuts}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $optnuts->[$i]->id();
	}
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
