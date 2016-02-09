########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::GapfillingSolution - This is the moose object corresponding to the KBaseFBA.GapfillingSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::GapfillingSolution;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::GapfillingReaction;
use Bio::KBase::ObjectAPI::KBaseFBA::GapfillingReaction;
use Bio::KBase::ObjectAPI::KBaseFBA::ActivatedReaction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has biomassRemoval_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has solutionCost => (is => 'rw', isa => 'Num', printOrder => '1', default => '1', type => 'attribute', metaclass => 'Typed');
has rejscore => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has integrated => (is => 'rw', isa => 'Bool', printOrder => '1', default => '0', type => 'attribute', metaclass => 'Typed');
has objective => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has koRestore_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has candscore => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has failedReaction_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has gfscore => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has mediaSupplement_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has suboptimal => (is => 'rw', isa => 'Bool', printOrder => '1', default => '0', type => 'attribute', metaclass => 'Typed');
has actscore => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has rejectedCandidates => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(GapfillingReaction)', metaclass => 'Typed', reader => '_rejectedCandidates', printOrder => '-1');
has gapfillingSolutionReactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(GapfillingReaction)', metaclass => 'Typed', reader => '_gapfillingSolutionReactions', printOrder => '-1');
has activatedReactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ActivatedReaction)', metaclass => 'Typed', reader => '_activatedReactions', printOrder => '-1');


# LINKS:
has biomassRemovals => (is => 'rw', type => 'link(FBAModel,modelcompounds,biomassRemoval_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_biomassRemovals', clearer => 'clear_biomassRemovals', isa => 'ArrayRef');
has koRestores => (is => 'rw', type => 'link(FBAModel,modelreactions,koRestore_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_koRestores', clearer => 'clear_koRestores', isa => 'ArrayRef');
has failedReactions => (is => 'rw', type => 'link(FBAModel,modelreactions,failedReaction_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_failedReactions', clearer => 'clear_failedReactions', isa => 'ArrayRef');
has mediaSupplements => (is => 'rw', type => 'link(FBAModel,modelcompounds,mediaSupplement_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_mediaSupplements', clearer => 'clear_mediaSupplements', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/gapfillingSolutions/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_biomassRemovals {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->biomassRemoval_refs());
}
sub _build_koRestores {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->koRestore_refs());
}
sub _build_failedReactions {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->failedReaction_refs());
}
sub _build_mediaSupplements {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->mediaSupplement_refs());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.GapfillingSolution'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'GapfillingSolution'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'biomassRemoval_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'solutionCost',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'rejscore',
            'type' => 'Num',
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
            'printOrder' => -1,
            'name' => 'objective',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'koRestore_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'candscore',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'failedReaction_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gfscore',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'mediaSupplement_refs',
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
            'name' => 'actscore',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {biomassRemoval_refs => 0, solutionCost => 1, rejscore => 2, integrated => 3, objective => 4, koRestore_refs => 5, candscore => 6, failedReaction_refs => 7, gfscore => 8, mediaSupplement_refs => 9, id => 10, suboptimal => 11, actscore => 12};
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
            'name' => 'biomassRemovals',
            'attribute' => 'biomassRemoval_refs',
            'array' => 1,
            'clearer' => 'clear_biomassRemovals',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound',
            'method' => 'modelcompounds',
            'module' => 'KBaseFBA',
            'field' => 'id'
          },
          {
            'parent' => 'FBAModel',
            'name' => 'koRestores',
            'attribute' => 'koRestore_refs',
            'array' => 1,
            'clearer' => 'clear_koRestores',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction',
            'method' => 'modelreactions',
            'module' => 'KBaseFBA',
            'field' => 'id'
          },
          {
            'parent' => 'FBAModel',
            'name' => 'failedReactions',
            'attribute' => 'failedReaction_refs',
            'array' => 1,
            'clearer' => 'clear_failedReactions',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction',
            'method' => 'modelreactions',
            'module' => 'KBaseFBA',
            'field' => 'id'
          },
          {
            'parent' => 'FBAModel',
            'name' => 'mediaSupplements',
            'attribute' => 'mediaSupplement_refs',
            'array' => 1,
            'clearer' => 'clear_mediaSupplements',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound',
            'method' => 'modelcompounds',
            'module' => 'KBaseFBA',
            'field' => 'id'
          }
        ];

my $link_map = {biomassRemovals => 0, koRestores => 1, failedReactions => 2, mediaSupplements => 3};
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
            'name' => 'rejectedCandidates',
            'type' => 'child',
            'class' => 'GapfillingReaction',
            'module' => 'KBaseFBA'
          },
          {
            'req' => undef,
            'printOrder' => -1,
            'name' => 'gapfillingSolutionReactions',
            'default' => undef,
            'description' => undef,
            'class' => 'GapfillingReaction',
            'type' => 'child',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'activatedReactions',
            'type' => 'child',
            'class' => 'ActivatedReaction',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {rejectedCandidates => 0, gapfillingSolutionReactions => 1, activatedReactions => 2};
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
around 'rejectedCandidates' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('rejectedCandidates');
};
around 'gapfillingSolutionReactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gapfillingSolutionReactions');
};
around 'activatedReactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('activatedReactions');
};


__PACKAGE__->meta->make_immutable;
1;
