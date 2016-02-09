########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::BiochemistryStructures - This is the moose object corresponding to the KBaseBiochem.BiochemistryStructures object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::BiochemistryStructures;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseBiochem::CompoundStructure;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has description => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has structures => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(CompoundStructure)', metaclass => 'Typed', reader => '_structures', printOrder => '0');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseBiochem.BiochemistryStructures'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'BiochemistryStructures'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'name',
            'type' => 'Str',
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
            'printOrder' => -1,
            'name' => 'description',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {name => 0, id => 1, description => 2};
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
            'printOrder' => 0,
            'name' => 'structures',
            'default' => undef,
            'description' => undef,
            'class' => 'CompoundStructure',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          }
        ];

my $subobject_map = {structures => 0};
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
around 'structures' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('structures');
};


__PACKAGE__->meta->make_immutable;
1;
