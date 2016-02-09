########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateRole - This is the moose object corresponding to the KBaseFBA.TemplateRole object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateRole;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has aliases => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has source => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has features => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/roles/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateRole'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateRole'; }
sub _top { return 0; }

my $attributes = [
          {
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'name' => 'aliases',
            'printOrder' => -1,
            'perm' => 'rw',
            'req' => 0
          },
          {
            'req' => 1,
            'perm' => 'rw',
            'printOrder' => 0,
            'name' => 'id',
            'type' => 'Str'
          },
          {
            'req' => 0,
            'type' => 'Str',
            'printOrder' => -1,
            'name' => 'name',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'type' => 'Str',
            'perm' => 'rw',
            'name' => 'source',
            'printOrder' => -1
          },
          {
            'perm' => 'rw',
            'name' => 'features',
            'printOrder' => -1,
            'type' => 'ArrayRef',
            'default' => 'sub {return [];}',
            'req' => 0
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'type',
            'perm' => 'rw',
            'type' => 'Str'
          }
        ];

my $attribute_map = {aliases => 0, id => 1, name => 2, source => 3, features => 4, type => 5};
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

my $subobjects = [];

my $subobject_map = {};
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
__PACKAGE__->meta->make_immutable;
1;
