########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::GapgenerationSolution - This is the moose object corresponding to the KBaseFBA.GapgenerationSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::GapgenerationSolution;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::GapgenerationSolutionReaction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has mediaRemoval_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has solutionCost => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has integrated => (is => 'rw', isa => 'Bool', printOrder => '1', default => '0', type => 'attribute', metaclass => 'Typed');
has suboptimal => (is => 'rw', isa => 'Bool', printOrder => '1', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassSuppplement_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has additionalKO_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has gapgenSolutionReactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(GapgenerationSolutionReaction)', metaclass => 'Typed', reader => '_gapgenSolutionReactions', printOrder => '-1');


# LINKS:
has mediaRemovals => (is => 'rw', type => 'link(FBAModel,modelcompounds,mediaRemoval_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_mediaRemovals', clearer => 'clear_mediaRemovals', isa => 'ArrayRef');
has biomassSuppplements => (is => 'rw', type => 'link(FBAModel,modelcompounds,biomassSuppplement_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_biomassSuppplements', clearer => 'clear_biomassSuppplements', isa => 'ArrayRef');
has additionalKOs => (is => 'rw', type => 'link(FBAModel,modelreactions,additionalKO_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_additionalKOs', clearer => 'clear_additionalKOs', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/gapgenSolutions/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_mediaRemovals {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->mediaRemoval_refs());
}
sub _build_biomassSuppplements {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->biomassSuppplement_refs());
}
sub _build_additionalKOs {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->additionalKO_refs());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.GapgenerationSolution'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'GapgenerationSolution'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'mediaRemoval_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'solutionCost',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'integrated',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'suboptimal',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'biomassSuppplement_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'additionalKO_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {mediaRemoval_refs => 0, solutionCost => 1, integrated => 2, suboptimal => 3, biomassSuppplement_refs => 4, additionalKO_refs => 5, id => 6};
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
            'name' => 'mediaRemovals',
            'attribute' => 'mediaRemoval_refs',
            'array' => 1,
            'clearer' => 'clear_mediaRemovals',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound',
            'method' => 'modelcompounds',
            'module' => 'KBaseFBA',
            'field' => 'id'
          },
          {
            'parent' => 'FBAModel',
            'name' => 'biomassSuppplements',
            'attribute' => 'biomassSuppplement_refs',
            'array' => 1,
            'clearer' => 'clear_biomassSuppplements',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound',
            'method' => 'modelcompounds',
            'module' => 'KBaseFBA',
            'field' => 'id'
          },
          {
            'parent' => 'FBAModel',
            'name' => 'additionalKOs',
            'attribute' => 'additionalKO_refs',
            'array' => 1,
            'clearer' => 'clear_additionalKOs',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction',
            'method' => 'modelreactions',
            'module' => 'KBaseFBA',
            'field' => 'id'
          }
        ];

my $link_map = {mediaRemovals => 0, biomassSuppplements => 1, additionalKOs => 2};
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
            'name' => 'gapgenSolutionReactions',
            'default' => undef,
            'description' => undef,
            'class' => 'GapgenerationSolutionReaction',
            'type' => 'child',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {gapgenSolutionReactions => 0};
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
around 'gapgenSolutionReactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gapgenSolutionReactions');
};


__PACKAGE__->meta->make_immutable;
1;
