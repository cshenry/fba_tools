########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::DB::Mapping - This is the moose object corresponding to the KBaseOntology.Mapping object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseOntology::DB::Mapping;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseOntology::Role;
use Bio::KBase::ObjectAPI::KBaseOntology::Subsystem;
use Bio::KBase::ObjectAPI::KBaseOntology::Complex;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has subsystem_aliases => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has complex_aliases => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has role_aliases => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has roles => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Role)', metaclass => 'Typed', reader => '_roles', printOrder => '2');
has subsystems => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Subsystem)', metaclass => 'Typed', reader => '_subsystems', printOrder => '-1');
has complexes => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Complex)', metaclass => 'Typed', reader => '_complexes', printOrder => '4');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseOntology.Mapping'; }
sub _module { return 'KBaseOntology'; }
sub _class { return 'Mapping'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'subsystem_aliases',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
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
            'name' => 'complex_aliases',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'role_aliases',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
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

my $attribute_map = {subsystem_aliases => 0, name => 1, complex_aliases => 2, role_aliases => 3, id => 4};
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
            'req' => undef,
            'printOrder' => 2,
            'name' => 'roles',
            'default' => undef,
            'description' => undef,
            'class' => 'Role',
            'type' => 'child',
            'module' => 'KBaseOntology'
          },
          {
            'printOrder' => -1,
            'name' => 'subsystems',
            'type' => 'child',
            'class' => 'Subsystem',
            'module' => 'KBaseOntology'
          },
          {
            'req' => undef,
            'printOrder' => 4,
            'name' => 'complexes',
            'default' => undef,
            'description' => undef,
            'class' => 'Complex',
            'type' => 'child',
            'module' => 'KBaseOntology'
          }
        ];

my $subobject_map = {roles => 0, subsystems => 1, complexes => 2};
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
around 'roles' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('roles');
};
around 'subsystems' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('subsystems');
};
around 'complexes' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('complexes');
};


__PACKAGE__->meta->make_immutable;
1;
