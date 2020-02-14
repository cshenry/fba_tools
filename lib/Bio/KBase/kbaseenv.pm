package Bio::KBase::kbaseenv;
use strict;
use warnings;
use Bio::KBase::utilities;
use Workspace::WorkspaceClient;

our $ws_client = undef;
our $ga_client = undef;
our $ac_client = undef;
our $rast_client = undef;
our $gfu_client = undef;
our $rastsdk_client = undef;
our $handle_client = undef;
our $data_file_client = undef;
our $objects_created = [];
our $ontology_hash = undef;
our $sso_hash = undef;
my $readmapper_client = undef;

sub log {
	my ($msg,$tag) = @_;
	if (defined($tag) && $tag eq "debugging") {
		if (defined(Bio::KBase::utilities::utilconf("debugging")) && Bio::KBase::utilities::utilconf("debugging") == 1) {
			print $msg."\n";
		}
	} else {
		print $msg."\n";
	}
}

sub data_file_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($data_file_client)) {
		require "DataFileUtil/DataFileUtilClient.pm";
		$data_file_client = new DataFileUtil::DataFileUtilClient(Bio::KBase::utilities::utilconf("call_back_url"));
	}
	return $data_file_client;
}

#create_report: creates a report object using the KBaseReport service
sub create_report {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,["workspace_name","report_object_name"],{
		warnings => [],
		html_links => [],
		file_links => [],
		direct_html_link_index => undef,
		direct_html => undef,
		message => ""
	});
	my $kr;
	if (Bio::KBase::utilities::utilconf("reportimpl") == 1) {
		require "KBaseReport/KBaseReportImpl.pm";
		$kr = KBaseReport::KBaseReportImpl->new();
		if (!defined($KBaseReport::KBaseReportServer::CallContext)) {
			$KBaseReport::KBaseReportServer::CallContext = Bio::KBase::utilities::context();
		}
	} else {
		require "KBaseReport/KBaseReportClient.pm";
		$kr = KBaseReport::KBaseReportClient->new(Bio::KBase::utilities::utilconf("call_back_url"),token => Bio::KBase::utilities::token());
	}
	if (defined(Bio::KBase::utilities::utilconf("debugging")) && Bio::KBase::utilities::utilconf("debugging") == 1) {
		Bio::KBase::utilities::add_report_file({
			path => Bio::KBase::utilities::utilconf("debugfile"),
			name => "Debug.txt",
			description => "Debug file"
		});
	};
	my $data = {
		message => Bio::KBase::utilities::report_message(),
        objects_created => $objects_created,
        warnings => $parameters->{warnings},
        html_links => Bio::KBase::utilities::report_html_files(),
        direct_html => Bio::KBase::utilities::report_html(),
        direct_html_link_index => $parameters->{direct_html_link_index},
        file_links => Bio::KBase::utilities::report_files(),
        report_object_name => $parameters->{report_object_name},
        workspace_name => $parameters->{workspace_name}
	};
	return $kr->create_extended_report($data);
}

sub create_context_from_client_config {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		filename => $ENV{ KB_CLIENT_CONFIG },
		setcontext => 1,
		method => "unknown",
		provenance => []
	});
	my $config = Bio::KBase::utilities::read_config({
		filename => $parameters->{filename},
		service => "authentication"
	});
	if (!defined($config->{authentication}->{token})) {
		print "Setting token from environment variable\n";
		$config->{authentication}->{token} = $ENV{'KB_AUTH_TOKEN'};
	}
	if (!defined($config->{authentication}->{user_id})) {
		$config->{authentication}->{user_id} = "chenry";
	}
	return Bio::KBase::utilities::create_context({
		setcontext => $parameters->{setcontext},
		token => $config->{authentication}->{token},
		user => $config->{authentication}->{user_id},
		provenance => $parameters->{provenance},
		method => $parameters->{method}
	});
}

sub ws_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0,
		url => Bio::KBase::utilities::utilconf("workspace-url")
	});
	if ($parameters->{refresh} == 1 || !defined($ws_client)) {
		$ws_client = new Workspace::WorkspaceClient($parameters->{url},token => Bio::KBase::utilities::token());
	}
	return $ws_client;
}

sub ga_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($ga_client)) {
		require "GenomeAnnotationAPI/GenomeAnnotationAPIClient.pm";
		$ga_client = new GenomeAnnotationAPI::GenomeAnnotationAPIClient(Bio::KBase::utilities::utilconf("call_back_url"),token => Bio::KBase::utilities::token());
	}
	return $ga_client;
}

sub sdkrast_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($rastsdk_client)) {
		require "RAST_SDK/RAST_SDKClient.pm";
		$rastsdk_client = new RAST_SDK::RAST_SDKClient(Bio::KBase::utilities::utilconf("call_back_url"),token => Bio::KBase::utilities::token());
	}
	return $rastsdk_client;
}

sub rast_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($rast_client)) {
		require "Bio/KBase/GenomeAnnotation/Client.pm";
		$rast_client = new Bio::KBase::GenomeAnnotation::Client("http://tutorial.theseed.org/services/genome_annotation");
	}
	return $rast_client;
}

sub ac_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($ac_client)) {
		require "AssemblyUtil/AssemblyUtilClient.pm";
		$ac_client = new AssemblyUtil::AssemblyUtilClient(Bio::KBase::utilities::utilconf("call_back_url"),token => Bio::KBase::utilities::token());
	}
	return $ac_client;
}

sub gfu_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($gfu_client)) {
		require "GenomeFileUtil/GenomeFileUtilClient.pm";
		$gfu_client = new GenomeFileUtil::GenomeFileUtilClient(Bio::KBase::utilities::utilconf("call_back_url"),token => Bio::KBase::utilities::token());
	}
	return $gfu_client;
}

sub readmapper_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($readmapper_client)) {
		require "kb_readmapper/kb_readmapperClient.pm";
		$readmapper_client = new kb_readmapper::kb_readmapperClient(Bio::KBase::utilities::utilconf("call_back_url"),token => Bio::KBase::utilities::token());
	}
	return $readmapper_client;
}

sub handle_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($handle_client)) {
		require "Bio/KBase/HandleService.pm";
		$handle_client = new Bio::KBase::HandleService(Bio::KBase::utilities::conf("fba_tools","handle-service-url"),token => Bio::KBase::utilities::token());
	}
	return $handle_client;
}

sub assembly_to_fasta {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,["ref","path","filename"],{});
	File::Path::mkpath($parameters->{path});
	if (-e $parameters->{path}."/".$parameters->{filename}) {
		unlink($parameters->{path}."/".$parameters->{filename});
	}
	if (Bio::KBase::utilities::utilconf("use_assembly_utils") == 1) {
		my $assutil = Bio::KBase::kbaseenv::ac_client();
		my $output = $assutil->get_assembly_as_fasta({"ref" => $parameters->{"ref"},"filename" => $parameters->{path}."/".$parameters->{filename}});
	} else {
		my $output = Bio::KBase::kbaseenv::ws_client()->get_objects([{"ref" => $parameters->{"ref"}}]);
		my $hc = Bio::KBase::kbaseenv::handle_client();
		$hc->download(
			$output->[0]->{data}->{fasta_handle_info}->{handle},
			$parameters->{path}."/".$parameters->{filename}
		);
	}
}

sub get_object {
	my ($ws,$id) = @_;
	my $output = Bio::KBase::kbaseenv::ws_client()->get_objects([Bio::KBase::kbaseenv::configure_ws_id($ws,$id)]);
	return $output->[0]->{data};
}

sub get_objects {
	my ($args,$options) = @_;
	my $input = {
		objects => $args,
	};
	my $output = Bio::KBase::kbaseenv::ws_client()->get_objects2($input);
	return $output->{data};
}

sub list_objects {
	my ($args) = @_;
	return Bio::KBase::kbaseenv::ws_client()->list_objects($args);
}

sub get_object_info {
	my ($argone,$argtwo) = @_;
	return Bio::KBase::kbaseenv::ws_client()->get_object_info($argone,$argtwo);
}

sub administer {
	my ($args) = @_;
	return Bio::KBase::kbaseenv::ws_client()->administer($args);
}

sub reset_objects_created {
	$objects_created = [];
}

sub add_object_created {
	my ($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,["ref","description"],{});
	push(@{$objects_created},$parameters);
}

sub save_objects {
	my ($args) = @_;
	my $retryCount = 3;
	my $error;
	my $output;
	while ($retryCount > 0) {
		eval {
			$output = Bio::KBase::kbaseenv::ws_client()->save_objects($args);
			for (my $i=0; $i < @{$output}; $i++) {
				my $array = [split(/\./,$output->[$i]->[2])];
				my $description = $array->[1]." ".$output->[$i]->[1];
				if (defined($output->[$i]->[10]) && defined($output->[$i]->[10]->{description})) {
					$description = $output->[$i]->[10]->{description};
				}
				push(@{$objects_created},{
					"ref" => $output->[$i]->[6]."/".$output->[$i]->[0]."/".$output->[$i]->[4],
					description => $description
				});
			}
		};
		# If there is a network glitch, wait a second and try again.
		if ($@) {
			$retryCount--;
			$error = $@;
		} else {
			last;
		}
	}
	if ($retryCount == 0) {
		Bio::KBase::utilities::error($error);
	}
	return $output;
}

sub configure_ws_id {
	my ($ws,$id,$version) = @_;
	my $input = {};
 	if ($ws =~ m/^\d+$/) {
 		$input->{wsid} = $ws;
	} else {
		$input->{workspace} = $ws;
	}
	if ($id =~ m/^\d+$/) {
		$input->{objid} = $id;
	} else {
		$input->{name} = $id;
	}
	if (defined($version)) {
		$input->{ver} = $version;
	}
	return $input;
}

sub initialize_call {
	my ($ctx) = @_;
	Bio::KBase::kbaseenv::reset_objects_created();
	Bio::KBase::utilities::timestamp(1);
	Bio::KBase::utilities::set_context($ctx);
	Bio::KBase::kbaseenv::ws_client({refresh => 1});
	print("Starting ".Bio::KBase::utilities::method()." method.\n");
}

sub get_ontology_hash {
	if (!defined($ontology_hash)) {
		$ontology_hash = {};
		my $list = Bio::KBase::utilities::conf("ModelSEED","ontology_map_list");
		$list = [split(/;/,$list)];
		for (my $i=0; $i < @{$list}; $i++) {
			my $subarray = [split(/:/,$list->[$i])];
			my $output = Bio::KBase::kbaseenv::get_object(Bio::KBase::utilities::conf("ModelSEED","ontology_map_workspace"),$subarray->[1]);
			foreach my $term (keys(%{$output->{translation}})) {
				foreach my $otherterm (@{$output->{translation}->{$term}->{equiv_terms}}) {
					if (defined($otherterm->{equiv_term})) {
						$ontology_hash->{$term}->{$otherterm->{equiv_term}} = $subarray->[0];
					}
				}
			}
		}
	}
	return $ontology_hash;
}

sub get_sso_hash {
	if (!defined($sso_hash)) {
		my $output = $ws_client->get_objects([{
			workspace => "KBaseOntology",
			name => "seed_subsystem_ontology"
		}]);
		$sso_hash = {};
		foreach my $term (keys(%{$output->[0]->{data}->{term_hash}})) {
			my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($output->[0]->{data}->{term_hash}->{$term}->{name});
			$output->[0]->{data}->{term_hash}->{$term}->{searchname} = $searchrole;
			$sso_hash->{$searchrole} = $output->[0]->{data}->{term_hash}->{$term};
			$sso_hash->{$term} = $output->[0]->{data}->{term_hash}->{$term};
			$sso_hash->{$output->[0]->{data}->{term_hash}->{$term}->{id}} = $output->[0]->{data}->{term_hash}->{$term};
		}
	}
	return $sso_hash;
}

1;
