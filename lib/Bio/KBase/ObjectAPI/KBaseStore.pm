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

=head1 Bio::KBase::ObjectAPI::KBaseStore 

Class for managing KBase object retreival from KBase

=head2 ABSTRACT

=head2 NOTE


=head2 METHODS

=head3 new

    my $Store = Bio::KBase::ObjectAPI::KBaseStore->new(\%);
    my $Store = Bio::KBase::ObjectAPI::KBaseStore->new(%);

This initializes a Storage interface object. This accepts a hash
or hash reference to configuration details:

=over

=item auth

Authentication token to use when retrieving objects

=item workspace

Client or server class for accessing a KBase workspace

=back

=head3 Object Methods

=cut

package Bio::KBase::ObjectAPI::KBaseStore;
use Moose;
use Bio::KBase::ObjectAPI::utilities;

use Class::Autouse qw(
    Bio::KBase::kbaseenv
    Bio::KBase::workspace::Client
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
has uuid_refs => ( is => 'rw', isa => 'HashRef',default => sub { return {}; });
has updated_refs => ( is => 'rw', isa => 'HashRef',default => sub { return {}; });
has user_override => ( is => 'rw', isa => 'Str',default => "");

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub is_a_cache_target {
	my ($self,$ref) = @_;
	if (!defined($self->{_cache_targets})) {
		$self->{_cache_all} = 0;
		$self->{_cache_targets} = {};
		my $cache_targets = Bio::KBase::utilities::conf("ModelSEED","kbase_cache_targets");
		if (defined($cache_targets) && length($cache_targets) > 0) {
			my $array = [split(/;/,$cache_targets)];
			for (my $i=0; $i < @{$array}; $i++) {
				if ($array->[$i] eq "all") {
					$self->{_cache_all} = 1;
				} else {
					$self->{_cache_targets}->{$array->[$i]} = 1;
				}
			}
		}
	}
	if ($self->{_cache_all} == 1) {
		return 1;
	}
	if (defined($self->{_cache_targets}->{$ref})) {
		return 1;
	}
	return 0;
} 

sub ref_to_identity {
	my ($self,$ref) = @_;
	my $array = [split(/\//,$ref)];
	my $objid = {};
	if (@{$array} < 2) {
		Bio::KBase::ObjectAPI::utilities->error("Invalid reference:".$ref);
	}
	if ($array->[0] =~ m/^\d+$/) {
		$objid->{wsid} = $array->[0];
	} else {
		$objid->{workspace} = $array->[0];
	}
	if ($array->[1] =~ m/^\d+$/) {
		$objid->{objid} = $array->[1];
	} else {
		$objid->{name} = $array->[1];
	}
	if (defined($array->[2])) {
		$objid->{ver} = $array->[2];
	}
	return $objid;
}

#This function writes data to file cache if it's been flagged for local file caching
sub write_object_to_file_cache {
	my ($self,$info,$data) = @_;
	my $cache_dir = Bio::KBase::utilities::conf("ModelSEED","kbase_file_cache");
	if (defined($cache_dir) && length($cache_dir) > 0 && $self->is_a_cache_target($info->[6]."/".$info->[0]."/".$info->[4]) == 1 && !-e $cache_dir."/KBCache/".$info->[6]."/".$info->[0]."/".$info->[4]."/meta") {
		File::Path::mkpath $cache_dir."/KBCache/".$info->[6]."/".$info->[0]."/".$info->[4];
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($cache_dir."/KBCache/".$info->[6]."/".$info->[0]."/".$info->[4]."/meta",[Bio::KBase::ObjectAPI::utilities::TOJSON($info)]);
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($cache_dir."/KBCache/".$info->[6]."/".$info->[0]."/".$info->[4]."/data",[Bio::KBase::ObjectAPI::utilities::TOJSON($data)]);
	}
}

#This function writes data to file cache if it's been flagged for local file caching
sub read_object_from_file_cache {
	my ($self,$ref,$options) = @_;
	my $cache_dir = Bio::KBase::utilities::conf("ModelSEED","kbase_file_cache");
	if ($self->is_a_cache_target($ref) == 1) {
		#Get WS metadata
		my $infos;
		eval {
		$infos = Bio::KBase::kbaseenv::get_object_info([$self->ref_to_identity($ref)],0);
		};
		if ($@) {
			return 0;
		}
		my $info = $infos->[0];
		if (-e $cache_dir."/KBCache/".$info->[6]."/".$info->[0]."/".$info->[4]."/meta") {
			my $filearray = Bio::KBase::ObjectAPI::utilities::LOADFILE($cache_dir."/KBCache/".$info->[6]."/".$info->[0]."/".$info->[4]."/meta");
			my $meta = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{$filearray}));
			$filearray = Bio::KBase::ObjectAPI::utilities::LOADFILE($cache_dir."/KBCache/".$info->[6]."/".$info->[0]."/".$info->[4]."/data");
			my $data = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{$filearray}));
			$self->process_object($meta,$data,$ref,$options);
			return 1;
		}
	}
	return 0;
}

sub process_object {
	my ($self,$info,$data,$ref,$options) = @_;
	my $origref = $ref;
	my $array = [split(/;/,$ref)];
	$ref = pop(@{$array});
	$self->write_object_to_file_cache($info,$data);
	if ($info->[2] =~ m/^(.+)\.(.+)-/) {
		my $module = $1;
		my $type = $2;
		$type =~ s/^New//;
		my $class = "Bio::KBase::ObjectAPI::".$module."::".$type;
		if (($type eq "Genome" && Bio::KBase::utilities::conf("fba_tools","use_data_api") == 1) || ($type eq "GenomeAnnotation")) {
			require "GenomeAnnotationAPI/GenomeAnnotationAPIClient.pm";
			my $ga = new GenomeAnnotationAPI::GenomeAnnotationAPIClient(Bio::KBase::utilities::conf("fba_tools","call_back_url"));
			my $gaoutput = $ga->get_genome_v1({
				genomes => [{
					"ref" => $info->[6]."/".$info->[0]."/".$info->[4]
				}],
				ignore_errors => 1,
				no_data => 0,
				no_metadata => 1
			});
			$data = $gaoutput->{genomes}->[0]->{data};
			$class = "Bio::KBase::ObjectAPI::KBaseGenomes::Genome";
		}
		if ($type eq "MediaSet" || $type eq "ExpressionMatrix" || $type eq "ProteomeComparison" || $options->{raw} == 1) {
			$self->cache()->{$ref} = $data;
			$self->cache()->{$ref}->{_reference} = $info->[6]."/".$info->[0]."/".$info->[4];
			$self->cache()->{$ref}->{_ref_chain} = $origref;
		} else {
			$self->cache()->{$ref} = $class->new($data);
			$self->cache()->{$ref}->ref_chain($origref);
			$self->cache()->{$ref}->parent($self);
			$self->cache()->{$ref}->_wsobjid($info->[0]);
			$self->cache()->{$ref}->_wsname($info->[1]);
			$self->cache()->{$ref}->_wstype($info->[2]);
			$self->cache()->{$ref}->_wssave_date($info->[3]);
			$self->cache()->{$ref}->_wsversion($info->[4]);
			$self->cache()->{$ref}->_wssaved_by($info->[5]);
			$self->cache()->{$ref}->_wswsid($info->[6]);
			$self->cache()->{$ref}->_wsworkspace($info->[7]);
			$self->cache()->{$ref}->_wschsum($info->[8]);
			$self->cache()->{$ref}->_wssize($info->[9]);
			$self->cache()->{$ref}->_wsmeta($info->[10]);
			$self->cache()->{$ref}->_reference($info->[6]."/".$info->[0]."/".$info->[4]);
			$self->uuid_refs()->{$self->cache()->{$ref}->uuid()} = $info->[6]."/".$info->[0]."/".$info->[4];
		}
		if (!defined($self->cache()->{$info->[6]."/".$info->[0]."/".$info->[4]})) {
			$self->cache()->{$info->[6]."/".$info->[0]."/".$info->[4]} = $self->cache()->{$ref};
		}
		if ($type eq "Biochemistry") {
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
		if ($type eq "FBAModel" && $options->{raw} != 1) {
			if (defined($self->cache()->{$ref}->template_ref())) {
				if ($self->cache()->{$ref}->template_ref() =~ m/(\w+)\/(\w+)\/*\d*/) {
					my $output = Bio::KBase::kbaseenv::get_object_info([{
						"ref" => $self->cache()->{$ref}->template_ref()
					}],0);
					if ($output->[0]->[7] eq "KBaseTemplateModels" && $output->[0]->[1] eq "GramPosModelTemplate") {
						$self->cache()->{$ref}->template_ref("NewKBaseModelTemplates/GramPosModelTemplate");
					} elsif ($output->[0]->[7] eq "KBaseTemplateModels" && $output->[0]->[1] eq "GramNegModelTemplate") {
						$self->cache()->{$ref}->template_ref("NewKBaseModelTemplates/GramNegModelTemplate");
					} elsif ($output->[0]->[7] eq "KBaseTemplateModels" && $output->[0]->[1] eq "CoreModelTemplate ") {
						$self->cache()->{$ref}->template_ref("NewKBaseModelTemplates/GramNegModelTemplate");
					} elsif ($output->[0]->[7] eq "KBaseTemplateModels" && $output->[0]->[1] eq "PlantModelTemplate") {
						$self->cache()->{$ref}->template_ref("NewKBaseModelTemplates/PlantModelTemplate");
					} elsif ($output->[0]->[7] eq "NewKBaseModelTemplates") {
						$self->cache()->{$ref}->template_ref($output->[0]->[7]."/".$output->[0]->[1]);
					}
				}
			}
			if (defined($self->cache()->{$ref}->template_refs())) {
				my $temprefs = $self->cache()->{$ref}->template_refs();
				for (my $j=0; $j < @{$temprefs}; $j++) {
					my $output = Bio::KBase::kbaseenv::get_object_info([{
						"ref" => $temprefs->[$j]
					}],0);
					if ($output->[0]->[7] eq "KBaseTemplateModels" && $output->[0]->[1] eq "GramPosModelTemplate") {
						$temprefs->[$j] = "NewKBaseModelTemplates/GramPosModelTemplate";
					} elsif ($output->[0]->[7] eq "KBaseTemplateModels" && $output->[0]->[1] eq "GramNegModelTemplate") {
						$temprefs->[$j] = "NewKBaseModelTemplates/GramNegModelTemplate";
					} elsif ($output->[0]->[7] eq "KBaseTemplateModels" && $output->[0]->[1] eq "CoreModelTemplate ") {
						$temprefs->[$j] = "NewKBaseModelTemplates/GramNegModelTemplate";
					} elsif ($output->[0]->[7] eq "KBaseTemplateModels" && $output->[0]->[1] eq "PlantModelTemplate") {
						$temprefs->[$j] = "NewKBaseModelTemplates/PlantModelTemplate";
					} elsif ($output->[0]->[7] eq "NewKBaseModelTemplates") {
						$temprefs->[$j] = $output->[0]->[7]."/".$output->[0]->[1];
					}
				}
			}
			if (!defined($self->cache()->{$ref}->{_updated})) {
				my $obj = $self->cache()->{$ref};
				$obj->update_from_old_versions();
			}
		}
	}
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
		if ($refs->[$i] =~ m/^489\/6\/\d+$/ || $refs->[$i] =~ m/^kbase\/default\/\d+$/) {
			$refs->[$i] = "kbase/default";
		} elsif ($refs->[$i] =~ m/(.+;)489\/6\/\d+$/ || $refs->[$i] =~ m/(.+;)kbase\/default\/\d+$/) {
			$refs->[$i] = $1."kbase/default";
		}
		my $array = [split(/;/,$refs->[$i])];
		my $finalref = pop(@{$array});
		if ($finalref eq $refs->[$i] && defined($options->{parent}) && defined($options->{parent}->{_ref_chain})) {
			$refs->[$i] = $options->{parent}->{_ref_chain}.";".$refs->[$i];
		}
		if (!defined($self->cache()->{$finalref}) || $options->{refreshcache} == 1) {
    		if ($self->read_object_from_file_cache($finalref,$options) == 0) {
    			push(@{$newrefs},$refs->[$i]);
    		}
    	}
	}
	#Pulling objects from workspace
	if (@{$newrefs} > 0) {
		my $objids = [];
		for (my $i=0; $i < @{$newrefs}; $i++) {
			push(@{$objids},{"ref" => $newrefs->[$i]});
		}
		my $objdatas;
		eval {
			$objdatas = Bio::KBase::kbaseenv::get_objects($objids);
		};
		if ($@) {
			for (my $i=0; $i < @{$objids}; $i++) {
				my $array = [split(/;/,$objids->[$i]->{"ref"})];
				$objids->[$i]->{"ref"} = pop(@{$array});
			}
			$objdatas = Bio::KBase::kbaseenv::get_objects($objids);
		}
		for (my $i=0; $i < @{$objdatas}; $i++) {
			$self->process_object($objdatas->[$i]->{info},$objdatas->[$i]->{data},$newrefs->[$i],$options);
		}
	}
	#Gathering objects out of the cache
	my $objs = [];
	for (my $i=0; $i < @{$refs}; $i++) {
		my $array = [split(/;/,$refs->[$i])];
		my $finalref = pop(@{$array});
		$objs->[$i] = $self->cache()->{$finalref};
	}
	return $objs;
}

sub get_object {
    my ($self,$ref,$options) = @_;
    return $self->get_objects([$ref],$options)->[0];
}

sub get_object_by_handle {
    my ($self,$handle,$type,$options) = @_;
    my $typehandle = [split(/\./,$type)];
    $typehandle->[1] =~ s/^New//;
    my $class = "Bio::KBase::ObjectAPI::".$typehandle->[0]."::".$typehandle->[1];
    my $data;
    if ($handle->{type} eq "data") {
    	$data = $handle->{data};
    } elsif ($handle->{type} eq "workspace") {
    	$options->{url} = $handle->{url};
    	return $self->get_object($handle->{reference},$options);
    }
    return $class->new($data);
}

sub save_object {
    my ($self,$object,$ref,$params) = @_;
    my $args = {$ref => {hidden => $params->{hidden},meta => $params->{meta},object => $object}};
    if (defined($params->{hash}) && $params->{hash} == 1) {
    	$args->{$ref}->{hash} = 1;
    	$args->{$ref}->{type} = $params->{type};
    }
    my $output = $self->save_objects($args);
    return $output->{$ref};
}

sub save_objects {
    my ($self,$refobjhash) = @_;
    my $wsdata;
    my $output = {};
    foreach my $ref (keys(%{$refobjhash})) {
    	my $obj = $refobjhash->{$ref};
    	my $objdata = {
    		provenance => Bio::KBase::utilities::provenance()
    	};
    	if (defined($obj->{hash}) && $obj->{hash} == 1) {
    		$objdata->{type} = $obj->{type};
    		$objdata->{data} = $obj->{object};
    	} else {
    		$objdata->{type} = $obj->{object}->_type();
    		$objdata->{data} = $obj->{object}->serializeToDB();	
    	}
    	if (defined($obj->{hidden})) {
    		$objdata->{hidden} = $obj->{hidden};
    	}
    	if (defined($obj->{meta})) {
    		$objdata->{meta} = $obj->{meta};
    	}
    	if (defined($objdata->{provenance}->[0]->{method_params}->[0]->{notes})) {
    		$objdata->{meta}->{notes} = $objdata->{provenance}->[0]->{method_params}->[0]->{notes};
    	}
    	my $array = [split(/\//,$ref)];
		if (@{$array} < 2) {
			Bio::KBase::ObjectAPI::utilities->error("Invalid reference:".$ref);
		}
		if ($array->[1] =~ m/^\d+$/) {
			$objdata->{objid} = $array->[1];
		} else {
			$objdata->{name} = $array->[1];
		}
		if ($objdata->{type} eq "KBaseGenomes.Genome" && Bio::KBase::utilities::conf("fba_tools","use_data_api") == 1) {
			require "GenomeAnnotationAPI/GenomeAnnotationAPIClient.pm";
			my $ga = new GenomeAnnotationAPI::GenomeAnnotationAPIClient(Bio::KBase::utilities::conf("ModelSEED","call_back_url"));
			my $gaout = $ga->save_one_genome_v1({
				workspace => $array->[0],
		        name => $array->[1],
		        data => $objdata->{data},
		        provenance => $objdata->{provenance},
		        hidden => $obj->{hidden}
			});
			my $info = $gaout->{info};
	    	$self->cache()->{$gaout->{info}->[6]."/".$gaout->{info}->[0]."/".$gaout->{info}->[4]} = $obj->{object};
	    	$self->cache()->{$gaout->{info}->[7]."/".$gaout->{info}->[1]."/".$gaout->{info}->[4]} = $obj->{object};
		    $self->uuid_refs()->{$obj->{object}->uuid()} = $gaout->{info}->[7]."/".$gaout->{info}->[1]."/".$gaout->{info}->[4];
		    $refobjhash->{$ref}->{object}->_reference($gaout->{info}->[6]."/".$gaout->{info}->[0]."/".$gaout->{info}->[4]);
	    	$refobjhash->{$ref}->{object}->_wsobjid($gaout->{info}->[0]);
			$refobjhash->{$ref}->{object}->_wsname($gaout->{info}->[1]);
			$refobjhash->{$ref}->{object}->_wstype($gaout->{info}->[2]);
			$refobjhash->{$ref}->{object}->_wssave_date($gaout->{info}->[3]);
			$refobjhash->{$ref}->{object}->_wsversion($gaout->{info}->[4]);
			$refobjhash->{$ref}->{object}->_wssaved_by($gaout->{info}->[5]);
			$refobjhash->{$ref}->{object}->_wswsid($gaout->{info}->[6]);
			$refobjhash->{$ref}->{object}->_wsworkspace($gaout->{info}->[7]);
			$refobjhash->{$ref}->{object}->_wschsum($gaout->{info}->[8]);
			$refobjhash->{$ref}->{object}->_wssize($gaout->{info}->[9]);
			$refobjhash->{$ref}->{object}->_wsmeta($gaout->{info}->[10]);
	    	$output->{$ref} = $gaout->{info};
			next;
		}
		push(@{$wsdata->{$array->[0]}->{refs}},$ref);
		push(@{$wsdata->{$array->[0]}->{objects}},$objdata);
    }
	foreach my $ws (keys(%{$wsdata})) {
    	my $input = {objects => $wsdata->{$ws}->{objects}};
    	if ($ws  =~ m/^\d+$/) {
    		$input->{id} = $ws;
    	} else {
    		$input->{workspace} = $ws;
    	}
    	my $listout;
    	if (defined($self->user_override()) && length($self->user_override()) > 0) {
    		$listout = Bio::KBase::utilities::administer({
    			"command" => "saveObjects",
    			"user" => $self->user_override(),
    			"params" => $input
    		});
    	} else {
    		$listout = Bio::KBase::kbaseenv::save_objects($input);
    	}    	
	    #Placing output into a hash of references pointing to object infos
	    for (my $i=0; $i < @{$listout}; $i++) {
	    	$self->cache()->{$listout->[$i]->[6]."/".$listout->[$i]->[0]."/".$listout->[$i]->[4]} = $refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object};
	    	$self->cache()->{$listout->[$i]->[7]."/".$listout->[$i]->[1]."/".$listout->[$i]->[4]} = $refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object};
	    	if (!defined($refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{hash}) || $refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{hash} == 0) {
		    	$self->uuid_refs()->{$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->uuid()} = $listout->[$i]->[6]."/".$listout->[$i]->[0]."/".$listout->[$i]->[4];
		    	if ($refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_reference() =~ m/^\w+\/\w+\/\w+$/) {
		    		$self->updated_refs()->{$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_reference()} = $listout->[$i]->[6]."/".$listout->[$i]->[0]."/".$listout->[$i]->[4];
		    	}
		    	$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_reference($listout->[$i]->[6]."/".$listout->[$i]->[0]."/".$listout->[$i]->[4]);
		    	$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wsobjid($listout->[$i]->[0]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wsname($listout->[$i]->[1]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wstype($listout->[$i]->[2]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wssave_date($listout->[$i]->[3]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wsversion($listout->[$i]->[4]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wssaved_by($listout->[$i]->[5]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wswsid($listout->[$i]->[6]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wsworkspace($listout->[$i]->[7]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wschsum($listout->[$i]->[8]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wssize($listout->[$i]->[9]);
				$refobjhash->{$wsdata->{$ws}->{refs}->[$i]}->{object}->_wsmeta($listout->[$i]->[10]);
	    	}
	    	$output->{$wsdata->{$ws}->{refs}->[$i]} = $listout->[$i];
	    }
	    return $output;
    }
}

sub list_objects {
	my ($self,$input) = @_;
	return Bio::KBase::kbaseenv::list_objects($input);
}

sub uuid_to_ref {
	my ($self,$uuid) = @_;
	return $self->uuid_refs()->{$uuid};
}

sub updated_reference {
	my ($self,$oldref) = @_;
	return $self->updated_refs()->{$oldref};
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
