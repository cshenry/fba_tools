########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelGapfill - This is the moose object corresponding to the KBaseFBA.ModelGapfill object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelGapfill;
use Bio::KBase::ObjectAPI::BaseObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has gapfill_id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has media_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has integrated => (is => 'rw', isa => 'Bool', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has jobnode => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has integrated_solution => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has gapfill_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has fba_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has media => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Media,media_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_media', clearer => 'clear_media', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media', weak_ref => 1);
has gapfill => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Gapfilling,gapfill_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_gapfill', clearer => 'clear_gapfill', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::Gapfilling', weak_ref => 1);
has fba => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,FBA,fba_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fba', clearer => 'clear_fba', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::FBA', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->parent()->_reference().'/gapfillings/id/'.$self->id(); }
sub _build_uuid { my ($self) = @_;return $self->_reference(); }
sub _build_media {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->media_ref());
}
sub _build_gapfill {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->gapfill_ref());
}
sub _build_fba {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fba_ref());
}


# CONSTANTS:
sub _type { return 'KBaseFBA.ModelGapfill'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'ModelGapfill'; }
sub _top { return 0; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'gapfill_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
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
            'name' => 'integrated',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'jobnode',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'integrated_solution',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'gapfill_ref',
            'type' => 'Str',
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
            'name' => 'fba_ref',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {gapfill_id => 0, media_ref => 1, integrated => 2, jobnode => 3, integrated_solution => 4, gapfill_ref => 5, id => 6, fba_ref => 7};
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
            'attribute' => 'gapfill_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_gapfill',
            'name' => 'gapfill',
            'method' => 'Gapfilling',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::Gapfilling',
            'module' => 'KBaseFBA'
          },
          {
            'attribute' => 'fba_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_fba',
            'name' => 'fba',
            'method' => 'FBA',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::FBA',
            'module' => 'KBaseFBA'
          }
        ];

my $link_map = {media => 0, gapfill => 1, fba => 2};
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
