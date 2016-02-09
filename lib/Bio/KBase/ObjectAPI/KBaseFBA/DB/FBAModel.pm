########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAModel - This is the moose object corresponding to the KBaseFBA.FBAModel object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAModel;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseFBA::Biomass;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelQuantOpt;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelGapgen;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelCompartment;
use Bio::KBase::ObjectAPI::KBaseFBA::ModelGapfill;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has source => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has template_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has ATPMaintenance => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has ATPSynthaseStoichiometry => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has metagenome_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has genome_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has template_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has source_id => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');
has metagenome_otu_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '5', default => 'Singlegenome', type => 'attribute', metaclass => 'Typed');
has rxnprobs_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has biomasses => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Biomass)', metaclass => 'Typed', reader => '_biomasses', printOrder => '0');
has quantopts => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelQuantOpt)', metaclass => 'Typed', reader => '_quantopts', printOrder => '-1');
has gapgens => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelGapgen)', metaclass => 'Typed', reader => '_gapgens', printOrder => '-1');
has modelcompounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelCompound)', metaclass => 'Typed', reader => '_modelcompounds', printOrder => '2');
has modelreactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelReaction)', metaclass => 'Typed', reader => '_modelreactions', printOrder => '3');
has modelcompartments => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelCompartment)', metaclass => 'Typed', reader => '_modelcompartments', printOrder => '1');
has gapfillings => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelGapfill)', metaclass => 'Typed', reader => '_gapfillings', printOrder => '-1');
has gapfilledcandidates => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelReaction)', metaclass => 'Typed', reader => '_gapfilledcandidates', printOrder => '3');


# LINKS:
has templates => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::Util::KBaseStore,ModelTemplate,template_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_templates', clearer => 'clear_templates', isa => 'ArrayRef');
has metagenome => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,MetagenomeAnnotation,metagenome_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_metagenome', clearer => 'clear_metagenome', isa => 'Bio::KBase::ObjectAPI::KBaseGenomes::MetagenomeAnnotation', weak_ref => 1);
has genome => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Genome,genome_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_genome', clearer => 'clear_genome', isa => 'Bio::KBase::ObjectAPI::KBaseGenomes::Genome', weak_ref => 1);
has template => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,ModelTemplate,template_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_template', clearer => 'clear_template', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate', weak_ref => 1);
has metagenome_otu => (is => 'rw', type => 'link(MetagenomeAnnotation,otus,metagenome_otu_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_metagenome_otu', clearer => 'clear_metagenome_otu', isa => 'Bio::KBase::ObjectAPI::KBaseGenomes::MetagenomeAnnotationOTU', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_templates {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->template_refs());
}
sub _build_metagenome {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->metagenome_ref());
}
sub _build_genome {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->genome_ref());
}
sub _build_template {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->template_ref());
}
sub _build_metagenome_otu {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->metagenome_otu_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseFBA.FBAModel'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'FBAModel'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'source',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'template_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'ATPMaintenance',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'ATPSynthaseStoichiometry',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'id',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'metagenome_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'genome_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'template_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'source_id',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'name',
            'default' => '',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'metagenome_otu_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'type',
            'default' => 'Singlegenome',
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'rxnprobs_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
        ];

my $attribute_map = {source => 0, template_refs => 1, ATPMaintenance => 2, ATPSynthaseStoichiometry => 3, id => 4, metagenome_ref => 5, genome_ref => 6, template_ref => 7, source_id => 8, name => 9, metagenome_otu_ref => 10, type => 11, rxnprobs_ref => 12};
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
            'parent' => 'Bio::KBase::ObjectAPI::Util::KBaseStore',
            'name' => 'templates',
            'attribute' => 'template_refs',
            'array' => 1,
            'clearer' => 'clear_templates',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate',
            'method' => 'ModelTemplate',
            'module' => 'KBaseFBA'
          },
          {
            'attribute' => 'metagenome_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_metagenome',
            'name' => 'metagenome',
            'method' => 'MetagenomeAnnotation',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::MetagenomeAnnotation',
            'module' => 'KBaseGenomes'
          },
          {
            'attribute' => 'genome_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_genome',
            'name' => 'genome',
            'method' => 'Genome',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::Genome',
            'module' => 'KBaseGenomes'
          },
          {
            'attribute' => 'template_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_template',
            'name' => 'template',
            'method' => 'ModelTemplate',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate',
            'module' => 'KBaseFBA'
          },
          {
            'parent' => 'MetagenomeAnnotation',
            'name' => 'metagenome_otu',
            'attribute' => 'metagenome_otu_ref',
            'clearer' => 'clear_metagenome_otu',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::MetagenomeAnnotationOTU',
            'method' => 'otus',
            'module' => 'KBaseGenomes',
            'field' => 'id'
          }
        ];

my $link_map = {templates => 0, metagenome => 1, genome => 2, template => 3, metagenome_otu => 4};
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
            'name' => 'biomasses',
            'default' => undef,
            'description' => undef,
            'class' => 'Biomass',
            'type' => 'child',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'quantopts',
            'type' => 'child',
            'class' => 'ModelQuantOpt',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'gapgens',
            'type' => 'child',
            'class' => 'ModelGapgen',
            'module' => 'KBaseFBA'
          },
          {
            'req' => undef,
            'printOrder' => 2,
            'name' => 'modelcompounds',
            'default' => undef,
            'description' => undef,
            'class' => 'ModelCompound',
            'type' => 'child',
            'module' => 'KBaseFBA'
          },
          {
            'req' => undef,
            'printOrder' => 3,
            'name' => 'modelreactions',
            'default' => undef,
            'description' => undef,
            'class' => 'ModelReaction',
            'type' => 'child',
            'module' => 'KBaseFBA'
          },
          {
            'req' => undef,
            'printOrder' => 1,
            'name' => 'modelcompartments',
            'default' => undef,
            'description' => undef,
            'class' => 'ModelCompartment',
            'type' => 'child',
            'module' => 'KBaseFBA'
          },
          {
            'printOrder' => -1,
            'name' => 'gapfillings',
            'type' => 'child',
            'class' => 'ModelGapfill',
            'module' => 'KBaseFBA'
          },
          {
            'req' => undef,
            'printOrder' => 3,
            'name' => 'gapfilledcandidates',
            'default' => undef,
            'description' => undef,
            'class' => 'ModelReaction',
            'type' => 'child',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {biomasses => 0, quantopts => 1, gapgens => 2, modelcompounds => 3, modelreactions => 4, modelcompartments => 5, gapfillings => 6,gapfilledcandidates => 7};
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
around 'biomasses' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('biomasses');
};
around 'quantopts' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('quantopts');
};
around 'gapgens' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gapgens');
};
around 'modelcompounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('modelcompounds');
};
around 'modelreactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('modelreactions');
};
around 'modelcompartments' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('modelcompartments');
};
around 'gapfillings' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gapfillings');
};
around 'gapfilledcandidates' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gapfilledcandidates');
};


__PACKAGE__->meta->make_immutable;
1;
