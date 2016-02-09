########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::FBADeletionResult - This is the moose object corresponding to the KBaseFBA.FBADeletionResult object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::FBADeletionResult;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has growthFraction => (is => 'rw', isa => 'Num', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has feature_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');


# LINKS:
has features => (is => 'rw', type => 'link(Genome,features,feature_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_features', clearer => 'clear_features', isa => 'ArrayRef');


# BUILDERS:
sub _build_features {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->feature_refs());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.FBADeletionResult'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'FBADeletionResult'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'growthFraction',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'feature_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {growthFraction => 0, feature_refs => 1};
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
            'parent' => 'Genome',
            'name' => 'features',
            'attribute' => 'feature_refs',
            'array' => 1,
            'clearer' => 'clear_features',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::Feature',
            'method' => 'features',
            'module' => 'KBaseGenomes',
            'field' => 'id'
          }
        ];

my $link_map = {features => 0};
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
