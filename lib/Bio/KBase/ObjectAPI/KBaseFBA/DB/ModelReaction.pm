########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReaction - This is the moose object corresponding to the KBaseFBA.ModelReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReaction;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionReagent;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelReactionProtein;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
#has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has protons => (is => 'rw', isa => 'Num', printOrder => '7', default => '0', type => 'attribute', metaclass => 'Typed');
has reaction_ref => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '5', default => '=', type => 'attribute', metaclass => 'Typed');
has modelcompartment_ref => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has maxforflux => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has reference => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has maxrevflux => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has probability => (is => 'rw', isa => 'Num', printOrder => '8', default => '1', type => 'attribute', metaclass => 'Typed');
has pathway => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has aliases => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has gapfill_data => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');

# SUBOBJECTS:
has modelReactionReagents => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelReactionReagent)', metaclass => 'Typed', reader => '_modelReactionReagents', printOrder => '-1');
has modelReactionProteins => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelReactionProtein)', metaclass => 'Typed', reader => '_modelReactionProteins', printOrder => '-1');


# LINKS:
has reaction => (is => 'rw', type => 'link(Biochemistry,reactions,reaction_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_reaction', clearer => 'clear_reaction', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Reaction', weak_ref => 1);
has modelcompartment => (is => 'rw', type => 'link(FBAModel,modelcompartments,modelcompartment_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_modelcompartment', clearer => 'clear_modelcompartment', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompartment', weak_ref => 1);


# BUILDERS:
sub _reference { my ($self) = @_;return $self->parent()->_reference().'/modelreactions/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_reaction {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->reaction_ref());
}
sub _build_modelcompartment {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->modelcompartment_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.ModelReaction'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'ModelReaction'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'protons',
            'default' => 0,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'reaction_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'direction',
            'default' => '=',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'modelcompartment_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'maxforflux',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reference',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'maxrevflux',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'probability',
            'default' => 1,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'pathway',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'aliases',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gapfill_data',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },

        ];

my $attribute_map = {protons => 0, reaction_ref => 1, direction => 2, modelcompartment_ref => 3, maxforflux => 4, reference => 5, id => 6, maxrevflux => 7, name => 8, probability => 9, pathway => 10, aliases => 11,gapfill_data => 12};
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
            'parent' => 'Biochemistry',
            'name' => 'reaction',
            'attribute' => 'reaction_ref',
            'clearer' => 'clear_reaction',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Reaction',
            'method' => 'reactions',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          },
          {
            'parent' => 'FBAModel',
            'name' => 'modelcompartment',
            'attribute' => 'modelcompartment_ref',
            'clearer' => 'clear_modelcompartment',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompartment',
            'method' => 'modelcompartments',
            'module' => 'KBaseFBA',
            'field' => 'id'
          }
        ];

my $link_map = {reaction => 0, modelcompartment => 1};
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
            'name' => 'modelReactionReagents',
            'default' => undef,
            'description' => undef,
            'class' => 'ModelReactionReagent',
            'type' => 'child',
            'module' => 'KBaseFBA'
          },
          {
            'req' => undef,
            'printOrder' => -1,
            'name' => 'modelReactionProteins',
            'default' => undef,
            'description' => undef,
            'class' => 'ModelReactionProtein',
            'type' => 'child',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {modelReactionReagents => 0, modelReactionProteins => 1};
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
around 'modelReactionReagents' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('modelReactionReagents');
};
around 'modelReactionProteins' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('modelReactionProteins');
};


__PACKAGE__->meta->make_immutable;
1;
