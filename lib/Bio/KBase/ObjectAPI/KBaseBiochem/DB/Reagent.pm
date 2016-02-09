########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::Reagent - This is the moose object corresponding to the KBaseBiochem.Reagent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::Reagent;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has isCofactor => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has compound_ref => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has compartment_ref => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has coefficient => (is => 'rw', isa => 'Num', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has compound => (is => 'rw', type => 'link(Biochemistry,compounds,compound_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound', weak_ref => 1);
has compartment => (is => 'rw', type => 'link(Biochemistry,compartments,compartment_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_compartment', clearer => 'clear_compartment', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compartment', weak_ref => 1);


# BUILDERS:
sub _build_compound {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->compound_ref());
}
sub _build_compartment {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->compartment_ref());
}


# CONSTANTS:
sub _type { return 'KBaseBiochem.Reagent'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'Reagent'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'isCofactor',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'compound_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'compartment_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'coefficient',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {isCofactor => 0, compound_ref => 1, compartment_ref => 2, coefficient => 3};
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
            'parent' => 'Biochemistry',
            'name' => 'compound',
            'attribute' => 'compound_ref',
            'clearer' => 'clear_compound',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound',
            'method' => 'compounds',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          },
          {
            'parent' => 'Biochemistry',
            'name' => 'compartment',
            'attribute' => 'compartment_ref',
            'clearer' => 'clear_compartment',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compartment',
            'method' => 'compartments',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          }
        ];

my $link_map = {compound => 0, compartment => 1};
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
