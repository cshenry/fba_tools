########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAMinimalMediaResult - This is the moose object corresponding to the KBaseFBA.FBAMinimalMediaResult object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAMinimalMediaResult;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has optionalNutrient_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has essentialNutrient_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has optionalNutrients => (is => 'rw', type => 'link(Biochemistry,compounds,optionalNutrient_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_optionalNutrients', clearer => 'clear_optionalNutrients', isa => 'ArrayRef');
has essentialNutrients => (is => 'rw', type => 'link(Biochemistry,compounds,essentialNutrient_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_essentialNutrients', clearer => 'clear_essentialNutrients', isa => 'ArrayRef');


# BUILDERS:
sub _build_optionalNutrients {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->optionalNutrient_refs());
}
sub _build_essentialNutrients {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->essentialNutrient_refs());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.FBAMinimalMediaResult'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'FBAMinimalMediaResult'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'optionalNutrient_refs',
            'default' => undef,
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'essentialNutrient_refs',
            'default' => undef,
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {optionalNutrient_refs => 0, essentialNutrient_refs => 1};
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
            'name' => 'optionalNutrients',
            'attribute' => 'optionalNutrient_refs',
            'array' => 1,
            'clearer' => 'clear_optionalNutrients',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound',
            'method' => 'compounds',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          },
          {
            'parent' => 'Biochemistry',
            'name' => 'essentialNutrients',
            'attribute' => 'essentialNutrient_refs',
            'array' => 1,
            'clearer' => 'clear_essentialNutrients',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound',
            'method' => 'compounds',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          }
        ];

my $link_map = {optionalNutrients => 0, essentialNutrients => 1};
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
