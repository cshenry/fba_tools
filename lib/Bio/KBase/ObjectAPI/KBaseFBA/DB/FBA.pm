########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::FBA - This is the moose object corresponding to the KBaseFBA.FBA object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::FBA;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAMetaboliteProductionResult;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAReactionBound;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAPromResult;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAMinimalMediaResult;
use Bio::KBase::ObjectAPI::KBaseFBA::FBABiomassVariable;
use Bio::KBase::ObjectAPI::KBaseFBA::FBACompoundBound;
use Bio::KBase::ObjectAPI::KBaseFBA::QuantitativeOptimizationSolution;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAMinimalReactionsResult;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAConstraint;
use Bio::KBase::ObjectAPI::KBaseFBA::FBACompoundVariable;
use Bio::KBase::ObjectAPI::KBaseFBA::FBATintleResult;
use Bio::KBase::ObjectAPI::KBaseFBA::FBADeletionResult;
use Bio::KBase::ObjectAPI::KBaseFBA::GapfillingSolution;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAReactionVariable;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has media_ref => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has compoundflux_objterms => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has phenotypesimulationset_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has maximizeObjective => (is => 'rw', isa => 'Bool', printOrder => '-1', required => 1, default => '1', type => 'attribute', metaclass => 'Typed');
has jobnode => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has promconstraint_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has phenotypeset_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has geneKO_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has inputfiles => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has drainfluxUseVariables => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has quantitativeOptimization => (is => 'rw', isa => 'Bool', printOrder => '-1', type => 'attribute', metaclass => 'Typed',default => "0");
has additionalCpd_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has outputfiles => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has parameters => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has noErrorThermodynamicConstraints => (is => 'rw', isa => 'Bool', printOrder => '17', default => '1', type => 'attribute', metaclass => 'Typed');
has objectiveConstraintFraction => (is => 'rw', isa => 'Num', printOrder => '0', default => 'none', type => 'attribute', metaclass => 'Typed');
has regulome_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has minimize_reactions => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has minimizeErrorThermodynamicConstraints => (is => 'rw', isa => 'Bool', printOrder => '18', default => '1', type => 'attribute', metaclass => 'Typed');
has uptakeLimits => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has allReversible => (is => 'rw', isa => 'Bool', printOrder => '14', default => '0', type => 'attribute', metaclass => 'Typed');
has tintleKappa => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has objectiveValue => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has minimize_reaction_costs => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has numberOfSolutions => (is => 'rw', isa => 'Int', printOrder => '23', default => '1', type => 'attribute', metaclass => 'Typed');
has fluxMinimization => (is => 'rw', isa => 'Bool', printOrder => '12', default => '0', type => 'attribute', metaclass => 'Typed');
has thermodynamicConstraints => (is => 'rw', isa => 'Bool', printOrder => '16', default => '1', type => 'attribute', metaclass => 'Typed');
has defaultMaxDrainFlux => (is => 'rw', isa => 'Num', printOrder => '22', required => 1, default => '1000', type => 'attribute', metaclass => 'Typed');
has reactionflux_objterms => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has fbamodel_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has tintleW => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has reactionKO_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has fluxUseVariables => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has findMinimalMedia => (is => 'rw', isa => 'Bool', printOrder => '13', default => '0', type => 'attribute', metaclass => 'Typed');
has PROMKappa => (is => 'rw', isa => 'Num', printOrder => '19', default => '1', type => 'attribute', metaclass => 'Typed');
has simpleThermoConstraints => (is => 'rw', isa => 'Bool', printOrder => '15', default => '1', type => 'attribute', metaclass => 'Typed');
has comboDeletions => (is => 'rw', isa => 'Int', printOrder => '11', default => '0', type => 'attribute', metaclass => 'Typed');
has defaultMinDrainFlux => (is => 'rw', isa => 'Num', printOrder => '21', required => 1, default => '-1000', type => 'attribute', metaclass => 'Typed');
has expression_matrix_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has fva => (is => 'rw', isa => 'Bool', printOrder => '10', default => '0', type => 'attribute', metaclass => 'Typed');
has decomposeReversibleDrainFlux => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassflux_objterms => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has defaultMaxFlux => (is => 'rw', isa => 'Num', printOrder => '20', required => 1, default => '1000', type => 'attribute', metaclass => 'Typed');
has decomposeReversibleFlux => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has calculateReactionKnockoutSensitivity => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has maximizeActiveReactions => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassRemovals => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has expression_matrix_column => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has MFALog => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');

# SUBOBJECTS:
has FBAMetaboliteProductionResults => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAMetaboliteProductionResult)', metaclass => 'Typed', reader => '_FBAMetaboliteProductionResults', printOrder => '-1');
has FBAReactionBounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAReactionBound)', metaclass => 'Typed', reader => '_FBAReactionBounds', printOrder => '-1');
has FBAPromResults => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAPromResult)', metaclass => 'Typed', reader => '_FBAPromResults', printOrder => '-1');
has FBAMinimalMediaResults => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAMinimalMediaResult)', metaclass => 'Typed', reader => '_FBAMinimalMediaResults', printOrder => '-1');
has FBABiomassVariables => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBABiomassVariable)', metaclass => 'Typed', reader => '_FBABiomassVariables', printOrder => '-1');
has FBACompoundBounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBACompoundBound)', metaclass => 'Typed', reader => '_FBACompoundBounds', printOrder => '-1');
has QuantitativeOptimizationSolutions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(QuantitativeOptimizationSolution)', metaclass => 'Typed', reader => '_QuantitativeOptimizationSolutions', printOrder => '-1');
has FBAMinimalReactionsResults => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAMinimalReactionsResult)', metaclass => 'Typed', reader => '_FBAMinimalReactionsResults', printOrder => '-1');
has FBAConstraints => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAConstraint)', metaclass => 'Typed', reader => '_FBAConstraints', printOrder => '-1');
has FBACompoundVariables => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBACompoundVariable)', metaclass => 'Typed', reader => '_FBACompoundVariables', printOrder => '-1');
has FBATintleResults => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBATintleResult)', metaclass => 'Typed', reader => '_FBATintleResults', printOrder => '-1');
has FBADeletionResults => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBADeletionResult)', metaclass => 'Typed', reader => '_FBADeletionResults', printOrder => '-1');
has gapfillingSolutions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(GapfillingSolution)', metaclass => 'Typed', reader => '_gapfillingSolutions', printOrder => '-1');
has FBAReactionVariables => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(FBAReactionVariable)', metaclass => 'Typed', reader => '_FBAReactionVariables', printOrder => '-1');


# LINKS:
has media => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Media,media_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_media', clearer => 'clear_media', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media', weak_ref => 1);
has phenotypesimulationset => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,PhenotypeSimulationSet,phenotypesimulationset_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_phenotypesimulationset', clearer => 'clear_phenotypesimulationset', isa => 'Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulationSet', weak_ref => 1);
has promconstraint => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,PromConstraint,promconstraint_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_promconstraint', clearer => 'clear_promconstraint', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::PromConstraint', weak_ref => 1);
has phenotypeset => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,PhenotypeSet,phenotypeset_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_phenotypeset', clearer => 'clear_phenotypeset', isa => 'Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSet', weak_ref => 1);
has geneKOs => (is => 'rw', type => 'link(Genome,features,geneKO_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_geneKOs', clearer => 'clear_geneKOs', isa => 'ArrayRef');
has additionalCpds => (is => 'rw', type => 'link(FBAModel,modelcompounds,additionalCpd_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_additionalCpds', clearer => 'clear_additionalCpds', isa => 'ArrayRef');
has regulome => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Regulome,regulome_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_regulome', clearer => 'clear_regulome', isa => 'Bio::KBase::ObjectAPI::KBaseRegulation::Regulome', weak_ref => 1);
has fbamodel => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,FBAModel,fbamodel_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fbamodel', clearer => 'clear_fbamodel', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::FBAModel', weak_ref => 1);
has reactionKOs => (is => 'rw', type => 'link(FBAModel,modelreactions,reactionKO_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_reactionKOs', clearer => 'clear_reactionKOs', isa => 'ArrayRef');
has expression_matrix => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,ExpressionMatrix,expression_matrix_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_expression_matrix', clearer => 'clear_expression_matrix', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_media {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->media_ref());
}
sub _build_phenotypesimulationset {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->phenotypesimulationset_ref());
}
sub _build_promconstraint {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->promconstraint_ref());
}
sub _build_phenotypeset {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->phenotypeset_ref());
}
sub _build_geneKOs {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->geneKO_refs());
}
sub _build_additionalCpds {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->additionalCpd_refs());
}
sub _build_regulome {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->regulome_ref());
}
sub _build_fbamodel {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fbamodel_ref());
}
sub _build_reactionKOs {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->reactionKO_refs());
}
sub _build_expression_matrix {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->expression_matrix_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseFBA.FBA'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'FBA'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'media_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'compoundflux_objterms',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'phenotypesimulationset_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'maximizeObjective',
            'default' => 1,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'jobnode',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'promconstraint_ref',
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
            'name' => 'phenotypeset_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'geneKO_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'inputfiles',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'drainfluxUseVariables',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'quantitativeOptimization',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'additionalCpd_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'outputfiles',
            'default' => 'sub{return [];}',
            'type' => 'HashRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'parameters',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 17,
            'name' => 'noErrorThermodynamicConstraints',
            'default' => 1,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'objectiveConstraintFraction',
            'default' => 'none',
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'regulome_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'minimize_reactions',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 18,
            'name' => 'minimizeErrorThermodynamicConstraints',
            'default' => 1,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'uptakeLimits',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 14,
            'name' => 'allReversible',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'tintleKappa',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'objectiveValue',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'minimize_reaction_costs',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 23,
            'name' => 'numberOfSolutions',
            'default' => 1,
            'type' => 'Int',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => undef,
            'printOrder' => 12,
            'name' => 'fluxMinimization',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 16,
            'name' => 'thermodynamicConstraints',
            'default' => 1,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 22,
            'name' => 'defaultMaxDrainFlux',
            'default' => 1000,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reactionflux_objterms',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
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
            'name' => 'tintleW',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reactionKO_refs',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'fluxUseVariables',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => undef,
            'printOrder' => 13,
            'name' => 'findMinimalMedia',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 19,
            'name' => 'PROMKappa',
            'default' => 1,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 15,
            'name' => 'simpleThermoConstraints',
            'default' => 1,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => undef,
            'printOrder' => 11,
            'name' => 'comboDeletions',
            'default' => 0,
            'type' => 'Int',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 21,
            'name' => 'defaultMinDrainFlux',
            'default' => -1000,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'expression_matrix_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => undef,
            'printOrder' => 10,
            'name' => 'fva',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'decomposeReversibleDrainFlux',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'biomassflux_objterms',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 20,
            'name' => 'defaultMaxFlux',
            'default' => 1000,
            'type' => 'Num',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'decomposeReversibleFlux',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'calculateReactionKnockoutSensitivity',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'maximizeActiveReactions',
            'default' => 0,
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'biomassRemovals',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'expression_matrix_column',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'MFALog',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {media_ref => 0, compoundflux_objterms => 1, phenotypesimulationset_ref => 2, maximizeObjective => 3, jobnode => 4, promconstraint_ref => 5, id => 6, phenotypeset_ref => 7, geneKO_refs => 8, inputfiles => 9, drainfluxUseVariables => 10, quantitativeOptimization => 11, additionalCpd_refs => 12, outputfiles => 13, parameters => 14, noErrorThermodynamicConstraints => 15, objectiveConstraintFraction => 16, regulome_ref => 17, minimize_reactions => 18, minimizeErrorThermodynamicConstraints => 19, uptakeLimits => 20, allReversible => 21, tintleKappa => 22, objectiveValue => 23, minimize_reaction_costs => 24, numberOfSolutions => 25, fluxMinimization => 26, thermodynamicConstraints => 27, defaultMaxDrainFlux => 28, reactionflux_objterms => 29, fbamodel_ref => 30, tintleW => 31, reactionKO_refs => 32, fluxUseVariables => 33, findMinimalMedia => 34, PROMKappa => 35, simpleThermoConstraints => 36, comboDeletions => 37, defaultMinDrainFlux => 38, expression_matrix_ref => 39, fva => 40, decomposeReversibleDrainFlux => 41, biomassflux_objterms => 42, defaultMaxFlux => 43, decomposeReversibleFlux => 44,calculateReactionKnockoutSensitivity => 45,maximizeActiveReactions => 46,biomassRemovals => 47,expression_matrix_column => 48,MFALog => 49};
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
            'attribute' => 'media_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_media',
            'name' => 'media',
            'method' => 'Media',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media',
            'module' => 'KBaseBiochem'
          },
          {
            'attribute' => 'phenotypesimulationset_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_phenotypesimulationset',
            'name' => 'phenotypesimulationset',
            'method' => 'PhenotypeSimulationSet',
            'class' => 'Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulationSet',
            'module' => 'KBasePhenotypes'
          },
          {
            'attribute' => 'promconstraint_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_promconstraint',
            'name' => 'promconstraint',
            'method' => 'PromConstraint',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::PromConstraint',
            'module' => 'KBaseFBA'
          },
          {
            'attribute' => 'phenotypeset_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_phenotypeset',
            'name' => 'phenotypeset',
            'method' => 'PhenotypeSet',
            'class' => 'Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSet',
            'module' => 'KBasePhenotypes'
          },
          {
            'parent' => 'Genome',
            'name' => 'geneKOs',
            'attribute' => 'geneKO_refs',
            'array' => 1,
            'clearer' => 'clear_geneKOs',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::Feature',
            'method' => 'features',
            'module' => 'KBaseGenomes',
            'field' => 'id'
          },
          {
            'parent' => 'FBAModel',
            'name' => 'additionalCpds',
            'attribute' => 'additionalCpd_refs',
            'array' => 1,
            'clearer' => 'clear_additionalCpds',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound',
            'method' => 'modelcompounds',
            'module' => 'KBaseFBA',
            'field' => 'id'
          },
          {
            'attribute' => 'regulome_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_regulome',
            'name' => 'regulome',
            'method' => 'Regulome',
            'class' => 'Bio::KBase::ObjectAPI::KBaseRegulation::Regulome',
            'module' => 'KBaseRegulation'
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
            'parent' => 'FBAModel',
            'name' => 'reactionKOs',
            'attribute' => 'reactionKO_refs',
            'array' => 1,
            'clearer' => 'clear_reactionKOs',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction',
            'method' => 'modelreactions',
            'module' => 'KBaseFBA',
            'field' => 'id'
          },
          {
            'attribute' => 'expression_matrix_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_expression_matrix',
            'name' => 'expression_matrix',
            'method' => 'ExpressionMatrix',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFeatureValue::ExpressionMatrix',
            'module' => 'KBaseFeatureValue'
          }
        ];

my $link_map = {media => 0, phenotypesimulationset => 1, promconstraint => 2, phenotypeset => 3, geneKOs => 4, additionalCpds => 5, regulome => 6, fbamodel => 7, reactionKOs => 8, expression_matrix => 9};
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
            'name' => 'FBAMetaboliteProductionResults',
            'type' => 'child',
            'class' => 'FBAMetaboliteProductionResult',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBAReactionBounds',
            'type' => 'child',
            'class' => 'FBAReactionBound',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBAPromResults',
            'type' => 'child',
            'class' => 'FBAPromResult',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBAMinimalMediaResults',
            'type' => 'child',
            'class' => 'FBAMinimalMediaResult',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBABiomassVariables',
            'type' => 'child',
            'class' => 'FBABiomassVariable',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBACompoundBounds',
            'type' => 'child',
            'class' => 'FBACompoundBound',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'QuantitativeOptimizationSolutions',
            'type' => 'child',
            'class' => 'QuantitativeOptimizationSolution',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBAMinimalReactionsResults',
            'type' => 'child',
            'class' => 'FBAMinimalReactionsResult',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBAConstraints',
            'type' => 'child',
            'class' => 'FBAConstraint',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBACompoundVariables',
            'type' => 'child',
            'class' => 'FBACompoundVariable',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBATintleResults',
            'type' => 'child',
            'class' => 'FBATintleResult',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBADeletionResults',
            'type' => 'child',
            'class' => 'FBADeletionResult',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'gapfillingSolutions',
            'type' => 'child',
            'class' => 'GapfillingSolution',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'FBAReactionVariables',
            'type' => 'child',
            'class' => 'FBAReactionVariable',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {FBAMetaboliteProductionResults => 0, FBAReactionBounds => 1, FBAPromResults => 2, FBAMinimalMediaResults => 3, FBABiomassVariables => 4, FBACompoundBounds => 5, QuantitativeOptimizationSolutions => 6, FBAMinimalReactionsResults => 7, FBAConstraints => 8, FBACompoundVariables => 9, FBATintleResults => 10, FBADeletionResults => 11, gapfillingSolutions => 12, FBAReactionVariables => 13};
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
around 'FBAMetaboliteProductionResults' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBAMetaboliteProductionResults');
};
around 'FBAReactionBounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBAReactionBounds');
};
around 'FBAPromResults' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBAPromResults');
};
around 'FBAMinimalMediaResults' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBAMinimalMediaResults');
};
around 'FBABiomassVariables' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBABiomassVariables');
};
around 'FBACompoundBounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBACompoundBounds');
};
around 'QuantitativeOptimizationSolutions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('QuantitativeOptimizationSolutions');
};
around 'FBAMinimalReactionsResults' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBAMinimalReactionsResults');
};
around 'FBAConstraints' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBAConstraints');
};
around 'FBACompoundVariables' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBACompoundVariables');
};
around 'FBATintleResults' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBATintleResults');
};
around 'FBADeletionResults' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBADeletionResults');
};
around 'gapfillingSolutions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gapfillingSolutions');
};
around 'FBAReactionVariables' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('FBAReactionVariables');
};


__PACKAGE__->meta->make_immutable;
1;
