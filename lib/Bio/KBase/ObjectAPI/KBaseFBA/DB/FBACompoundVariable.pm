########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::FBACompoundVariable - This is the moose object corresponding to the KBaseFBA.FBACompoundVariable object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::FBACompoundVariable;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has value => (is => 'rw', isa => 'Num', printOrder => '6', type => 'attribute', metaclass => 'Typed');
has min => (is => 'rw', isa => 'Num', printOrder => '7', type => 'attribute', metaclass => 'Typed');
has lowerBound => (is => 'rw', isa => 'Num', printOrder => '4', type => 'attribute', metaclass => 'Typed');
has max => (is => 'rw', isa => 'Num', printOrder => '8', type => 'attribute', metaclass => 'Typed');
has upperBound => (is => 'rw', isa => 'Num', printOrder => '5', type => 'attribute', metaclass => 'Typed');
has modelcompound_ref => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'Str', printOrder => '9', type => 'attribute', metaclass => 'Typed');
has variableType => (is => 'rw', isa => 'Str', printOrder => '3', type => 'attribute', metaclass => 'Typed');


# LINKS:
has modelcompound => (is => 'rw', type => 'link(FBAModel,modelcompounds,modelcompound_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_modelcompound', clearer => 'clear_modelcompound', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound', weak_ref => 1);


# BUILDERS:
sub _build_modelcompound {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->modelcompound_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.FBACompoundVariable'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'FBACompoundVariable'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'value',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'min',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'lowerBound',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'max',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'upperBound',
            'default' => undef,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'modelcompound_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 9,
            'name' => 'class',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'variableType',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {value => 0, min => 1, lowerBound => 2, max => 3, upperBound => 4, modelcompound_ref => 5, class => 6, variableType => 7};
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
            'name' => 'modelcompound',
            'attribute' => 'modelcompound_ref',
            'clearer' => 'clear_modelcompound',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound',
            'method' => 'modelcompounds',
            'module' => 'KBaseFBA',
            'field' => 'id'
          }
        ];

my $link_map = {modelcompound => 0};
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
