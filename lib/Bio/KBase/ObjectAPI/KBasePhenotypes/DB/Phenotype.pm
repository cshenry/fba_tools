########################################################################
# Bio::KBase::ObjectAPI::KBasePhenotypes::DB::Phenotype - This is the moose object corresponding to the KBasePhenotypes.Phenotype object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBasePhenotypes::DB::Phenotype;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has media_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has geneko_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has additionalcompound_refs => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub {return [];}, type => 'attribute', metaclass => 'Typed');
has normalizedGrowth => (is => 'rw', isa => 'Num', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has media => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Media,media_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_media', clearer => 'clear_media', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media', weak_ref => 1);
has genekos => (is => 'rw', type => 'link(Genome,features,geneko_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_genekos', clearer => 'clear_genekos', isa => 'ArrayRef');
has additionalcompounds => (is => 'rw', type => 'link(Biochemistry,compounds,additionalcompound_refs)', metaclass => 'Typed', lazy => 1, builder => '_build_additionalcompounds', clearer => 'clear_additionalcompounds', isa => 'ArrayRef');


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/phenotypes/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_media {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->media_ref());
}
sub _build_genekos {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->geneko_refs());
}
sub _build_additionalcompounds {
	 my ($self) = @_;
	 return $self->getLinkedObjectArray($self->additionalcompound_refs());
}


# CONSTANTS:
sub _type { return 'KBasePhenotypes.Phenotype'; }
sub _module { return 'KBasePhenotypes'; }
sub _class { return 'Phenotype'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'media_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'geneko_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
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
            'name' => 'additionalcompound_refs',
            'default' => 'sub {return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'normalizedGrowth',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {media_ref => 0, name => 1, geneko_refs => 2, id => 3, additionalcompound_refs => 4, normalizedGrowth => 5};
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
            'attribute' => 'media_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_media',
            'name' => 'media',
            'method' => 'Media',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media',
            'module' => 'KBaseBiochem'
          },
          {
            'parent' => 'Genome',
            'name' => 'genekos',
            'attribute' => 'geneko_refs',
            'array' => 1,
            'clearer' => 'clear_genekos',
            'class' => 'Bio::KBase::ObjectAPI::KBaseGenomes::Feature',
            'method' => 'features',
            'module' => 'KBaseGenomes',
            'field' => 'id'
          },
          {
            'parent' => 'Biochemistry',
            'name' => 'additionalcompounds',
            'attribute' => 'additionalcompound_refs',
            'array' => 1,
            'clearer' => 'clear_additionalcompounds',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Compound',
            'method' => 'compounds',
            'module' => 'KBaseBiochem',
            'field' => 'id'
          }
        ];

my $link_map = {media => 0, genekos => 1, additionalcompounds => 2};
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
