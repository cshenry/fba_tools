########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBAReactionVariable - This is the moose object corresponding to the FBAReactionVariable object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-04-28T22:56:11
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAReactionVariable;
package Bio::KBase::ObjectAPI::KBaseFBA::FBAReactionVariable;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAReactionVariable';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has reactionID => ( is => 'rw', isa => 'Str',printOrder => '1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionID');
has reactionName => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionName');
has modelreaction => ( is => 'rw', isa => 'Ref',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmodelreaction');

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildreactionID {
	my ($self) = @_;
	return $self->modelreaction()->reaction()->msid();
}
sub _buildreactionName {
	my ($self) = @_;
	return $self->modelreaction()->reaction()->msname();
}
sub _buildmodelreaction {
	 my ($self) = @_;
	 if ($self->modelreaction_ref() =~ m/~\/modelreactions\/id\/(.+)/) {
	 	$self->modelreaction_ref("~/fbamodel/modelreactions/id/".$1);
	 }
	 return $self->getLinkedObject($self->modelreaction_ref());
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
