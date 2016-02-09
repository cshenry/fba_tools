########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TemplateRole - This is the moose object corresponding to the KBaseFBA.TemplateRole object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-10-16T03:20:25
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateRole;
package Bio::KBase::ObjectAPI::KBaseFBA::TemplateRole;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateRole';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has searchname => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildsearchname' );


#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildsearchname {
	my ($self) = @_;
	return Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($self->name());
}


#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
