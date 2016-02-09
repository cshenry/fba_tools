########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateComplex - This is the moose object corresponding to the KBaseFBA.TemplateComplex object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateComplex;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateComplexRole;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has confidence => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has source => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has reference => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has complexroles => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateComplexRole)', metaclass => 'Typed', reader => '_complexroles', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/complexes/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateComplex'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateComplex'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'type' => 'Num',
            'perm' => 'rw',
            'name' => 'confidence',
            'printOrder' => -1
          },
          {
            'req' => 0,
            'name' => 'source',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Str'
          },
          {
            'req' => 0,
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'name',
            'type' => 'Str'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reference',
            'perm' => 'rw',
            'type' => 'Str'
          },
          {
            'req' => 0,
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'id',
            'type' => 'Str'
          }
        ];

my $attribute_map = {confidence => 0, source => 1, name => 2, reference => 3, id => 4};
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
            'class' => 'TemplateComplexRole',
            'module' => 'KBaseFBA',
            'type' => 'child',
            'name' => 'complexroles',
            'printOrder' => -1
          }
        ];

my $subobject_map = {complexroles => 0};
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
around 'complexroles' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('complexroles');
};


__PACKAGE__->meta->make_immutable;
1;
