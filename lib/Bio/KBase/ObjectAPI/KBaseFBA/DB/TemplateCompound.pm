########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompound - This is the moose object corresponding to the KBaseFBA.TemplateCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompound;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has compound_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has aliases => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has deltaGErr => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has isCofactor => (is => 'rw', isa => 'Bool', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has formula => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has abbreviation => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has md5 => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has defaultCharge => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has deltaG => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has mass => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has compound => (is => 'rw', type => 'link(,,compound_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/compounds/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_compound {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->compound_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateCompound'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateCompound'; }
sub _top { return 0; }

my $attributes = [
          {
            'type' => 'Str',
            'perm' => 'rw',
            'name' => 'compound_ref',
            'printOrder' => -1,
            'req' => 0
          },
          {
            'perm' => 'rw',
            'name' => 'aliases',
            'printOrder' => -1,
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'req' => 0
          },
          {
            'type' => 'Str',
            'perm' => 'rw',
            'printOrder' => 0,
            'name' => 'id',
            'req' => 1
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'deltaGErr',
            'perm' => 'rw',
            'type' => 'Num'
          },
          {
            'type' => 'Bool',
            'printOrder' => -1,
            'name' => 'isCofactor',
            'perm' => 'rw',
            'req' => 0
          },
          {
            'req' => 0,
            'perm' => 'rw',
            'name' => 'formula',
            'printOrder' => -1,
            'type' => 'Str'
          },
          {
            'req' => 0,
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'abbreviation',
            'type' => 'Str'
          },
          {
            'type' => 'Str',
            'printOrder' => -1,
            'name' => 'name',
            'perm' => 'rw',
            'req' => 0
          },
          {
            'perm' => 'rw',
            'name' => 'md5',
            'printOrder' => -1,
            'type' => 'Str',
            'req' => 0
          },
          {
            'req' => 0,
            'type' => 'Num',
            'printOrder' => -1,
            'name' => 'defaultCharge',
            'perm' => 'rw'
          },
          {
            'type' => 'Num',
            'perm' => 'rw',
            'name' => 'deltaG',
            'printOrder' => -1,
            'req' => 0
          },
          {
            'name' => 'mass',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Num',
            'req' => 0
          }
        ];

my $attribute_map = {compound_ref => 0, aliases => 1, id => 2, deltaGErr => 3, isCofactor => 4, formula => 5, abbreviation => 6, name => 7, md5 => 8, defaultCharge => 9, deltaG => 10, mass => 11};
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
            'name' => 'compound',
            'parent' => undef,
            'module' => undef,
            'attribute' => 'compound_ref',
            'class' => undef,
            'field' => undef,
            'clearer' => 'clear_compound',
            'method' => undef
          }
        ];

my $link_map = {compound => 0};
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
