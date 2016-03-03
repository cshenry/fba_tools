########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBACompoundVariable - This is the moose object corresponding to the FBACompoundVariable object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-04-28T22:56:11
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBACompoundVariable;
package Bio::KBase::ObjectAPI::KBaseFBA::FBACompoundVariable;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBACompoundVariable';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has compoundID => ( is => 'rw', isa => 'Str',printOrder => '1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundID');
has compoundName => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundName');
has modelcompound => ( is => 'rw', isa => 'Ref',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmodelcompound');

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcompoundID {
	my ($self) = @_;
	return $self->modelcompound()->compound()->id();
}
sub _buildcompoundName {
	my ($self) = @_;
	return $self->modelcompound()->compound()->name();
}
sub _buildmodelcompound {
	 my ($self) = @_;
	 if ($self->modelcompound_ref() =~ m/~\/modelcompounds\/id\/(.+)/) {
	 	$self->modelcompound_ref("~/fbamodel/modelcompounds/id/".$1);
	 }
	 return $self->getLinkedObject($self->modelcompound_ref());
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************


#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 clearProblem

Definition:
	Output = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->clearProblem();
	Output = {
		success => 0/1
	};
Description:
	Builds the FBA problem

=cut

__PACKAGE__->meta->make_immutable;
1;
