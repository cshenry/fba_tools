########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::DB::Genome - This is the moose object corresponding to the KBaseGenomes.Genome object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseGenomes::DB::Genome;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseGenomes::Close_genome;
use Bio::KBase::ObjectAPI::KBaseGenomes::Genome_quality_measure;
use Bio::KBase::ObjectAPI::KBaseGenomes::Feature;
use Bio::KBase::ObjectAPI::KBaseGenomes::Contig;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has source => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has contigset_ref => (is => 'rw', isa => 'Str', printOrder => '11', type => 'attribute', metaclass => 'Typed');
has dna_size => (is => 'rw', isa => 'Int', printOrder => '6', type => 'attribute', metaclass => 'Typed');
has domain => (is => 'rw', isa => 'Str', printOrder => '4', type => 'attribute', metaclass => 'Typed');
has contig_lengths => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has contig_ids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has publications => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has num_contigs => (is => 'rw', isa => 'Int', printOrder => '7', type => 'attribute', metaclass => 'Typed');
has source_id => (is => 'rw', isa => 'Str', printOrder => '2', type => 'attribute', metaclass => 'Typed');
has gc_content => (is => 'rw', isa => 'Num', printOrder => '9', type => 'attribute', metaclass => 'Typed');
has taxonomy => (is => 'rw', isa => 'Str', printOrder => '8', default => '', type => 'attribute', metaclass => 'Typed');
has scientific_name => (is => 'rw', isa => 'Str', printOrder => '3', type => 'attribute', metaclass => 'Typed');
has genetic_code => (is => 'rw', isa => 'Int', printOrder => '5', type => 'attribute', metaclass => 'Typed');
has md5 => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has complete => (is => 'rw', isa => 'Int', printOrder => '10', type => 'attribute', metaclass => 'Typed');
has quality => (is => 'rw', isa => 'HashRef', default => sub { return {}; }, type => 'attribute', metaclass => 'Typed', printOrder => '-1');

# SUBOBJECTS:
has close_genomes => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Close_genome)', metaclass => 'Typed', reader => '_close_genomes', printOrder => '-1');
has features => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Feature)', metaclass => 'Typed', reader => '_features', printOrder => '0');
has contigs => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Contig)', metaclass => 'Typed', reader => '_contigs', printOrder => '-1');


# LINKS:
has contigset => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,ContigSet,contigset_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_contigset', clearer => 'clear_contigset', isa => 'Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_contigset {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->contigset_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseGenomes.Genome'; }
sub _module { return 'KBaseGenomes'; }
sub _class { return 'Genome'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'source',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 11,
            'name' => 'contigset_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'dna_size',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'domain',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'contig_lengths',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'contig_ids',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'publications',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'id',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'num_contigs',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'source_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 9,
            'name' => 'gc_content',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'taxonomy',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'scientific_name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'genetic_code',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'md5',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 10,
            'name' => 'complete',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'quality',
            'type' => 'HashRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {source => 0, contigset_ref => 1, dna_size => 2, domain => 3, contig_lengths => 4, contig_ids => 5, publications => 6, id => 7, num_contigs => 8, source_id => 9, gc_content => 10, taxonomy => 11, scientific_name => 12, genetic_code => 13, md5 => 14, complete => 15, quality => 16};
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
            'attribute' => 'contigset_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_contigset',
            'name' => 'contigset',
            'method' => 'ContigSet',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet',
            'module' => 'KBaseGenomes'
          }
        ];

my $link_map = {contigset => 0};
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
            'name' => 'close_genomes',
            'type' => 'child',
            'class' => 'Close_genome',
            'module' => 'KBaseGenomes'
          },
          {
            'printOrder' => 0,
            'name' => 'features',
            'type' => 'child',
            'class' => 'Feature',
            'module' => 'KBaseGenomes'
          },
          {
            'printOrder' => -1,
            'name' => 'contigs',
            'type' => 'child',
            'class' => 'Contig',
            'module' => 'KBaseGenomes'
          }
        ];

my $subobject_map = {close_genomes => 0, features => 1, contigs => 2};
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
around 'close_genomes' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('close_genomes');
};
around 'features' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('features');
};
around 'contigs' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('contigs');
};


__PACKAGE__->meta->make_immutable;
1;
