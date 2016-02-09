########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::ActivatedReaction - This is the moose object corresponding to the KBaseFBA.ActivatedReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::ActivatedReaction;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has modelreaction_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has round => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has modelreaction => (is => 'rw', type => 'link(FBAModel,modelreactions,modelreaction_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_modelreaction', clearer => 'clear_modelreaction', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction', weak_ref => 1);


# BUILDERS:
sub _build_modelreaction {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->modelreaction_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.ActivatedReaction'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'ActivatedReaction'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'modelreaction_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'round',
            'type' => 'Int',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {modelreaction_ref => 0, round => 1};
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
