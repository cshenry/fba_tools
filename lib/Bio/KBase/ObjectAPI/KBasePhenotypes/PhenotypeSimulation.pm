########################################################################
# Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulation - This is the moose object corresponding to the KBasePhenotypes.PhenotypeSimulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-01-05T15:36:51
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSimulation;
package Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulation;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSimulation';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has gapfilledReactionString => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgapfilledReactionString'  );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildgapfilledReactionString {
	my ($self) = @_;
	my $gapfillstring = "";
	my $rxns = $self->gapfilledReactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		if (length($gapfillstring) > 0) {
			$gapfillstring .= "<br>";
		}
		$gapfillstring .= $rxns->[$i];
		if ($rxns->[$i] =~ m/([-\+])(rxn\d+)/) {
			my $rxnid = $2;
			my $rxnobj = $self->parent()->fbamodel()->template()->searchForReaction($rxnid);
			if (defined($rxnobj)) {
				$gapfillstring .= " (".$rxnobj->definition().")";
			}
		}
	}
	return $gapfillstring;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
