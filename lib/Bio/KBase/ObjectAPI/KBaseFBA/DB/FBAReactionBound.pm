########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAReactionBound - This is the moose object corresponding to the KBaseFBA.FBAReactionBound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAReactionBound;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has modelreaction_ref => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has lowerBound => (is => 'rw', isa => 'Num', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has upperBound => (is => 'rw', isa => 'Num', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has variableType => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has modelreaction => (is => 'rw', type => 'link(FBAModel,modelreactions,modelreaction_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_modelreaction', clearer => 'clear_modelreaction', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction', weak_ref => 1);


# BUILDERS:
sub _build_modelreaction {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->modelreaction_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.FBAReactionBound'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'FBAReactionBound'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'modelreaction_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'lowerBound',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'upperBound',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'variableType',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {modelreaction_ref => 0, lowerBound => 1, upperBound => 2, variableType => 3};
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
            'parent' => 'FBAModel',
            'name' => 'modelreaction',
            'attribute' => 'modelreaction_ref',
            'clearer' => 'clear_modelreaction',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction',
            'method' => 'modelreactions',
            'module' => 'KBaseFBA',
            'field' => 'id'
          }
        ];

my $link_map = {modelreaction => 0};
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
