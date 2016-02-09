########################################################################
# Bio::KBase::ObjectAPI::KBaseExpression::DB::GsmObject - This is the moose object corresponding to the KBaseExpression.GsmObject object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseExpression::DB::GsmObject;
use Bio::KBase::ObjectAPI::BaseObject;
use Bio::KBase::ObjectAPI::KBaseExpression::GPL;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has gsm_submission_date => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_title => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_sample_characteristics => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has gsm_description => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_errors => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has gsm_value_type => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_sample_organism => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_data => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has gsm_id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_contact_people => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');
has gsm_tax_id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_feature_mapping_approach => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_molecule => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gsm_warning => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has ontology_ids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has gsm_protocol => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has gsm_platform => (is => 'rw', singleton => 1, isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(GPL)', metaclass => 'Typed', reader => '_gsm_platform', printOrder => '-1');


# LINKS:


# BUILDERS:


# CONSTANTS:
sub _type { return 'KBaseExpression.GsmObject'; }
sub _module { return 'KBaseExpression'; }
sub _class { return 'GsmObject'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_submission_date',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_title',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_sample_characteristics',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_description',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_errors',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_value_type',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_sample_organism',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_data',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_contact_people',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_tax_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_feature_mapping_approach',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_molecule',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_warning',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'ontology_ids',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gsm_protocol',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {gsm_submission_date => 0, gsm_title => 1, gsm_sample_characteristics => 2, gsm_description => 3, gsm_errors => 4, gsm_value_type => 5, gsm_sample_organism => 6, gsm_data => 7, gsm_id => 8, gsm_contact_people => 9, gsm_tax_id => 10, gsm_feature_mapping_approach => 11, gsm_molecule => 12, gsm_warning => 13, ontology_ids => 14, gsm_protocol => 15};
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
            'name' => 'gsm_platform',
            'type' => 'child',
            'class' => 'GPL',
            'singleton' => 1,
            'module' => 'KBaseExpression'
          }
        ];

my $subobject_map = {gsm_platform => 0};
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
around 'gsm_platform' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gsm_platform');
};


__PACKAGE__->meta->make_immutable;
1;
