########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::DB::Pangenome - This is the moose object corresponding to the KBaseGenomes.Pangenome object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseGenomes::DB::Pangenome;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseGenomes::OrthologFamily;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has genome_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has orthologs => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(OrthologFamily)', metaclass => 'Typed', reader => '_orthologs', printOrder => '-1');


# LINKS:
has genomes => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::Util::KBaseStore,Genome,genome_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_genomes', clearer => 'clear_genomes', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_genomes {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->genome_refs());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseGenomes.Pangenome'; }
sub _module { return 'KBaseGenomes'; }
sub _class { return 'Pangenome'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'genome_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
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
            'name' => 'type',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {genome_refs => 0, name => 1, type => 2, id => 3};
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
            'parent' => 'Bio::KBase::ObjectAPI::Util::KBaseStore',
            'name' => 'genomes',
            'attribute' => 'genome_refs',
            'array' => 1,
            'clearer' => 'clear_genomes',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::Genome',
            'method' => 'Genome',
            'module' => 'KBaseGenomes'
          }
        ];

my $link_map = {genomes => 0};
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
            'name' => 'orthologs',
            'type' => 'child',
            'class' => 'OrthologFamily',
            'module' => 'KBaseGenomes'
          }
        ];

my $subobject_map = {orthologs => 0};
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
around 'orthologs' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('orthologs');
};


__PACKAGE__->meta->make_immutable;
1;
