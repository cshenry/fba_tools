########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::MetabolicMap - This is the moose object corresponding to the KBaseBiochem.MetabolicMap object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::MetabolicMap;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseBiochem::MapCompound;
use Bio::KBase::ObjectAPI::KBaseBiochem::MapReaction;
use Bio::KBase::ObjectAPI::KBaseBiochem::MapLink;
use Bio::KBase::ObjectAPI::KBaseBiochem::ReactionGroup;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has link => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has source => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has source_id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has compound_ids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has description => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has reaction_ids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has compounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(MapCompound)', metaclass => 'Typed', reader => '_compounds', printOrder => '-1');
has reactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(MapReaction)', metaclass => 'Typed', reader => '_reactions', printOrder => '-1');
has linkedmaps => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(MapLink)', metaclass => 'Typed', reader => '_linkedmaps', printOrder => '-1');
has groups => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ReactionGroup)', metaclass => 'Typed', reader => '_groups', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'//id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseBiochem.MetabolicMap'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'MetabolicMap'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'link',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'source',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'source_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'compound_ids',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'name',
            'type' => 'Str',
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
            'name' => 'reaction_ids',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
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

my $attribute_map = {link => 0, source => 1, source_id => 2, compound_ids => 3, name => 4, description => 5, reaction_ids => 6, id => 7};
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
            'printOrder' => -1,
            'name' => 'compounds',
            'type' => 'child',
            'class' => 'MapCompound',
            'module' => 'KBaseBiochem'
          },
          {
            'printOrder' => -1,
            'name' => 'reactions',
            'type' => 'child',
            'class' => 'MapReaction',
            'module' => 'KBaseBiochem'
          },
          {
            'printOrder' => -1,
            'name' => 'linkedmaps',
            'type' => 'child',
            'class' => 'MapLink',
            'module' => 'KBaseBiochem'
          },
          {
            'printOrder' => -1,
            'name' => 'groups',
            'type' => 'child',
            'class' => 'ReactionGroup',
            'module' => 'KBaseBiochem'
          }
        ];

my $subobject_map = {compounds => 0, reactions => 1, linkedmaps => 2, groups => 3};
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
around 'reactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('reactions');
};
around 'linkedmaps' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('linkedmaps');
};
around 'groups' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('groups');
};


__PACKAGE__->meta->make_immutable;
1;
