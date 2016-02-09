########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::Role - This is the moose object corresponding to the Role object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseOntology::DB::Role;
package Bio::KBase::ObjectAPI::KBaseOntology::Role;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseOntology::DB::Role';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has searchname => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildsearchname' );
has reactions => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactions' );
has complexIDs => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcomplexIDs' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildsearchname {
	my ($self) = @_;
	return Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($self->name());
}
sub _buildreactions {
	my ($self) = @_;
	my $hash = $self->parent()->roleReactionHash();
	my $rxnlist = "";
	if (defined($hash->{$self->uuid()})) {
		foreach my $rxn (keys(%{$hash->{$self->uuid()}})) {
			if (length($rxnlist) > 0) {
				$rxnlist .= ";";
			}
			$rxnlist .= $hash->{$self->uuid()}->{$rxn}->id();
		}
	}
	return $rxnlist;
}
sub _buildcomplexIDs {
	my ($self) = @_;
	my $hash = $self->parent()->roleComplexHash();
	my $complexes = [];
	if (defined($hash->{$self->uuid()})) {
		foreach my $cpxid (keys(%{$hash->{$self->uuid()}})) {
			push(@{$complexes},$hash->{$self->uuid()}->{$cpxid}->id());
		}
	}
	return $complexes;
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
    my $aliases = $self->parent()->role_aliases()->{$self->id()};
    if (defined($aliases) && defined($aliases->{$setName})) {
    	return $aliases->{$setName};
    }
    return $output;
}

sub allAliases {
	my ($self) = @_;
    my $output = [];
    my $aliases = $self->parent()->role_aliases()->{$self->id()};
    if (defined($aliases)) {
    	foreach my $set (keys(%{$aliases})) {
    		push(@{$output},@{$aliases->{$set}});
    	}
    }
    return $output;
}

sub hasAlias {
    my ($self,$alias,$setName) = @_;
    my $aliases = $self->parent()->role_aliases()->{$self->id()};
    if (defined($aliases) && defined($aliases->{$setName})) {
    	foreach my $searchalias (@{$aliases->{$setName}}) {
    		if ($searchalias eq $alias) {
    			return 1;
    		}
    	}
    }
    return 0;
}


__PACKAGE__->meta->make_immutable;
1;
