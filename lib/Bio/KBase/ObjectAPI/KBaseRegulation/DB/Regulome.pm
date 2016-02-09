########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::DB::Regulome - This is the moose object corresponding to the KBaseRegulation.Regulome object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseRegulation::DB::Regulome;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseRegulation::Regulon;
use Bio::KBase::ObjectAPI::KBaseRegulation::RGenome;
use Bio::KBase::ObjectAPI::KBaseRegulation::Evidence;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has regulome_source => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has regulome_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has regulome_name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has regulons => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Regulon)', metaclass => 'Typed', reader => '_regulons', printOrder => '-1');
has genome => (is => 'rw', singleton => 1, isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(RGenome)', metaclass => 'Typed', reader => '_genome', printOrder => '-1');
has evidesnces => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Evidence)', metaclass => 'Typed', reader => '_evidesnces', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseRegulation.Regulome'; }
sub _module { return 'KBaseRegulation'; }
sub _class { return 'Regulome'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'regulome_source',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'regulome_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'regulome_name',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {regulome_source => 0, regulome_id => 1, regulome_name => 2};
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
            'name' => 'regulons',
            'type' => 'child',
            'class' => 'Regulon',
            'module' => 'KBaseRegulation'
          },
          {
            'printOrder' => -1,
            'name' => 'genome',
            'type' => 'child',
            'class' => 'RGenome',
            'singleton' => 1,
            'module' => 'KBaseRegulation'
          },
          {
            'printOrder' => -1,
            'name' => 'evidesnces',
            'type' => 'child',
            'class' => 'Evidence',
            'module' => 'KBaseRegulation'
          }
        ];

my $subobject_map = {regulons => 0, genome => 1, evidesnces => 2};
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
around 'regulons' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('regulons');
};
around 'genome' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('genome');
};
around 'evidesnces' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('evidesnces');
};


__PACKAGE__->meta->make_immutable;
1;
