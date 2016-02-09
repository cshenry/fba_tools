########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReactionProtein - This is the moose object corresponding to the KBaseFBA.ModelReactionProtein object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReactionProtein;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProteinSubunit;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has complex_ref => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has note => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');
has source => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has modelReactionProteinSubunits => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelReactionProteinSubunit)', metaclass => 'Typed', reader => '_modelReactionProteinSubunits', printOrder => '-1');


# LINKS:
has complex => (is => 'rw', type => 'link(Mapping,complexes,complex_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_complex', clearer => 'clear_complex', isa => 'Bio::KBase::ObjectAPI::KBaseOntology::Complex', weak_ref => 1);


# BUILDERS:
sub _build_complex {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->complex_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.ModelReactionProtein'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'ModelReactionProtein'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'complex_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'note',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'source',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {complex_ref => 0, note => 1,source => 2};
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
            'parent' => 'Mapping',
            'name' => 'complex',
            'attribute' => 'complex_ref',
            'clearer' => 'clear_complex',
            'class' => 'Bio::KBase::ObjectAPI::KBaseOntology::Complex',
            'method' => 'complexes',
            'module' => 'KBaseOntology',
            'field' => 'id'
          }
        ];

my $link_map = {complex => 0};
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
            'req' => undef,
            'printOrder' => -1,
            'name' => 'modelReactionProteinSubunits',
            'default' => undef,
            'description' => undef,
            'class' => 'ModelReactionProteinSubunit',
            'type' => 'child',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {modelReactionProteinSubunits => 0};
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
around 'modelReactionProteinSubunits' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('modelReactionProteinSubunits');
};


__PACKAGE__->meta->make_immutable;
1;
