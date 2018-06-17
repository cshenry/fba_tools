########################################################################
# Bio::KBase::ObjectAPI::KBaseStore - A class for managing KBase object retrieval from KBase
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2014-01-4
########################################################################

=head1 Bio::KBase::ObjectAPI::PATRICStore 

Class for managing object retreival from PATRIC workspace

=head2 ABSTRACT

=head2 NOTE


=head2 METHODS

=head3 new

    my $Store = Bio::KBase::ObjectAPI::PATRICStore->new({});

This initializes a Storage interface object. This accepts a hash
or hash reference to configuration details:

=over

=item auth

Authentication token to use when retrieving objects

=item workspace

Client or server class for accessing a PATRIC workspace

=back

=head3 Object Methods

=cut

package Bio::KBase::ObjectAPI::PATRICStore;
use Moose;
use Bio::KBase::ObjectAPI::utilities;
use Data::Dumper;
use Log::Log4perl;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::UUID;

use Class::Autouse qw(
    Bio::KBase::ObjectAPI::KBaseRegulation::Regulome
    Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry
    Bio::KBase::ObjectAPI::KBaseGenomes::Genome
    Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet
    Bio::KBase::ObjectAPI::KBaseBiochem::Media
    Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate
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

my $typetrans = {
	model => "Bio::KBase::ObjectAPI::KBaseFBA::FBAModel",
	modeltemplate => "Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate",
	fba => "Bio::KBase::ObjectAPI::KBaseFBA::FBA",
	biochemistry => "Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry",
	media => "Bio::KBase::ObjectAPI::KBaseBiochem::Media",
	mapping => "Bio::KBase::ObjectAPI::KBaseOntology::Mapping",
	genome => "Bio::KBase::ObjectAPI::KBaseGenomes::Genome",
};
my $transform = {
	media => {
		in => "transform_media_from_ws",
		out => "transform_media_to_ws"
	},
	genome => {
		in => "transform_genome_from_ws",
		out => "transform_genome_to_ws"
	}
};
my $jsontypes = {
	unspecified => 1,
	job_result => 1,
	feature_group => 1,
	rxnprobs => 1
};

#***********************************************************************************************************
# ATTRIBUTES:
#***********************************************************************************************************
has workspace => ( is => 'rw', isa => 'Ref', required => 1);
has helper => ( is => 'rw', isa => 'Ref', required => 1);
has data_api_url => ( is => 'rw', isa => 'Str', required => 1);
has cache => ( is => 'rw', isa => 'HashRef',default => sub { return {}; });
has adminmode => ( is => 'rw', isa => 'Num',default => 0);
has setowner => ( is => 'rw', isa => 'Str');
has provenance => ( is => 'rw', isa => 'ArrayRef',default => sub { return []; });
has user_override => ( is => 'rw', isa => 'Str',default => "");
has file_cache => ( is => 'rw', isa => 'Str',default => "");
has cache_targets => ( is => 'rw', isa => 'HashRef',default => sub { return {}; });

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub object_meta {
	my ($self,$ref) = @_;
	# Assumes object has already been retrieved and stored in cache.
	return $self->cache()->{$ref}->[0];
}

sub get_object_type {
	my ($self,$ref) = @_;
	# Assumes object has already been retrieved and stored in cache.
	return $self->cache()->{$ref}->[0]->[1];
}

sub get_object {
    my ($self,$ref,$options) = @_;
    return $self->get_objects([$ref],$options)->[0];
}

sub get_objects {
	my ($self,$refs,$options) = @_;
	#Checking cache for objects
	my $newrefs = [];
	for (my $i=0; $i < @{$refs}; $i++) {
		if ($refs->[$i] =~ m/(.+)\|\|$/) {
			$refs->[$i] = $1;
		}
		$refs->[$i] =~ s/\/+/\//g;
		if (!defined($self->cache()->{$refs->[$i]}) || defined($options->{refreshcache})) {
    		#Checking file cache for object
    		my $output = $self->read_object_from_file_cache($refs->[$i]);
    		if (defined($output)) {
    			$self->process_object($output->[0],$output->[1],$options);
    		} else {
    			push(@{$newrefs},$refs->[$i]);
    		}
    	}
	}
	#Pulling objects from workspace
	if (@{$newrefs} > 0) {
		my $objdatas = Bio::ModelSEED::patricenv::call_ws("get",{adminmode => $self->adminmode(),objects => $newrefs});
		for (my $i=0; $i < @{$objdatas}; $i++) {
			$self->process_object($objdatas->[$i]->[0],$objdatas->[$i]->[1],$options);
		}
	}
	my $objs = [];
	for (my $i=0; $i < @{$refs}; $i++) {
		$objs->[$i] = $self->cache()->{$refs->[$i]}->[1];
	}
	return $objs;
}

sub process_object {
	my ($self,$meta,$data,$options) = @_;
	if ($meta->[1] eq "modelfolder") {
		my $mdldata = $self->load_model($meta,$data);
		$meta = $mdldata->[0];
		$data = $mdldata->[1];
	}	
	#Downloading object from shock if the object is in shock
	$data = $self->download_object_from_shock($meta,$data);
	#Writing target object to file cache if they are not already there
	$self->write_object_to_file_cache($meta,$data);
	#Handling all transforms of objects
	if (defined($typetrans->{$meta->[1]}) && !defined($options->{data_only})) {
		my $class = $typetrans->{$meta->[1]};
		if (defined($transform->{$meta->[1]}->{in})) {
    		my $function = $transform->{$meta->[1]}->{in};
    		$data = $self->$function($data,$meta);
    		if (ref($data) eq "HASH") {
    			$data = $class->new($data);
    		}
		} else {
			$data = $class->new(Bio::KBase::ObjectAPI::utilities::FROMJSON($data));
		}
		if ($meta->[1] eq "modeltemplate") {
			$data->add("compounds",{
				id => "cpd00000",
				compound_ref => "~/biochemistry/compounds/id/cpd00000",
				name => "cpd00000",
				abbreviation => "cpd00000",
				md5 => "",
				formula => "",
				isCofactor => 0,
				aliases => [],
				defaultCharge => 0,
				mass => 0,
    			deltaG => 0,
    			deltaGErr => 0
			});
			$data->add("reactions",{
				id => "rxn00000",
				reaction_ref => "~/biochemistry/reactions/id/rxn00000",
				name => "rxn00000",
				type => "custom",
				reference => "",
				direction => "=",
				GapfillDirection => "=",
				maxforflux => 0,
				maxrevflux => 0,
				deltaG => 0,
				deltaGErr => 0,
				status => "OK",
				templatecompartment_ref => "~/compartments/id/c",
				base_cost => 0,
		    	forward_penalty => 0,
		    	reverse_penalty => 0,
				templateReactionReagents => [],
				templatecomplex_refs => []
			});
		}
		$data->wsmeta($meta);
		$data->parent($self);
		$data->_reference($meta->[2].$meta->[0]."||");
	} elsif (defined($jsontypes->{$meta->[1]})) {
		$data = Bio::KBase::ObjectAPI::utilities::FROMJSON($data);
	}
	#Stashing objects into memmory cache based on uuid and workspace address
	$self->cache()->{$meta->[4]} = [$meta,$data];
	$self->cache()->{$meta->[2].$meta->[0]} = $self->cache()->{$meta->[4]};
}

#This function downloads an object from skock if it has a shock URL
sub download_object_from_shock {
	my ($self,$meta,$data) = @_;
	if (defined($meta->[11]) && length($meta->[11]) > 0 && !defined($meta->[12])) {
		my $ua = LWP::UserAgent->new();
		my $res = $ua->get($meta->[11]."?download",Authorization => "OAuth " . $self->workspace()->{token});
		$data = $res->{_content};
	}
	return $data;
}

#This function writes data to file cache if it's been flagged for local file caching
sub write_object_to_file_cache {
	my ($self,$meta,$data) = @_;
	if (length($self->file_cache()) > 0 && defined($self->cache_targets()->{$meta->[2].$meta->[0]}) && !-e $self->file_cache()."/meta".$meta->[2].$meta->[0]) {
		if (!-d $self->file_cache()."/meta/".$meta->[2]) {
			File::Path::mkpath $self->file_cache()."/meta/".$meta->[2];
		}
		if (!-d $self->file_cache()."/data/".$meta->[2]) {
			File::Path::mkpath $self->file_cache()."/data/".$meta->[2];
		}
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($self->file_cache()."/meta".$meta->[2].$meta->[0],[Bio::KBase::ObjectAPI::utilities::TOJSON($meta)]);
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($self->file_cache()."/data".$meta->[2].$meta->[0],[$data]);
	}
}

#This function writes data to file cache if it's been flagged for local file caching
sub read_object_from_file_cache {
	my ($self,$ref) = @_;
	if (defined($self->cache_targets()->{$ref}) && -e $self->file_cache()."/meta".$ref) {
		my $filearray = Bio::KBase::ObjectAPI::utilities::LOADFILE($self->file_cache()."/meta".$ref);
		my $meta = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{$filearray}));
		$filearray = Bio::KBase::ObjectAPI::utilities::LOADFILE($self->file_cache()."/data".$ref);
		my $data = join("\n",@{$filearray});
		return [$meta,$data];
	}
	return undef;
}

sub save_object {
    my ($self,$object,$ref,$meta,$type,$overwrite) = @_;
    my $output = $self->save_objects({$ref => {usermeta => $meta,object => $object,type => $type}},$overwrite);
    return $output->{$ref};
}

sub save_objects {
    my ($self,$refobjhash,$overwrite) = @_;
    my $objectdata = {};
    if (!defined($overwrite)) {
    	$overwrite = 1;
    }
    my $input = {
    	objects => [],
    	overwrite => 1,
    	adminmode => $self->adminmode(),
    	createUploadNodes => 1
    };
    if (defined($self->adminmode()) && $self->adminmode() == 1 && defined($self->setowner())) {
    	$input->{setowner} = $self->setowner();
    }
    my $reflist;
    my $objecthash = {};
    foreach my $ref (keys(%{$refobjhash})) {
    	my $obj = $refobjhash->{$ref};
    	push(@{$reflist},$ref);
    	$objecthash->{$ref} = 0;
    	if ($obj->{type} eq "model") {
    		$self->save_model($obj->{object},$ref);
    	} elsif ($obj->{type} eq "fba") {
    		$self->save_fba($obj->{object},$ref);
    	} elsif (defined($typetrans->{$obj->{type}}) && ref($obj->{object}) ne 'HASH') {
    		$objecthash->{$ref} = 1;
    		$obj->{object}->parent($self);
    		if (defined($transform->{$obj->{type}}->{out})) {
    			my $function = $transform->{$obj->{type}}->{out};
    			$objectdata->{$ref} = $self->$function($obj->{object},$obj->{usermeta});
    			push(@{$input->{objects}},[$ref,$obj->{type},$obj->{usermeta},undef]);
    		} else {
    			$objectdata->{$ref} = $obj->{object}->toJSON();
    			push(@{$input->{objects}},[$ref,$obj->{type},$obj->{usermeta},undef]);
    		}
    	} elsif (defined($jsontypes->{$obj->{type}}) || ref($obj->{object}) eq 'HASH') {
    		$objectdata->{$ref} = Bio::KBase::ObjectAPI::utilities::TOJSON($obj->{object});
    		push(@{$input->{objects}},[$ref,$obj->{type},$obj->{usermeta},undef]);
    	} else {
    		$objectdata->{$ref} = $obj->{object};
    		push(@{$input->{objects}},[$ref,$obj->{type},$obj->{usermeta},undef]);
    	}
    }
    my $listout = Bio::ModelSEED::patricenv::call_ws("create",$input);
    my $output = {};
    for (my $i=0; $i < @{$reflist}; $i++) {
    	my $refinedref = $reflist->[$i];
    	$refinedref =~ s/\/+/\//g;
    	for (my $j=0; $j < @{$listout}; $j++) {
    		if ($refinedref eq $listout->[$j]->[2].$listout->[$j]->[0]) {
    			$self->upload_to_shock($objectdata->{$reflist->[$i]},$listout->[$j]->[11]);
    			$output->{$reflist->[$i]} = $listout->[$j];
    			$self->cache()->{$reflist->[$i]} = [$listout->[$j],$refobjhash->{$reflist->[$i]}->{object}];
		    	$self->cache()->{$listout->[$j]->[2].$listout->[$j]->[0]} = [$listout->[$j],$refobjhash->{$reflist->[$i]}->{object}];
		    	$self->cache()->{$listout->[$j]->[4]} = [$listout->[$j],$refobjhash->{$reflist->[$i]}->{object}];
		    	if ($objecthash->{$reflist->[$i]} == 1) {
		    		$self->cache()->{$reflist->[$i]}->[1]->wsmeta($listout->[$j]);
					$self->cache()->{$reflist->[$i]}->[1]->_reference($listout->[$j]->[2].$listout->[$j]->[0]."||");
		    	}
		    	last;
    		}
    	}	
    }
    return $output; 
}

sub upload_to_shock {
	my ($self,$content,$url) = @_;	
	my $uuid = Data::UUID->new()->create_str();
	File::Path::mkpath Bio::KBase::utilities::conf("ModelSEED","fbajobdir");
	my $filename = Bio::KBase::utilities::conf("ModelSEED","fbajobdir").$uuid;
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($filename,[$content]);
	my $ua = LWP::UserAgent->new();
	my $req = HTTP::Request::Common::POST($url,Authorization => "OAuth ".Bio::KBase::utilities::token(),Content_Type => 'multipart/form-data',Content => [upload => [$filename]]);
	$req->method('PUT');
	my $res = $ua->request($req);
	Bio::KBase::utilities::log($res->content);
	unlink($filename);
}

sub object_from_file {
	my ($self,$filename) = @_;
	my $meta = Bio::KBase::ObjectAPI::utilities::LOADFILE($filename.".meta");
	$meta = join("\n",@{$meta});
	$meta = Bio::KBase::ObjectAPI::utilities::FROMJSON($meta);
	my $data = Bio::KBase::ObjectAPI::utilities::LOADFILE($filename.".data");
	$data = join("\n",@{$data});
	$data = Bio::KBase::ObjectAPI::utilities::FROMJSON($data);
	
	return [$meta,$data];
}

sub transform_genome_from_ws {
	my ($self,$data,$meta) = @_;
	$data = Bio::KBase::ObjectAPI::utilities::FROMJSON($data);
	$data->{id} = $meta->[0];
	if (!defined($data->{source})) {
		$data->{source} = "PATRIC";
	}
	foreach my $gene (@{$data->{features}}) {
		delete $gene->{feature_creation_event};
		if (defined($gene->{protein_translation})) {
			if (!defined($gene->{protein_translation_length})) {
				$gene->{protein_translation_length} = length($gene->{protein_translation});
			}
			if (!defined($gene->{dna_sequence_length})) {
				$gene->{dna_sequence_length} = 3*$gene->{protein_translation_length};
			}
			if (!defined($gene->{md5})) {
				$gene->{md5} = Digest::MD5::md5_hex($gene->{protein_translation}),
			}
			if (!defined($gene->{publications})) {
				$gene->{publications} = [],
			}
			if (!defined($gene->{subsystems})) {
				$gene->{subsystems} = [],
			}
			if (!defined($gene->{protein_families})) {
				$gene->{protein_families} = [],
			}
			if (!defined($gene->{aliases})) {
				$gene->{aliases} = [],
			}
			if (!defined($gene->{subsystem_data})) {
				$gene->{subsystem_data} = [],
			}
			if (!defined($gene->{regulon_data})) {
				$gene->{regulon_data} = [],
			}
			if (!defined($gene->{atomic_regulons})) {
				$gene->{atomic_regulons} = [],
			}
			if (!defined($gene->{coexpressed_fids})) {
				$gene->{coexpressed_fids} = [],
			}
			if (!defined($gene->{co_occurring_fids})) {
				$gene->{co_occurring_fids} = [],
			}
		}
	}
	my $contigset;
	if (defined($data->{contigs})) {
		my $obj = {
			id => $meta->[0].".contigs",
			name => $data->{scientific_name},
			md5 => "",
			source_id => $meta->[0],
			source => "PATRIC",
			type => "organism",
			contigs => []
		};
		foreach my $contig (@{$data->{contigs}}) {
			push(@{$obj->{contigs}},{
				id => $contig->{id},
				length => length($contig->{dna}),
				sequence => $contig->{dna},
				md5 => Digest::MD5::md5_hex($contig->{dna}),
			});
		}
		$contigset = Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet->new($obj);
		delete $data->{contigs};
	}
	$data = Bio::KBase::ObjectAPI::KBaseGenomes::Genome->new($data);
	if (defined($contigset)) {
		$data->contigs($contigset);
	}
	return $data;
}

sub transform_genome_to_ws {
	my ($self,$object,$meta) = @_;
	return $object->export( { format => "json" } );
}

sub transform_media_from_ws {
	my ($self,$data,$meta) = @_;
	my $object = {
		id => $meta->[0],
		name => $meta->[0],
		type => "custom",
		isMinimal => 1,
		isDefined => 1,
		source_id => $meta->[0],
		mediacompounds => []
	};
	my $array = [split(/\r\n?|\n/,$data)];
	my $heading = [split(/\t/,$array->[0])];
	my $headinghash = {};
	for (my $i=1; $i < @{$heading}; $i++) {
		$headinghash->{$heading->[$i]} = $i;
	}
	my $biochem;
	for (my $i=1; $i < @{$array}; $i++) {
		my $subarray = [split(/\t/,$array->[$i])];
		my $cpdobj = {
			concentration => 0.001,
			minFlux => -100,
			maxFlux => 100
		};
		my $name;
		if (defined($headinghash->{id})) {
			$name = $subarray->[$headinghash->{id}];
			if ($subarray->[$headinghash->{id}] =~ /cpd\d+/) {
				$cpdobj->{compound_ref} = "/chenry/public/modelsupport/biochemistry/default.biochem||/compounds/id/".$subarray->[$headinghash->{id}];
			}
		} elsif (defined($headinghash->{name})) {
			$name = $subarray->[$headinghash->{name}];
		}
		if (!defined($cpdobj->{compound_ref})) {
			if (defined($name)) {
				if (!defined($biochem)) {
					$biochem = $self->get_object("/chenry/public/modelsupport/biochemistry/default.biochem");
				}
				my $biocpdobj = $biochem->searchForCompound($name);
				if (defined($biocpdobj)) {
					$cpdobj->{compound_ref} = $biocpdobj->_reference();
				}
			}
		}
		if (defined($cpdobj->{compound_ref})) {
			if ($headinghash->{concentration}) {
				$cpdobj->{concentration} = $subarray->[$headinghash->{concentration}];
			}
			if ($headinghash->{minflux}) {
				$cpdobj->{minFlux} = $subarray->[$headinghash->{minflux}];
			}
			if ($headinghash->{maxflux}) {
				$cpdobj->{maxFlux} = $subarray->[$headinghash->{maxflux}];
			}
			push(@{$object->{mediacompounds}},$cpdobj);
		}
	}
	return $object;
}

sub transform_media_to_ws {
	my ($self,$object,$meta) = @_;
	$meta->{name} = $object->name();
	$meta->{type} = $object->type();
	$meta->{isMinimal} = $object->isMinimal();
	$meta->{isDefined} = $object->isDefined();
	$meta->{source_id} = $object->source_id();
	$meta->{number_compounds} = @{$object->mediacompounds()};
	my $data = "id\tname\tconcentration\tminflux\tmaxflux\n";
	my $mediacpds = $object->mediacompounds();
	my $compounds = "";
	for (my $i=0; $i < @{$mediacpds}; $i++) {
		$data .= $mediacpds->[$i]->id()."\t".
			$mediacpds->[$i]->name()."\t".
			$mediacpds->[$i]->concentration()."\t".
			$mediacpds->[$i]->minFlux()."\t".
			$mediacpds->[$i]->maxFlux()."\n";
		if (length($compounds) > 0) {
			$compounds .= "|";
		}
		$compounds .= $mediacpds->[$i]->id().":".$mediacpds->[$i]->name();
	}
	$meta->{compounds} = $compounds;
	return $data;
}

sub save_model {
	my ($self,$object,$ref) = @_;
	my $array = [split(/\/+/,$ref)];
	$ref = join("/",@{$array});
	print "ModelRef:".$ref."\n";
	my $name = pop(@{$array});
	#Listing contents of any existing model folder in this location
	if (Bio::KBase::utilities::conf("ProbModelSEED","old_models") == 1) {
		my $listout = Bio::ModelSEED::patricenv::call_ws("create",{
			objects => [[$ref,"folder",{},undef]]
		});
	} else {
		my $listout = Bio::ModelSEED::patricenv::call_ws("create",{
			objects => [[$ref,"modelfolder",{},undef]]
		});
	}
	my $output = Bio::ModelSEED::patricenv::call_ws("ls",{
		paths => [$ref],
		recursive => 1,
	});
	#Checking what data is already present
	my $refobject;
	my $refpath;
	if ($ref =~ m/^(.+)\/([^\/]+)$/) {
		$refpath = $1;
		$refobject = $2;
	}
	$object->id($refobject);
	my $createinput = {objects => [],createUploadNodes => 1};
	my $exists = 0;
	my $subobjects = {};
	if (defined($output->{$ref})) {
		for (my $i=0; $i < @{$output->{$ref}}; $i++) {
			if ($output->{$ref}->[$i]->[2].$output->{$ref}->[$i]->[0] eq $ref."/fba" && $output->{$ref}->[$i]->[1] eq "folder") {
				$subobjects->{fba} = 1;	
			} elsif ($output->{$ref}->[$i]->[2].$output->{$ref}->[$i]->[0] eq $ref."/gapfilling" && $output->{$ref}->[$i]->[1] eq "folder") {
				$subobjects->{gapfill} = 1;
			} elsif ($output->{$ref}->[$i]->[2].$output->{$ref}->[$i]->[0] eq $ref."/genome" && $output->{$ref}->[$i]->[1] eq "genome") {
				$subobjects->{genome} = 1;
			}
		}
	}
	$object->genome();
	$object->genome_ref($ref."/genome||");
	$object->genome()->_reference($ref."/genome||");
	my $objectdata = {};
	#Adding folders and genome if not already present
	my $listout = [];
	if (!defined($subobjects->{fba})) {
		push(@{$createinput->{objects}},[$ref."/fba","folder",{},undef]);
	}
	if (!defined($subobjects->{gapfill})) {
		push(@{$createinput->{objects}},[$ref."/gapfilling","folder",{},undef]);
	}
	if (!defined($subobjects->{genome})) {
		push(@{$createinput->{objects}},[$ref."/genome","genome",{},undef]);
		$objectdata->{$ref."/genome"} = $self->transform_genome_to_ws($object->genome());
	}
	#Saving model JSON structure
	push(@{$createinput->{objects}},[$ref."/model","model",{},undef]);
	$objectdata->{$ref."/model"} = $object->toJSON();
	#Saving model SBML format
	if (Bio::KBase::utilities::conf("ProbModelSEED","old_models") == 1) {
		$name =~ s/^\.//;
	}
	push(@{$createinput->{objects}},[$ref."/".$name.".sbml","string",{
	   description => "SBML version of model data for use in COBRA toolbox and other applications"
	},undef]);
	$objectdata->{$ref."/".$name.".sbml"} = $object->export({format => "sbml"});
	#Saving compound table for model
	push(@{$createinput->{objects}},[$ref."/".$name.".cpdtbl","string",{
		   description => "Tab delimited table containing data on compounds in metabolic model",
	},undef]);
	my $mdlcpds = $object->modelcompounds();
	my $cpdtbl = "ID\tName\tFormula\tCharge\tCompartment\n";
	for (my $i=0; $i < @{$mdlcpds}; $i++) {
		$cpdtbl .= $mdlcpds->[$i]->id()."\t".$mdlcpds->[$i]->name()."\t".$mdlcpds->[$i]->formula()."\t".$mdlcpds->[$i]->compound()->defaultCharge()."\t".$mdlcpds->[$i]->modelcompartment()->label()."\n";
	}
	$objectdata->{$ref."/".$name.".cpdtbl"} = $cpdtbl;
	#Saving reaction table for model
	push(@{$createinput->{objects}},[$ref."/".$name.".rxntbl","string",{
		   description => "Tab delimited table containing data on reactions in metabolic model",
	},undef]);
	my $mdlrxns = $object->modelreactions();
	my $rxntbl = "ID\tName\tEquation\tDefinition\tGenes\n";
	for (my $i=0; $i < @{$mdlrxns}; $i++) {
		$rxntbl .= $mdlrxns->[$i]->id()."\t".$mdlrxns->[$i]->name()."\t".$mdlrxns->[$i]->equation()."\t".$mdlrxns->[$i]->definition()."\t".$mdlrxns->[$i]->gprString()."\n";
	}
	$objectdata->{$ref."/".$name.".rxntbl"} = $rxntbl;
	#Calling create functions
	my $createoutput = Bio::ModelSEED::patricenv::call_ws("create",$createinput);
	for (my $i=0; $i < @{$createoutput}; $i++) {
		push(@{$listout},$createoutput->[$i]);
	}
	#Uploading actual files to shock
	$output = {};
	my $modelmeta;
	for (my $i=0; $i < @{$listout}; $i++) {
		Bio::KBase::utilities::log("Save model:".$i."\t".join("\t",@{$listout->[$i]}));
		if (defined($listout->[$i]->[11]) && length($listout->[$i]->[11]) > 0 && defined($objectdata->{$listout->[$i]->[2].$listout->[$i]->[0]})) {
			$self->upload_to_shock($objectdata->{$listout->[$i]->[2].$listout->[$i]->[0]},$listout->[$i]->[11]);
		}
		if ($listout->[$i]->[0] eq "model" || $listout->[$i]->[0] eq "genome") {
			$output->{$listout->[$i]->[2].$listout->[$i]->[0]} = $listout->[$i];
			if ($listout->[$i]->[0] eq "model") {
				$modelmeta = $listout->[$i];
				$modelmeta->[0] = $refobject;
				$modelmeta->[2] = $refpath."/";				
				$object->wsmeta($modelmeta);
				$object->_reference($ref."||");
				$self->cache()->{$modelmeta->[2].$modelmeta->[0]} = [$modelmeta,$object];
				$self->cache()->{$modelmeta->[4]} = [$modelmeta,$object];
				$self->cache()->{$ref} = [$modelmeta,$object];
			}
			if ($listout->[$i]->[0] eq "genome") {
		    	$self->cache()->{$listout->[$i]->[4]} = [$listout->[$i],$object->genome()];
		    	$self->cache()->{$listout->[$i]->[2].$listout->[$i]->[0]} = [$listout->[$i],$object->genome()];
		    	$self->cache()->{$listout->[$i]->[2].$listout->[$i]->[0]}->[1]->wsmeta($listout->[$i]);
				$self->cache()->{$listout->[$i]->[2].$listout->[$i]->[0]}->[1]->_reference($listout->[$i]->[2].$listout->[$i]->[0]."||");
			}
		}	
	}
	my $summary = $self->helper()->get_model_summary($object);
	if (Bio::KBase::utilities::conf("ProbModelSEED","old_models") == 1) {
    	my $path = $ref;
    	if ($ref =~ m/(.+)\/\.([^\/]+)$/) {
    		$path = $1."/".$2;
    		my $data = $object->serializeToDB();
    		$data->{genome_ref} = ".".$2."/genome||";
    		if (defined($data->{gapfilling}->[0])) {
    			$data->{gapfilling}->[0]->{fba_ref} = ".".$2."/gapfilling/".$data->{gapfilling}->[0]->{id}."||";
    		}
    		$data = Bio::KBase::ObjectAPI::utilities::TOJSON($data);
    		my $tempoutput = Bio::ModelSEED::patricenv::call_ws("create",{
    			objects => [[$path,"model",$summary,$data]]
    		});
    	}
    }
    $summary->{status} = "complete";
    $summary->{status_timestamp} = Bio::KBase::utilities::timestamp();
	$self->helper()->update_model_meta($ref,$summary);
	return $output;
}

sub load_model {
	my ($self,$meta) = @_;
	my $objdatas = Bio::ModelSEED::patricenv::call_ws("get",{objects => [$meta->[2].$meta->[0]."/model"]});
	$objdatas->[0]->[0]->[0] = $meta->[0];
	$objdatas->[0]->[0]->[2] = $meta->[2];
	return $objdatas->[0];
}

sub save_fba {
	my ($self,$object,$ref) = @_;
	my $array = [split(/\/+/,$ref)];
	$ref = join("/",@{$array});
	my $name = pop(@{$array});
	#Listing contents of any existing model folder in this location
	my $output = Bio::ModelSEED::patricenv::call_ws("ls",{
		paths => [$ref],
		recursive => 1,
	});
	#Checking what data is already present
	my $refobject;
	my $refpath;
	if ($ref =~ m/^(.+)\/([^\/]+)$/) {
		$refpath = $1;
		$refobject = $2;
	}
	my $createinput = {objects => [],createUploadNodes => 1};
	my $objectdata = {};
	#Adding folders and genome if not already present
	my $listout = [];
	#Saving model JSON structure
	my $mediaref = $object->media_ref();
    my $modelref = $object->fbamodel_ref();
    $mediaref =~ s/\|\|//;
    $modelref =~ s/\|\|//;
	my $fbameta = {
		objective => $object->objectiveValue(),
    	media => $mediaref
	};
	#Checking if gapfilling
	my $gfs = $object->gapfillingSolutions();
	if (@{$gfs} > 0) {
		my $gfsols = [];
		my $gftbl = "Solution\tID\tName\tEquation\tDirection\n";
		for (my $i=0; $i < @{$object->gapfillingSolutions()}; $i++) {
			for (my $j=0; $j < @{$object->gapfillingSolutions()->[$i]->gapfillingSolutionReactions()}; $j++) {
				my $rxn = $object->gapfillingSolutions()->[$i]->gapfillingSolutionReactions()->[$j];
				$gftbl .= $i."\t".$rxn->reaction()->id()."\t".$rxn->reaction()->name()."\t".
	    		$rxn->reaction()->definition()."\t".$rxn->direction()."\n";
				$gfsols->[$i]->[$j] = $object->gapfillingSolutions()->[$i]->gapfillingSolutionReactions()->[$j]->serializeToDB();
			}
		}
		my $solutiondata = Bio::KBase::ObjectAPI::utilities::TOJSON($gfsols);
		$fbameta->{integrated_solution} = 0;
		$fbameta->{integratedindex} = 0;
		$fbameta->{solutiondata} = $solutiondata;
		$fbameta->{integrated} = $object->parameters()->{integrate_solution};
		push(@{$createinput->{objects}},[$ref.".gftbl","string",{
		   description => "Tab delimited table of reactions gapfilled in metabolic model",
		   fba => $ref,
		   media => $mediaref,
		   model => $modelref
		},undef]);
		$objectdata->{$ref.".gftbl"} = $gftbl;
	}
	push(@{$createinput->{objects}},[$ref,"fba",$fbameta,undef]);
	$objectdata->{$ref} = $object->toJSON();
	if (@{$gfs} > 0) {
		push(@{$createinput->{objects}},[$ref.".gftbl","string",{
		   description => "Tab delimited table of reactions gapfilled in metabolic model",
		   fba => $ref,
		   objective => $object->objectiveValue(),
		   media => $mediaref,
		   model => $modelref
		},undef]);
	}
	#Saving fba flux table
	my $fbatbl = "ID\tName\tEquation\tFlux\tUpper bound\tLower bound\tMax\tMin\n";
    my $objs = $object->FBABiomassVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->biomass()->id()."\t".$objs->[$i]->biomass()->name()."\t".
    		$objs->[$i]->biomass()->definition()."\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    }
    $objs = $object->FBAReactionVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->modelreaction()->id()."\t".$objs->[$i]->modelreaction()->name()."\t".
    		$objs->[$i]->modelreaction()->definition()."\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    }
    $objs = $object->FBACompoundVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->modelcompound()->id()."\t".$objs->[$i]->modelcompound()->name()."\t".
    		"=> ".$objs->[$i]->modelcompound()->name()."[e]\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    }
    push(@{$createinput->{objects}},[$ref.".fluxtbl","string",{
	   description => "Tab delimited table containing data on reaction fluxes from flux balance analysis",
	   fba => $ref,
	   objective => $object->objectiveValue(),
	   media => $mediaref,
	   model => $modelref
	},undef]);
	$objectdata->{$ref.".fluxtbl"} = $fbatbl;
    #Saving essential gene lists
    if ($object->comboDeletions() == 1) {
	    my $esslist = [];
	    my $ftrlist = [];
	    my $delresults = $object->FBADeletionResults();
	    for (my $i=0; $i < @{$delresults}; $i++) {
	    	if ($delresults->[$i]->growthFraction < 0.00001) {
	    		my $ftrs =  $delresults->[$i]->features();
	    		my $aliases = $ftrs->[0]->aliases();
	    		my $ftrid;
	    		for (my $j=0; $j < @{$aliases}; $j++) {
	    		 	if ($aliases->[$j] =~ m/^PATRIC\./) {
	    		 		$ftrid = $aliases->[$j];
	    		 		last;
	    		 	}
	    		}
	    		if (!defined($ftrid)) {
	    			$ftrid = $ftrs->[0]->id();
	    		}
	    		push(@{$ftrlist},$ftrid);
	    		push(@{$esslist},$ftrs->[0]->id());
	    	}
	    }
	    push(@{$createinput->{objects}},[$ref.".essentials","string",{
		   description => "List of predicted essential genes from flux balance analysis",
		   fba => $ref,
		   objective => $object->objectiveValue(),
		   media => $mediaref,
		   model => $modelref
		},undef]);
		$objectdata->{$ref.".essentials"} = join("\n",@{$esslist});
	    my $ftrgroup = {
	    	id_list => {
	    		feature_id => $ftrlist
	    	},
	    	name => $object->fbamodel()->wsmeta()->[0]."-".$object->media()->wsmeta()->[0]."-essentials"
	    };
	    push(@{$createinput->{objects}},["/".Bio::KBase::utilities::user_id()."/home/Feature Groups/".$object->fbamodel()->wsmeta()->[0]."-".$object->media()->wsmeta()->[0]."-essentials","string",{
		   description => "Group of essential genes predicted by metabolic models",
		   fba => $ref,
		   objective => $object->objectiveValue(),
		   media => $mediaref,
		   model => $modelref
		},undef]);
		$objectdata->{"/".Bio::KBase::utilities::user_id()."/home/Feature Groups/".$object->fbamodel()->wsmeta()->[0]."-".$object->media()->wsmeta()->[0]."-essentials"} = Bio::KBase::ObjectAPI::utilities::TOJSON($ftrgroup);
    }
	#Calling create functions
	my $createoutput = Bio::ModelSEED::patricenv::call_ws("create",$createinput);
	for (my $i=0; $i < @{$createoutput}; $i++) {
		push(@{$listout},$createoutput->[$i]);
	}
	#Uploading actual files to shock
	$output = {};
	for (my $i=0; $i < @{$listout}; $i++) {
		Bio::KBase::utilities::log("Save fba:".$i."\t".join("\t",@{$listout->[$i]}));
		if (defined($listout->[$i]->[11]) && length($listout->[$i]->[11]) > 0 && defined($objectdata->{$listout->[$i]->[2].$listout->[$i]->[0]})) {
			$self->upload_to_shock($objectdata->{$listout->[$i]->[2].$listout->[$i]->[0]},$listout->[$i]->[11]);
		}
		if ($listout->[$i]->[0] eq "fba") {
			$output->{$listout->[$i]->[2].$listout->[$i]->[0]} = $listout->[$i];
			$fbameta = $listout->[$i];
			$fbameta->[0] = $refobject;
			$fbameta->[2] = $refpath."/";				
			$object->wsmeta($fbameta);
			$object->_reference($ref."||");
			$self->cache()->{$fbameta->[2].$fbameta->[0]} = [$fbameta,$object];
			$self->cache()->{$fbameta->[4]} = [$fbameta,$object];
			$self->cache()->{$ref} = [$fbameta,$object];
		}
	}
	return $output;
}

sub get_ref_from_metadata {
	my ($self,$metadata) = @_;
	return $metadata->[2].$metadata->[0];
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
