########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::DB::RegulatedOperon - This is the moose object corresponding to the KBaseRegulation.RegulatedOperon object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseRegulation::DB::RegulatedOperon;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseRegulation::RegulatorySite;
use Bio::KBase::ObjectAPI::KBaseRegulation::Gene;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has operon_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has sites => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(RegulatorySite)', metaclass => 'Typed', reader => '_sites', printOrder => '-1');
has genes => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Gene)', metaclass => 'Typed', reader => '_genes', printOrder => '-1');


# LINKS:


# BUILDERS:


# CONSTANTS:
sub _type { return 'KBaseRegulation.RegulatedOperon'; }
sub _module { return 'KBaseRegulation'; }
sub _class { return 'RegulatedOperon'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'operon_id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {operon_id => 0};
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
            'name' => 'sites',
            'type' => 'child',
            'class' => 'RegulatorySite',
            'module' => 'KBaseRegulation'
          },
          {
            'printOrder' => -1,
            'name' => 'genes',
            'type' => 'child',
            'class' => 'Gene',
            'module' => 'KBaseRegulation'
          }
        ];

my $subobject_map = {sites => 0, genes => 1};
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
around 'sites' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('sites');
};
around 'genes' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('genes');
};


__PACKAGE__->meta->make_immutable;
1;
