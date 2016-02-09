########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::DB::ProbabilisticAnnotation - This is the moose object corresponding to the KBaseGenomes.ProbabilisticAnnotation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseGenomes::DB::ProbabilisticAnnotation;
use Bio::KBase::ObjectAPI::IndexedObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has skipped_features => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has genome_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has roleset_probabilities => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has genome => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Genome,genome_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_genome', clearer => 'clear_genome', isa => 'Bio::KBase::ObjectAPI::KBaseGenomes::Genome', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_genome {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->genome_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseGenomes.ProbabilisticAnnotation'; }
sub _module { return 'KBaseGenomes'; }
sub _class { return 'ProbabilisticAnnotation'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'skipped_features',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'genome_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'roleset_probabilities',
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

my $attribute_map = {skipped_features => 0, genome_ref => 1, roleset_probabilities => 2, id => 3};
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
            'attribute' => 'genome_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_genome',
            'name' => 'genome',
            'method' => 'Genome',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::Genome',
            'module' => 'KBaseGenomes'
          }
        ];

my $link_map = {genome => 0};
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
