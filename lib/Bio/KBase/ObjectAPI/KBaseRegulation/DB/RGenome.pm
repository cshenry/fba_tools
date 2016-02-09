########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::DB::RGenome - This is the moose object corresponding to the KBaseRegulation.RGenome object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseRegulation::DB::RGenome;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has genome_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has genome_name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has genome_id => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has ncbi_taxonomy_id => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has genome => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Genome,genome_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_genome', clearer => 'clear_genome', isa => 'Bio::KBase::ObjectAPI::KBaseGenomes::Genome', weak_ref => 1);


# BUILDERS:
sub _build_genome {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->genome_ref());
}


# CONSTANTS:
sub _type { return 'KBaseRegulation.RGenome'; }
sub _module { return 'KBaseRegulation'; }
sub _class { return 'RGenome'; }
sub _top { return 0; }

my $attributes = [
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
            'name' => 'genome_name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'genome_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'ncbi_taxonomy_id',
            'type' => 'Int',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {genome_ref => 0, genome_name => 1, genome_id => 2, ncbi_taxonomy_id => 3};
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
