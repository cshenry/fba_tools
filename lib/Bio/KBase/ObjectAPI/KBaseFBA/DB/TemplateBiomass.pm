########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateBiomass - This is the moose object corresponding to the KBaseFBA.TemplateBiomass object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateBiomass;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomassComponent;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has dna => (is => 'rw', isa => 'Num', printOrder => '2', default => '0', type => 'attribute', metaclass => 'Typed');
has cofactor => (is => 'rw', isa => 'Num', printOrder => '7', default => '0', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '1', default => 'defaultGrowth', type => 'attribute', metaclass => 'Typed');
has other => (is => 'rw', isa => 'Num', printOrder => '2', default => '0', type => 'attribute', metaclass => 'Typed');
has energy => (is => 'rw', isa => 'Num', printOrder => '8', default => '0', type => 'attribute', metaclass => 'Typed');
has cellwall => (is => 'rw', isa => 'Num', printOrder => '6', default => '0', type => 'attribute', metaclass => 'Typed');
has rna => (is => 'rw', isa => 'Num', printOrder => '3', default => '0', type => 'attribute', metaclass => 'Typed');
has lipid => (is => 'rw', isa => 'Num', printOrder => '5', default => '0', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has protein => (is => 'rw', isa => 'Num', printOrder => '4', default => '0', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has templateBiomassComponents => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateBiomassComponent)', metaclass => 'Typed', reader => '_templateBiomassComponents', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/biomasses/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateBiomass'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateBiomass'; }
sub _top { return 0; }

my $attributes = [
          {
            'type' => 'Num',
            'default' => '0',
            'name' => 'dna',
            'printOrder' => 2,
            'description' => undef,
            'perm' => 'rw',
            'req' => 0
          },
          {
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw',
            'description' => undef,
            'name' => 'cofactor',
            'printOrder' => 7,
            'req' => 0
          },
          {
            'printOrder' => 1,
            'name' => 'type',
            'perm' => 'rw',
            'description' => undef,
            'default' => 'defaultGrowth',
            'type' => 'Str',
            'req' => 0
          },
          {
            'req' => 0,
            'type' => 'Num',
            'default' => '0',
            'description' => undef,
            'perm' => 'rw',
            'printOrder' => 2,
            'name' => 'other'
          },
          {
            'description' => undef,
            'perm' => 'rw',
            'printOrder' => 8,
            'name' => 'energy',
            'type' => 'Num',
            'default' => '0',
            'req' => 0
          },
          {
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw',
            'description' => undef,
            'printOrder' => 6,
            'name' => 'cellwall',
            'req' => 0
          },
          {
            'description' => undef,
            'perm' => 'rw',
            'printOrder' => 3,
            'name' => 'rna',
            'default' => '0',
            'type' => 'Num',
            'req' => 0
          },
          {
            'req' => 0,
            'perm' => 'rw',
            'description' => undef,
            'printOrder' => 5,
            'name' => 'lipid',
            'default' => '0',
            'type' => 'Num'
          },
          {
            'description' => undef,
            'perm' => 'rw',
            'name' => 'name',
            'printOrder' => 1,
            'default' => undef,
            'type' => 'Str',
            'req' => 1
          },
          {
            'type' => 'Str',
            'perm' => 'rw',
            'printOrder' => 0,
            'name' => 'id',
            'req' => 1
          },
          {
            'default' => '0',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw',
            'name' => 'protein',
            'printOrder' => 4,
            'req' => 0
          }
        ];

my $attribute_map = {dna => 0, cofactor => 1, type => 2, other => 3, energy => 4, cellwall => 5, rna => 6, lipid => 7, name => 8, id => 9, protein => 10};
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
            'default' => undef,
            'description' => undef,
            'name' => 'templateBiomassComponents',
            'req' => undef,
            'module' => 'KBaseFBA',
            'class' => 'TemplateBiomassComponent',
            'type' => 'child',
            'printOrder' => -1
          }
        ];

my $subobject_map = {templateBiomassComponents => 0};
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
around 'templateBiomassComponents' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('templateBiomassComponents');
};


__PACKAGE__->meta->make_immutable;
1;
