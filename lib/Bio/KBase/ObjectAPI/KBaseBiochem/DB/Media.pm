########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::Media - This is the moose object corresponding to the KBaseBiochem.Media object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::Media;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseBiochem::MediaReagent;
use Bio::KBase::ObjectAPI::KBaseBiochem::MediaCompound;
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
has protocol_link => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has pH_data => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has atmosphere => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has atmosphere_addition => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has temperature => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has isAerobic => (is => 'rw', isa => 'Bool', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has source_id => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has isMinimal => (is => 'rw', isa => 'Bool', printOrder => '5', default => '0', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '6', default => 'unknown', type => 'attribute', metaclass => 'Typed');
has isDefined => (is => 'rw', isa => 'Bool', printOrder => '4', default => '0', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has reagents => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(MediaReagent)', metaclass => 'Typed', reader => '_reagents', printOrder => '-1');
has mediacompounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(MediaCompound)', metaclass => 'Typed', reader => '_mediacompounds', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseBiochem.Media'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'Media'; }
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
            'req' => 0,
            'printOrder' => -1,
            'name' => 'protocol_link',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'pH_data',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'atmosphere',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'id',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'atmosphere_addition',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'temperature',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'isAerobic',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'source_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'isMinimal',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'name',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'type',
            'default' => 'unknown',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'isDefined',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {source => 0, protocol_link => 1, pH_data => 2, atmosphere => 3, id => 4, atmosphere_addition => 5, temperature => 6, isAerobic => 7, source_id => 8, isMinimal => 9, name => 10, type => 11, isDefined => 12};
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
            'name' => 'reagents',
            'type' => 'child',
            'class' => 'MediaReagent',
            'module' => 'KBaseBiochem'
          },
          {
            'req' => undef,
            'printOrder' => -1,
            'name' => 'mediacompounds',
            'default' => undef,
            'description' => undef,
            'class' => 'MediaCompound',
            'type' => 'child',
            'module' => 'KBaseBiochem'
          }
        ];

my $subobject_map = {reagents => 0, mediacompounds => 1};
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
around 'reagents' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('reagents');
};
around 'mediacompounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('mediacompounds');
};


__PACKAGE__->meta->make_immutable;
1;
