########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::DB::Regulog - This is the moose object corresponding to the KBaseRegulation.Regulog object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseRegulation::DB::Regulog;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseRegulation::Regulator;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has regulon_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has regulog_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has regulator => (is => 'rw', singleton => 1, isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Regulator)', metaclass => 'Typed', reader => '_regulator', printOrder => '-1');


# LINKS:
has regulons => (is => 'rw', type => 'link(,,regulon_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_regulons', clearer => 'clear_regulons', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/regulogs/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_regulons {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->regulon_refs());
}


# CONSTANTS:
sub _type { return 'KBaseRegulation.Regulog'; }
sub _module { return 'KBaseRegulation'; }
sub _class { return 'Regulog'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'regulon_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'regulog_id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {regulon_refs => 0, regulog_id => 1};
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
            'parent' => undef,
            'name' => 'regulons',
            'attribute' => 'regulon_refs',
            'array' => 1,
            'clearer' => 'clear_regulons',
            'class' => undef,
            'method' => undef,
            'module' => undef,
            'field' => undef
          }
        ];

my $link_map = {regulons => 0};
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
            'name' => 'regulator',
            'type' => 'child',
            'class' => 'Regulator',
            'singleton' => 1,
            'module' => 'KBaseRegulation'
          }
        ];

my $subobject_map = {regulator => 0};
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
around 'regulator' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('regulator');
};


__PACKAGE__->meta->make_immutable;
1;
