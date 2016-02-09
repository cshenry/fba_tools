########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::DB::Feature - This is the moose object corresponding to the KBaseGenomes.Feature object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseGenomes::DB::Feature;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseGenomes::ProteinFamily;
use Bio::KBase::ObjectAPI::KBaseGenomes::Analysis_event;
use Bio::KBase::ObjectAPI::KBaseGenomes::Feature_quality_measure;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has function => (is => 'rw', isa => 'Str', printOrder => '2', type => 'attribute', metaclass => 'Typed');
has subsystems => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has atomic_regulons => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has coexpressed_fids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has dna_sequence => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has protein_translation => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has co_occurring_fids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has regulon_data => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has publications => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has location => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has subsystem_data => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has annotations => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has dna_sequence_length => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has orthologs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has protein_translation_length => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has aliases => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '1', default => 'peg', type => 'attribute', metaclass => 'Typed');
has md5 => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has protein_families => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ProteinFamily)', metaclass => 'Typed', reader => '_protein_families', printOrder => '-1');
has feature_creation_event => (is => 'rw', singleton => 1, isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Analysis_event)', metaclass => 'Typed', reader => '_feature_creation_event', printOrder => '-1');
has quality => (is => 'rw', singleton => 1, isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Feature_quality_measure)', metaclass => 'Typed', reader => '_quality', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/features/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseGenomes.Feature'; }
sub _module { return 'KBaseGenomes'; }
sub _class { return 'Feature'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'function',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'subsystems',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'atomic_regulons',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'coexpressed_fids',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'dna_sequence',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'protein_translation',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'co_occurring_fids',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'regulon_data',
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
            'printOrder' => -1,
            'name' => 'location',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'subsystem_data',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'annotations',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'dna_sequence_length',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'orthologs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'protein_translation_length',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'aliases',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'type',
            'default' => 'peg',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'md5',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {function => 0, subsystems => 1, atomic_regulons => 2, coexpressed_fids => 3, dna_sequence => 4, protein_translation => 5, co_occurring_fids => 6, regulon_data => 7, publications => 8, id => 9, location => 10, subsystem_data => 11, annotations => 12, dna_sequence_length => 13, orthologs => 14, protein_translation_length => 15, aliases => 16, type => 17, md5 => 18};
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
            'name' => 'protein_families',
            'type' => 'child',
            'class' => 'ProteinFamily',
            'module' => 'KBaseGenomes'
          },
          {
            'printOrder' => -1,
            'name' => 'feature_creation_event',
            'type' => 'child',
            'class' => 'Analysis_event',
            'singleton' => 1,
            'module' => 'KBaseGenomes'
          },
          {
            'printOrder' => -1,
            'name' => 'quality',
            'type' => 'child',
            'class' => 'Feature_quality_measure',
            'singleton' => 1,
            'module' => 'KBaseGenomes'
          }
        ];

my $subobject_map = {protein_families => 0, feature_creation_event => 1, quality => 2};
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
around 'protein_families' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('protein_families');
};
around 'feature_creation_event' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('feature_creation_event');
};
around 'quality' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('quality');
};


__PACKAGE__->meta->make_immutable;
1;
