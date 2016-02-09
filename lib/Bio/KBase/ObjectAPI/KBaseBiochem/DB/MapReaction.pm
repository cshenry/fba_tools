########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::MapReaction - This is the moose object corresponding to the KBaseBiochem.MapReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::MapReaction;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseBiochem::MapReactionReactant;
use Bio::KBase::ObjectAPI::KBaseBiochem::MapReactionReactant;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has w => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has link => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has rxns => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has x => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has y => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has h => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has reversible => (is => 'rw', isa => 'Bool', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has ec => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has shape => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has substrate_refs => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(MapReactionReactant)', metaclass => 'Typed', reader => '_substrate_refs', printOrder => '-1');
has product_refs => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(MapReactionReactant)', metaclass => 'Typed', reader => '_product_refs', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/reactions/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseBiochem.MapReaction'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'MapReaction'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'w',
            'type' => 'Int',
            'perm' => 'rw'
          },
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
            'name' => 'name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'rxns',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'x',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'y',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'h',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reversible',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'ec',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'shape',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {w => 0, link => 1, name => 2, rxns => 3, x => 4, y => 5, h => 6, reversible => 7, ec => 8, id => 9, shape => 10};
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
            'name' => 'substrate_refs',
            'type' => 'child',
            'class' => 'MapReactionReactant',
            'module' => 'KBaseBiochem'
          },
          {
            'printOrder' => -1,
            'name' => 'product_refs',
            'type' => 'child',
            'class' => 'MapReactionReactant',
            'module' => 'KBaseBiochem'
          }
        ];

my $subobject_map = {substrate_refs => 0, product_refs => 1};
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
around 'substrate_refs' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('substrate_refs');
};
around 'product_refs' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('product_refs');
};


__PACKAGE__->meta->make_immutable;
1;
