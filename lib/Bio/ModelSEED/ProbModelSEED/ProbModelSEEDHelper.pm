package Bio::ModelSEED::ProbModelSEED::ProbModelSEEDHelper;
use strict;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

use Bio::P3::Workspace::WorkspaceClientExt;
use JSON::XS;
use Data::Dumper;
use Log::Log4perl;
use Bio::KBase::ObjectAPI::utilities;
use Bio::KBase::ObjectAPI::logging;
use Bio::KBase::ObjectAPI::PATRICStore;
use Bio::ModelSEED::Client::SAP;
use Bio::KBase::AppService::Client;
use Bio::KBase::ObjectAPI::KBaseStore;
use Bio::ModelSEED::MSSeedSupportServer::MSSeedSupportClient;

#****************************************************************************
#Data retrieval and storage functions functions
#****************************************************************************
sub save_object {
	my($self, $ref,$data,$type,$metadata) = @_;
	my $object = $self->PATRICStore()->save_object($data,$ref,$metadata,$type,1);
	return $object;
}
sub copy_object {
	my($self,$ref,$destination,$recursive) = @_;
	return $self->call_ws("copy",{
		objects => [[$ref,$destination]],
		adminmode => Bio::KBase::ObjectAPI::config::adminmode(),
		overwrite => 1,
		recursive => $recursive,
	});
}
sub get_object {
	my($self, $ref,$type,$options) = @_;
	my $object = $self->PATRICStore()->get_object($ref,$options);
	if (defined($type)) {
		my $objtype = $self->PATRICStore()->get_object_type($ref);
		if ($objtype ne $type) {
			$self->error("Type retrieved (".$objtype.") does not match specified type (".$type.")!");
		}
	}
	return $object;
}
sub get_genome {
	my($self, $ref) = @_;
	my $obj;
	if ($ref =~ m/^PATRIC:(.+)/) {
    	return $self->retrieve_PATRIC_genome($1);
    } elsif ($ref =~ m/^PATRICSOLR:(.+)/) {
    	Bio::KBase::ObjectAPI::config::old_models(1);
    	return $self->retrieve_PATRIC_genome($1);
	} elsif ($ref =~ m/^REFSEQ:(.+)/) {
    	return $self->retrieve_PATRIC_genome($1,1);
	} elsif ($ref =~ m/^PUBSEED:(.+)/) {
    	return $self->retrieve_SEED_genome($1);
	} elsif ($ref =~ m/^RAST:(.+)/) {
    	return $self->retrieve_RAST_genome($1);
	} else {
		$obj = $self->get_object($ref);
	    if (defined($obj) && ref($obj) ne "Bio::KBase::ObjectAPI::KBaseGenomes::Genome" && defined($obj->{output_files})) {
	    	my $output = $obj->{output_files};
	    	for (my $i=0; $i < @{$obj->{output_files}}; $i++) {
	    		if ($obj->{output_files}->[$i]->[0] =~ m/\.genome$/) {
	    			$ref = $obj->{output_files}->[$i]->[0];
	    		}
	    	}
	    	$obj = $self->get_object($ref,"genome");
	    }
	}
    if (!defined($obj)) {
    	$self->error("Genome retrieval failed!");
    }
	return $obj;
}
sub get_model_meta {
	my($self, $ref) = @_;
	my $metas = $self->call_ws("get",{
		objects => [$ref],
		metadata_only => 1,
		adminmode => Bio::KBase::ObjectAPI::config::adminmode()
	});
	if (!defined($metas->[0]->[0]->[0])) {
    	return undef;
    }
	return $metas->[0]->[0];
}

sub update_model_meta {
	my($self,$ref,$meta,$create_time) = @_;
	$self->workspace_service()->update_metadata({
		objects => [ [$ref,$meta] ],
		adminmode => Bio::KBase::ObjectAPI::config::adminmode()
	});
	return;
}
#This function retrieves or sets the biochemistry object in the server memory, making retrieval of biochemsitry very fast
sub biochemistry {
	my($self,$bio) = @_;
	if (defined($bio)) {
		#In this case, the cache is being overwritten with an existing biochemistry object (e.g. ProbModelSEED servers will call this)
		$self->{_cached_biochemistry} = $bio;
		$self->PATRICStore()->cache()->{Bio::KBase::ObjectAPI::config::biochemistry()}->[0] = $bio->wsmeta();
		$self->PATRICStore()->cache()->{Bio::KBase::ObjectAPI::config::biochemistry()}->[1] = $bio;
	}
	if (!defined($self->{_cached_biochemistry})) {
		$self->{_cached_biochemistry} = $self->get_object(Bio::KBase::ObjectAPI::config::biochemistry(),"biochemistry");		
	}
	return $self->{_cached_biochemistry};
}

sub workspace_service {
	my($self) = @_;
	if (!defined($self->{_workspace_service})) {
		$self->{_workspace_service} = Bio::P3::Workspace::WorkspaceClientExt->new(Bio::KBase::ObjectAPI::config::workspace_url(),token => Bio::KBase::ObjectAPI::config::token());
	}
	return $self->{_workspace_service};
}
sub app_service {
	my($self) = @_;
	if (!defined($self->{_app_service})) {
		$self->{_app_service} = Bio::KBase::AppService::Client->new(Bio::KBase::ObjectAPI::config::appservice_url(),token => Bio::KBase::ObjectAPI::config::token());
	}
	return $self->{_app_service};
}
sub PATRICStore {
	my($self) = @_;
	if (!defined($self->{_PATRICStore})) {
		my $cachetarg = {};
		for (my $i=0; $i < @{Bio::KBase::ObjectAPI::config::cache_targets()}; $i++) {
			$cachetarg->{Bio::KBase::ObjectAPI::config::cache_targets()->[$i]} = 1;
		}
		$self->{_PATRICStore} = Bio::KBase::ObjectAPI::PATRICStore->new({
			helper => $self,
			data_api_url => Bio::KBase::ObjectAPI::config::data_api_url(),
			workspace => $self->workspace_service(),
			adminmode => Bio::KBase::ObjectAPI::config::adminmode(),
			file_cache => Bio::KBase::ObjectAPI::config::file_cache(),
    		cache_targets => $cachetarg
		});
	}
	return $self->{_PATRICStore};
}
sub KBaseStore {
	my($self,$parameters) = @_;
	$parameters = $self->validate_args($parameters,[],{
		kbwsurl => Bio::KBase::ObjectAPI::config::kbwsurl(),
		kbuser => undef,
		kbpassword => undef,
		kbtoken => undef
    });
    if (!defined($parameters->{kbtoken})) {
    	my $token = Bio::KBase::ObjectAPI::utilities::kblogin({
    		user_id => $parameters->{kbuser},
    		password => $parameters->{kbpassword}
    	});
		if (!defined($token)) {
			Bio::KBase::ObjectAPI::utilities::error("Failed to authenticate KBase user ".$parameters->{kbuser});
		}
		$parameters->{kbtoken} = $token;
    }
    require "Bio/KBase/workspace/Client.pm";
    my $wsclient = Bio::KBase::workspace::Client->new($parameters->{kbwsurl},token => $parameters->{kbtoken});
    return Bio::KBase::ObjectAPI::KBaseStore->new({
		provenance => [{
			"time" => DateTime->now()->datetime()."+0000",
			service_ver => $VERSION,
			service => "ProbModelSEED",
			method => Bio::KBase::ObjectAPI::config::method,
			method_params => [],
			input_ws_objects => [],
			resolved_ws_objects => [],
			intermediate_incoming => [],
			intermediate_outgoing => []
		}],
		workspace => $wsclient,
		file_cache => undef,
		cache_targets => [],
	});
}
sub call_ws {
	my($self,$function,$args) = @_;
	return $self->PATRICStore()->call_ws($function,$args);
}
#****************************************************************************
#Utility functions
#****************************************************************************
sub validate_args {
	my ($self,$args,$mandatoryArguments,$optionalArguments) = @_;
	return Bio::KBase::ObjectAPI::utilities::ARGS($args,$mandatoryArguments,$optionalArguments);
}
sub error {
	my($self,$msg) = @_;
	Bio::KBase::ObjectAPI::utilities::error($msg);
}

#****************************************************************************
#Research functions
#****************************************************************************
=head3 delete_model

Definition:
	Genome = $self->delete_model(ref Model);
Description:
	Deletes the specified model
		
=cut
sub delete_model {
	my($self,$model) = @_;
	# Not quite sure what will happen if the model or modelfolder does not exist 
	my $output = $self->call_ws("delete",{
		objects => [$model],
		deleteDirectories => 1,
		force => 1,
	});
	# Only return metadata on model object.
	return $output->[0];
}

=head3 get_model_data

Definition:
	model_data = $self->get_model_data(ref modelref);
Description:
	Gets the specified model
		
=cut
sub get_model_data {
	my ($self,$modelref) = @_;
	my $model = $self->get_object($modelref);
	return $model->export({format => "condensed"});
}

sub get_model_summary {
	my ($self,$model) = @_;
	my $modelmeta = $model->wsmeta();
	my $numcpds = @{$model->modelcompounds()};
	my $numrxns = @{$model->modelreactions()};
	my $numcomps = @{$model->modelcompartments()};
	my $numbio = @{$model->biomasses()};
	my $output = {
		id => $modelmeta->[0],
		source => $model->source(),
		source_id => $modelmeta->[0],
		name => $model->name(),
		type => $model->type(),
		genome_ref => $modelmeta->[2].$modelmeta->[0]."/genome",
		template_ref => $model->template_ref(),
		num_compounds => $numcpds,
		num_reactions => $numrxns,
		num_compartments => $numcomps,
		num_biomasses => $numbio,
		num_genes => $model->gene_count(),
		rundate => $modelmeta->[3],
		"ref" => $modelmeta->[2].$modelmeta->[0],
		gene_associated_reactions => $model->gene_associated_reaction_count(),
		gapfilled_reactions => $model->gapfilled_reaction_count(),
		fba_count => 0,
		num_biomass_compounds => $model->biomass_compound_count(),
		integrated_gapfills => $model->integrated_gapfill_count(),
		unintegrated_gapfills => $model->unintegrated_gapfill_count()
	};
	if (defined($model->genome_ref()) && defined($model->genome())) {
		$output->{genome_source} = $model->genome()->source();
	}
	$output->{template_ref} =~ s/\|\|//;
	my $list = $self->call_ws("ls",{
		paths => [$modelmeta->[2].$modelmeta->[0]."/fba"],
		excludeDirectories => 1,
		excludeObjects => 0,
		recursive => 0,
		query => {type => "fba"}
	});
	if (defined($list->{$modelmeta->[2].$modelmeta->[0]."/fba"})) {
		$list = $list->{$modelmeta->[2].$modelmeta->[0]."/fba"};
		$output->{fba_count} = @{$list};
	}
	return $output;
}

=head3 classify_genome

Definition:
	Genome = $self->classify_genome(string classifier,Genome genome);
Description:
	Returns the cell wall classification for genome
		
=cut
sub classify_genome {
	my($self,$classifier,$genome) = @_;
	my $data = [split(/\n/,$classifier)];
    my $headings = [split(/\t/,$data->[0])];
	my $popprob = [split(/\t/,$data->[1])];
	my $classdata = {};
	for (my $i=1; $i < @{$headings}; $i++) {
		$classdata->{classifierClassifications}->{$headings->[$i]} = {
			name => $headings->[$i],
			populationProbability => $popprob->[$i]
		};
	}
	my $cfRoleHash = {};
	for (my $i=2;$i < @{$data}; $i++) {
		my $row = [split(/\t/,$data->[$i])];
		my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($row->[0]);
		$classdata->{classifierRoles}->{$searchrole} = {
			classificationProbabilities => {},
			role => $row->[0]
		};
		for (my $j=1; $j < @{$headings}; $j++) {
			$classdata->{classifierRoles}->{$searchrole}->{classificationProbabilities}->{$headings->[$j]} = $row->[$j];
		}
	}
	my $scores = {};
	my $sum = 0;
	foreach my $class (keys(%{$classdata->{classifierClassifications}})) {
		$scores->{$class} = 0;
		$sum += $classdata->{classifierClassifications}->{$class}->{populationProbability};
	}
	my $genes = $genome->features();
	foreach my $gene (@{$genes}) {
		my $roles = $gene->roles();
		foreach my $role (@{$roles}) {
			my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($role);
			if (defined($classdata->{classifierRoles}->{$searchrole})) {
				foreach my $class (keys(%{$classdata->{classifierClassifications}})) {
					$scores->{$class} += $classdata->{classifierRoles}->{$searchrole}->{classificationProbabilities}->{$class};
				}
			}
		}
	}
	my $largest;
	my $largestClass;
	foreach my $class (keys(%{$classdata->{classifierClassifications}})) {
		$scores->{$class} += log($classdata->{classifierClassifications}->{$class}->{populationProbability}/$sum);
		if (!defined($largest)) {
			$largest = $scores->{$class};
			$largestClass = $class;
		} elsif ($largest > $scores->{$class}) {
			$largest = $scores->{$class};
			$largestClass = $class;
		}
	}
	return $largestClass;
}
=head3 retrieve_PATRIC_genome

Definition:
	Genome = $self->retrieve_PATRIC_genome(string genome);
Description:
	Returns typed object for genome in PATRIC reference database
		
=cut
sub retrieve_PATRIC_genome {
	my ($self,$genomeid,$refseq) = @_;
	#Retrieving genome information
	my $data = Bio::KBase::ObjectAPI::utilities::rest_download({url => Bio::KBase::ObjectAPI::config::data_api_url()."genome/?genome_id=".$genomeid."&http_accept=application/json",token => Bio::KBase::ObjectAPI::config::token()});
	if (!defined($refseq)) {
		$refseq = 0;
	}
	$data = $data->[0];
	my $perm = "n";
	my $uperm = "o";
	if ($data->{public} == 1) {
		$perm = "r";
		$uperm = "r";
	}
	$data = Bio::KBase::ObjectAPI::utilities::ARGS($data,[],{
		genome_length => 0,
		contigs => 0,
		genome_name => "Unknown",
		taxon_lineage_names => ["Unknown"],
		owner => "Unknown",
		gc_content => 0,
		publication => "Unknown",
		completion_date => "1970-01-01T00:00:00+0000"
	});
	my $meta = [
    	$genomeid,
		"genome",
		Bio::KBase::ObjectAPI::config::data_api_url()."genome/?genome_id=".$genomeid."&http_accept=application/json",
		$data->{completion_date},
		$genomeid,
		$data->{owner},
		$data->{genome_length},
		{},
		{},
		$uperm,
		$perm
    ];
    my $genomesource = "PATRIC";
    if ($refseq == 1) {
    	$genomesource = "RefSeq";
    }
	my $genome = {
    	id => $genomeid,
		scientific_name => $data->{genome_name},
		domain => $data->{taxon_lineage_names}->[0],
		genetic_code => 11,
		dna_size => $data->{genome_length},
		num_contigs => $data->{contigs},
		contigs => [],
		contig_lengths => [],
		contig_ids => [],
		source => $genomesource,
		source_id => $genomeid,
		md5 => "none",
		taxonomy => join(":",@{$data->{taxon_lineage_names}}),
		gc_content => $data->{gc_content},
		complete => 1,
		publications => [$data->{publication}],
		features => [],
		contigset_ref => "",
	};
	#Retrieving feature information
	my $start = 0;
	my $params = {};
	my $loopcount = 0;
	my $ftrcount = 0;
	while ($start >= 0 && $loopcount < 100) {
		$loopcount++;#Insurance that no matter what, this loop won't run for more than 100 iterations
		my $ftrdata = Bio::KBase::ObjectAPI::utilities::rest_download({url => Bio::KBase::ObjectAPI::config::data_api_url()."genome_feature/?genome_id=".$genomeid."&http_accept=application/json&limit(10000,$start)",token => Bio::KBase::ObjectAPI::config::token()},$params);
		if (defined($ftrdata) && @{$ftrdata} > 0) {
			my $currentcount = @{$ftrdata};
			$ftrcount += $currentcount;
			for (my $i=0; $i < @{$ftrdata}; $i++) {
				$data = $ftrdata->[$i];
				if (($data->{feature_id} =~ m/^PATRIC/ && $refseq == 0) || ($data->{feature_id} =~ m/^RefSeq/ && $refseq == 1)) {
					my $id;
					if ($refseq == 1) {
						$id = $data->{refseq_locus_tag};
					} else {
						$id = $data->{patric_id};
					}
					if (defined($id)) {
						my $ftrobj = {id => $id,type => "CDS",aliases=>[]};
						if (defined($data->{start})) {
							$ftrobj->{location} = [[$data->{sequence_id},$data->{start},$data->{strand},$data->{na_length}]];
						}
						if (defined($data->{feature_type})) {
							$ftrobj->{type} = $data->{feature_type};
						}
						if (defined($data->{product})) {
							$ftrobj->{function} = $data->{product};
						}
						if (defined($data->{na_sequence})) {
							$ftrobj->{dna_sequence} = $data->{na_sequence};
							$ftrobj->{dna_sequence_length} = $data->{na_length};
						}
						if (defined($data->{aa_sequence})) {
							$ftrobj->{protein_translation} = $data->{aa_sequence};
							$ftrobj->{protein_translation_length} = $data->{aa_length};
							$ftrobj->{md5} = $data->{aa_sequence_md5};
						}
						my $list = ["feature_id","alt_locus_tag","refseq_locus_tag","protein_id","figfam_id"];
						for (my $j=0; $j < @{$list}; $j++) {
							if (defined($data->{$list->[$j]})) {
								push(@{$ftrobj->{aliases}},$data->{$list->[$j]});
							}
						}
						push(@{$genome->{features}},$ftrobj);
					}
				}
			}
		}
		if ($ftrcount < $params->{count}) {
			$start = $ftrcount;
		} else {
			$start = -1;
		}
	}
	my $genome = Bio::KBase::ObjectAPI::KBaseGenomes::Genome->new($genome);
	$genome->wsmeta($meta);
	if ($refseq == 1) {
		$genome->_reference("REFSEQ:".$genomeid);
	} else {
		$genome->_reference("PATRIC:".$genomeid);
	}
	$genome->parent($self->PATRICStore());
	return $genome;
}
=head3 retrieve_SEED_genome
Definition:
	Genome = $self->retrieve_SEED_genome(string genome);
Description:
	Returns typed object for genome in SEED reference database
		
=cut
sub retrieve_SEED_genome {
	my($self,$id) = @_;
	my $sapsvr = Bio::ModelSEED::Client::SAP->new();
	my $data = $sapsvr->genome_data({
		-ids => [$id],
		-data => [qw(gc-content dna-size name taxonomy domain genetic-code)]
	});
	if (!defined($data->{$id})) {
    	$self->error("PubSEED genome ".$id." not found!");
    }
    my $genomeObj = {
		id => $id,
		scientific_name => $data->{$id}->[2],
		domain => $data->{$id}->[4],
		genetic_code => $data->{$id}->[5],
		dna_size => $data->{$id}->[1],
		num_contigs => 0,
		contig_lengths => [],
		contig_ids => [],
		source => "PubSEED",
		source_id => $id,
		taxonomy => $data->{$id}->[3],
		gc_content => $data->{$id}->[0]/100,
		complete => 1,
		publications => [],
		features => [],
    };
    my $contigset = {
		name => $genomeObj->{scientific_name},
		source_id => $genomeObj->{source_id},
		source => $genomeObj->{source},
		type => "Organism",
		contigs => []
    };
	my $featureHash = $sapsvr->all_features({-ids => $id});
	my $genomeHash = $sapsvr->genome_contigs({
		-ids => [$id]
	});
	my $featureList = $featureHash->{$id};
	my $contigList = $genomeHash->{$id};
	my $functions = $sapsvr->ids_to_functions({-ids => $featureList});
	my $locations = $sapsvr->fid_locations({-ids => $featureList});
	my $sequences = $sapsvr->fids_to_proteins({-ids => $featureList,-sequence => 1});
	my $contigHash = $sapsvr->contig_sequences({
		-ids => $contigList
	});
	foreach my $key (keys(%{$contigHash})) {
		$genomeObj->{num_contigs}++;
		push(@{$genomeObj->{contig_ids}},$key);
		push(@{$genomeObj->{contig_lengths}},length($contigHash->{$key}));
		push(@{$contigset->{contigs}},{
			id => $key,
			"length" => length($contigHash->{$key}),
			md5 => Digest::MD5::md5_hex($contigHash->{$key}),
			sequence => $contigHash->{$key},
			name => $key
		});
	}
	my $sortedcontigs = [sort { $a->{sequence} cmp $b->{sequence} } @{$contigset->{contigs}}];
	my $str = "";
	for (my $i=0; $i < @{$sortedcontigs}; $i++) {
		if (length($str) > 0) {
			$str .= ";";
		}
		$str .= $sortedcontigs->[$i]->{sequence};	
	}
	$genomeObj->{md5} = Digest::MD5::md5_hex($str);
	$contigset->{md5} = $genomeObj->{md5};
	$contigset->{id} = $id.".contigs";
	for (my $i=0; $i < @{$featureList}; $i++) {
		my $feature = {
  			id => $featureList->[$i],
			type => "peg",
			publications => [],
			subsystems => [],
			protein_families => [],
			aliases => [],
			annotations => [],
			subsystem_data => [],
			regulon_data => [],
			atomic_regulons => [],
			coexpressed_fids => [],
			co_occurring_fids => []
  		};
  		if ($featureList->[$i] =~ m/\.([^\.]+)\.\d+$/) {
  			$feature->{type} = $1;
  		}
		if (defined($functions->{$featureList->[$i]})) {
			$feature->{function} = $functions->{$featureList->[$i]};
		}
		if (defined($sequences->{$featureList->[$i]})) {
			$feature->{protein_translation} = $sequences->{$featureList->[$i]};
			$feature->{protein_translation_length} = length($feature->{protein_translation});
  			$feature->{dna_sequence_length} = 3*$feature->{protein_translation_length};
  			$feature->{md5} = Digest::MD5::md5_hex($feature->{protein_translation});
		}
  		if (defined($locations->{$featureList->[$i]}->[0])) {
			for (my $j=0; $j < @{$locations->{$featureList->[$i]}}; $j++) {
				my $loc = $locations->{$featureList->[$i]}->[$j];
				if ($loc =~ m/^(.+)_(\d+)([\+\-])(\d+)$/) {
					my $array = [split(/:/,$1)];
					if ($3 eq "-" || $3 eq "+") {
						$feature->{location}->[$j] = [$array->[1],$2,$3,$4];
					} elsif ($2 > $4) {
						$feature->{location}->[$j] = [$array->[1],$2,"-",($2-$4)];
					} else {
						$feature->{location}->[$j] = [$array->[1],$2,"+",($4-$2)];
					}
					$feature->{location}->[$j]->[1] = $feature->{location}->[$j]->[1]+0;
					$feature->{location}->[$j]->[3] = $feature->{location}->[$j]->[3]+0;
				}
			}
			
		}
  		push(@{$genomeObj->{features}},$feature);	
	}
	my $ContigObj = Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet->new($contigset);
	$genomeObj = Bio::KBase::ObjectAPI::KBaseGenomes::Genome->new($genomeObj);
	$genomeObj->contigs($ContigObj);
	return $genomeObj;
}
=head3 retrieve_RAST_genome

Definition:
	Genome = $self->retrieve_RAST_genome(string genome);
Description:
	Returns typed object for genome in RAST reference database
		
=cut
sub retrieve_RAST_genome {
	my($self,$id,$username,$password) = @_;
	my $mssvr = Bio::ModelSEED::MSSeedSupportServer::MSSeedSupportClient->new(Bio::KBase::ObjectAPI::config::mssserver_url());
	$mssvr->{token} = Bio::KBase::ObjectAPI::config::token();
	$mssvr->{client}->{token} = Bio::KBase::ObjectAPI::config::token();
	my $data = $mssvr->getRastGenomeData({
		genome => $id,
		username => $username,
		password => $password,
		getSequences => 1,
		getDNASequence => 1
	});
    if (!defined($data->{owner})) {
    	$self->_error("RAST genome ".$id." not found!",'get_genomeobject');
    }
	my $genomeObj = {
		id => $id,
		scientific_name => $data->{name},
		domain => $data->{taxonomy},
		genetic_code => 11,
		dna_size => $data->{size},
		num_contigs => 0,
		contig_lengths => [],
		contig_ids => [],
		source => "RAST",
		source_id => $id,
		taxonomy => $data->{taxonomy},
		gc_content => 0.5,
		complete => 1,
		publications => [],
		features => [],
    };
    my $contigset = {
		name => $genomeObj->{scientific_name},
		source_id => $genomeObj->{source_id},
		source => $genomeObj->{source},
		type => "Organism",
		contigs => []
    };
    my $contighash = {};
	for (my $i=0; $i < @{$data->{features}}; $i++) {
		my $ftr = $data->{features}->[$i];
		my $feature = {
  			id => $ftr->{ID}->[0],
			type => "peg",
			publications => [],
			subsystems => [],
			protein_families => [],
			aliases => [],
			annotations => [],
			subsystem_data => [],
			regulon_data => [],
			atomic_regulons => [],
			coexpressed_fids => [],
			co_occurring_fids => [],
			protein_translation_length => 0,
			protein_translation => "",
			dna_sequence_length => 0,
			md5 => ""
  		};
  		if ($ftr->{ID}->[0] =~ m/\.([^\.]+)\.\d+$/) {
  			$feature->{type} = $1;
  		}
  		if (defined($ftr->{SEQUENCE})) {
			$feature->{protein_translation} = $ftr->{SEQUENCE}->[0];
			$feature->{protein_translation_length} = length($feature->{protein_translation});
  			$feature->{dna_sequence_length} = 3*$feature->{protein_translation_length};
  			$feature->{md5} = Digest::MD5::md5_hex($feature->{protein_translation});
		}
		if (defined($ftr->{ROLES})) {
			$feature->{function} = join(" / ",@{$ftr->{ROLES}});
		}
  		if (defined($ftr->{LOCATION}->[0]) && $ftr->{LOCATION}->[0] =~ m/^(.+)_(\d+)([\+\-_])(\d+)$/) {
			my $contigData = $1;
			if (!defined($contighash->{$contigData})) {
				$contighash->{$contigData} = $2;
			} elsif ($2 > $contighash->{$contigData}) {
				$contighash->{$contigData} = $2;
			}
			if ($3 eq "-" || $3 eq "+") {
				$feature->{location} = [[$contigData,$2,$3,$4]];
			} elsif ($2 > $4) {
				$feature->{location} = [[$contigData,$2,"-",($2-$4)]];
			} else {
				$feature->{location} = [[$contigData,$2,"+",($4-$2)]];
			}
			$feature->{location}->[0]->[1] = $feature->{location}->[0]->[1]+0;
			$feature->{location}->[0]->[3] = $feature->{location}->[0]->[3]+0;
		}
  		push(@{$genomeObj->{features}},$feature);
	}
	my $ContigObj;
	if (defined($data->{DNAsequence}->[0])) {
    	my $gccount = 0;
    	my $size = 0;
    	for (my $i=0; $i < @{$data->{DNAsequence}}; $i++) {
    		my $closest;
    		foreach my $key (keys(%{$contighash})) {
    			my $dist = abs(length($data->{DNAsequence}->[$i]) - $contighash->{$key});
    			my $closestdist = abs(length($data->{DNAsequence}->[$i]) - $contighash->{$closest});
    			if (!defined($closest) || $dist < $closestdist) {
    				$closest = $key;
    			}
    		}
    		push(@{$contigset->{contigs}},{
    			id => $closest,
				"length" => length($data->{DNAsequence}->[$i]),
				md5 => Digest::MD5::md5_hex($data->{DNAsequence}->[$i]),
				sequence => $data->{DNAsequence}->[$i],
				name => $closest
    		});
    		push(@{$genomeObj->{contig_lengths}},length($data->{DNAsequence}->[$i]));
    		$size += length($data->{DNAsequence}->[$i]);
    		push(@{$genomeObj->{contig_ids}},$closest);
			for ( my $j = 0 ; $j < length($data->{DNAsequence}->[$i]) ; $j++ ) {
				if ( substr( $data->{DNAsequence}->[$i], $j, 1 ) =~ m/[gcGC]/ ) {
					$gccount++;
				}
			}
    	}
    	if ($size > 0) {
			$genomeObj->{gc_content} = $$gccount/$size;
		}
		my $sortedcontigs = [sort { $a->{sequence} cmp $b->{sequence} } @{$contigset->{contigs}}];
		my $str = "";
		for (my $i=0; $i < @{$sortedcontigs}; $i++) {
			if (length($str) > 0) {
				$str .= ";";
			}
			$str .= $sortedcontigs->[$i]->{sequence};	
		}
		$genomeObj->{md5} = Digest::MD5::md5_hex($str);
		$contigset->{md5} = $genomeObj->{md5};
		$contigset->{id} = $id.".contigs";
    	$ContigObj = Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet->new($contigset);
	}
	$genomeObj = Bio::KBase::ObjectAPI::KBaseGenomes::Genome->new($genomeObj);
	$genomeObj->contigs($ContigObj);
	return $genomeObj;
}
=head3 build_fba_object

Definition:
	Genome = $self->build_fba_object({} params);
Description:
	Returns typed object for FBA
		
=cut
sub build_fba_object {
	my($self,$model,$params) = @_;
	my $media = $self->get_object($params->{media},"media");
    if (!defined($media)) {
    	$self->error("Media retrieval failed!");
    }
    my $simptherm = 0;
    my $thermconst = 0;
    if ($params->{thermo_const_type} eq "Simple") {
    	$simptherm = 1;
    	$thermconst = 1;
    }
    my $fba = Bio::KBase::ObjectAPI::KBaseFBA::FBA->new({
		id => $params->{output_file},
		fva => $params->{fva},
		fluxMinimization => $params->{minimizeflux},
		findMinimalMedia => $params->{findminmedia},
		allReversible => $params->{allreversible},
		simpleThermoConstraints => $simptherm,
		thermodynamicConstraints => $thermconst,
		noErrorThermodynamicConstraints => 0,
		minimizeErrorThermodynamicConstraints => 1,
		maximizeObjective => 1,
		compoundflux_objterms => {},
    	reactionflux_objterms => {},
		biomassflux_objterms => {},
		comboDeletions => 0,
		numberOfSolutions => 1,
		objectiveConstraintFraction => $params->{objective_fraction},
		defaultMaxFlux => 1000,
		defaultMaxDrainFlux => 0,
		defaultMinDrainFlux => -1000,
		decomposeReversibleFlux => 0,
		decomposeReversibleDrainFlux => 0,
		fluxUseVariables => 0,
		drainfluxUseVariables => 0,
		fbamodel_ref => $model->_reference(),
		media_ref => $media->_reference(),
		geneKO_refs => [],
		reactionKO_refs => [],
		additionalCpd_refs => [],
		uptakeLimits => {},
		parameters => {},
		inputfiles => {},
		FBAConstraints => [],
		FBAReactionBounds => [],
		FBACompoundBounds => [],
		outputfiles => {},
		FBACompoundVariables => [],
		FBAReactionVariables => [],
		FBABiomassVariables => [],
		FBAPromResults => [],
		FBADeletionResults => [],
		FBAMinimalMediaResults => [],
		FBAMetaboliteProductionResults => [],
	});
	if ($params->{predict_essentiality} == 1) {
		$fba->{comboDeletions} = 1;
	}
	$fba->parent($self->PATRICStore());
	foreach my $term (@{$params->{objective}}) {
		if ($term->[0] eq "flux" || $term->[0] eq "reactionflux") {
			$term->[0] = "flux";
			my $obj = $model->searchForReaction($term->[1]);
			if (!defined($obj)) {
				$self->error("Reaction ".$term->[1]." not found!");
			}
			$fba->reactionflux_objterms()->{$obj->id()} = $term->[2];
		} elsif ($term->[0] eq "compoundflux" || $term->[0] eq "drainflux") {
			$term->[0] = "drainflux";
			my $obj = $model->searchForCompound($term->[1]);
			if (!defined($obj)) {
				$self->error("Compound ".$term->[1]." not found!");
			}
			$fba->compoundflux_objterms()->{$obj->id()} = $term->[2];
		} elsif ($term->[0] eq "biomassflux") {
			my $obj = $model->searchForBiomass($term->[1]);
			if (!defined($obj)) {
				$self->error("Biomass ".$term->[1]." not found!");
			}
			$fba->biomassflux_objterms()->{$obj->id()} = $term->[2];
		} else {
			$self->error("Objective variable type ".$term->[0]." not recognized!");
		}
	}
	foreach my $term (@{$params->{custom_bounds}}) {
		if ($term->[0] eq "flux" || $term->[0] eq "reactionflux") {
			$term->[0] = "flux";
			my $obj = $model->searchForReaction($term->[1]);
			if (!defined($obj)) {
				$self->error("Reaction ".$term->[1]." not found!");
			}
			$fba->add("FBAReactionBounds",{modelreaction_ref => $obj->_reference(),variableType=> $term->[0],upperBound => $term->[2],lowerBound => $term->[3]});
		} elsif ($term->[0] eq "compoundflux" || $term->[0] eq "drainflux") {
			$term->[0] = "flux";
			my $obj = $model->searchForCompound($term->[1]);
			if (!defined($obj)) {
				$self->error("Compound ".$term->[1]." not found!");
			}
			$fba->add("FBACompoundBounds",{modelcompound_ref => $obj->_reference(),variableType=> $term->[0],upperBound => $term->[2],lowerBound => $term->[3]});
		} else {
			$self->error("Objective variable type ".$term->[0]." not recognized!");
		}
	}
	if (defined($model->genome_ref())) {
		my $genome = $model->genome();
		foreach my $gene (@{$params->{geneko}}) {
			my $geneObj = $genome->searchForFeature($gene);
			if (defined($geneObj)) {
				$fba->addLinkArrayItem("geneKOs",$geneObj);
			}
		}
	}
	foreach my $reaction (@{$params->{rxnko}}) {
		my $rxnObj = $model->searchForReaction($reaction);
		if (defined($rxnObj)) {
			$fba->addLinkArrayItem("reactionKOs",$rxnObj);
		}
	}
	foreach my $compound (@{$params->{media_supplement}}) {
		my $cpdObj = $model->searchForCompound($compound);
		if (defined($cpdObj)) {
			$fba->addLinkArrayItem("additionalCpds",$cpdObj);
		}
	}
	if ($params->{probanno}) {
		Bio::KBase::ObjectAPI::logging::log("Getting reaction likelihoods from ".$model->rxnprobs_ref());
		my $rxnprobs = $self->get_object($model->rxnprobs_ref(),undef,{refreshcache => 1});
	    if (!defined($rxnprobs)) {
	    	$self->error("Reaction likelihood retrieval from ".$model->rxnprobs_ref()." failed");
	    }		
		$fba->{parameters}->{"Objective coefficient file"} = "ProbModelReactionCoefficients.txt";
		$fba->{inputfiles}->{"ProbModelReactionCoefficients.txt"} = [];
		my $rxncosts = {};
		foreach my $rxn (@{$rxnprobs->{reaction_probabilities}}) {
			$rxncosts->{$rxn->[0]} = (1-$rxn->[1]); # ID is first element, likelihood is second element
		}
		my $compindecies = {};
		my $comps = $model->modelcompartments();
		for (my $i=0; $i < @{$comps}; $i++) {
			$compindecies->{$comps->[$i]->compartmentIndex()}->{$comps->[$i]->compartment()->id()} = 1;
		}
		foreach my $compindex (keys(%{$compindecies})) {
			my $tmp = $model->template();
			my $tmprxns = $tmp->reactions();
			for (my $i=0; $i < @{$tmprxns}; $i++) {
				my $tmprxn = $tmprxns->[$i];
				my $tmpid = $tmprxn->id().$compindex;
				if (defined($rxncosts->{$tmprxn->id()})) {
					push(@{$fba->{inputfiles}->{"ProbModelReactionCoefficients.txt"}},"forward\t".$tmpid."\t".$rxncosts->{$tmprxn->id()});
					push(@{$fba->{inputfiles}->{"ProbModelReactionCoefficients.txt"}},"reverse\t".$tmpid."\t".$rxncosts->{$tmprxn->id()});
				}
			}
		}	
    	Bio::KBase::ObjectAPI::logging::log("Added reaction coefficients from reaction likelihoods in ".$model->rxnprobs_ref());
	}
	return $fba;
}
#****************************************************************************
#Probanno functions
#****************************************************************************


#****************************************************************************
#Non-APP API Call Implementations
#****************************************************************************
sub copy_genome {
	my($self,$input) = @_;
	$input = $self->validate_args($input,["genome"],{
    	destination => undef,
    	destname => undef,
		to_kbase => 0,
		workspace_url => undef,
		kbase_username => undef,
		kbase_password => undef,
		kbase_token => undef,
		plantseed => 0,
    });
    my $genome = $self->get_genome($input->{genome});
    if (!defined($input->{destination})) {
    	$input->{destination} = "/".Bio::KBase::ObjectAPI::config::username()."/modelseed/genomes/";
    	if ($input->{plantseed} == 1) {
    		$input->{destination} = "/".Bio::KBase::ObjectAPI::config::username()."/plantseed/genomes/";
    	}
    }
    if (!defined($input->{destname})) {
    	$input->{destname} = $genome->wsmeta()->[0];
    }
    if ($input->{destination}.$input->{destname} eq $input->{genome}) {
    	$self->error("Copy source and destination identical! Aborting!");
    }
    if (defined($self->get_model_meta($genome->wsmeta()->[2]."/.".$genome->wsmeta()->[0]))) {
    	$self->copy_object($genome->wsmeta()->[2]."/.".$genome->wsmeta()->[0],$input->{destination}.".".$input->{destname},1);
    }
    
    return $self->save_object($input->{destination}.$input->{destname},$genome,"genome");
}
sub copy_model {
	my($self,$input) = @_;
	$input = $self->validate_args($input,["model"],{
    	destination => undef,
		destname => undef,
		to_kbase => 0,
		copy_genome => 1,
		workspace_url => undef,
		kbase_username => undef,
		kbase_password => undef,
		kbase_token => undef,
		plantseed => 0,
    });
    my $model = $self->get_object($input->{model});
    if (!defined($input->{destination})) {
    	$input->{destination} = "/".Bio::KBase::ObjectAPI::config::username()."/home/models/";
    	if ($input->{plantseed} == 1) {
    		$input->{destination} = "/".Bio::KBase::ObjectAPI::config::username()."/plantseed/models/";
    	}
    }
    if (!defined($input->{destname})) {
    	$input->{destname} = $model->wsmeta()->[0];
    }
    if ($input->{destination}.$input->{destname} eq $input->{model}) {
    	$self->error("Copy source and destination identical! Aborting!");
    }
    if (defined($self->get_model_meta($model->wsmeta()->[2]."/.".$model->wsmeta()->[0]))) {
    	$self->copy_object($model->wsmeta()->[2]."/.".$model->wsmeta()->[0],$input->{destination}.".".$input->{destname},1);
    }
    if ($input->{copy_genome} == 1) {
    	$self->copy_genome({
    		genome => $model->genome_ref(),
    		plantseed => $input->{plantseed}
    	});
    	$model->genome_ref($model->genome()->_reference());
    }
    my $oldautometa = $model->wsmeta()->[8];
    my $meta = $self->save_object($input->{destination}.$input->{destname},$model,"model");
    $meta->[8] = $oldautometa;
    return $self->get_model_summary($model);
}

sub list_model_fba {
	my($self,$model) = @_;
	my $list = $self->call_ws("ls",{
		paths => [$model."/fba"],
		excludeDirectories => 1,
		excludeObjects => 0,
		recursive => 1,
		query => {type => "fba"}
	});
	my $output = [];
	if (defined($list->{$model."/fba"})) {
		$list = $list->{$model."/fba"};
		for (my $i=0; $i < @{$list}; $i++) {
			push(@{$output},{
				rundate => $list->[$i]->[3],
				id => $list->[$i]->[0],
				"ref" => $list->[$i]->[2].$list->[$i]->[0],
				media_ref => $list->[$i]->[7]->{media},
				objective => $list->[$i]->[7]->{objective},
				objective_function => $list->[$i]->[8]->{objective_function},				
			});
		}
	}
    $output = [sort { $b->{rundate} cmp $a->{rundate} } @{$output}];
	return $output;
}

sub list_model_gapfills {
	my($self,$model,$includemetadata) = @_;
	my $list = $self->call_ws("ls",{
		paths => [$model."/gapfilling"],
		excludeDirectories => 1,
		excludeObjects => 0,
		recursive => 1,
		query => {type => "fba"}
	});
	my $output = [];
	if (defined($list->{$model."/gapfilling"})) {
		$list = $list->{$model."/gapfilling"};
		for (my $i=0; $i < @{$list}; $i++) {
			push(@{$output},{
				rundate => $list->[$i]->[3],
				id => $list->[$i]->[0],
				"ref" => $list->[$i]->[2].$list->[$i]->[0],
				media_ref => $list->[$i]->[7]->{media},
				integrated => $list->[$i]->[7]->{integrated},
				integrated_solution => $list->[$i]->[7]->{integrated_solution},
				solution_reactions => []				
			});
			if (defined($list->[$i]->[7]->{solutiondata})) {
				$output->[$i]->{solution_reactions} = Bio::KBase::ObjectAPI::utilities::FROMJSON($list->[$i]->[7]->{solutiondata});
				for (my $j=0; $j < @{$output->[$i]->{solution_reactions}}; $j++) {
					for (my $k=0; $k < @{$output->[$i]->{solution_reactions}->[$j]}; $k++) {
						my $comp = "c";
						if ($output->[$i]->{solution_reactions}->[$j]->[$k]->{compartment_ref} =~ m/\/([^\/]+)$/) {
							$comp = $1;
						}
						$output->[$i]->{solution_reactions}->[$j]->[$k] = {
							direction => $output->[$i]->{solution_reactions}->[$j]->[$k]->{direction},
							reaction => $output->[$i]->{solution_reactions}->[$j]->[$k]->{reaction_ref},
							compartment => $comp.$output->[$i]->{solution_reactions}->[$j]->[$k]->{compartmentIndex}
						};
					}
				}
			}
			if ($includemetadata == 1) {
				$output->[$i]->{metadata} = $list->[$i]->[7];
			}
		}
	}
    $output = [sort { $b->{rundate} cmp $a->{rundate} } @{$output}];
	return $output;
}

sub list_models {
	my ($self,$input) = @_;
	$input = $self->validate_args($input,[],{
		path => "/".Bio::KBase::ObjectAPI::config::username()."/".Bio::KBase::ObjectAPI::config::home_dir()."/"
	});
    my $list = $self->call_ws("ls",{
		paths => [$input->{path}],
		recursive => 0,
		excludeDirectories => 0,
	});
	my $output;
	$list = $list->{$input->{path}};
    for (my $j=0; $j < @{$list}; $j++) {
    	my $key = $list->[$j]->[2].$list->[$j]->[0];
		$output->{$key}->{rundate} = $list->[$j]->[3];
		$output->{$key}->{id} = $list->[$j]->[0];
		$output->{$key}->{source} = $list->[$j]->[7]->{source};
		$output->{$key}->{source_id} = $list->[$j]->[7]->{source_id};
		$output->{$key}->{name} = $list->[$j]->[7]->{name};
		$output->{$key}->{type} = $list->[$j]->[7]->{type};
		$output->{$key}->{"ref"} = $list->[$j]->[2].$list->[$j]->[0];
		$output->{$key}->{template_ref} = $list->[$j]->[7]->{template_ref};
		$output->{$key}->{num_genes} = $list->[$j]->[7]->{num_genes};
		$output->{$key}->{num_compounds} = $list->[$j]->[7]->{num_compounds};
		$output->{$key}->{num_reactions} = $list->[$j]->[7]->{num_reactions};
		$output->{$key}->{num_biomasses} = $list->[$j]->[7]->{num_biomasses};
		$output->{$key}->{num_biomass_compounds} = $list->[$j]->[7]->{num_biomass_compounds};
		$output->{$key}->{num_compartments} = $list->[$j]->[7]->{num_compartments};				
		$output->{$key}->{gene_associated_reactions} = $list->[$j]->[7]->{gene_associated_reactions};
		$output->{$key}->{gapfilled_reactions} = $list->[$j]->[7]->{gapfilled_reactions};
		$output->{$key}->{fba_count} = $list->[$j]->[7]->{fba_count};
		$output->{$key}->{integrated_gapfills} = $list->[$j]->[7]->{integrated_gapfills};
		$output->{$key}->{unintegrated_gapfills} = $list->[$j]->[7]->{unintegrated_gapfills};
    }
	return $output;
}

sub delete_model_objects {
	my($self,$model,$ids,$type) = @_;
	my $output = {};
	my $idhash = {};
	for (my $i=0; $i < @{$ids}; $i++) {
		$idhash->{$ids->[$i]} = 1;
	}
	my $folder = "/fba";
	my $modelobj;
	if ($type eq "gapfilling") {
		$folder = "/gapfilling";
		$modelobj = $self->get_object($model);
	}
	my $list = $self->call_ws("ls",{
		paths => [$model.$folder],
		excludeDirectories => 1,
		excludeObjects => 0,
		recursive => 1
	});
	$list = $list->{$model.$folder};
	for (my $i=0; $i < @{$list}; $i++) {
		my $selected = 0;
		if (defined($idhash->{$list->[$i]->[0]})) {
			if ($type eq "gapfilling") {
				$modelobj->deleteGapfillSolution({gapfill => $list->[$i]->[0]});	
			}
			my $list = $self->call_ws("delete",{
				objects => [$list->[$i]->[2].$list->[$i]->[0]],
			});
			$selected = 1;
		} elsif ($list->[$i]->[0] =~ m/(.+)\.[^\.]+$/) {
			if (defined($idhash->{$1})) {
				my $list = $self->call_ws("delete",{
					objects => [$list->[$i]->[2].$list->[$i]->[0]],
				});
			}
			$selected = 1;
		}
		if ($selected == 1) {
			$output->{$list->[$i]->[0]} = {
				rundate => $list->[$i]->[3],
				id => $list->[$i]->[0],
				"ref" => $list->[$i]->[2].$list->[$i]->[0],
				media_ref => $list->[$i]->[7]->{media},				
			};
			if ($type eq "gapfilling") {
				$output->{$list->[$i]->[0]}->{integrated} = $list->[$i]->[7]->{integrated};
				$output->{$list->[$i]->[0]}->{integrated_solution} = $list->[$i]->[7]->{integrated_solution};
			} else {
				$output->{$list->[$i]->[0]}->{objective} = $list->[$i]->[7]->{objective};
				$output->{$list->[$i]->[0]}->{objective_function} = $list->[$i]->[7]->{objective_function};
			}
		}
	}
	return $output;
}

sub integrate_model_gapfills {
	my($self,$model,$intlist) = @_;
	$model = $self->get_object($model);
	for (my $i=0; $i < @{$intlist}; $i++) {
		$model->integrateGapfillSolution({
			gapfill => $intlist->[$i]
		});
	}
	$self->save_object($model->wsmeta()->[2].$model->wsmeta()->[0],$model,"model");
}

sub unintegrate_model_gapfills {
	my($self,$model,$intlist) = @_;
	$model = $self->get_object($model);
	for (my $i=0; $i < @{$intlist}; $i++) {
		$model->unintegrateGapfillSolution({
			gapfill => $intlist->[$i]
		});
	}
	$self->save_object($model->wsmeta()->[2].$model->wsmeta()->[0],$model,"model");
}

sub check_jobs {
	my($self,$input) = @_;
	$input = $self->validate_args($input,[],{
		jobs => [],
		return_errors => 0,
		exclude_failed => 0,
		exclude_running => 0,
		exclude_complete => 0,
	});
	my $output = {};
	if (@{$input->{jobs}} == 0) {
		my $enumoutput = $self->app_service()->enumerate_tasks(0,10000);
		for (my $i=0; $i < @{$enumoutput}; $i++) {
			if ($enumoutput->[$i]->{app} eq "RunProbModelSEEDJob") {
				$output->{$enumoutput->[$i]->{id}} = $enumoutput->[$i];
			}
		}
	} else {
		$output = $self->app_service()->query_tasks($input->{jobs});
	}
	foreach my $key (keys(%{$output})) {
		if ($input->{exclude_failed} == 1 && $output->{$key}->{status} eq "failed") {
			delete $output->{$key};
		}
		if ($input->{exclude_running} == 1 && $output->{$key}->{status} eq "running") {
			delete $output->{$key};
		}
		if ($input->{exclude_complete} == 1 && $output->{$key}->{status} eq "completed") {
			delete $output->{$key};
		}
	}
	if ($input->{return_errors} == 1 || keys(%{$output}) == 1) {
		foreach my $key (keys(%{$output})) {
			if ($output->{$key}->{status} eq "failed") {
				my $commandoutput = Bio::KBase::ObjectAPI::utilities::runexecutable("curl ".Bio::KBase::ObjectAPI::config::appservice_url()."/task_info/".$output->{$key}->{id}."/stderr");
				$output->{$key}->{errors} = join("\n",@{$commandoutput});
			}
		}
	}
	return $output;
}
#****************************************************************************
#Apps
#****************************************************************************
sub app_harness {
	my($self,$command,$parameters) = @_;
	my $starttime = time();
	if (Bio::KBase::ObjectAPI::config::run_as_app() == 1) {
		Bio::KBase::ObjectAPI::logging::log($command.": issuing app");
		my $task = $self->app_service()->start_app("RunProbModelSEEDJob",{command => $command,arguments => $parameters},"/".Bio::KBase::ObjectAPI::config::username()."/".Bio::KBase::ObjectAPI::config::home_dir()."/");
		Bio::KBase::ObjectAPI::logging::log($command.": app issued");
		return $task->{id};
	} else {
		my $jobresult = {
			id => 0,
			start_time => $starttime,
			parameters => {
				command => $command,
				arguments => $parameters
			},
			hostname => Bio::KBase::ObjectAPI::config::appservice_url(),
			app => {
				"id" => "RunProbModelSEEDJob",
				"script" => "App-RunProbModelSEEDJob",
				"label" => "Runs a ProbModelSEED job",
				"description" => "Runs a ProbModelSEED modeling job",
				"parameters" => [{
					"id" => "command",
					"label" => "Command",
					"required" => 1,
					"default" => undef,
					"desc" => "ProbModelSEED command to run",
					"type" => "string"
				},{
					"id" => "arguments",
					"label" => "Arguments",
					"required" => 1,
					"default" => undef,
					"desc" => "ProbModelSEED arguments",
					"type" => "string"
				}]
			},
			output_files => []
		};
		Bio::KBase::ObjectAPI::logging::log($command.": job started");
	    my $output = $self->$command($parameters,$jobresult);
		$jobresult->{end_time} = time();
		$jobresult->{elapsed_time} = (time()-$starttime);
		if (ref($output)) {
			$jobresult->{job_output} = Bio::KBase::ObjectAPI::utilities::TOJSON($output);
		} else {
			$jobresult->{job_output} = $output;
		}
		$jobresult->{output_files} = [keys(%{$self->PATRICStore()->save_file_list()})];
		$self->save_object($jobresult->{path},$jobresult,"job_result");
	    Bio::KBase::ObjectAPI::logging::log($command.": job done (elapsed time ".$jobresult->{elapsed_time}.")");
	    return $output;
	}
}

sub ComputeReactionProbabilities {
	my($self,$parameters,$jobresult) = @_;
    $parameters = $self->validate_args($parameters,["genome", "template", "rxnprobs"], {});
    my $cmd = Bio::KBase::ObjectAPI::config::bin_directory()."/bin/ms-probanno ".$parameters->{genome}." ".$parameters->{template}." ".$parameters->{rxnprobs}." --token '".Bio::KBase::ObjectAPI::config::token()."'";
    system($cmd);
    if ($? != 0) {
    	$self->error("Calculating reaction likelihoods failed!");
    }
    Bio::KBase::ObjectAPI::logging::log("Finished calculating reaction likelihoods");
	$jobresult->{path} = $parameters->{rxnprobs}.".jobresult";
	return $parameters->{rxnprobs};
}

sub ModelReconstruction {
	my($self,$parameters,$jobresult) = @_;
    Bio::KBase::ObjectAPI::config::old_models(0);
    $parameters = $self->validate_args($parameters,[],{
    	media => undef,
    	template_model => undef,
    	fulldb => 0,
    	output_path => undef,
    	genome => undef,
    	output_file => undef,
    	gapfill => 1,
    	probannogapfill => 0,
    	probanno => 0,
    	predict_essentiality => 1,
    });
	my $genome = $self->get_genome($parameters->{genome});
    if (!defined($parameters->{output_file})) {
    	$parameters->{output_file} = $genome->id();
    }
    if (Bio::KBase::ObjectAPI::config::old_models() == 1) {
    	$parameters->{output_file} = ".".$parameters->{output_file};
    }
    if (!defined($parameters->{media})) {
		if ($genome->domain() eq "Plant" || $genome->taxonomy() =~ /viridiplantae/i) {
			$parameters->{media} = "/chenry/public/modelsupport/media/PlantHeterotrophicMedia";
		} else {
			$parameters->{media} = Bio::KBase::ObjectAPI::config::default_media();
		}
	}
    my $template;
    if (!defined($parameters->{templatemodel})) {
    	if ($genome->domain() eq "Plant" || $genome->taxonomy() =~ /viridiplantae/i) {
    		if (!defined($parameters->{output_path})) {
    			$parameters->{output_path} = "/".Bio::KBase::ObjectAPI::config::username()."/".Bio::KBase::ObjectAPI::config::plantseed_home_dir()."/";
    		}
    		$template = $self->get_object(Bio::KBase::ObjectAPI::config::template_dir()."plant.modeltemplate","modeltemplate");
    	} else {
    		if (!defined($parameters->{output_path})) {
    			$parameters->{output_path} = "/".Bio::KBase::ObjectAPI::config::username()."/".Bio::KBase::ObjectAPI::config::home_dir()."/";
    		}
    		my $classifier_data = $self->get_object(Bio::KBase::ObjectAPI::config::classifier(),"string");
    		my $class = $self->classify_genome($classifier_data,$genome);
    		if ($class eq "Gram positive") {
	    		$template = $self->get_object(Bio::KBase::ObjectAPI::config::template_dir()."GramPositive.modeltemplate","modeltemplate");
	    	} elsif ($class eq "Gram negative") {
	    		$template = $self->get_object(Bio::KBase::ObjectAPI::config::template_dir()."GramNegative.modeltemplate","modeltemplate");
	    	}
    	}
    } else {
    	$template = $self->get_object($parameters->{templatemodel},"modeltemplate");
    }
    if (!defined($template)) {
    	$self->error("template retrieval failed!");
    }
    if (!defined($parameters->{output_path})) {
    	if ($genome->domain() eq "Plant" || $genome->taxonomy() =~ /viridiplantae/i) {
    		$parameters->{output_path} = "/".Bio::KBase::ObjectAPI::config::username()."/".Bio::KBase::ObjectAPI::config::plantseed_home_dir()."/";
    	} else {
    		$parameters->{output_path} = "/".Bio::KBase::ObjectAPI::config::username()."/".Bio::KBase::ObjectAPI::config::home_dir()."/";
    	}
    }
    if (substr($parameters->{output_path},-1,1) ne "/") {
    	$parameters->{output_path} .= "/";
    }
    my $folder = $parameters->{output_path}.$parameters->{output_file};   	
   	if (Bio::KBase::ObjectAPI::config::old_models() == 1) {
   		$self->save_object($folder,undef,"folder");
   	} else {
   		$self->save_object($folder,undef,"modelfolder");
   	}
   	$self->save_object($folder."/genome",$genome,"genome");
   	my $mdl = $template->buildModel({
	    genome => $genome,
	    modelid => $parameters->{output_file},
	    fulldb => $parameters->{fulldb}
	});
	$mdl->genome_ref($parameters->{output_file}."/genome||");
	$mdl->wsmeta()->[2] = $parameters->{output_path};
	$mdl->wsmeta()->[0] = $parameters->{output_file};
	#Now compute reaction probabilities if they are needed for gapfilling or probanno model building
    if ($parameters->{probanno} == 1 || ($parameters->{gapfill} == 1 && $parameters->{probannogapfill} == 1)) {
    	my $genomeref = $folder."/genome";
    	my $templateref = $template->_reference();
    	$templateref =~ s/\|\|$//; # Remove the extraneous || at the end of the reference
    	my $rxnprobsref = $folder."/rxnprobs";
    	$self->ComputeReactionProbabilities({
    		genome => $genomeref,
    		template => $templateref,
    		rxnprobs => $rxnprobsref
    	},$jobresult);
    	$mdl->rxnprobs_ref($rxnprobsref);
    }
    $self->save_object($folder,$mdl,"model");
   	if ($parameters->{gapfill} == 1) {
    	$self->GapfillModel({
    		model => $folder,
    		media => $parameters->{media},
    		integrate_solution => 1,
    		probanno => $parameters->{probanno},
    	},$jobresult,$mdl);    	
    	if ($parameters->{predict_essentiality} == 1) {
    		$self->FluxBalanceAnalysis({
	    		model => $folder,
	    		media => $parameters->{media},
	    		predict_essentiality => 1
	    	},$jobresult,$mdl);
    	}	
    }
	$jobresult->{path} = $folder."/jobresult";
    return $folder;
}

sub FluxBalanceAnalysis {
	my($self,$parameters,$jobresult,$model) = @_;
	$parameters = $self->validate_args($parameters,["model"],{
		media => undef,
		fva => 1,
		predict_essentiality => 0,
		minimizeflux => 1,
		findminmedia => 0,
		allreversible => 0,
		thermo_const_type => "None",
		media_supplement => [],
		geneko => [],
		rxnko => [],
		objective_fraction => 1,
		custom_bounds => [],
		objective => [["biomassflux","bio1",1]],
		custom_constraints => [],
		uptake_limits => [],
	});
	$parameters->{fva} = 1;
	$parameters->{minimizeflux} = 1;
	if (!defined($model)) {
		$model = $self->get_object($parameters->{model});
	}
    $parameters->{model} = $model->_reference();
    if (!defined($parameters->{media})) {
		if ($model->genome()->domain() eq "Plant" || $model->genome()->taxonomy() =~ /viridiplantae/i) {
			$parameters->{media} = "/chenry/public/modelsupport/media/PlantHeterotrophicMedia";
		} else {
			$parameters->{media} = Bio::KBase::ObjectAPI::config::default_media();
		}
	}
    
    #Setting output path based on model and then creating results folder
    $parameters->{output_path} = $model->wsmeta()->[2].$model->wsmeta()->[0]."/fba";
    if (!defined($parameters->{output_file})) {
	    my $list = $self->call_ws("ls",{
			adminmode => Bio::KBase::ObjectAPI::config::adminmode(),
			paths => [$parameters->{output_path}],
			excludeDirectories => 1,
			excludeObjects => 0,
			recursive => 1,
			query => {type => "fba"}
		});
		my $index = 0;
		if (defined($list->{$parameters->{output_path}})) {
			$list = $list->{$parameters->{output_path}};
			$index = @{$list};
			for (my $i=0; $i < @{$list}; $i++) {
				if ($list->[$i]->[0] =~ /^fba\.(\d+)$/) {
					if ($1 > $index) {
						$index = $1+1;
					}
				}
			}
		}
		$parameters->{output_file} = "fba.".$index;
    }
    my $outputfile = $parameters->{output_path}."/".$parameters->{output_file};
    my $fba = $self->build_fba_object($model,$parameters);
    Bio::KBase::ObjectAPI::logging::log("Started solving flux balance problem");
    my $objective = $fba->runFBA();
    Bio::KBase::ObjectAPI::logging::log("Objective:".$objective);
    if (!defined($objective)) {
    	$self->error("FBA failed with no solution returned! See ".$fba->jobnode());
    }
    Bio::KBase::ObjectAPI::logging::log("Got solution for flux balance problem");
    #Printing essential gene list as feature group and text list
    my $fbatbl = "ID\tName\tEquation\tFlux\tUpper bound\tLower bound\tMax\tMin\n";
    my $objs = $fba->FBABiomassVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->biomass()->id()."\t".$objs->[$i]->biomass()->name()."\t".
    		$objs->[$i]->biomass()->definition()."\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    }
    $objs = $fba->FBAReactionVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->modelreaction()->id()."\t".$objs->[$i]->modelreaction()->name()."\t".
    		$objs->[$i]->modelreaction()->definition()."\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    }
    $objs = $fba->FBACompoundVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->modelcompound()->id()."\t".$objs->[$i]->modelcompound()->name()."\t".
    		"=> ".$objs->[$i]->modelcompound()->name()."[e]\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    } 
    $self->save_object($outputfile.".fluxtbl",$fbatbl,"string",{
	   description => "Tab delimited table containing data on reaction fluxes from flux balance analysis",
	   fba => $parameters->{output_file},
	   media => $parameters->{media},
	   model => $parameters->{model}
	});
    if ($parameters->{predict_essentiality} == 1) {
	    my $esslist = [];
	    my $ftrlist = [];
	    my $delresults = $fba->FBADeletionResults();
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
	   	$self->save_object($outputfile.".essentials",join("\n",@{$esslist}),"string",{
	    	description => "Tab delimited table containing list of predicted genes from flux balance analysis",
	    	media => $parameters->{media},
	    	model => $parameters->{model}
	    });
	    my $ftrgroup = {
	    	id_list => {
	    		feature_id => $ftrlist
	    	},
	    	name => $model->wsmeta()->[0]."-".$fba->media()->wsmeta()->[0]."-essentials"
	    };
	    $self->save_object("/".Bio::KBase::ObjectAPI::config::username()."/home/Feature Groups/".$model->wsmeta()->[0]."-".$fba->media()->wsmeta()->[0]."-essentials",$ftrgroup,"feature_group",{
	    	description => "Group of essential genes predicted by metabolic models",
	    	media => $parameters->{media},
	    	model => $parameters->{model}
	    });
    }
    $self->save_object($outputfile,$fba,"fba",{
    	objective => $objective,
    	media => $parameters->{media}
    });
    $jobresult->{path} = $outputfile.".jobresult";
    return $outputfile;
}

sub GapfillModel {
	my($self,$parameters,$jobresult,$model) = @_;
    $parameters = $self->validate_args($parameters,["model"],{
		media => undef,
		probanno => 0,
		alpha => 0,
		allreversible => 0,
		thermo_const_type => "None",
		media_supplement => [],
		geneko => [],
		rxnko => [],
		objective_fraction => 0.001,
		uptake_limits => [],
		custom_bounds => [],
		objective => [["biomassflux","bio1",1]],
		custom_constraints => [],
		low_expression_theshold => 0.5,
		high_expression_theshold => 0.5,
		target_reactions => [],
		completeGapfill => 0,
		solver => undef,
		omega => 0,
		allowunbalanced => 0,
		blacklistedrxns => [],
		gauranteedrxns => [],
		exp_raw_data => {},
		source_model => undef,
		integrate_solution => 0,
		fva => 0,
		minimizeflux => 0,
		findminmedia => 0
	});
	if (!defined($model)) {
    	$model = $self->get_object($parameters->{model});
	}
    $parameters->{model} = $model->_reference();
    if (!defined($parameters->{media})) {
		if ($model->genome()->domain() eq "Plant" || $model->genome()->taxonomy() =~ /viridiplantae/i) {
			$parameters->{media} = "/chenry/public/modelsupport/media/PlantHeterotrophicMedia";
		} else {
			$parameters->{media} = Bio::KBase::ObjectAPI::config::default_media();
		}
	}
    #Setting output path based on model and then creating results folder
    $parameters->{output_path} = $model->wsmeta()->[2].$model->wsmeta()->[0]."/gapfilling";
    if (!defined($parameters->{output_file})) {
	    my $gflist = $self->call_ws("ls",{
			adminmode => Bio::KBase::ObjectAPI::config::adminmode(),
			paths => [$parameters->{output_path}],
			excludeDirectories => 1,
			excludeObjects => 0,
			recursive => 1,
			query => {type => "fba"}
		});
		my $index = 0;
		if (defined($gflist->{$parameters->{output_path}})) {
			$gflist = $gflist->{$parameters->{output_path}};
			$index = @{$gflist};
			for (my $i=0; $i < @{$gflist}; $i++) {
				if ($gflist->[$i]->[0] =~ /^gf\.(\d+)$/) {
					if ($1 > $index) {
						$index = $1+1;
					}
				}
			}
		}
		$parameters->{output_file} = "gf.".$index;
    }
    my $outputfile = $parameters->{output_path}."/".$parameters->{output_file};
    if (defined($parameters->{source_model})) {
		$parameters->{source_model} = $self->get_object($parameters->{source_model});
    }
    my $fba = $self->build_fba_object($model,$parameters);
    $fba->PrepareForGapfilling($parameters);
    Bio::KBase::ObjectAPI::logging::log("Started solving gap fill problem");
    my $objective = $fba->runFBA();
    $fba->parseGapfillingOutput();
    if (!defined($fba->gapfillingSolutions()->[0])) {
		$self->error("Analysis completed, but no valid solutions found!");
	}
	if (@{$fba->gapfillingSolutions()->[0]->gapfillingSolutionReactions()} == 0) {
		Bio::KBase::ObjectAPI::logging::log("No gapfilling needed on specified condition!");
	}
    Bio::KBase::ObjectAPI::logging::log("Got solution for gap fill problem");
	my $gfsols = [];
	my $gftbl = "Solution\tID\tName\tEquation\tDirection\n";
	for (my $i=0; $i < @{$fba->gapfillingSolutions()}; $i++) {
		for (my $j=0; $j < @{$fba->gapfillingSolutions()->[$i]->gapfillingSolutionReactions()}; $j++) {
			my $rxn = $fba->gapfillingSolutions()->[$i]->gapfillingSolutionReactions()->[$j];
			$gftbl .= $i."\t".$rxn->reaction()->id()."\t".$rxn->reaction()->name()."\t".
    		$rxn->reaction()->definition()."\t".$rxn->direction()."\n";
			$gfsols->[$i]->[$j] = $fba->gapfillingSolutions()->[$i]->gapfillingSolutionReactions()->[$j]->serializeToDB();
		}
	}
	my $solutiondata = Bio::KBase::ObjectAPI::utilities::TOJSON($gfsols);
	$self->save_object($outputfile,$fba,"fba",{
		integrated_solution => 0,
		solutiondata => $solutiondata,
		integratedindex => 0,
		media => $parameters->{media},
		integrated => $parameters->{integrate_solution}
	});
	$self->save_object($outputfile.".gftbl",$gftbl,"string",{
	   description => "Tab delimited table of reactions gapfilled in metabolic model",
	   fba => $parameters->{output_file},
	   media => $parameters->{media},
	   model => $parameters->{model}
	});
	my $fbatbl = "ID\tName\tEquation\tFlux\tUpper bound\tLower bound\tMax\tMin\n";
    my $objs = $fba->FBABiomassVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->biomass()->id()."\t".$objs->[$i]->biomass()->name()."\t".
    		$objs->[$i]->biomass()->definition()."\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    }
    $objs = $fba->FBAReactionVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->modelreaction()->id()."\t".$objs->[$i]->modelreaction()->name()."\t".
    		$objs->[$i]->modelreaction()->definition()."\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    }
    $objs = $fba->FBACompoundVariables();
    for (my $i=0; $i < @{$objs}; $i++) {
    	$fbatbl .= $objs->[$i]->modelcompound()->id()."\t".$objs->[$i]->modelcompound()->name()."\t".
    		"=> ".$objs->[$i]->modelcompound()->name()."[e]\t".
    		$objs->[$i]->value()."\t".$objs->[$i]->upperBound()."\t".
    		$objs->[$i]->lowerBound()."\t".$objs->[$i]->max()."\t".
    		$objs->[$i]->min()."\t".$objs->[$i]->class()."\n";
    } 
    $self->save_object($outputfile.".fbatbl",$fbatbl,"string",{
	   description => "Table of fluxes through reactions used in gapfilling solution",
	   fba => $parameters->{output_file},
	   media => $parameters->{media},
	   model => $parameters->{model}
	});
	Bio::KBase::ObjectAPI::logging::log("Adding new gapfilling:".$fba->id());
	$model->add("gapfillings",{
		id => $fba->id(),
		gapfill_id => $fba->id(),
		fba_ref => $fba->_reference(),
		integrated => $parameters->{integrate_solution},
		integrated_solution => 0,
		media_ref => $parameters->{media},
	});
	if ($parameters->{integrate_solution}) {
		my $report = $model->integrateGapfillSolutionFromObject({
			gapfill => $fba
		});
	}
	$self->save_object($model->wsmeta()->[2].$model->wsmeta()->[0],$model,"model");
	$jobresult->{path} = $outputfile.".jobresult";
	return $model->wsmeta()->[2].$model->wsmeta()->[0];
}

sub MergeModels {
	my($self,$parameters,$jobresult) = @_;
	$parameters = $self->validate_args($parameters,["models","output_file"],{
		output_path => "/".Bio::KBase::ObjectAPI::config::username()."/".Bio::KBase::ObjectAPI::config::home_dir()."/"
    });
    #Pulling first model to obtain biochemistry ID
	my $model = $self->get_object($parameters->{models}->[0]->[0]);
	#Creating new community model
	my $commdl = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new({
		source_id => $parameters->{output_file},
		source => Bio::KBase::ObjectAPI::config::source(),
		id => $parameters->{output_file},
		type => "CommunityModel",
		name => $parameters->{output_file},
		template_ref => $model->template_ref(),
		template_refs => [$model->template_ref()],
		genome_ref => $parameters->{output_path}."/".$parameters->{output_file}."/genome||",
		modelreactions => [],
		modelcompounds => [],
		modelcompartments => [],
		biomasses => [],
		gapgens => [],
		gapfillings => [],
	});
	for (my $i=0; $i < @{$parameters->{models}}; $i++) {
		$parameters->{models}->[$i]->[0] .= "||";
	}
	$commdl->wsmeta()->[2] = $parameters->{output_path};
	$commdl->wsmeta()->[0] = $parameters->{output_file};
	$commdl->parent($self->PATRICStore());
	my $genomeObj = $commdl->merge_models({
		models => $parameters->{models}
	});
	$commdl->genome_ref($parameters->{output_file}."/genome||");
	$self->save_object($parameters->{output_path}."/".$parameters->{output_file},$commdl,"model",{});
	$jobresult->{path} = $parameters->{output_path}."/".$parameters->{output_file}."/jobresult";
	return $parameters->{output_path}."/".$parameters->{output_file};
}

sub ImportKBaseModel {
	my($self,$parameters,$jobresult) = @_;
	$parameters = $self->validate_args($parameters,["kbws","kbid"],{
		kbwsurl => undef,
		kbuser => undef,
		kbpassword => undef,
		kbtoken => undef,
		output_file => $parameters->{kbid},
		output_path => "/".Bio::KBase::ObjectAPI::config::username()."/".Bio::KBase::ObjectAPI::config::home_dir()."/"
    });
    #Making sure the output path has a slash at the end
    if (substr($parameters->{output_path},-1,1) ne "/") {
    	$parameters->{output_path} .= "/";
    }
    #Retrieving model from KBase
    my $kbstore = $self->KBaseStore({
    	kbuser => $parameters->{kbuser},
		kbpassword => $parameters->{kbpassword},
		kbtoken => $parameters->{kbtoken},
		kbwsurl => $parameters->{kbwsurl},
    });
    my $model = $kbstore->get_object($parameters->{kbws}."/".$parameters->{kbid});
    $model->id($parameters->{output_file});
    $model->source("ModelSEED");
    #Creating folder for imported model
	my $folder = $parameters->{output_path}.$parameters->{output_file};
    $self->save_object($folder,undef,"modelfolder");
   	#Saving contigsets inside the model folder if they exist for the genome - saved as contigset for now so no translation needed
   	my $genome = $model->genome();
   	$model->name($genome->scientific_name()." model");
   	if (defined($genome->contigset_ref())) {
   		$self->save_object($folder."/contigset",$genome->contigs(),"contigset");
   		#Resetting reference for contigset to local path
   		$genome->contigset_ref("contigset||");
   	}
   	#Saving genome inside the model folder - no translation is needed
   	$self->save_object($folder."/genome",$genome,"genome");
    #Changing template reference
    if ($model->template_ref() =~ m/228\/2\/*\d*/) {
    	$model->template_ref(Bio::KBase::ObjectAPI::config::template_dir()."GramNegative.modeltemplate||");
    } elsif ($model->template_ref() =~ m/228\/1\/*\d*/) {
    	$model->template_ref(Bio::KBase::ObjectAPI::config::template_dir()."GramPositive.modeltemplate||");
    } elsif ($model->template_ref() =~ m/228\/4\/*\d*/) {
    	$model->template_ref(Bio::KBase::ObjectAPI::config::template_dir()."plant.modeltemplate||");
    }
    $model->translate_to_localrefs();
   	#Transfering gapfillings
    $self->save_object($folder."/gapfilling",undef,"folder");
    my $oldgfs = $model->gapfillings();
    $model->gapfillings([]);
    for (my $i=0; $i < @{$oldgfs}; $i++) {
    	#Only transfering integrated gapfillings
    	if ($oldgfs->[$i]->integrated() == 1) {
	    	my $oldparent = $model->parent();
	    	$oldgfs->[$i]->id("gf.".$i);
	    	$oldgfs->[$i]->gapfill_id("gf.".$i);
	    	my $fba;
	    	if (defined($oldgfs->[$i]->gapfill_ref())) {
	    		my $gf = $oldgfs->[$i]->gapfill();
	    		Bio::KBase::ObjectAPI::logging::log($gf->serializeToDB());
	    		$fba = $gf->fba();
	    		if (defined($gf->gapfillingSolutions()->[0])) {
	    			$fba->add("gapfillingSolutions",$gf->gapfillingSolutions()->[0]);
	    		}
	    	} else {
	    		$fba = $oldgfs->[$i]->fba();
	    	}
	    	if (defined($fba->gapfillingSolutions()->[0])) {
		    	Bio::KBase::ObjectAPI::logging::log("Valid gapfilling:".$parameters->{output_file}."/gapfilling/gf.".$i);
		    	push(@{$model->gapfillings()},$oldgfs->[$i]);
		    	$fba->fbamodel($model);
		    	$fba->id("gf.".$i);
		    	$oldgfs->[$i]->fba_ref($parameters->{output_file}."/gapfilling/".$fba->id()."||"); 
		    	$fba->translate_to_localrefs();
		    	if ($fba->media_ref() =~ m/\/([^\/]+)$/) {
		    		$fba->media_ref("/chenry/public/modelsupport/patric-media/".$1."||");
		    		$oldgfs->[$i]->media_ref($fba->media_ref());
		    	}	    	
		    	#Saving FBA object
		    	$fba->fbamodel_ref("../../".$model->id()."||");
		    	$self->save_object($folder."/gapfilling/".$fba->id(),$fba,"fba");
		    	my $solution = $fba->gapfillingSolutions()->[0];
		    	#Integrating new reactions into model
				$model->parent($self->PATRICStore());
				$fba->parent($self->PATRICStore());
				my $rxns = $solution->gapfillingSolutionReactions();
				for (my $i=0; $i < @{$rxns}; $i++) {
					my $rxn = $rxns->[$i];
					my $obj = $rxn->getLinkedObject($rxn->reaction_ref());
					if (defined($obj)) {
						my $rxnid = $rxn->reaction()->id();
						my $mdlrxn;
						my $ismdlrxn = 0;
						$mdlrxn = $model->getObject("modelreactions",$rxnid.$rxn->compartmentIndex());
						if (!defined($mdlrxn)) {
							Bio::KBase::ObjectAPI::logging::log("Could not find ".$rxnid." in model ".$parameters->{output_file});
							$mdlrxn = $model->addModelReaction({
								reaction => $rxn->reaction()->msid(),
								compartment => $rxn->reaction()->templatecompartment()->id(),
								compartmentIndex => $rxn->compartmentIndex(),
								direction => $rxn->direction()
							});
							$mdlrxn->gapfill_data()->{$fba->id()} = "added:".$rxn->direction();
						} else {
							my $prots = $mdlrxn->modelReactionProteins();
							if (@{$prots} == 0) {
								$mdlrxn->gapfill_data()->{$fba->id()} = "added:".$rxn->direction();
							} else {
								$mdlrxn->direction("=");
								$mdlrxn->gapfill_data()->{$fba->id()} = "reversed:".$rxn->direction();
							}
						}
					}
				}
				$model->parent($oldparent);
	    	}
    	}
    }
    $model->parent($self->PATRICStore());
    #Saving model to PATRIC
    $model->wsmeta->[0] = $parameters->{output_file};
    $model->wsmeta->[2] = $parameters->{output_path};
    $model->genome_ref($model->id()."/genome||");
	$self->save_object($parameters->{output_path}.$parameters->{output_file},$model,"model",{});
	$jobresult->{path} = $parameters->{output_path}.$parameters->{output_file}."/jobresult";
	return $parameters->{output_path}.$parameters->{output_file};
}

sub ExportToKBase {
	my($self,$parameters,$jobresult) = @_;
	$parameters = $self->validate_args($parameters,["model","kbws","kbid"],{
		kbwsurl => undef,
		kbuser => undef,
		kbpassword => undef,
		kbtoken => undef,
    });
    #Getting model
    my $model = $self->get_object($parameters->{model});
    #Getting KBase store
    my $kbstore = $self->KBaseStore({
    	kbuser => $parameters->{kbuser},
		kbpassword => $parameters->{kbpassword},
		kbtoken => $parameters->{kbtoken},
		kbwsurl => $parameters->{kbwsurl},
    });
    #Getting genome
    my $genome = $model->genome();
    #Saving contig set
    if (defined($genome->{contigset_ref})) {
    	my $contigs = $genome->contigs();
    	$kbstore->save_object($contigs,$parameters->{kbws}."/".$parameters->{kbid}.".contigs");
    	$genome->contigset_ref($parameters->{kbws}."/".$parameters->{kbid}.".contigs");
    }
    #Saving genome
    $kbstore->save_object($genome,$parameters->{kbws}."/".$parameters->{kbid}.".genome");
    #Saving gapfilling
    for (my $i=0; $i < @{$model->gapfillings()}; $i++) {
    	my $fba = $model->gapfillings()->[$i]->fba();
    	$model->gapfillings()->[$i]->fba_ref($genome,$parameters->{kbws}."/".$parameters->{kbid}.".".$model->gapfillings()->[$i]->id());
    	$fba->fbamodel_ref($parameters->{kbws}."/".$parameters->{kbid});
    	if ($fba->media_ref() =~ m/\/([^\/]+)$/) {
    		$fba->media_ref("KBaseMedia/".$1);
    	}
    	$fba->fbamodel_ref($parameters->{kbws}."/".$parameters->{kbid});
    }
    #Saving model
    if ($model->template_ref() =~ m/GramNegative/) {
    	$model->template_ref("228/2");
    } elsif ($model->template_ref() =~ m/GramPositive/) {
    	$model->template_ref("228/1");
    } elsif ($model->template_ref() =~ m/plant/) {
    	$model->template_ref("228/4");
    }
    $model->genome_ref($parameters->{kbws}."/".$parameters->{kbid}.".genome");
    $model->parent($kbstore);
    $kbstore->save_object($model,$parameters->{kbws}."/".$parameters->{kbid});
    $jobresult->{path} = $parameters->{model}."/kbase_export_jobresult";
	return $parameters->{kbws}."/".$parameters->{kbid};
}

sub TranslateOlderModels {
	my($self,$parameters,$jobresult) = @_;
	$parameters = $self->validate_args($parameters,["model"],{ 
		output_file => undef,
		output_path => undef
    });
    #Getting the model
    my $model = $self->get_object($parameters->{model});
    if (!defined($parameters->{output_file})) {
    	$parameters->{output_file} = $model->wsmeta()->[0];
    }
    if (!defined($parameters->{output_path})) {
    	$parameters->{output_path} = $model->wsmeta()->[2];
    }
    #Making sure the output path has a slash at the end
	if (substr($parameters->{output_path},-1,1) ne "/") {
    	$parameters->{output_path} .= "/";
    }
    $model->id($parameters->{output_file});
    $model->source("ModelSEED");
    #Creating folder for imported model
	my $folder = $parameters->{output_path}.$parameters->{output_file};
    $self->save_object($folder,undef,"modelfolder");
    my $genome = $model->genome();
    $model->name($genome->scientific_name()." model");
    if (defined($genome->contigset_ref())) {
   		$self->save_object($folder."/contigset",$genome->contigs(),"contigset");
   		#Resetting reference for contigset to local path
   		$genome->contigset_ref("contigset||");
   	}
    #Saving genome inside the model folder - no translation is needed
   	$self->save_object($folder."/genome",$genome,"genome");
    $model->translate_to_localrefs();
    $self->save_object($folder."/gapfilling",undef,"folder");
    #Transfering gapfillings
    my $gfs = $model->gapfillings();
    if (@{$gfs} == 0) {
    	Bio::KBase::ObjectAPI::logging::log($model->wsmeta()->[2].".".$model->wsmeta()->[0]."/gapfilling");
    	my $list = $self->call_ws("ls",{
			paths => [$model->wsmeta()->[2].".".$model->wsmeta()->[0]."/gapfilling"],
			excludeDirectories => 1,
			excludeObjects => 0,
			recursive => 1,
			query => {type => "fba"}
		});
		if (defined($list->{$model->wsmeta()->[2].".".$model->wsmeta()->[0]."/gapfilling"})) {
			$list = $list->{$model->wsmeta()->[2].".".$model->wsmeta()->[0]."/gapfilling"};
			for (my $i=0; $i < @{$list}; $i++) {
				$model->add("gapfillings",{
					id => $list->[$i]->[0],
					gapfill_id => $list->[$i]->[0],
					fba_ref => $list->[$i]->[2]."/".$list->[$i]->[0]."||",
					integrated => 1,
					integrated_solution => 0,
					media_ref => $list->[$i]->[7]->{media}
				});
			}
			$gfs = $model->gapfillings();
		}
    }
    for (my $i=0; $i < @{$gfs}; $i++) {
    	my $fba = $gfs->[$i]->fba();
    	if (!defined($fba->gapfillingSolutions()->[0])) {
    		$model->remove("gapfillings",$gfs->[$i]);
    	} else {
    		Bio::KBase::ObjectAPI::logging::log("Valid gapfilling:".$parameters->{output_file}."/gapfilling/gf.".$i);
	    	$fba->fbamodel($model);
	    	$gfs->[$i]->fba_ref($parameters->{output_file}."/gapfilling/".$fba->id()."||");
	    	$fba->translate_to_localrefs();	    	
	    	#Saving FBA object
	    	$fba->fbamodel_ref("../../".$model->id()."||");
	    	$self->save_object($folder."/gapfilling/".$fba->id(),$fba,"fba");
	    	my $solution = $fba->gapfillingSolutions()->[0];
	    	#Integrating new reactions into model
			my $rxns = $solution->gapfillingSolutionReactions();
			for (my $i=0; $i < @{$rxns}; $i++) {
				my $rxn = $rxns->[$i];
				my $rxnid = $rxn->reaction()->id();
				my $mdlrxn;
				my $ismdlrxn = 0;
				$mdlrxn = $model->getObject("modelreactions",$rxnid.$rxn->compartmentIndex());
				if (!defined($mdlrxn)) {
					Bio::KBase::ObjectAPI::logging::log("Could not find ".$rxnid." in model ".$parameters->{output_file});
					$mdlrxn = $model->addModelReaction({
						reaction => $rxn->reaction()->msid(),
						compartment => $rxn->reaction()->templatecompartment()->id(),
						compartmentIndex => $rxn->compartmentIndex(),
						direction => $rxn->direction()
					});
					$mdlrxn->gapfill_data()->{$fba->id()} = "added:".$rxn->direction();
				} else {
					my $prots = $mdlrxn->modelReactionProteins();
					if (@{$prots} == 0) {
						$mdlrxn->gapfill_data()->{$fba->id()} = "added:".$rxn->direction();
					} else {
						$mdlrxn->direction("=");
						$mdlrxn->gapfill_data()->{$fba->id()} = "reversed:".$rxn->direction();
					}
				}
			}
    	}
    }
    $model->genome_ref($model->id()."/genome||");
	$self->save_object($parameters->{output_path}.$parameters->{output_file},$model,"model",{});
	$jobresult->{path} = $parameters->{output_path}.$parameters->{output_file}."/jobresult";
	return $parameters->{output_path}.$parameters->{output_file};
}

sub load_to_shock {
	my($self,$data) = @_;
	my $uuid = Data::UUID->new()->create_str();
	File::Path::mkpath Bio::KBase::ObjectAPI::config::mfatoolkit_job_dir();
	my $filename = Bio::KBase::ObjectAPI::config::mfatoolkit_job_dir().$uuid;
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($filename,[$data]);
	my $output = Bio::KBase::ObjectAPI::utilities::runexecutable("curl -H \"Authorization: OAuth ".Bio::KBase::ObjectAPI::config::token()."\" -X POST -F 'upload=\@".$filename."' ".Bio::KBase::ObjectAPI::config::shock_url()."/node");
	$output = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{$output}));
	return Bio::KBase::ObjectAPI::config::shock_url()."/node/".$output->{data}->{id};
}

#****************************************************************************
#Constructor
#****************************************************************************
sub new {
    my($class, $parameters) = @_;
    my $self = {};
    bless $self, $class;
    $parameters = $self->validate_args($parameters,["token","username"],{
    	setowner => undef,
    	adminmode => 0,
    	method => "unknown",
    	configfile => $ENV{KB_DEPLOYMENT_CONFIG},
    	configservice => "ProbModelSEED",
    	workspace_url => undef
    });
    #Loading config if it's not already loaded
    if (!defined(Bio::KBase::ObjectAPI::config::configfile_loaded()) || Bio::KBase::ObjectAPI::config::configfile_loaded() ne $parameters->{configfile}) {
    	Bio::KBase::ObjectAPI::config::load_config({
    		filename => $parameters->{configfile},
			service => $parameters->{configservice},
    	});
    }
    #Setting ephemeral configs from input arguments (token, username, adminmode)
    if (defined($parameters->{workspace_url})) {
    	Bio::KBase::ObjectAPI::config::workspace_url($parameters->{workspace_url});
    }
    if (defined($parameters->{username})) {
    	Bio::KBase::ObjectAPI::config::username($parameters->{username});
    }
    if (defined($parameters->{token})) {
    	Bio::KBase::ObjectAPI::config::token($parameters->{token});
    }
    if (defined($parameters->{adminmode})) {
    	Bio::KBase::ObjectAPI::config::adminmode($parameters->{adminmode});
    }
    if (defined($parameters->{adminmode})) {
    	Bio::KBase::ObjectAPI::config::setowner($parameters->{setowner});
    }
    return $self;
}

1;
