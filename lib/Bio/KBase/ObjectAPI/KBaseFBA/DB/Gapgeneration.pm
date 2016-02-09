########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::DB::Gapgeneration - This is the moose object corresponding to the KBaseFBA.Gapgeneration object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package Bio::KBase::ObjectAPI::KBaseFBA::DB::Gapgeneration;
use Bio::KBase::ObjectAPI::IndexedObject;
use Bio::KBase::ObjectAPI::KBaseFBA::GapgenerationSolution;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::IndexedObject';


our $VERSION = 1.0;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');
# ATTRIBUTES:
has uuid => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_uuid');
has _reference => (is => 'rw', lazy => 1, isa => 'Str', type => 'msdata', metaclass => 'Typed',builder => '_build_reference');
has fbamodel_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has biomassHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has totalTimeLimit => (is => 'rw', isa => 'Int', printOrder => '17', type => 'attribute', metaclass => 'Typed');
has gprHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has media_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has timePerSolution => (is => 'rw', isa => 'Int', printOrder => '16', type => 'attribute', metaclass => 'Typed');
has mediaHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has referenceMedia_ref => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has fba_ref => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has reactionRemovalHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has gapgenSolutions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(GapgenerationSolution)', metaclass => 'Typed', reader => '_gapgenSolutions', printOrder => '0');


# LINKS:
has fbamodel => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,FBAModel,fbamodel_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fbamodel', clearer => 'clear_fbamodel', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::FBAModel', weak_ref => 1);
has media => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Media,media_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_media', clearer => 'clear_media', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media', weak_ref => 1);
has referenceMedia => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,Media,referenceMedia_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_referenceMedia', clearer => 'clear_referenceMedia', isa => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media', weak_ref => 1);
has fba => (is => 'rw', type => 'link(Bio::KBase::ObjectAPI::KBaseStore,FBA,fba_ref)', metaclass => 'Typed', lazy => 1, builder => '_build_fba', clearer => 'clear_fba', isa => 'Bio::KBase::ObjectAPI::KBaseFBA::FBA', weak_ref => 1);


# BUILDERS:
sub _build_reference { my ($self) = @_;return $self->uuid(); }
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_fbamodel {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fbamodel_ref());
}
sub _build_media {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->media_ref());
}
sub _build_referenceMedia {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->referenceMedia_ref());
}
sub _build_fba {
	 my ($self) = @_;
	 return $self->getLinkedObject($self->fba_ref());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'KBaseFBA.Gapgeneration'; }
sub _module { return 'KBaseFBA'; }
sub _class { return 'Gapgeneration'; }
sub _top { return 1; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'fbamodel_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'biomassHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 17,
            'name' => 'totalTimeLimit',
            'default' => undef,
            'type' => 'Int',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'gprHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
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
            'printOrder' => 16,
            'name' => 'timePerSolution',
            'default' => undef,
            'type' => 'Int',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'mediaHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'description' => undef,
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
            'req' => 1,
            'printOrder' => 0,
            'name' => 'referenceMedia_ref',
            'default' => undef,
            'type' => 'Str',
            'description' => undef,
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'fba_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'reactionRemovalHypothesis',
            'default' => '1',
            'type' => 'Bool',
            'description' => undef,
            'perm' => 'rw'
          }
        ];

my $attribute_map = {fbamodel_ref => 0, biomassHypothesis => 1, totalTimeLimit => 2, gprHypothesis => 3, media_ref => 4, timePerSolution => 5, mediaHypothesis => 6, id => 7, referenceMedia_ref => 8, fba_ref => 9, reactionRemovalHypothesis => 10};
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
            'attribute' => 'fbamodel_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_fbamodel',
            'name' => 'fbamodel',
            'method' => 'FBAModel',
            'class' => 'Bio::KBase::ObjectAPI::KBaseFBA::FBAModel',
            'module' => 'KBaseFBA'
          },
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
            'attribute' => 'referenceMedia_ref',
            'parent' => 'Bio::KBase::ObjectAPI::KBaseStore',
            'clearer' => 'clear_referenceMedia',
            'name' => 'referenceMedia',
            'method' => 'Media',
            'class' => 'Bio::KBase::ObjectAPI::KBaseBiochem::Media',
            'module' => 'KBaseBiochem'
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

my $link_map = {fbamodel => 0, media => 1, referenceMedia => 2, fba => 3};
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
            'req' => undef,
            'printOrder' => 0,
            'name' => 'gapgenSolutions',
            'default' => undef,
            'description' => undef,
            'class' => 'GapgenerationSolution',
            'type' => 'child',
            'module' => 'KBaseFBA'
          }
        ];

my $subobject_map = {gapgenSolutions => 0};
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
around 'gapgenSolutions' => sub {
	 my ($orig, $self) = @_;
	 return $self->_build_all_objects('gapgenSolutions');
};


__PACKAGE__->meta->make_immutable;
1;
