########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateReaction - This is the moose object corresponding to the KBaseFBA.TemplateReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateReaction;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateReactionReagent;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has templatecomplex_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has forward_penalty => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '1', type => 'attribute', metaclass => 'Typed');
has maxrevflux => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has deltaG => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has base_cost => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has GapfillDirection => (is => 'rw', isa => 'Str', printOrder => '-1', default => '=', type => 'attribute', metaclass => 'Typed');
has reverse_penalty => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has status => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has deltaGErr => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has maxforflux => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has templatecompartment_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has reference => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has reaction_ref => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has templateReactionReagents => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateReactionReagent)', metaclass => 'Typed', reader => '_templateReactionReagents', printOrder => '-1');


# LINKS:
has templatecomplexs => (is => 'rw', type => 'link(TemplateModel,complexes,templatecomplex_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_templatecomplexs', clearer => 'clear_templatecomplexs', isa => 'ArrayRef');
has templatecompartment => (is => 'rw', type => 'link(TemplateModel,compartments,templatecompartment_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_templatecompartment', clearer => 'clear_templatecompartment', isa => 'Ref', weak_ref => 1);
has reaction => (is => 'rw', type => 'link(,,reaction_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_reaction', clearer => 'clear_reaction', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/reactions/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_templatecomplexs {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->templatecomplex_refs());
}
sub _build_templatecompartment {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->templatecompartment_ref());
}
sub _build_reaction {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->reaction_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.TemplateReaction'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TemplateReaction'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'printOrder' => -1,
            'name' => 'templatecomplex_refs',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'name' => 'forward_penalty',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Num'
          },
          {
            'req' => 0,
            'default' => undef,
            'type' => 'Str',
            'printOrder' => 1,
            'name' => 'type',
            'perm' => 'rw',
            'description' => undef
          },
          {
            'type' => 'Num',
            'perm' => 'rw',
            'name' => 'maxrevflux',
            'printOrder' => -1,
            'req' => 0
          },
          {
            'type' => 'Num',
            'perm' => 'rw',
            'name' => 'deltaG',
            'printOrder' => -1,
            'req' => 0
          },
          {
            'type' => 'Num',
            'perm' => 'rw',
            'name' => 'base_cost',
            'printOrder' => -1,
            'req' => 0
          },
          {
            'default' => '=',
            'type' => 'Str',
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'GapfillDirection',
            'req' => 0
          },
          {
            'type' => 'Num',
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'reverse_penalty',
            'req' => 0
          },
          {
            'printOrder' => -1,
            'name' => 'name',
            'perm' => 'rw',
            'type' => 'Str',
            'req' => 0
          },
          {
            'req' => 0,
            'type' => 'Str',
            'name' => 'status',
            'printOrder' => -1,
            'perm' => 'rw'
          },
          {
            'printOrder' => -1,
            'name' => 'deltaGErr',
            'perm' => 'rw',
            'type' => 'Num',
            'req' => 0
          },
          {
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'maxforflux',
            'type' => 'Num',
            'req' => 0
          },
          {
            'req' => 0,
            'type' => 'Str',
            'perm' => 'rw',
            'printOrder' => -1,
            'name' => 'templatecompartment_ref'
          },
          {
            'req' => 0,
            'type' => 'Str',
            'perm' => 'rw',
            'name' => 'reference',
            'printOrder' => -1
          },
          {
            'description' => undef,
            'perm' => 'rw',
            'name' => 'direction',
            'printOrder' => 1,
            'default' => undef,
            'type' => 'Str',
            'req' => 0
          },
          {
            'type' => 'Str',
            'printOrder' => 0,
            'name' => 'id',
            'perm' => 'rw',
            'req' => 1
          },
          {
            'perm' => 'rw',
            'description' => undef,
            'name' => 'reaction_ref',
            'printOrder' => -1,
            'default' => undef,
            'type' => 'Str',
            'req' => 1
          }
        ];

my $attribute_map = {templatecomplex_refs => 0, forward_penalty => 1, type => 2, maxrevflux => 3, deltaG => 4, base_cost => 5, GapfillDirection => 6, reverse_penalty => 7, name => 8, status => 9, deltaGErr => 10, maxforflux => 11, templatecompartment_ref => 12, reference => 13, direction => 14, id => 15, reaction_ref => 16};
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
            'clearer' => 'clear_templatecomplexs',
            'method' => 'complexes',
            'array' => 1,
            'parent' => 'TemplateModel',
            'name' => 'templatecomplexs',
            'attribute' => 'templatecomplex_refs',
            'class' => 'TemplateModel',
            'module' => undef
          },
          {
            'module' => undef,
            'attribute' => 'templatecompartment_ref',
            'class' => 'TemplateModel',
            'parent' => 'TemplateModel',
            'name' => 'templatecompartment',
            'method' => 'compartments',
            'clearer' => 'clear_templatecompartment',
            'field' => 'id'
          },
          {
            'parent' => undef,
            'name' => 'reaction',
            'attribute' => 'reaction_ref',
            'module' => undef,
            'class' => undef,
            'field' => undef,
            'clearer' => 'clear_reaction',
            'method' => undef
          }
        ];

my $link_map = {templatecomplexs => 0, templatecompartment => 1, reaction => 2};
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
            'module' => 'KBaseFBA',
            'class' => 'TemplateReactionReagent',
            'type' => 'child',
            'printOrder' => -1,
            'name' => 'templateReactionReagents'
          }
        ];

my $subobject_map = {templateReactionReagents => 0};
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
around 'templateReactionReagents' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('templateReactionReagents');
};


__PACKAGE__->meta->make_immutable;
1;
