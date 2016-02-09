########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::QuantitativeOptimizationSolution - This is the moose object corresponding to the KBaseFBA.QuantitativeOptimizationSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::QuantitativeOptimizationSolution;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::QuantOptBoundMod;
use Bio::KBase::ObjectAPI::KBaseFBA::QuantOptBiomassMod;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has atp_synthase => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has atp_maintenance => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has QuantOptBoundMods => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(QuantOptBoundMod)', metaclass => 'Typed', reader => '_QuantOptBoundMods', printOrder => '-1');
has QuantOptBiomassMods => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(QuantOptBiomassMod)', metaclass => 'Typed', reader => '_QuantOptBiomassMods', printOrder => '-1');


# LINKS:


# BUILDERS:


# CONSTANTS:
sub _type { return 'KBaseFBA.QuantitativeOptimizationSolution'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'QuantitativeOptimizationSolution'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'atp_synthase',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'atp_maintenance',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {atp_synthase => 0, atp_maintenance => 1};
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
            'name' => 'QuantOptBoundMods',
            'type' => 'child',
            'class' => 'QuantOptBoundMod',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'QuantOptBiomassMods',
            'type' => 'child',
            'class' => 'QuantOptBiomassMod',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {QuantOptBoundMods => 0, QuantOptBiomassMods => 1};
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
around 'QuantOptBoundMods' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('QuantOptBoundMods');
};
around 'QuantOptBiomassMods' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('QuantOptBiomassMods');
};


__PACKAGE__->meta->make_immutable;
1;
