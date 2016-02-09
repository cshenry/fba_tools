########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplatePathway - This is the moose object corresponding to the KBaseFBA.TemplatePathway object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplatePathway;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has broadClassification => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has midClassification => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has source => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has templatereaction_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has source_id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has templatereactions => (is => 'rw', type => 'link(TemplateModel,reactions,templatereaction_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_templatereactions', clearer => 'clear_templatereactions', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/pathways/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_templatereactions {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->templatereaction_refs());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplatePathway'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplatePathway'; }
sub _top { return 0; }

my $attributes = [
          {
            'type' => 'Str',
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'name',
            'req' => 0
          },
          {
            'req' => 1,
            'type' => 'Str',
            'perm' => 'rw',
            'name' => 'id',
            'printOrder' => 0
          },
          {
            'req' => 0,
            'type' => 'Str',
            'printOrder' => -1,
            'name' => 'broadClassification',
            'perm' => 'rw'
          },
          {
            'perm' => 'rw',
            'name' => 'midClassification',
            'printOrder' => -1,
            'type' => 'Str',
            'req' => 0
          },
          {
            'req' => 0,
            'perm' => 'rw',
            'name' => 'source',
            'printOrder' => -1,
            'type' => 'Str'
          },
          {
            'req' => 0,
            'name' => 'templatereaction_refs',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'ArrayRef',
            'default' => 'sub {return [];}'
          },
          {
            'type' => 'Str',
            'printOrder' => -1,
            'name' => 'source_id',
            'perm' => 'rw',
            'req' => 0
          }
        ];

my $attribute_map = {name => 0, id => 1, broadClassification => 2, midClassification => 3, source => 4, templatereaction_refs => 5, source_id => 6};
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
            'clearer' => 'clear_templatereactions',
            'field' => 'id',
            'array' => 1,
            'method' => 'reactions',
            'parent' => 'TemplateModel',
            'name' => 'templatereactions',
            'attribute' => 'templatereaction_refs',
            'module' => undef,
            'class' => 'TemplateModel'
          }
        ];

my $link_map = {templatereactions => 0};
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
