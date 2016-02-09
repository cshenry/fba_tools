########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::DB::RegulatorySite - This is the moose object corresponding to the KBaseRegulation.RegulatorySite object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseRegulation::DB::RegulatorySite;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseRegulation::Evidence;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has regulatory_mechanism => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has sequence => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has position => (is => 'rw', isa => 'Int', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has score => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has regulatory_site_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has evidesnces => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Evidence)', metaclass => 'Typed', reader => '_evidesnces', printOrder => '-1');


# LINKS:


# BUILDERS:


# CONSTANTS:
sub _type { return 'KBaseRegulation.RegulatorySite'; }
sub _module { return 'KBaseRegulation'; }
sub _class { return 'RegulatorySite'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'regulatory_mechanism',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'sequence',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'position',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'score',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'regulatory_site_id',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {regulatory_mechanism => 0, sequence => 1, position => 2, score => 3, regulatory_site_id => 4};
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
          }
        ];

my $subobject_map = {evidesnces => 0};
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


__PACKAGE__->meta->make_immutable;
1;
