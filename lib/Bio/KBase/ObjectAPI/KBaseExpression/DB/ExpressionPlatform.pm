########################################################################
# Bio::KBase::ObjectAPI::KBaseExpression::DB::ExpressionPlatform - This is the moose object corresponding to the KBaseExpression.ExpressionPlatform object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseExpression::DB::ExpressionPlatform;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseExpression::Strain;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has source_id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has technology => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has genome_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has title => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has strain => (is => 'rw', singleton => 1, isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Strain)', metaclass => 'Typed', reader => '_strain', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'//id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseExpression.ExpressionPlatform'; }
sub _module { return 'KBaseExpression'; }
sub _class { return 'ExpressionPlatform'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'source_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'technology',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'genome_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'title',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {source_id => 0, technology => 1, id => 2, genome_id => 3, title => 4};
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
            'printOrder' => -1,
            'name' => 'strain',
            'type' => 'child',
            'class' => 'Strain',
            'singleton' => 1,
            'module' => 'KBaseExpression'
          }
        ];

my $subobject_map = {strain => 0};
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
around 'strain' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('strain');
};


__PACKAGE__->meta->make_immutable;
1;
