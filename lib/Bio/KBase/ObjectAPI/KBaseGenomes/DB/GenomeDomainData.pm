########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::DB::GenomeDomainData - This is the moose object corresponding to the KBaseGenomes.GenomeDomainData object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseGenomes::DB::GenomeDomainData;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseGenomes::Domain;
use Bio::KBase::ObjectAPI::KBaseGenomes::FeatureDomainData;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has num_domains => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has genome_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has num_features => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has scientific_name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has genome_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has domains => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Domain)', metaclass => 'Typed', reader => '_domains', printOrder => '-1');
has featuredomains => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FeatureDomainData)', metaclass => 'Typed', reader => '_featuredomains', printOrder => '-1');


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
sub _type { return 'KBaseGenomes.GenomeDomainData'; }
sub _module { return 'KBaseGenomes'; }
sub _class { return 'GenomeDomainData'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'num_domains',
            'type' => 'Int',
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
            'name' => 'num_features',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'scientific_name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'genome_id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {num_domains => 0, genome_ref => 1, num_features => 2, scientific_name => 3, id => 4, genome_id => 5};
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

my $subobjects = [
          {
            'printOrder' => -1,
            'name' => 'domains',
            'type' => 'child',
            'class' => 'Domain',
            'module' => 'KBaseGenomes'
          },
          {
            'printOrder' => -1,
            'name' => 'featuredomains',
            'type' => 'child',
            'class' => 'FeatureDomainData',
            'module' => 'KBaseGenomes'
          }
        ];

my $subobject_map = {domains => 0, featuredomains => 1};
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
around 'domains' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('domains');
};
around 'featuredomains' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('featuredomains');
};


__PACKAGE__->meta->make_immutable;
1;
