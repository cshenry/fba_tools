########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::DB::Regulon - This is the moose object corresponding to the KBaseRegulation.Regulon object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseRegulation::DB::Regulon;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseRegulation::Evidence;
use Bio::KBase::ObjectAPI::KBaseRegulation::TranscriptionFactor;
use Bio::KBase::ObjectAPI::KBaseRegulation::RegulatedOperon;
use Bio::KBase::ObjectAPI::KBaseRegulation::Regulator;
use Bio::KBase::ObjectAPI::KBaseRegulation::Effector;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has regulon_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has evidesnces => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Evidence)', metaclass => 'Typed', reader => '_evidesnces', printOrder => '-1');
has tfs => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TranscriptionFactor)', metaclass => 'Typed', reader => '_tfs', printOrder => '-1');
has operons => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(RegulatedOperon)', metaclass => 'Typed', reader => '_operons', printOrder => '-1');
has regulator => (is => 'rw', singleton => 1, isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Regulator)', metaclass => 'Typed', reader => '_regulator', printOrder => '-1');
has effectors => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Effector)', metaclass => 'Typed', reader => '_effectors', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/regulons/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }


# CONSTANTS:
sub _type { return 'KBaseRegulation.Regulon'; }
sub _module { return 'KBaseRegulation'; }
sub _class { return 'Regulon'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'regulon_id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {regulon_id => 0};
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

my $links = [];

my $link_map = {};
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
            'name' => 'evidesnces',
            'type' => 'child',
            'class' => 'Evidence',
            'module' => 'KBaseRegulation'
          },
          {
            'printOrder' => -1,
            'name' => 'tfs',
            'type' => 'child',
            'class' => 'TranscriptionFactor',
            'module' => 'KBaseRegulation'
          },
          {
            'printOrder' => -1,
            'name' => 'operons',
            'type' => 'child',
            'class' => 'RegulatedOperon',
            'module' => 'KBaseRegulation'
          },
          {
            'printOrder' => -1,
            'name' => 'regulator',
            'type' => 'child',
            'class' => 'Regulator',
            'singleton' => 1,
            'module' => 'KBaseRegulation'
          },
          {
            'printOrder' => -1,
            'name' => 'effectors',
            'type' => 'child',
            'class' => 'Effector',
            'module' => 'KBaseRegulation'
          }
        ];

my $subobject_map = {evidesnces => 0, tfs => 1, operons => 2, regulator => 3, effectors => 4};
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
around 'evidesnces' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('evidesnces');
};
around 'tfs' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('tfs');
};
around 'operons' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('operons');
};
around 'regulator' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('regulator');
};
around 'effectors' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('effectors');
};


__PACKAGE__->meta->make_immutable;
1;
