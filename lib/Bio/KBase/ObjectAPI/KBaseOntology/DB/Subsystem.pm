########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::DB::Subsystem - This is the moose object corresponding to the KBaseOntology.Subsystem object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseOntology::DB::Subsystem;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has name => (is => 'rw', isa => 'Str', printOrder => '3', default => '', type => 'attribute', metaclass => 'Typed');
has role_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has subclass => (is => 'rw', isa => 'Str', printOrder => '2', default => 'unclassified', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'Str', printOrder => '1', default => 'unclassified', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '4', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has roles => (is => 'rw', type => 'link(Mapping,roles,role_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_roles', clearer => 'clear_roles', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/subsystems/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_roles {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->role_refs());
}


# CONSTANTS:
sub _type { return 'KBaseOntology.Subsystem'; }
sub _module { return 'KBaseOntology'; }
sub _class { return 'Subsystem'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'name',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'role_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'subclass',
            'default' => 'unclassified',
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
            'name' => 'class',
            'default' => 'unclassified',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 4,
            'name' => 'type',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {name => 0, role_refs => 1, subclass => 2, id => 3, class => 4, type => 5};
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
            'name' => 'roles',
            'attribute' => 'role_refs',
            'array' => 1,
            'clearer' => 'clear_roles',
            'class' => 'Bio::KBase::ObjectAPI::KBaseOntology::Role',
            'method' => 'roles',
            'module' => 'KBaseOntology',
            'field' => 'id'
          }
        ];

my $link_map = {roles => 0};
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
