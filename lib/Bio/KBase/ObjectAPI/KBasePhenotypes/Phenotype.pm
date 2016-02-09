########################################################################
# Bio::KBase::ObjectAPI::KBasePhenotypes::Phenotype - This is the moose object corresponding to the KBasePhenotypes.Phenotype object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-01-05T15:36:51
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBasePhenotypes::DB::Phenotype;
package Bio::KBase::ObjectAPI::KBasePhenotypes::Phenotype;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBasePhenotypes::DB::Phenotype';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has geneKOString => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_geneKOString' );
has additionalCpdString => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_additionalCpdString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _build_geneKOString {
	my ($self) = @_;
	my $genes = $self->genekos();
	my $output = "";
	for (my $i=0; $i < @{$genes};$i++) {
		if (length($output) > 0) {
			$output .= ";";
		}
		$output .= $genes->[$i]->id();
		
	}
	if (length($output) == 0) {
		$output = "none";
	}
	return $output;
}

sub _build_additionalCpdString {
	my ($self) = @_;
	my $cpds = $self->additionalcompounds();
	my $output = "";
	for (my $i=0; $i < @{$cpds};$i++) {
		if (length($output) > 0) {
			$output .= ";";
		}
		$output .= $cpds->[$i]->id();
	}
	if (length($output) == 0) {
		$output = "none";
	}
	return $output;
}


#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
