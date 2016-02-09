########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::DB::ComplexRole - This is the moose object corresponding to the KBaseOntology.ComplexRole object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseOntology::DB::ComplexRole;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has triggering => (is => 'rw', isa => 'Int', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has role_ref => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has optionalRole => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '0', default => 'G', type => 'attribute', metaclass => 'Typed');


# LINKS:
has role => (is => 'rw', type => 'link(Mapping,roles,role_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_role', clearer => 'clear_role', isa => 'Bio::KBase::ObjectAPI::KBaseOntology::Role', weak_ref => 1);


# BUILDERS:
sub _build_role {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->role_ref());
}


# CONSTANTS:
sub _type { return 'KBaseOntology.ComplexRole'; }
sub _module { return 'KBaseOntology'; }
sub _class { return 'ComplexRole'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'triggering',
            'default' => '1',
            'type' => 'Int',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'role_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'optionalRole',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'type',
            'default' => 'G',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {triggering => 0, role_ref => 1, optionalRole => 2, type => 3};
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
            'parent' => 'Mapping',
            'name' => 'role',
            'attribute' => 'role_ref',
            'clearer' => 'clear_role',
            'class' => 'Bio::KBase::ObjectAPI::KBaseOntology::Role',
            'method' => 'roles',
            'module' => 'KBaseOntology',
            'field' => 'id'
          }
        ];

my $link_map = {role => 0};
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
