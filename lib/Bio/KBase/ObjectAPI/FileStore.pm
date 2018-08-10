########################################################################
# Bio::KBase::ObjectAPI::FileStore - A class for managing object storage an retrievel from local file system
# Authors: Christopher Henry
########################################################################

=head1 Bio::KBase::ObjectAPI::FileStore 

A class for managing object storage an retrievel from local file system

=cut

package Bio::KBase::ObjectAPI::FileStore;
use Moose;
use Bio::KBase::ObjectAPI::utilities;

use Class::Autouse qw(
	Bio::KBase::utilities
	Bio::KBase::ObjectAPI::KBaseRegulation::Regulome
	Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry
	Bio::KBase::ObjectAPI::KBaseGenomes::Genome
	Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet
	Bio::KBase::ObjectAPI::KBaseBiochem::Media
	Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate
	Bio::KBase::ObjectAPI::KBaseFBA::FBAComparison
	Bio::KBase::ObjectAPI::KBaseOntology::Mapping
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel
	Bio::KBase::ObjectAPI::KBaseBiochem::BiochemistryStructures
	Bio::KBase::ObjectAPI::KBaseFBA::Gapfilling
	Bio::KBase::ObjectAPI::KBaseFBA::FBA
	Bio::KBase::ObjectAPI::KBaseFBA::Gapgeneration
	Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSet
	Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulationSet
);
use Module::Load;

#***********************************************************************************************************
# ATTRIBUTES:
#***********************************************************************************************************
has cache => ( is => 'rw', isa => 'HashRef',default => sub { return {}; });
has directory => ( is => 'rw', isa => 'Str',default => "");

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub updated_reference {
	return;
}

sub get_objects {
	my ($self,$refs,$options) = @_;
	$options = Bio::KBase::utilities::args($options,[],{
		refreshcache => 0,
		raw => 0
	});
	#Checking cache for objects
	my $newrefs = [];
	for (my $i=0; $i < @{$refs}; $i++) {
		my $array = [split(/;/,$refs->[$i])];
		$refs->[$i] = pop(@{$array});
		if ($refs->[$i] =~ m/(.+)\|\|$/) {
			$refs->[$i] = $1;
		}
		$refs->[$i] =~ s/\/+/\//g;
		if (!defined($self->cache()->{$refs->[$i]}) || $options->{refreshcache} == 1) {
			push(@{$newrefs},$refs->[$i]);
		}
	}
	#Pulling objects from workspace
	for (my $i=0; $i < @{$newrefs}; $i++) {
		my $directory = Bio::KBase::utilities::conf("FileStore","directory");
		$directory =~ s/\/+$//;
		my $filearray = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory.$newrefs->[$i]);
		my $data = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{$filearray}));
		$self->process_object($data,$newrefs->[$i],$options);
	}
	#Gathering objects out of the cache
	my $objs = [];
	for (my $i=0; $i < @{$refs}; $i++) {
		$objs->[$i] = $self->cache()->{$refs->[$i]};
	}
	return $objs;
}

sub process_object {
	my ($self,$data,$ref,$options) = @_;
	my $array = [split(/\//,$ref)];
	my $name = pop(@{$array});
	my $folder = join("/",@{$array});
	if (!defined($data->{__type__}) || $data->{__type__} eq "HASH" || $options->{raw} == 1) {
		$self->cache()->{$ref} = $data;
		$self->cache()->{$ref}->{_reference} = $ref."||";
	} else {
		my $class = "Bio::KBase::ObjectAPI::".$data->{__type__};
		$self->cache()->{$ref} = $class->new($data);
		$self->cache()->{$ref}->parent($self);
		$self->cache()->{$ref}->_wsname($name);
		$self->cache()->{$ref}->_wstype($data->{__type__});
		$self->cache()->{$ref}->_wsworkspace($folder);
		$self->cache()->{$ref}->_reference($ref."||");			
		if ($data->{__type__} eq "KBaseBiochem::Biochemistry") {
			$self->cache()->{$ref}->add("compounds",{
				id => "cpd00000",
				isCofactor => 0,
				name => "CustomCompound",
				abbreviation => "CustomCompound",
				md5 => "",
				formula => "",
				unchargedFormula => "",
				mass => 0,
				defaultCharge => 0,
				deltaG => 0,
				deltaGErr => 0,
				comprisedOfCompound_refs => [],
				cues => {},
				pkas => {},
				pkbs => {}
			});
			$self->cache()->{$ref}->add("reactions",{
				id => "rxn00000",
				name => "CustomReaction",
				abbreviation => "CustomReaction",
				md5 => "",
				direction => "=",
				thermoReversibility => "=",
				status => "OK",
				defaultProtons => 0,
				deltaG => 0,
				deltaGErr => 0,
				cues => {},
				reagents => []
			});
		}
	}
}

sub get_object {
	my ($self,$ref,$options) = @_;
	if ($ref eq "kbase/default") {
		$ref = "/Biochemistry/default";
	}
	return $self->get_objects([$ref],$options)->[0];
}

sub save_object {
	my ($self,$object,$ref,$params) = @_;
	my $args = {$ref => {hidden => $params->{hidden},object => $object}};
	if (defined($params->{hash}) && $params->{hash} == 1) {
		$args->{$ref}->{hash} = 1;
		$args->{$ref}->{type} = $params->{type};
	}
	my $output = $self->save_objects($args);
	return $output->{$ref};
}

sub save_objects {
	my ($self,$refobjhash) = @_;
	my $output = {};
	foreach my $ref (keys(%{$refobjhash})) {
		my $obj = $refobjhash->{$ref};
		my $data;
		my $array = [split(/\//,$ref)];
		my $name = pop(@{$array});
		my $folder = join("/",@{$array});
		if (defined($obj->{hash}) && $obj->{hash} == 1) {
			$data = $obj->{object};
			$data->{__type__} = $obj->{type};
		} else {
			$data = $obj->{object}->serializeToDB();
			$data->{__type__} = $obj->{object}->_type();
			$data->{__type__} =~ s/\./::/;
		}
		$output->{$ref} = {
			id => $name,
			workspace => $folder,
			"ref" => $ref,
			type => $data->{__type__}
		};
		$data->{__provenance__} = Bio::KBase::utilities::provenance();
		if ($folder ne "NULL") {
			my $directory = Bio::KBase::utilities::conf("FileStore","directory");
			$directory =~ s/\/+$//;
			File::Path::mkpath $directory.$folder;
			Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory.$ref,[Bio::KBase::ObjectAPI::utilities::TOJSON($data)]);
		}
		$self->cache()->{$ref} = $obj->{object};
		if (defined($obj->{hash}) && $obj->{hash} == 1) {
			$self->cache()->{$ref} = $data;
			$self->cache()->{$ref}->{_reference} = $ref."||";
		} else {
			$self->cache()->{$ref}->parent($self);
			$self->cache()->{$ref}->_wsname($name);
			$self->cache()->{$ref}->_wstype($data->{__type__});
			$self->cache()->{$ref}->_wsworkspace($folder);
			$self->cache()->{$ref}->_reference($ref);
		}
	}
	return $output;
}

sub get_ref_from_metadata {
	my ($self,$metadata) = @_;
	return $metadata->{"ref"};
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
