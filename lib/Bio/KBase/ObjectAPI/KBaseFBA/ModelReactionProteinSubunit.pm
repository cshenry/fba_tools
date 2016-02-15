########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProteinSubunit - This is the moose object corresponding to the ModelReactionProteinSubunit object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-05-21T02:47:43
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReactionProteinSubunit;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProteinSubunit;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReactionProteinSubunit';
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
	if (@{$self->features()} == 0) {
		return "Unknown";
	}
	my $gpr = "";
	my $ftrs = $self->features();
	foreach my $gene (@{$ftrs}) {
		if (length($gpr) > 0) {
			$gpr .= " or ";	
		}
		$gpr .= $gene->id();
	}
	if (@{$ftrs} > 1) {
		$gpr = "(".$gpr.")";	
	}
	return $gpr;
}
sub _buildexchangeGPRString {
	my ($self) = @_;
	my $gpr = "";
	if (!defined($self->role()) || $self->role() =~ m/^[0\-]+$/) {
		$gpr .= "{";
	} else {
		$gpr .= "{";
	}
	my $features = $self->features();
	my $fgpr = "";
	foreach my $feature (@{$features}) {
		if (length($fgpr) > 0) {
			$fgpr .= "/";
		}
		$fgpr .= $feature->id();
	}
	$gpr .= $fgpr;
	$gpr .= "}";
	return $gpr;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub subunit_expression {
	my ($self,$expression_hash) = @_;
	my $highest_expression = 0;
	my $ftrs = $self->feature_refs();
	foreach my $ftr (@{$ftrs}) {
		if ($ftr =~ m/\/([^\/]+)$/) {
			my $ftrid = $1;
			if (defined($expression_hash->{$ftrid}) && $expression_hash->{$ftrid} > $highest_expression) {
				$highest_expression = $expression_hash->{$ftrid};
			}
		}
	}
	return $highest_expression;
}

__PACKAGE__->meta->make_immutable;
1;
