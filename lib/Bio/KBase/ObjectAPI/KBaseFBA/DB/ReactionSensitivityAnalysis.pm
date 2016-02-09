########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::ReactionSensitivityAnalysis - This is the moose object corresponding to the KBaseFBA.ReactionSensitivityAnalysis object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::ReactionSensitivityAnalysis;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseFBA::ReactionSensitivityAnalysisCorrectedReaction;
use Bio::KBase::ObjectAPI::KBaseFBA::ReactionSensitivityAnalysisReaction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has fbamodel_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has integrated_deletions_in_model => (is => 'rw', isa => 'Bool', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has deleted_noncontributing_reactions => (is => 'rw', isa => 'Bool', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has corrected_reactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ReactionSensitivityAnalysisCorrectedReaction)', metaclass => 'Typed', reader => '_corrected_reactions', printOrder => '-1');
has reactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ReactionSensitivityAnalysisReaction)', metaclass => 'Typed', reader => '_reactions', printOrder => '-1');


# LINKS:
has fbamodel => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,FBAModel,fbamodel_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fbamodel', clearer => 'clear_fbamodel', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::FBAModel', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_fbamodel {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fbamodel_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseFBA.ReactionSensitivityAnalysis'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'ReactionSensitivityAnalysis'; }
sub _top { return 1; }

my $attributes = [
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
            'name' => 'integrated_deletions_in_model',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'deleted_noncontributing_reactions',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'type',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {fbamodel_ref => 0, integrated_deletions_in_model => 1, deleted_noncontributing_reactions => 2, id => 3, type => 4};
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
            'attribute' => 'fbamodel_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_fbamodel',
            'name' => 'fbamodel',
            'method' => 'FBAModel',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::FBAModel',
            'module' => 'KBaseFBA'
          }
        ];

my $link_map = {fbamodel => 0};
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
            'name' => 'corrected_reactions',
            'type' => 'child',
            'class' => 'ReactionSensitivityAnalysisCorrectedReaction',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'reactions',
            'type' => 'child',
            'class' => 'ReactionSensitivityAnalysisReaction',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {corrected_reactions => 0, reactions => 1};
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
around 'corrected_reactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('corrected_reactions');
};
around 'reactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('reactions');
};


__PACKAGE__->meta->make_immutable;
1;
