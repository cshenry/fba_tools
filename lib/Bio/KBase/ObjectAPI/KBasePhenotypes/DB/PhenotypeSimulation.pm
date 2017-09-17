########################################################################
# Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSimulation - This is the moose object corresponding to the KBasePhenotypes.PhenotypeSimulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSimulation;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has gapfilledReactions => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has phenotype_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has numGapfilledReactions => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed', default => 0);
has simulatedGrowth => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has simulatedGrowthFraction => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has phenoclass => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has fluxes => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');

# LINKS:
has phenotype => (is => 'rw', type => 'link(PhenotypeSet,phenotypes,phenotype_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_phenotype', clearer => 'clear_phenotype', isa => 'Bio::KBase::ObjectAPI::KBasePhenotypes::Phenotype', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/phenotypeSimulations/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_phenotype {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->phenotype_ref());
}


# CONSTANTS:
sub _type { return 'KBasePhenotypes.PhenotypeSimulation'; }
sub _module { return 'KBasePhenotypes'; }
sub _class { return 'PhenotypeSimulation'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gapfilledReactions',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'phenotype_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'numGapfilledReactions',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'simulatedGrowth',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'simulatedGrowthFraction',
            'type' => 'Num',
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
            'name' => 'phenoclass',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'fluxes',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {gapfilledReactions => 0, phenotype_ref => 1, numGapfilledReactions => 2, simulatedGrowth => 3, simulatedGrowthFraction => 4, id => 5, phenoclass => 6,fluxes => 7};
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
            'parent' => 'PhenotypeSet',
            'name' => 'phenotype',
            'attribute' => 'phenotype_ref',
            'clearer' => 'clear_phenotype',
            'class' => 'Bio::KBase::ObjectAPI::KBasePhenotypes::Phenotype',
            'method' => 'phenotypes',
            'module' => 'KBasePhenotypes',
            'field' => 'id'
          }
        ];

my $link_map = {phenotype => 0};
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
