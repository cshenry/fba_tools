########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProtein - This is the moose object corresponding to the ModelReactionProtein object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-05-21T02:47:43
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReactionProtein;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProtein;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReactionProtein';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has gprString => ( is => 'rw', isa => 'Str',printOrder => '0', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgprString' );
has exchangeGPRString => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildexchangeGPRString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildgprString {
	my ($self) = @_;
	if (@{$self->modelReactionProteinSubunits()} == 0) {
		#if (length($self->note()) > 0) {
		#	return $self->note();
		#}
		return "Unknown";
	}
	my $gpr = "";
	foreach my $subunit (@{$self->modelReactionProteinSubunits()}) {
		if (length($gpr) > 0) {
			$gpr .= " and ";	
		}
		$gpr .= $subunit->gprString();
	}
	if (@{$self->modelReactionProteinSubunits()} > 1) {
		$gpr = "(".$gpr.")";	
	}
	return $gpr;
}
sub _buildexchangeGPRString {
	my ($self) = @_;
	my $gpr = "";
	if (!defined($self->complex_uuid()) || $self->complex_uuid() =~ m/^[0\-]+$/) {
		$gpr .= "unknown{";
	} else {
		$gpr .= $self->complex()->name()."{";
	}
	my $sus = $self->modelReactionProteinSubunits();
	my $sugpr = "";
	foreach my $su (@{$sus}) {
		if (length($sugpr) > 0) {
			$sugpr .= "+";
		}
		$sugpr .= $su->exchangeGPRString();
	}
	$gpr .= $sugpr;
	$gpr .= "}";
	return $gpr;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub SplitFluxToGenesByAbundance {
	my ($self,$abundance_hash,$flux,$gene_flux) = @_;
	foreach my $subunit (@{$self->modelReactionProteinSubunits()}) {
		$gene_flux = $subunit->SplitFluxToGenesByAbundance($abundance_hash,$flux,$gene_flux);
	}
	return $gene_flux;
}

sub protein_expression {
	my ($self,$expression_hash) = @_;
	my $lowest_expression;
	foreach my $subunit (@{$self->modelReactionProteinSubunits()}) {
		my $subunitexp = $subunit->subunit_expression($expression_hash);
		if ($subunitexp > 0 && (!defined($lowest_expression) || $subunitexp < $lowest_expression)) {
			$lowest_expression = $subunitexp;
		}
	}
	if (!defined($lowest_expression)) {
		$lowest_expression = 0;
	}
	return $lowest_expression;
}

__PACKAGE__->meta->make_immutable;
1;
