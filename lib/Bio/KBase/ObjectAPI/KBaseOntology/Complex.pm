########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::Complex - This is the moose object corresponding to the Complex object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseOntology::DB::Complex;
package Bio::KBase::ObjectAPI::KBaseOntology::Complex;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseOntology::DB::Complex';
has roleList => (
    is         => 'rw',
    isa        => 'Str',
    printOrder => '2',
    type       => 'msdata',
    metaclass  => 'Typed',
    lazy       => 1,
    builder    => '_build_roleList'
);
has reactionList => (
    is         => 'rw',
    isa        => 'Str',
    printOrder => '3',
    type       => 'msdata',
    metaclass  => 'Typed',
    lazy       => 1,
    builder    => '_build_reactionList'
);
has roleTuples => (
    is         => 'rw',
    isa        => 'ArrayRef',
    printOrder => '3',
    type       => 'msdata',
    metaclass  => 'Typed',
    lazy       => 1,
    builder    => '_build_roleTuples'
);

sub getAlias {
    my ($self,$set) = @_;
    my $aliases = $self->getAliases($set);
    return (@$aliases) ? $aliases->[0] : undef;
}

sub getAliases {
    my ($self,$setName) = @_;
    return [] unless(defined($setName));
    my $output = [];
    my $aliases = $self->parent()->complex_aliases()->{$self->id()};
    if (defined($aliases) && defined($aliases->{$setName})) {
    	return $aliases->{$setName};
    }
    return $output;
}

sub allAliases {
	my ($self) = @_;
    my $output = [];
    my $aliases = $self->parent()->complex_aliases()->{$self->id()};
    if (defined($aliases)) {
    	foreach my $set (keys(%{$aliases})) {
    		push(@{$output},@{$aliases->{$set}});
    	}
    }
    return $output;
}

sub hasAlias {
    my ($self,$alias,$setName) = @_;
    my $aliases = $self->parent()->complex_aliases()->{$self->id()};
    if (defined($aliases) && defined($aliases->{$setName})) {
    	foreach my $searchalias (@{$aliases->{$setName}}) {
    		if ($searchalias eq $alias) {
    			return 1;
    		}
    	}
    }
    return 0;
}

sub isActivatedWithRoles {
    my ($self, $args) = @_;
    $args = Bio::KBase::ObjectAPI::utilities::ARGS($args, ["roles"], {});
    my $roles = $args->{roles};
    my $uuid_roles = {};
    # Reduce roles to the simple uuid
    foreach my $role (@$roles) {
        if (ref($role) && eval { $role->isa('Bio::KBase::ObjectAPI::KBaseOntology::Role') }) {
            $uuid_roles->{$role->uuid} = 1;
        } else {
            $uuid_roles->{$role} = 1;
        }
    }
    # Match against complexrole
    foreach my $cpx_role (@{$self->complexroles}) {
        if ( defined($uuid_roles->{$cpx_role->role_uuid}) ) {
            return 1; 
        }
    }
}
sub createModelReactionProtein {
    my ($self, $args) = @_;
    $args = Bio::KBase::ObjectAPI::utilities::ARGS(
        $args, [], { features => [], note => undef }
    );
    # Generate subunits for each complexRole (takes same args as this function)
    my $subunits = [ map { $_->createProteinSubunit($args) } @{$self->complexroles} ];
    my $hash = {
        modelReactionProteinSubunits => $subunits,
        complex_uuid => $self->uuid,
    };
    $hash->{note} = $args->{note} if defined $args->{note};
    return Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProtein->new($hash);
}
sub _build_roleList {
	my ($self) = @_;
	my $roleList = "";
	for (my $i=0; $i < @{$self->complexroles()}; $i++) {
		if (length($roleList) > 0) {
			$roleList .= ";";
		}
		my $cpxroles = $self->complexroles()->[$i];
		$roleList .= $cpxroles->role()->name()."[".$cpxroles->optional()."_".$cpxroles->triggering()."]";		
	}
	return $roleList;
}
sub _build_reactionList {
	my ($self) = @_;
	my $reactionList = "";
	my $cpxrxns = $self->reactions();
	for (my $i=0; $i < @{$cpxrxns}; $i++) {
		if (length($reactionList) > 0) {
			$reactionList .= ";";
		}
		$reactionList .= $cpxrxns->[$i]->id();		
	}
	return $reactionList;
}
sub _build_roleTuples {
    my ($self) = @_;
    my $roletuples = [];
    my $roles = $self->complexroles();
    for (my $i=0; $i < @{$roles}; $i++) {
    	my $role = $roles->[$i];
    	push(@{$roletuples},[$role->role()->id(),$role->type(),$role->optionalRole(),$role->triggering()]);
    }
    return $roletuples;
}

__PACKAGE__->meta->make_immutable;
1;
