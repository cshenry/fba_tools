########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelCompartment - This is the moose object corresponding to the KBaseFBA.ModelCompartment object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelCompartment;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has pH => (is => 'rw', isa => 'Num', printOrder => '3', default => '7', type => 'attribute', metaclass => 'Typed');
has compartmentIndex => (is => 'rw', isa => 'Int', printOrder => '2', required => 1, type => 'attribute', metaclass => 'Typed');
has potential => (is => 'rw', isa => 'Num', printOrder => '4', default => '0', type => 'attribute', metaclass => 'Typed');
has compartment_ref => (is => 'rw', isa => 'Str', printOrder => '5', required => 1, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has label => (is => 'rw', isa => 'Str', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');


# LINKS:
has compartment => (is => 'rw', type => 'link(Biochemistry,compartments,compartment_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_compartment', clearer => 'clear_compartment', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compartment', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/modelcompartments/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_compartment {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->compartment_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.ModelCompartment'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'ModelCompartment'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'pH',
            'default' => '7',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 2,
            'name' => 'compartmentIndex',
            'default' => undef,
            'type' => 'Int',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'potential',
            'default' => '0',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 5,
            'name' => 'compartment_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
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
            'printOrder' => 1,
            'name' => 'label',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {pH => 0, compartmentIndex => 1, potential => 2, compartment_ref => 3, id => 4, label => 5};
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
            'name' => 'compartment',
            'attribute' => 'compartment_ref',
            'clearer' => 'clear_compartment',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compartment',
            'method' => 'compartments',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          }
        ];

my $link_map = {compartment => 0};
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
