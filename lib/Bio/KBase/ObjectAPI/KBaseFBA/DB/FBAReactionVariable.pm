########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAReactionVariable - This is the moose object corresponding to the KBaseFBA.FBAReactionVariable object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAReactionVariable;
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
has modelreaction_ref => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has upperBound => (is => 'rw', isa => 'Num', printOrder => '5', type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'Str', printOrder => '9', type => 'attribute', metaclass => 'Typed');
has variableType => (is => 'rw', isa => 'Str', printOrder => '3', type => 'attribute', metaclass => 'Typed');
has biomass_dependencies => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has coupled_reactions => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has expression => (is => 'rw', isa => 'Num', printOrder => '5', default => 0, type => 'attribute', metaclass => 'Typed');
has scaled_exp => (is => 'rw', isa => 'Num', printOrder => '5', default => 0, type => 'attribute', metaclass => 'Typed');
has exp_state => (is => 'rw', isa => 'Str', printOrder => '5', default => "unknown", type => 'attribute', metaclass => 'Typed');

# LINKS:
has modelreaction => (is => 'rw', type => 'link(FBAModel,modelreactions,modelreaction_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_modelreaction', clearer => 'clear_modelreaction', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_modelreaction {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->modelreaction_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.FBAReactionVariable'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'FBAReactionVariable'; }
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
            'req' => 1,
            'printOrder' => -1,
            'name' => 'modelreaction_ref',
            'default' => undef,
            'type' => 'Str',
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
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'biomass_dependencies',
            'default' => undef,
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'coupled_reactions',
            'default' => undef,
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          }
          ,
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'expression',
            'default' => 0,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          }
          ,
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'scaled_exp',
            'default' => 0,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          }
          ,
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'exp_state',
            'default' => 0,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {value => 0, min => 1, lowerBound => 2, max => 3, modelreaction_ref => 4, upperBound => 5, class => 6, variableType => 7,biomass_dependencies => 8,coupled_reactions => 9,expression => 10,scaled_exp => 11, exp_state => 12};
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
