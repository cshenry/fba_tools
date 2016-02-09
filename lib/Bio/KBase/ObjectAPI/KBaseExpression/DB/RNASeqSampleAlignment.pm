########################################################################
# Bio::KBase::ObjectAPI::KBaseExpression::DB::RNASeqSampleAlignment - This is the moose object corresponding to the KBaseExpression.RNASeqSampleAlignment object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseExpression::DB::RNASeqSampleAlignment;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseExpression::RNASeqSampleMetaData;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has shock_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has created => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has paired => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has metadata => (is => 'rw', singleton => 1, isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(RNASeqSampleMetaData)', metaclass => 'Typed', reader => '_metadata', printOrder => '-1');


# LINKS:
has shock => (is => 'rw', type => 'link(,,shock_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_shock', clearer => 'clear_shock', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_shock {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->shock_ref());
}


# CONSTANTS:
sub _type { return 'KBaseExpression.RNASeqSampleAlignment'; }
sub _module { return 'KBaseExpression'; }
sub _class { return 'RNASeqSampleAlignment'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'shock_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'created',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'paired',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'name',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {shock_ref => 0, created => 1, paired => 2, name => 3};
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
            'name' => 'shock',
            'attribute' => 'shock_ref',
            'clearer' => 'clear_shock',
            'class' => undef,
            'method' => undef,
            'module' => undef,
            'field' => undef
          }
        ];

my $link_map = {shock => 0};
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
            'name' => 'metadata',
            'type' => 'child',
            'class' => 'RNASeqSampleMetaData',
            'singleton' => 1,
            'module' => 'KBaseExpression'
          }
        ];

my $subobject_map = {metadata => 0};
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
around 'metadata' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('metadata');
};


__PACKAGE__->meta->make_immutable;
1;
