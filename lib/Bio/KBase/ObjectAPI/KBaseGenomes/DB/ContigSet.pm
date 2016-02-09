########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::DB::ContigSet - This is the moose object corresponding to the KBaseGenomes.ContigSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseGenomes::DB::ContigSet;
use Bio::KBase::ObjectAPI::IndexedObject;
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
has source => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has source_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has fasta_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has reads_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has md5 => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has contigs => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Contig)', metaclass => 'Typed', reader => '_contigs', printOrder => '-1');


# LINKS:
has fasta => (is => 'rw', type => 'link(,,fasta_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fasta', clearer => 'clear_fasta', isa => 'Ref', weak_ref => 1);
has reads => (is => 'rw', type => 'link(,,reads_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_reads', clearer => 'clear_reads', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_fasta {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fasta_ref());
}
sub _build_reads {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->reads_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseGenomes.ContigSet'; }
sub _module { return 'KBaseGenomes'; }
sub _class { return 'ContigSet'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'source',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'source_id',
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
            'name' => 'fasta_ref',
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
            'name' => 'type',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reads_ref',
            'type' => 'Str',
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

my $attribute_map = {source => 0, source_id => 1, name => 2, fasta_ref => 3, id => 4, type => 5, reads_ref => 6, md5 => 7};
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
            'parent' => undef,
            'name' => 'fasta',
            'attribute' => 'fasta_ref',
            'clearer' => 'clear_fasta',
            'class' => undef,
            'method' => undef,
            'module' => undef,
            'field' => undef
          },
          {
            'parent' => undef,
            'name' => 'reads',
            'attribute' => 'reads_ref',
            'clearer' => 'clear_reads',
            'class' => undef,
            'method' => undef,
            'module' => undef,
            'field' => undef
          }
        ];

my $link_map = {fasta => 0, reads => 1};
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
            'name' => 'contigs',
            'type' => 'child',
            'class' => 'Contig',
            'module' => 'KBaseGenomes'
          }
        ];

my $subobject_map = {contigs => 0};
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
around 'contigs' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('contigs');
};


__PACKAGE__->meta->make_immutable;
1;
