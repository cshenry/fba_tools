########################################################################
# Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSimulationSet - This is the moose object corresponding to the KBasePhenotypes.PhenotypeSimulationSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSimulationSet;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulation;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has phenotypeset_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has fbamodel_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has phenotypeSimulations => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(PhenotypeSimulation)', metaclass => 'Typed', reader => '_phenotypeSimulations', printOrder => '-1');


# LINKS:
has phenotypeset => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,PhenotypeSet,phenotypeset_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_phenotypeset', clearer => 'clear_phenotypeset', isa => 'Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSet', weak_ref => 1);
has fbamodel => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,FBAModel,fbamodel_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fbamodel', clearer => 'clear_fbamodel', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::FBAModel', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_phenotypeset {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->phenotypeset_ref());
}
sub _build_fbamodel {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fbamodel_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBasePhenotypes.PhenotypeSimulationSet'; }
sub _module { return 'KBasePhenotypes'; }
sub _class { return 'PhenotypeSimulationSet'; }
sub _top { return 1; }

my $attributes = [
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
            'name' => 'fbamodel_ref',
            'type' => 'Str',
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

my $attribute_map = {phenotypeset_ref => 0, fbamodel_ref => 1, id => 2};
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
            'attribute' => 'phenotypeset_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_phenotypeset',
            'name' => 'phenotypeset',
            'method' => 'PhenotypeSet',
            'class' => 'Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSet',
            'module' => 'KBasePhenotypes'
          },
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

my $link_map = {phenotypeset => 0, fbamodel => 1};
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
            'name' => 'phenotypeSimulations',
            'type' => 'child',
            'class' => 'PhenotypeSimulation',
            'module' => 'KBasePhenotypes'
          }
        ];

my $subobject_map = {phenotypeSimulations => 0};
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
around 'phenotypeSimulations' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('phenotypeSimulations');
};


__PACKAGE__->meta->make_immutable;
1;
