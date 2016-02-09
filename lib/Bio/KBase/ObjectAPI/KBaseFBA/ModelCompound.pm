########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound - This is the moose object corresponding to the ModelCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelCompound;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelCompound';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has name => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildname' );
has abbreviation => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildabbreviation' );
has id => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildid' );
has modelCompartmentLabel => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmodelCompartmentLabel' );
has isBiomassCompound  => ( is => 'rw', isa => 'Bool',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisBiomassCompound' );
has mapped_uuid  => ( is => 'rw', isa => 'ModelSEED::uuid',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmapped_uuid' );
has formula  => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildformula' );
has msid => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmsid' );
has msname => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmsname' );

has compound => (is => 'rw', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'Ref', weak_ref => 1);

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _build_compound {
	 my ($self) = @_;
	 my $array = [split(/\//,$self->compound_ref())];
	 my $compoundid = pop(@{$array});
	 $self->compound_ref("~/template/compounds/id/".$compoundid);
	 my $obj = $self->getLinkedObject($self->compound_ref());
	 if (!defined($obj)) {
	 	$obj = $self->getLinkedObject("~/template/compounds/id/cpd00000");
	 }
	 return $obj;
}
sub _buildid {
	my ($self) = @_;
	return $self->compound()->id()."_".$self->modelCompartmentLabel();
}
sub _buildname {
	my ($self) = @_;
	return $self->compound()->name()."_".$self->modelCompartmentLabel();
}
sub _buildabbreviation {
	my ($self) = @_;
	return $self->compound()->abbreviation()."_".$self->modelCompartmentLabel();
}
sub _buildmodelCompartmentLabel {
	my ($self) = @_;
	return $self->modelcompartment()->id();
}
sub _buildisBiomassCompound {
	my ($self) = @_;
	$self->parent()->labelBiomassCompounds();
	return $self->isBiomassCompound();
}
sub _buildmapped_uuid {
	my ($self) = @_;
	return "00000000-0000-0000-0000-000000000000";
}
sub _buildformula {
	my ($self) = @_;
	return $self->compound()->formula();
}
sub _buildmsid {
	my ($self) = @_;
	return $self->compound()->id();
}
sub _buildmsname {
	my ($self) = @_;
	return $self->compound()->name();
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
    my $aliases = $self->aliases();
    for (my $i=0; $i < @{$aliases}; $i++) {
    	if ($aliases->[$i] =~ m/$setName:(.+)/) {
    		push(@{$output},$1);
    	} elsif ($aliases->[$i] !~ m/:/ && $setName eq "name") {
    		push(@{$output},$aliases->[$i]);
    	}
    }
    return $output;
}

sub allAliases {
	my ($self) = @_;
    my $output = [];
    my $aliases = $self->aliases();
    for (my $i=0; $i < @{$aliases}; $i++) {
    	if ($aliases->[$i] =~ m/(.+):(.+)/) {
    		push(@{$output},$2);
    	} else {
    		push(@{$output},$aliases->[$i]);
    	}
    }
    return $output;
}

sub hasAlias {
    my ($self,$alias,$setName) = @_;
    my $aliases = $self->aliases();
    for (my $i=0; $i < @{$aliases}; $i++) {
    	if (defined($setName) && $aliases->[$i] eq $setName.":".$alias) {
    		return 1;
    	} elsif (!defined($setName) && $aliases->[$i] eq $alias) {
    		return 1;
    	}
    }
    return 0;
}

sub addAlias {
    my ($self,$alias,$setName) = @_;
    my $aliases = $self->aliases();
    for (my $i=0; $i < @{$aliases}; $i++) {
    	if (defined($setName) && $aliases->[$i] eq $setName.":".$alias) {
    		return ;
    	} elsif (!defined($setName) && $aliases->[$i] eq $alias) {
    		return ;
    	}
    }
    if (defined($setName)) {
    	push(@{$aliases},$setName.":".$alias);
    } else {
    	push(@{$aliases},$alias);
    }
}

__PACKAGE__->meta->make_immutable;
1;
