########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompartment - This is the moose object corresponding to the KBaseFBA.TemplateCompartment object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompartment;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has hierarchy => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has pH => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has aliases => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/compartments/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateCompartment'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateCompartment'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'perm' => 'rw',
            'name' => 'hierarchy',
            'printOrder' => -1,
            'type' => 'Int'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'pH',
            'perm' => 'rw',
            'type' => 'Num'
          },
          {
            'req' => 0,
            'type' => 'ArrayRef',
            'default' => 'sub {return [];}',
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'aliases'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'id',
            'perm' => 'rw',
            'type' => 'Str'
          },
          {
            'name' => 'name',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Str',
            'req' => 0
          }
        ];

my $attribute_map = {hierarchy => 0, pH => 1, aliases => 2, id => 3, name => 4};
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
