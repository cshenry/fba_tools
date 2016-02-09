########################################################################
# Bio::KBase::ObjectAPI::KBaseExpression::DB::SampleAnnotation - This is the moose object corresponding to the KBaseExpression.SampleAnnotation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseExpression::DB::SampleAnnotation;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has sample_annotation_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has ontology_definition => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has ontology_name => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has ontology_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:


# BUILDERS:


# CONSTANTS:
sub _type { return 'KBaseExpression.SampleAnnotation'; }
sub _module { return 'KBaseExpression'; }
sub _class { return 'SampleAnnotation'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'sample_annotation_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'ontology_definition',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'ontology_name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'ontology_id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {sample_annotation_id => 0, ontology_definition => 1, ontology_name => 2, ontology_id => 3};
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
