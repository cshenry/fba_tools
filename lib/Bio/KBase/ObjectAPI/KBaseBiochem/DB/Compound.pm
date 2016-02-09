########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::Compound - This is the moose object corresponding to the KBaseBiochem.Compound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::Compound;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has defaultCharge => (is => 'rw', isa => 'Num', printOrder => '5', default => '0', type => 'attribute', metaclass => 'Typed');
has isCofactor => (is => 'rw', isa => 'Bool', printOrder => '3', default => '0', type => 'attribute', metaclass => 'Typed');
has deltaG => (is => 'rw', isa => 'Num', printOrder => '6', type => 'attribute', metaclass => 'Typed');
has pkbs => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has formula => (is => 'rw', isa => 'Str', printOrder => '3', default => '', type => 'attribute', metaclass => 'Typed');
has mass => (is => 'rw', isa => 'Num', printOrder => '4', type => 'attribute', metaclass => 'Typed');
has pkas => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has unchargedFormula => (is => 'rw', isa => 'Str', printOrder => '-1', default => '', type => 'attribute', metaclass => 'Typed');
has deltaGErr => (is => 'rw', isa => 'Num', printOrder => '7', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has cues => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has structure_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has abbreviation => (is => 'rw', isa => 'Str', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');
has md5 => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has abstractCompound_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has comprisedOfCompound_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has structure => (is => 'rw', type => 'link(BiochemistryStructures,structures,structure_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_structure', clearer => 'clear_structure', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::CompoundStructure', weak_ref => 1);
has abstractCompound => (is => 'rw', type => 'link(Biochemistry,compounds,abstractCompound_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_abstractCompound', clearer => 'clear_abstractCompound', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound', weak_ref => 1);
has comprisedOfCompounds => (is => 'rw', type => 'link(Biochemistry,compounds,comprisedOfCompound_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_comprisedOfCompounds', clearer => 'clear_comprisedOfCompounds', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/compounds/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_structure {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->structure_ref());
}
sub _build_abstractCompound {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->abstractCompound_ref());
}
sub _build_comprisedOfCompounds {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->comprisedOfCompound_refs());
}


# CONSTANTS:
sub _type { return 'KBaseBiochem.Compound'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'Compound'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'defaultCharge',
            'default' => 0,
            'type' => 'Num',
            'description' => 'Computed charge for compound at pH 7.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'isCofactor',
            'default' => '0',
            'type' => 'Bool',
            'description' => 'A boolean indicating if this compound is a universal cofactor (e.g. water/H+).',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'deltaG',
            'default' => undef,
            'type' => 'Num',
            'description' => 'Computed Gibbs free energy value for compound at pH 7.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'pkbs',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => 'Hash of pKb values with atom numbers as values',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'formula',
            'default' => '',
            'type' => 'Str',
            'description' => 'Formula for the compound at pH 7.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'mass',
            'default' => undef,
            'type' => 'Num',
            'description' => 'Atomic mass of the compound',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'pkas',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => 'Hash of pKa values with atom numbers as values',
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
            'name' => 'unchargedFormula',
            'default' => '',
            'type' => 'Str',
            'description' => 'Formula for compound if it does not have a ionic charge.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'deltaGErr',
            'default' => undef,
            'type' => 'Num',
            'description' => 'Error bound on Gibbs free energy compoutation for compound.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'name',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'cues',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => 'Hash of cue uuids with cue coefficients as values',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'structure_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'abbreviation',
            'default' => '',
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
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'abstractCompound_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => 'Reference to abstract compound of which this compound is a specific class.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'comprisedOfCompound_refs',
            'default' => undef,
            'type' => 'ArrayRef',
            'description' => 'Array of references to subcompounds that this compound is comprised of.',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {defaultCharge => 0, isCofactor => 1, deltaG => 2, pkbs => 3, formula => 4, mass => 5, pkas => 6, id => 7, unchargedFormula => 8, deltaGErr => 9, name => 10, cues => 11, structure_ref => 12, abbreviation => 13, md5 => 14, abstractCompound_ref => 15, comprisedOfCompound_refs => 16};
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
            'parent' => 'BiochemistryStructures',
            'name' => 'structure',
            'attribute' => 'structure_ref',
            'clearer' => 'clear_structure',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::CompoundStructure',
            'method' => 'structures',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          },
          {
            'parent' => 'Biochemistry',
            'name' => 'abstractCompound',
            'attribute' => 'abstractCompound_ref',
            'clearer' => 'clear_abstractCompound',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound',
            'method' => 'compounds',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          },
          {
            'parent' => 'Biochemistry',
            'name' => 'comprisedOfCompounds',
            'attribute' => 'comprisedOfCompound_refs',
            'array' => 1,
            'clearer' => 'clear_comprisedOfCompounds',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound',
            'method' => 'compounds',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          }
        ];

my $link_map = {structure => 0, abstractCompound => 1, comprisedOfCompounds => 2};
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

my $subobjects = [];

my $subobject_map = {};
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
__PACKAGE__->meta->make_immutable;
1;
