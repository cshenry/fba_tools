########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::Biochemistry - This is the moose object corresponding to the KBaseBiochem.Biochemistry object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::Biochemistry;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseBiochem::Compound;
use Bio::KBase::ObjectAPI::KBaseBiochem::Cue;
use Bio::KBase::ObjectAPI::KBaseBiochem::ReactionSet;
use Bio::KBase::ObjectAPI::KBaseBiochem::Reaction;
use Bio::KBase::ObjectAPI::KBaseBiochem::Compartment;
use Bio::KBase::ObjectAPI::KBaseBiochem::CompoundSet;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has reaction_aliases => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has description => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has compound_aliases => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has compounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Compound)', metaclass => 'Typed', reader => '_compounds', printOrder => '3');
has cues => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Cue)', metaclass => 'Typed', reader => '_cues', printOrder => '1');
has reactionSets => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ReactionSet)', metaclass => 'Typed', reader => '_reactionSets', printOrder => '-1');
has reactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Reaction)', metaclass => 'Typed', reader => '_reactions', printOrder => '4');
has compartments => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Compartment)', metaclass => 'Typed', reader => '_compartments', printOrder => '0');
has compoundSets => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(CompoundSet)', metaclass => 'Typed', reader => '_compoundSets', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseBiochem.Biochemistry'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'Biochemistry'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reaction_aliases',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'name',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'description',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'compound_aliases',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {reaction_aliases => 0, name => 1, description => 2, compound_aliases => 3, id => 4};
sub _attributes {
	 my ($self, $key) = @_;
	 if (defined($key)) {
	 	 my $ind = $attribute_map->{$key};
	 	 if (defined($ind)) {
	 	 	 return $attributes->[$ind];
	 	 } else {
	 	 	 return;
	 	 }
	 } else {
	 	 return $attributes;
	 }
}

my $links = [];

my $link_map = {};
sub _links {
	 my ($self, $key) = @_;
	 if (defined($key)) {
	 	 my $ind = $link_map->{$key};
	 	 if (defined($ind)) {
	 	 	 return $links->[$ind];
	 	 } else {
	 	 	 return;
	 	 }
	 } else {
	 	 return $links;
	 }
}

my $subobjects = [
          {
            'req' => undef,
            'printOrder' => 3,
            'name' => 'compounds',
            'default' => undef,
            'description' => undef,
            'class' => 'Compound',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          },
          {
            'req' => undef,
            'printOrder' => 1,
            'name' => 'cues',
            'default' => undef,
            'description' => 'Structural cues for parts of compund structures',
            'class' => 'Cue',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          },
          {
            'req' => undef,
            'printOrder' => -1,
            'name' => 'reactionSets',
            'default' => undef,
            'description' => undef,
            'class' => 'ReactionSet',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          },
          {
            'req' => undef,
            'printOrder' => 4,
            'name' => 'reactions',
            'default' => undef,
            'description' => undef,
            'class' => 'Reaction',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          },
          {
            'req' => undef,
            'printOrder' => 0,
            'name' => 'compartments',
            'default' => undef,
            'description' => undef,
            'class' => 'Compartment',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          },
          {
            'req' => undef,
            'printOrder' => -1,
            'name' => 'compoundSets',
            'default' => undef,
            'description' => undef,
            'class' => 'CompoundSet',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          }
        ];

my $subobject_map = {compounds => 0, cues => 1, reactionSets => 2, reactions => 3, compartments => 4, compoundSets => 5};
sub _subobjects {
	 my ($self, $key) = @_;
	 if (defined($key)) {
	 	 my $ind = $subobject_map->{$key};
	 	 if (defined($ind)) {
	 	 	 return $subobjects->[$ind];
	 	 } else {
	 	 	 return;
	 	 }
	 } else {
	 	 return $subobjects;
	 }
}
# SUBOBJECT READERS:
around 'compounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('compounds');
};
around 'cues' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('cues');
};
around 'reactionSets' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('reactionSets');
};
around 'reactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('reactions');
};
around 'compartments' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('compartments');
};
around 'compoundSets' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('compoundSets');
};


__PACKAGE__->meta->make_immutable;
1;
