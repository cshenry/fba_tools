########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionReagent - This is the moose object corresponding to the ModelReactionReagent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-04-28T22:56:11
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReactionReagent;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionReagent;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReactionReagent';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has isCofactor => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisCofactor' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildisCofactor {
	my ($self) = @_;
	if ($self->modelcompound()->compound()->isCofactor()) {
		return 1;
	}
	my $rxn = $self->parent()->reaction();
	my $rgts = $rxn->reagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->templatecompcompound()->templatecompound() eq $self->modelcompound()->compound()) {
			if ($rgt->templatecompcompound()->templatecompartment() eq $self->modelcompound()->modelcompartment()->compartment()) {
				return $rgt->isCofactor();
			}
		}
	}
	return 0;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
