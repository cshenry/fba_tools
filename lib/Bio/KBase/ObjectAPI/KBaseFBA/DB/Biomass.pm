########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::Biomass - This is the moose object corresponding to the KBaseFBA.Biomass object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::Biomass;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::BiomassCompound;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
#has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has energy => (is => 'rw', isa => 'Num', printOrder => '9', default => '40', type => 'attribute', metaclass => 'Typed');
has cofactor => (is => 'rw', isa => 'Num', printOrder => '8', default => '0.15', type => 'attribute', metaclass => 'Typed');
has rna => (is => 'rw', isa => 'Num', printOrder => '4', default => '0.1', type => 'attribute', metaclass => 'Typed');
has dna => (is => 'rw', isa => 'Num', printOrder => '3', default => '0.05', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has cellwall => (is => 'rw', isa => 'Num', printOrder => '6', default => '0.15', type => 'attribute', metaclass => 'Typed');
has protein => (is => 'rw', isa => 'Num', printOrder => '5', default => '0.5', type => 'attribute', metaclass => 'Typed');
has other => (is => 'rw', isa => 'Num', printOrder => '2', default => '0', type => 'attribute', metaclass => 'Typed');
has lipid => (is => 'rw', isa => 'Num', printOrder => '7', default => '0.05', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');
has edits => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has deleted_compounds => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');

# SUBOBJECTS:
has biomasscompounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(BiomassCompound)', metaclass => 'Typed', reader => '_biomasscompounds', printOrder => '-1');
has removedcompounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(BiomassCompound)', metaclass => 'Typed', reader => '_removedcompounds', printOrder => '-1');

# LINKS:


# BUILDERS:
sub _reference { my ($self) = @_;return $self->parent()->_reference().'/biomasses/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseFBA.Biomass'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'Biomass'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 9,
            'name' => 'energy',
            'default' => '40',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'cofactor',
            'default' => '0.15',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'rna',
            'default' => '0.1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'dna',
            'default' => '0.05',
            'type' => 'Num',
            'description' => undef,
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
            'printOrder' => 6,
            'name' => 'cellwall',
            'default' => '0.15',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'protein',
            'default' => '0.5',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'other',
            'default' => '0',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'lipid',
            'default' => '0.05',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'id',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
		  {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'edits',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'deleted_compounds',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {energy => 0, cofactor => 1, rna => 2, dna => 3, name => 4, cellwall => 5, protein => 6, other => 7, lipid => 8, id => 9,edits => 10,deleted_compounds => 11};
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
            'req' => undef,
            'printOrder' => -1,
            'name' => 'biomasscompounds',
            'default' => undef,
            'description' => undef,
            'class' => 'BiomassCompound',
            'type' => 'child',
            'module' => 'KBaseFBA'
          },
          {
            'req' => undef,
            'printOrder' => -1,
            'name' => 'removedcompounds',
            'default' => undef,
            'description' => undef,
            'class' => 'BiomassCompound',
            'type' => 'child',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {biomasscompounds => 0,removedcompounds => 1};
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
around 'biomasscompounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('biomasscompounds');
};

around 'removedcompounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('removedcompounds');
};


__PACKAGE__->meta->make_immutable;
1;
