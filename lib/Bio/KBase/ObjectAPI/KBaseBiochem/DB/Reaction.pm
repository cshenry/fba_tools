########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::Reaction - This is the moose object corresponding to the KBaseBiochem.Reaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::Reaction;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseBiochem::Reagent;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has deltaG => (is => 'rw', isa => 'Num', printOrder => '8', type => 'attribute', metaclass => 'Typed');
has status => (is => 'rw', isa => 'Str', printOrder => '10', default => 'unknown', type => 'attribute', metaclass => 'Typed');
has thermoReversibility => (is => 'rw', isa => 'Str', printOrder => '6', default => '=', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has cues => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has defaultProtons => (is => 'rw', isa => 'Num', printOrder => '7', type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '5', default => '=', type => 'attribute', metaclass => 'Typed');
has abstractReaction_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has abbreviation => (is => 'rw', isa => 'Str', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');
has md5 => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has deltaGErr => (is => 'rw', isa => 'Num', printOrder => '9', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has reagents => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Reagent)', metaclass => 'Typed', reader => '_reagents', printOrder => '-1');


# LINKS:
has abstractReaction => (is => 'rw', type => 'link(Biochemistry,reactions,abstractReaction_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_abstractReaction', clearer => 'clear_abstractReaction', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Reaction', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/reactions/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_abstractReaction {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->abstractReaction_ref());
}


# CONSTANTS:
sub _type { return 'KBaseBiochem.Reaction'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'Reaction'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'deltaG',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 10,
            'name' => 'status',
            'default' => 'unknown',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'thermoReversibility',
            'default' => '=',
            'type' => 'Str',
            'description' => undef,
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
            'name' => 'cues',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'defaultProtons',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'direction',
            'default' => '=',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'abstractReaction_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => 'Reference to abstract reaction of which this reaction is an example.',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'abbreviation',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'md5',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 9,
            'name' => 'deltaGErr',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {deltaG => 0, status => 1, thermoReversibility => 2, name => 3, cues => 4, defaultProtons => 5, direction => 6, abstractReaction_ref => 7, id => 8, abbreviation => 9, md5 => 10, deltaGErr => 11};
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

my $links = [
          {
            'parent' => 'Biochemistry',
            'name' => 'abstractReaction',
            'attribute' => 'abstractReaction_ref',
            'clearer' => 'clear_abstractReaction',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Reaction',
            'method' => 'reactions',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          }
        ];

my $link_map = {abstractReaction => 0};
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
            'printOrder' => -1,
            'name' => 'reagents',
            'default' => undef,
            'description' => undef,
            'class' => 'Reagent',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          }
        ];

my $subobject_map = {reagents => 0};
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
around 'reagents' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('reagents');
};


__PACKAGE__->meta->make_immutable;
1;
