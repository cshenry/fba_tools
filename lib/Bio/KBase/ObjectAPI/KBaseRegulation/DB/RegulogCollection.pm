########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::DB::RegulogCollection - This is the moose object corresponding to the KBaseRegulation.RegulogCollection object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseRegulation::DB::RegulogCollection;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseRegulation::RGenome;
use Bio::KBase::ObjectAPI::KBaseRegulation::Regulog;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has regulog_collection_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has description => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has genomes => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(RGenome)', metaclass => 'Typed', reader => '_genomes', printOrder => '-1');
has regulogs => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Regulog)', metaclass => 'Typed', reader => '_regulogs', printOrder => '-1');


# LINKS:


# BUILDERS:


# CONSTANTS:
sub _type { return 'KBaseRegulation.RegulogCollection'; }
sub _module { return 'KBaseRegulation'; }
sub _class { return 'RegulogCollection'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'regulog_collection_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'name',
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

my $attribute_map = {regulog_collection_id => 0, name => 1, description => 2};
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
            'printOrder' => -1,
            'name' => 'genomes',
            'type' => 'child',
            'class' => 'RGenome',
            'module' => 'KBaseRegulation'
          },
          {
            'printOrder' => -1,
            'name' => 'regulogs',
            'type' => 'child',
            'class' => 'Regulog',
            'module' => 'KBaseRegulation'
          }
        ];

my $subobject_map = {genomes => 0, regulogs => 1};
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
around 'genomes' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('genomes');
};
around 'regulogs' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('regulogs');
};


__PACKAGE__->meta->make_immutable;
1;
