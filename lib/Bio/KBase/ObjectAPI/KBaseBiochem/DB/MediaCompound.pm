########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::DB::MediaCompound - This is the moose object corresponding to the KBaseBiochem.MediaCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseBiochem::DB::MediaCompound;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has compound_ref => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has concentration => (is => 'rw', isa => 'Num', printOrder => '0', default => '0.001', type => 'attribute', metaclass => 'Typed');
has maxFlux => (is => 'rw', isa => 'Num', printOrder => '0', default => '100', type => 'attribute', metaclass => 'Typed');
has minFlux => (is => 'rw', isa => 'Num', printOrder => '0', default => '-100', type => 'attribute', metaclass => 'Typed');


# LINKS:
has compound => (is => 'rw', type => 'link(Biochemistry,compounds,compound_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound', weak_ref => 1);


# BUILDERS:
sub _build_compound {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->compound_ref());
}


# CONSTANTS:
sub _type { return 'KBaseBiochem.MediaCompound'; }
sub _module { return 'KBaseBiochem'; }
sub _class { return 'MediaCompound'; }
sub _top { return 0; }

my $attributes = [
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
            'req' => 0,
            'printOrder' => 0,
            'name' => 'concentration',
            'default' => '0.001',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'maxFlux',
            'default' => '100',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'minFlux',
            'default' => '-100',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {compound_ref => 0, concentration => 1, maxFlux => 2, minFlux => 3};
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
          }
        ];

my $link_map = {compound => 0};
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
