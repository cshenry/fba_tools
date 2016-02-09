########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateComplexRole - This is the moose object corresponding to the KBaseFBA.TemplateComplexRole object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateComplexRole;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has type => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has templaterole_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has confidence => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has optional => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has triggering => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has templaterole => (is => 'rw', type => 'link(TemplateModel,roles,templaterole_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_templaterole', clearer => 'clear_templaterole', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_templaterole {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->templaterole_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateComplexRole'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateComplexRole'; }
sub _top { return 0; }

my $attributes = [
          {
            'printOrder' => -1,
            'name' => 'type',
            'perm' => 'rw',
            'type' => 'Str',
            'req' => 0
          },
          {
            'req' => 0,
            'name' => 'templaterole_ref',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Str'
          },
          {
            'req' => 0,
            'type' => 'Num',
            'printOrder' => -1,
            'name' => 'confidence',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'name' => 'optional',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Int'
          },
          {
            'req' => 0,
            'type' => 'Int',
            'perm' => 'rw',
            'name' => 'triggering',
            'printOrder' => -1
          }
        ];

my $attribute_map = {type => 0, templaterole_ref => 1, confidence => 2, optional => 3, triggering => 4};
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
            'field' => 'id',
            'clearer' => 'clear_templaterole',
            'method' => 'roles',
            'name' => 'templaterole',
            'parent' => 'TemplateModel',
            'class' => 'TemplateModel',
            'attribute' => 'templaterole_ref',
            'module' => undef
          }
        ];

my $link_map = {templaterole => 0};
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
