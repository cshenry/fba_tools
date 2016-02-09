########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::Gapfilling - This is the moose object corresponding to the KBaseFBA.Gapfilling object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::Gapfilling;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseFBA::GapfillingSolution;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has reactionMultipliers => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has allowableCompartment_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has noStructureMultiplier => (is => 'rw', isa => 'Num', printOrder => '11', default => '1', type => 'attribute', metaclass => 'Typed');
has targetedreaction_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has balancedReactionsOnly => (is => 'rw', isa => 'Bool', printOrder => '6', default => '1', type => 'attribute', metaclass => 'Typed');
has completeGapfill => (is => 'rw', isa => 'Bool', printOrder => '18', default => '0', type => 'attribute', metaclass => 'Typed');
has gprHypothesis => (is => 'rw', isa => 'Bool', printOrder => '4', default => '0', type => 'attribute', metaclass => 'Typed');
has media_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has timePerSolution => (is => 'rw', isa => 'Int', printOrder => '16', type => 'attribute', metaclass => 'Typed');
has probanno_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has deltaGMultiplier => (is => 'rw', isa => 'Num', printOrder => '10', default => '1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has fba_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has fbamodel_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has simultaneousGapfill => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassHypothesis => (is => 'rw', isa => 'Bool', printOrder => '3', default => '0', type => 'attribute', metaclass => 'Typed');
has totalTimeLimit => (is => 'rw', isa => 'Int', printOrder => '17', type => 'attribute', metaclass => 'Typed');
has noDeltaGMultiplier => (is => 'rw', isa => 'Num', printOrder => '12', default => '1', type => 'attribute', metaclass => 'Typed');
has drainFluxMultiplier => (is => 'rw', isa => 'Num', printOrder => '8', default => '1', type => 'attribute', metaclass => 'Typed');
has guaranteedReaction_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has reactionAdditionHypothesis => (is => 'rw', isa => 'Bool', printOrder => '5', default => '1', type => 'attribute', metaclass => 'Typed');
has singleTransporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '14', default => '1', type => 'attribute', metaclass => 'Typed');
has directionalityMultiplier => (is => 'rw', isa => 'Num', printOrder => '9', default => '1', type => 'attribute', metaclass => 'Typed');
has mediaHypothesis => (is => 'rw', isa => 'Bool', printOrder => '2', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassTransporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '13', default => '1', type => 'attribute', metaclass => 'Typed');
has reactionActivationBonus => (is => 'rw', isa => 'Num', printOrder => '7', default => '0', type => 'attribute', metaclass => 'Typed');
has transporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '15', default => '1', type => 'attribute', metaclass => 'Typed');
has blacklistedReaction_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has gapfillingSolutions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(GapfillingSolution)', metaclass => 'Typed', reader => '_gapfillingSolutions', printOrder => '0');


# LINKS:
has allowableCompartments => (is => 'rw', type => 'link(Biochemistry,compartments,allowableCompartment_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_allowableCompartments', clearer => 'clear_allowableCompartments', isa => 'ArrayRef');
has targetedreactions => (is => 'rw', type => 'link(Biochemistry,reactions,targetedreaction_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_targetedreactions', clearer => 'clear_targetedreactions', isa => 'ArrayRef');
has media => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Media,media_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_media', clearer => 'clear_media', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media', weak_ref => 1);
has probanno => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,ProbAnno,probanno_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_probanno', clearer => 'clear_probanno', isa => 'Bio::KBase::ObjectAPI::ProbabilisticAnnotation::ProbAnno', weak_ref => 1);
has fba => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,FBA,fba_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fba', clearer => 'clear_fba', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::FBA', weak_ref => 1);
has fbamodel => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,FBAModel,fbamodel_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fbamodel', clearer => 'clear_fbamodel', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::FBAModel', weak_ref => 1);
has guaranteedReactions => (is => 'rw', type => 'link(Biochemistry,reactions,guaranteedReaction_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_guaranteedReactions', clearer => 'clear_guaranteedReactions', isa => 'ArrayRef');
has blacklistedReactions => (is => 'rw', type => 'link(Biochemistry,reactions,blacklistedReaction_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_blacklistedReactions', clearer => 'clear_blacklistedReactions', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_allowableCompartments {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->allowableCompartment_refs());
}
sub _build_targetedreactions {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->targetedreaction_refs());
}
sub _build_media {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->media_ref());
}
sub _build_probanno {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->probanno_ref());
}
sub _build_fba {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fba_ref());
}
sub _build_fbamodel {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fbamodel_ref());
}
sub _build_guaranteedReactions {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->guaranteedReaction_refs());
}
sub _build_blacklistedReactions {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->blacklistedReaction_refs());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseFBA.Gapfilling'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'Gapfilling'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reactionMultipliers',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'allowableCompartment_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 11,
            'name' => 'noStructureMultiplier',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'targetedreaction_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'balancedReactionsOnly',
            'default' => '1',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 18,
            'name' => 'completeGapfill',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'gprHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'media_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 16,
            'name' => 'timePerSolution',
            'default' => undef,
            'type' => 'Int',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'probanno_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 10,
            'name' => 'deltaGMultiplier',
            'default' => '1',
            'type' => 'Num',
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
            'printOrder' => -1,
            'name' => 'fba_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'fbamodel_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'simultaneousGapfill',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'biomassHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 17,
            'name' => 'totalTimeLimit',
            'default' => undef,
            'type' => 'Int',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 12,
            'name' => 'noDeltaGMultiplier',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'drainFluxMultiplier',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'guaranteedReaction_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'reactionAdditionHypothesis',
            'default' => '1',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 14,
            'name' => 'singleTransporterMultiplier',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 9,
            'name' => 'directionalityMultiplier',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'mediaHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 13,
            'name' => 'biomassTransporterMultiplier',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'reactionActivationBonus',
            'default' => '0',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 15,
            'name' => 'transporterMultiplier',
            'default' => '1',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'blacklistedReaction_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {reactionMultipliers => 0, allowableCompartment_refs => 1, noStructureMultiplier => 2, targetedreaction_refs => 3, balancedReactionsOnly => 4, completeGapfill => 5, gprHypothesis => 6, media_ref => 7, timePerSolution => 8, probanno_ref => 9, deltaGMultiplier => 10, id => 11, fba_ref => 12, fbamodel_ref => 13, simultaneousGapfill => 14, biomassHypothesis => 15, totalTimeLimit => 16, noDeltaGMultiplier => 17, drainFluxMultiplier => 18, guaranteedReaction_refs => 19, reactionAdditionHypothesis => 20, singleTransporterMultiplier => 21, directionalityMultiplier => 22, mediaHypothesis => 23, biomassTransporterMultiplier => 24, reactionActivationBonus => 25, transporterMultiplier => 26, blacklistedReaction_refs => 27};
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
            'name' => 'allowableCompartments',
            'attribute' => 'allowableCompartment_refs',
            'array' => 1,
            'clearer' => 'clear_allowableCompartments',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compartment',
            'method' => 'compartments',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          },
          {
            'parent' => 'Biochemistry',
            'name' => 'targetedreactions',
            'attribute' => 'targetedreaction_refs',
            'array' => 1,
            'clearer' => 'clear_targetedreactions',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Reaction',
            'method' => 'reactions',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          },
          {
            'attribute' => 'media_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_media',
            'name' => 'media',
            'method' => 'Media',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media',
            'module' => 'KBaseBiochem'
          },
          {
            'attribute' => 'probanno_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_probanno',
            'name' => 'probanno',
            'method' => 'ProbAnno',
            'class' => 'Bio::KBase::ObjectAPI::ProbabilisticAnnotation::ProbAnno',
            'module' => 'ProbabilisticAnnotation'
          },
          {
            'attribute' => 'fba_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_fba',
            'name' => 'fba',
            'method' => 'FBA',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::FBA',
            'module' => 'KBaseFBA'
          },
          {
            'attribute' => 'fbamodel_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_fbamodel',
            'name' => 'fbamodel',
            'method' => 'FBAModel',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::FBAModel',
            'module' => 'KBaseFBA'
          },
          {
            'parent' => 'Biochemistry',
            'name' => 'guaranteedReactions',
            'attribute' => 'guaranteedReaction_refs',
            'array' => 1,
            'clearer' => 'clear_guaranteedReactions',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Reaction',
            'method' => 'reactions',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          },
          {
            'parent' => 'Biochemistry',
            'name' => 'blacklistedReactions',
            'attribute' => 'blacklistedReaction_refs',
            'array' => 1,
            'clearer' => 'clear_blacklistedReactions',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Reaction',
            'method' => 'reactions',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          }
        ];

my $link_map = {allowableCompartments => 0, targetedreactions => 1, media => 2, probanno => 3, fba => 4, fbamodel => 5, guaranteedReactions => 6, blacklistedReactions => 7};
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
            'printOrder' => 0,
            'name' => 'gapfillingSolutions',
            'default' => undef,
            'description' => undef,
            'class' => 'GapfillingSolution',
            'type' => 'child',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {gapfillingSolutions => 0};
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
around 'gapfillingSolutions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gapfillingSolutions');
};


__PACKAGE__->meta->make_immutable;
1;
