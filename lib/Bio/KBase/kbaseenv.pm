package Bio::KBase::kbaseenv;
use strict;
use warnings;
use Bio::KBase::utilities;

our $ws_client = undef;
our $ga_client = undef;
our $ac_client = undef;
our $objects_created = [];

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
		$kr = new KBaseReport::KBaseReportImpl();
		if (!defined($KBaseReport::KBaseReportServer::CallContext)) {
			$KBaseReport::KBaseReportServer::CallContext = Bio::KBase::utilities::context();
		}
	} else {
		require "KBaseReport/KBaseReportClient.pm";
		$kr = new KBaseReport::KBaseReportClient(Bio::KBase::utilities::utilconf("call_back_url"),token => Bio::KBase::utilities::token());
	}
	if (defined(Bio::KBase::utilities::utilconf("debugging")) && Bio::KBase::utilities::utilconf("debugging") == 1) {
		Bio::KBase::utilities::add_report_file({
			path => Bio::KBase::utilities::utilconf("debugfile"),
			name => "Debug.txt",
			description => "Debug file"
		});
	};
	return $kr->create_extended_report({
		message => Bio::KBase::utilities::report_message(),
        objects_created => $objects_created,
        warnings => $parameters->{warnings},
        html_links => Bio::KBase::utilities::report_html_files(),
        direct_html => Bio::KBase::utilities::report_html(),
        direct_html_link_index => $parameters->{direct_html_link_index},
        file_links => Bio::KBase::utilities::report_files(),
        report_object_name => $parameters->{report_object_name},
        workspace_name => $parameters->{workspace_name}
	});
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
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($ws_client)) {
		$ws_client = new Bio::KBase::workspace::Client(Bio::KBase::utilities::utilconf("workspace-url"),token => Bio::KBase::utilities::token());
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
		$ga_client = new GenomeAnnotationAPI::GenomeAnnotationAPIClient(Bio::KBase::utilities::utilconf("call_back_url"));
	}
	return $ga_client;
}

sub ac_client {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		refresh => 0
	});
	if ($parameters->{refresh} == 1 || !defined($ac_client)) {
		require "AssemblyUtil/AssemblyUtilClient.pm";
		$ac_client = new AssemblyUtil::AssemblyUtilClient(Bio::KBase::utilities::utilconf("call_back_url"));
	}
	return $ac_client;
}

sub get_object {
	my ($ws,$id) = @_;
	my $output = Bio::KBase::kbaseenv::ws_client()->get_objects();
	return $output->[0]->{data};
}

sub get_objects {
	my ($args) = @_;
	return Bio::KBase::kbaseenv::ws_client()->get_objects($args);
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
	my $output = Bio::KBase::kbaseenv::ws_client()->save_objects($args);
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
	return $output;
}

sub configure_ws_id {
	my ($ws,$id) = @_;
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

1;
