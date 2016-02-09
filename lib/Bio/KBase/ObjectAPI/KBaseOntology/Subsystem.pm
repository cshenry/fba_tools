########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::Subsystem - This is the moose object corresponding to the RoleSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseOntology::DB::Subsystem;
package Bio::KBase::ObjectAPI::KBaseOntology::Subsystem;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseOntology::DB::Subsystem';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has roleList => ( is => 'rw', isa => 'Str',printOrder => '5', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleList' );
has roleIDs => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleIDs' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildroleList {
	my ($self) = @_;
	my $roleList = "";
	for (my $i=0; $i < @{$self->roles()}; $i++) {
		if (length($roleList) > 0) {
			$roleList .= ";";
		}
		$roleList .= $self->roles()->[$i]->name();		
	}
	return $roleList;
}
sub _buildroleIDs {
	my ($self) = @_;
	my $roleIDs = [];
	my $roles = $self->roles();
	for (my $i=0; $i < @{$roles}; $i++) {
		push(@{$roleIDs},$roles->[$i]->id());		
	}
	return $roleIDs;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub getAlias {
    my ($self,$set) = @_;
    my $aliases = $self->getAliases($set);
    return (@$aliases) ? $aliases->[0] : undef;
}

sub getAliases {
    my ($self,$setName) = @_;
    return [] unless(defined($setName));
    my $output = [];
    my $aliases = $self->parent()->subsystem_aliases()->{$self->id()};
    if (defined($aliases)) {
    	foreach my $alias (@{$aliases}) {
    		if ($alias->[0] eq $setName) {
    			push(@{$output},$alias->[1]);
    		}
    	}
    }
    return $output;
}

sub allAliases {
	my ($self) = @_;
    my $output = [];
    my $aliases = $self->parent()->subsystem_aliases()->{$self->id()};
    if (defined($aliases)) {
    	foreach my $alias (@{$aliases}) {
    		push(@{$output},$alias->[1]);
    	}
    }
    return $output;
}

sub hasAlias {
    my ($self,$alias,$setName) = @_;
    my $aliases = $self->parent()->subsystem_aliases()->{$self->id()};
    if (defined($aliases)) {
    	foreach my $alias (@{$aliases}) {
    		if ($alias->[0] eq $setName && $alias->[1] eq $alias) {
    			return 1;
    		}
    	}
    }
    return 0;
}
=head3 addRole

Definition:
	void addRole();
Description:
	Adds role to roleset
	
=cut

sub addRole {
	my ($self,$role) = @_;
	for (my $i=0; $i < @{$self->role_uuids()}; $i++) {
		if ($self->role_uuids()->[$i] eq $role->uuid()) {
			return;
		}
	}
	push(@{$self->role_uuids()},$role->uuid());
	$self->clear_roles();
}

__PACKAGE__->meta->make_immutable;
1;
