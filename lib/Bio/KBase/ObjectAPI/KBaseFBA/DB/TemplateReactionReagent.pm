########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateReactionReagent - This is the moose object corresponding to the KBaseFBA.TemplateReactionReagent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateReactionReagent;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has coefficient => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has templatecompcompound_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has templatecompcompound => (is => 'rw', type => 'link(TemplateModel,compcompounds,templatecompcompound_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_templatecompcompound', clearer => 'clear_templatecompcompound', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_templatecompcompound {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->templatecompcompound_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateReactionReagent'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateReactionReagent'; }
sub _top { return 0; }

my $attributes = [
          {
            'name' => 'coefficient',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Num',
            'req' => 0
          },
          {
            'req' => 0,
            'name' => 'templatecompcompound_ref',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Str'
          }
        ];

my $attribute_map = {coefficient => 0, templatecompcompound_ref => 1};
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
            'method' => 'compcompounds',
            'field' => 'id',
            'clearer' => 'clear_templatecompcompound',
            'attribute' => 'templatecompcompound_ref',
            'class' => 'TemplateModel',
            'module' => undef,
            'name' => 'templatecompcompound',
            'parent' => 'TemplateModel'
          }
        ];

my $link_map = {templatecompcompound => 0};
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
