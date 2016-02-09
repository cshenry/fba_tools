########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::PromConstraint - This is the moose object corresponding to the KBaseFBA.PromConstraint object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::PromConstraint;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseFBA::TFtoTGmap;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has genome_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has expression_series_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has regulome_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has transcriptionFactorMaps => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TFtoTGmap)', metaclass => 'Typed', reader => '_transcriptionFactorMaps', printOrder => '-1');


# LINKS:
has genome => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Genome,genome_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_genome', clearer => 'clear_genome', isa => 'Bio::KBase::ObjectAPI::KBaseGenomes::Genome', weak_ref => 1);
has expression_series => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,ExpressionSeries,expression_series_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_expression_series', clearer => 'clear_expression_series', isa => 'Bio::KBase::ObjectAPI::KBaseExpression::ExpressionSeries', weak_ref => 1);
has regulome => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Regulome,regulome_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_regulome', clearer => 'clear_regulome', isa => 'Bio::KBase::ObjectAPI::KBaseRegulation::Regulome', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_genome {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->genome_ref());
}
sub _build_expression_series {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->expression_series_ref());
}
sub _build_regulome {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->regulome_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseFBA.PromConstraint'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'PromConstraint'; }
sub _top { return 1; }

my $attributes = [
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
            'name' => 'expression_series_ref',
            'type' => 'Str',
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
            'name' => 'regulome_ref',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {genome_ref => 0, expression_series_ref => 1, id => 2, regulome_ref => 3};
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
            'attribute' => 'genome_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_genome',
            'name' => 'genome',
            'method' => 'Genome',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::Genome',
            'module' => 'KBaseGenomes'
          },
          {
            'attribute' => 'expression_series_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_expression_series',
            'name' => 'expression_series',
            'method' => 'ExpressionSeries',
            'class' => 'Bio::KBase::ObjectAPI::KBaseExpression::ExpressionSeries',
            'module' => 'KBaseExpression'
          },
          {
            'attribute' => 'regulome_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_regulome',
            'name' => 'regulome',
            'method' => 'Regulome',
            'class' => 'Bio::KBase::ObjectAPI::KBaseRegulation::Regulome',
            'module' => 'KBaseRegulation'
          }
        ];

my $link_map = {genome => 0, expression_series => 1, regulome => 2};
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
            'name' => 'transcriptionFactorMaps',
            'type' => 'child',
            'class' => 'TFtoTGmap',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {transcriptionFactorMaps => 0};
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
around 'transcriptionFactorMaps' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('transcriptionFactorMaps');
};


__PACKAGE__->meta->make_immutable;
1;
