########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelTemplate - This is the moose object corresponding to the KBaseFBA.ModelTemplate object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelTemplate;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomass;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplatePathway;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompound;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompCompound;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateSubsystem;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompartment;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateReaction;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateRole;
use Bio::KBase::ObjectAPI::KBaseFBA::TemplateComplex;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has biochemistry_ref => (is => 'rw', isa => 'Str', printOrder => '-1', default => 'kbase/default', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has domain => (is => 'rw', isa => 'Str', printOrder => '2', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has biomasses => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateBiomass)', metaclass => 'Typed', reader => '_biomasses', printOrder => '-1');
has pathways => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplatePathway)', metaclass => 'Typed', reader => '_pathways', printOrder => '-1');
has compounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateCompound)', metaclass => 'Typed', reader => '_compounds', printOrder => '-1');
has compcompounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateCompCompound)', metaclass => 'Typed', reader => '_compcompounds', printOrder => '-1');
has subsystems => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateSubsystem)', metaclass => 'Typed', reader => '_subsystems', printOrder => '-1');
has compartments => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateCompartment)', metaclass => 'Typed', reader => '_compartments', printOrder => '-1');
has reactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateReaction)', metaclass => 'Typed', reader => '_reactions', printOrder => '-1');
has roles => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateRole)', metaclass => 'Typed', reader => '_roles', printOrder => '-1');
has complexes => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateComplex)', metaclass => 'Typed', reader => '_complexes', printOrder => '-1');


# LINKS:
has biochemistry => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Biochemistry,biochemistry_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_biochemistry', clearer => 'clear_biochemistry', isa => 'Ref', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_biochemistry {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->biochemistry_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseFBA.ModelTemplate'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'ModelTemplate'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'perm' => 'rw',
            'name' => 'biochemistry_ref',
            'printOrder' => -1,
            'default' => 'kbase/default',
            'type' => 'Str'
          },
          {
            'perm' => 'rw',
            'name' => 'id',
            'printOrder' => 0,
            'type' => 'Str',
            'req' => 1
          },
          {
            'name' => 'type',
            'printOrder' => -1,
            'perm' => 'rw',
            'type' => 'Str',
            'req' => 0
          },
          {
            'req' => 1,
            'default' => undef,
            'type' => 'Str',
            'perm' => 'rw',
            'description' => undef,
            'printOrder' => 1,
            'name' => 'name'
          },
          {
            'description' => undef,
            'perm' => 'rw',
            'name' => 'domain',
            'printOrder' => 2,
            'default' => undef,
            'type' => 'Str',
            'req' => 1
          }
        ];

my $attribute_map = {biochemistry_ref => 0, id => 1, type => 2, name => 3, domain => 4};
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
            'attribute' => 'biochemistry_ref',
            'class' => 'Biochemistry',
            'module' => undef,
            'method' => 'Biochemistry',
            'clearer' => 'clear_biochemistry',
            'name' => 'biochemistry',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore'
          }
        ];

my $link_map = {biochemistry => 0};
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
            'class' => 'TemplateBiomass',
            'type' => 'child',
            'name' => 'biomasses',
            'printOrder' => -1
          },
          {
            'type' => 'child',
            'printOrder' => -1,
            'name' => 'pathways',
            'module' => 'KBaseFBA',
            'class' => 'TemplatePathway'
          },
          {
            'class' => 'TemplateCompound',
            'module' => 'KBaseFBA',
            'type' => 'child',
            'name' => 'compounds',
            'printOrder' => -1
          },
          {
            'class' => 'TemplateCompCompound',
            'module' => 'KBaseFBA',
            'name' => 'compcompounds',
            'printOrder' => -1,
            'type' => 'child'
          },
          {
            'class' => 'TemplateSubsystem',
            'module' => 'KBaseFBA',
            'type' => 'child',
            'name' => 'subsystems',
            'printOrder' => -1
          },
          {
            'class' => 'TemplateCompartment',
            'module' => 'KBaseFBA',
            'name' => 'compartments',
            'printOrder' => -1,
            'type' => 'child'
          },
          {
            'class' => 'TemplateReaction',
            'module' => 'KBaseFBA',
            'name' => 'reactions',
            'printOrder' => -1,
            'type' => 'child'
          },
          {
            'module' => 'KBaseFBA',
            'class' => 'TemplateRole',
            'name' => 'roles',
            'printOrder' => -1,
            'type' => 'child'
          },
          {
            'name' => 'complexes',
            'printOrder' => -1,
            'type' => 'child',
            'class' => 'TemplateComplex',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {biomasses => 0, pathways => 1, compounds => 2, compcompounds => 3, subsystems => 4, compartments => 5, reactions => 6, roles => 7, complexes => 8};
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
around 'pathways' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('pathways');
};
around 'compounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('compounds');
};
around 'compcompounds' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('compcompounds');
};
around 'subsystems' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('subsystems');
};
around 'compartments' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('compartments');
};
around 'reactions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('reactions');
};
around 'roles' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('roles');
};
around 'complexes' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('complexes');
};


__PACKAGE__->meta->make_immutable;
1;
