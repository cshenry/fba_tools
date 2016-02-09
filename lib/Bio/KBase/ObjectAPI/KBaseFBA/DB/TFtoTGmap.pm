########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::TFtoTGmap - This is the moose object corresponding to the KBaseFBA.TFtoTGmap object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::TFtoTGmap;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseFBA::TargetGeneProbabilities;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has transcriptionFactor_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has targetGeneProbs => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TargetGeneProbabilities)', metaclass => 'Typed', reader => '_targetGeneProbs', printOrder => '-1');


# LINKS:


# BUILDERS:


# CONSTANTS:
sub _type { return 'KBaseFBA.TFtoTGmap'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'TFtoTGmap'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'transcriptionFactor_ref',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {transcriptionFactor_ref => 0};
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
            'name' => 'targetGeneProbs',
            'type' => 'child',
            'class' => 'TargetGeneProbabilities',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {targetGeneProbs => 0};
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
around 'targetGeneProbs' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('targetGeneProbs');
};


__PACKAGE__->meta->make_immutable;
1;
