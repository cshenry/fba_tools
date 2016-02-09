########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::GapgenerationSolution - This is the moose object corresponding to the GapgenSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-08-07T07:31:48
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::GapgenerationSolution;
package Bio::KBase::ObjectAPI::KBaseFBA::GapgenerationSolution;
use Moose;
use Bio::KBase::ObjectAPI::utilities;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::GapgenerationSolution';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has solrxn => ( is => 'rw',printOrder => -1, isa => 'ArrayRef', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildsolrxn' );
has biocpd => ( is => 'rw',printOrder => -1, isa => 'ArrayRef', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildbiocpd' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildsolrxn {
	my ($self) = @_;
	my $rxns = [];
	for (my $i=0; $i < @{$self->gapgenSolutionReactions()};$i++) {
		push(@{$rxns},[$self->gapgenSolutionReactions()->[$i]->direction(),$self->gapfillingSolutionReactions()->[$i]->reaction()->id()]);
	}
	return $rxns;
}
sub _buildbiocpd {
	my ($self) = @_;
	my $cpds = [];
	for (my $i=0; $i < @{$self->biomassSupplements()};$i++) {
		push(@{$cpds},$self->biomassSupplements()->[$i]->compound()->id())
	}
	return $cpds;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 loadFromData

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->loadFromData();
Description:
	Loads gapgen results from file

=cut

sub loadFromData {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["objective","reactions"], { model => $self->model }, @_);
	my $model = $args->{model};
	$self->solutionCost($args->{objective});
	for (my $m=0; $m < @{$args->{reactions}}; $m++) {
		if ($args->{reactions}->[$m] =~ m/([\-\+])(.+)/) {
			my $rxnid = $2;
			my $sign = $1;
			my $rxn = $model->biochemistry()->queryObject("reactions",{id => $rxnid});
			if (!defined($rxn)) {
				Bio::KBase::ObjectAPI::utilities::ERROR("Could not find gapgen reaction ".$rxnid."!");
			}
			my $mdlrxn = $model->queryObject("modelreactions",{reaction_uuid => $rxn->uuid()});
			my $direction = ">";
			if ($sign eq "-") {
				$direction = "<";
			}
			$self->add("gapgenSolutionReactions",{
				modelreaction_uuid => $mdlrxn->uuid(),
				modelreaction => $mdlrxn,
				direction => $direction
			});
			if ($mdlrxn->direction() eq $direction) {
				$model->remove("modelreactions",$mdlrxn);
			} elsif ($direction eq ">") {
				$mdlrxn->direction("<");
			} elsif ($direction eq "<") {
				$mdlrxn->direction(">");
			}
		}
	}
}

__PACKAGE__->meta->make_immutable;
1;
