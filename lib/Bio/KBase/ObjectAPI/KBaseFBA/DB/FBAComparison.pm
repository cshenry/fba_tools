########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAComparison - This is the moose object corresponding to the KBaseFBA.FBAComparison object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAComparison;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAComparisonCompound;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAComparisonReaction;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAComparisonFBA;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';

our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has common_reactions => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has common_compounds => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has compounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAComparisonCompound)', metaclass => 'Typed', reader => '_compounds', printOrder => '-1');
has reactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAComparisonReaction)', metaclass => 'Typed', reader => '_reactions', printOrder => '-1');
has fbas => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAComparisonFBA)', metaclass => 'Typed', reader => '_fbas', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseFBA.FBAComparison'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'FBAComparison'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'common_reactions',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'common_compounds',
            'type' => 'Int',
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

my $attribute_map = {common_reactions => 0, common_compounds => 1, id => 2};
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
            'name' => 'compounds',
            'type' => 'child',
            'class' => 'FBAComparisonCompound',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'reactions',
            'type' => 'child',
            'class' => 'FBAComparisonReaction',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'fbas',
            'type' => 'child',
            'class' => 'FBAComparisonFBA',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {compounds => 0, reactions => 1, fbas => 2};
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
around 'compounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('compounds');
};
around 'reactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('reactions');
};
around 'fbas' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('fbas');
};


__PACKAGE__->meta->make_immutable;
1;
