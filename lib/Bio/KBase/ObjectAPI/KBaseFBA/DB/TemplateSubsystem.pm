########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateSubsystem - This is the moose object corresponding to the KBaseFBA.TemplateSubsystem object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateSubsystem;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has class => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has role_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has subclass => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has roles => (is => 'rw', type => 'link(,,role_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_roles', clearer => 'clear_roles', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/subsystems/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_roles {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->role_refs());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateSubsystem'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateSubsystem'; }
sub _top { return 0; }

my $attributes = [
          {
            'printOrder' => -1,
            'name' => 'class',
            'perm' => 'rw',
            'type' => 'Str',
            'req' => 0
          },
          {
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'role_refs',
            'req' => 0
          },
          {
            'name' => 'name',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Str',
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
            'printOrder' => -1,
            'name' => 'subclass',
            'perm' => 'rw',
            'type' => 'Str'
          },
          {
            'req' => 0,
            'type' => 'Str',
            'printOrder' => -1,
            'name' => 'type',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {class => 0, role_refs => 1, name => 2, id => 3, subclass => 4, type => 5};
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
            'name' => 'roles',
            'parent' => undef,
            'module' => undef,
            'attribute' => 'role_refs',
            'class' => undef,
            'clearer' => 'clear_roles',
            'field' => undef,
            'method' => undef,
            'array' => 1
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
