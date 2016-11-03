package Bio::KBase::utilities;
use strict;
use warnings;
use Carp qw(cluck);
use Config::Simple;
use DateTime;

our $config = undef;
our $ws_client = undef;
our $ctx = undef;
our $timestamp = undef;
our $debugfile = undef;
our $objects_created = [];

#read_config: an all purpose general method for reading in service configurations and setting mandatory/optional values
sub read_config {
	my ($args) = @_;
	$args = Bio::KBase::utilities::args($args,[],{
		filename => $ENV{KB_DEPLOYMENT_CONFIG},
		service => $ENV{KB_SERVICE_NAME},
		mandatory => [],
		optional => {}
	});
	if (!defined($args->{service})) {
		Bio::KBase::utilities::error("No service specified!");
	}
	if (!defined($args->{filename})) {
		Bio::KBase::utilities::error("No config file specified!");
	}
	if (!-e $args->{filename}) {
		Bio::KBase::utilities::error("Specified config file ".$args->{filename}." doesn't exist!");
	}
	my $c = Config::Simple->new();
	$c->read($args->{filename});
	my $hash = $c->vars();
	foreach my $key (keys(%{$hash})) {
		my $array = [split(/\./,$key)];
		$config->{$array->[0]}->{$array->[1]} = $hash->{$key};
	}
	$config->{$args->{service}} = Bio::KBase::utilities::args($config->{$args->{service}},$args->{mandatory},$args->{optional});
	$config->{UtilConfig} = Bio::KBase::utilities::args($config->{UtilConfig},[],{
		fulltrace => 0,
		reportimpl => 0,
		call_back_url =>  $ENV{ SDK_CALLBACK_URL },
		token => undef
	});
	return $config;
}

#args: a function for validating argument hashes that checks for mandatory keys and sets default values on optional keys
sub args {
	my ($args,$mandatoryArguments,$optionalArguments,$substitutions) = @_;
	if (!defined($args)) {
	    $args = {};
	}
	if (ref($args) ne "HASH") {
		Bio::KBase::utilities::error("Arguments not hash");	
	}
	if (defined($substitutions) && ref($substitutions) eq "HASH") {
		foreach my $original (keys(%{$substitutions})) {
			$args->{$original} = $args->{$substitutions->{$original}};
		}
	}
	if (defined($mandatoryArguments)) {
		my $mandatorylist;
		for (my $i=0; $i < @{$mandatoryArguments}; $i++) {
			if (!defined($args->{$mandatoryArguments->[$i]})) {
				push(@{$mandatorylist},$mandatoryArguments->[$i]);
			}
		}
		if (defined($mandatorylist)) {
			Bio::KBase::utilities::error("Mandatory arguments missing ".join("; ",@{$mandatorylist}));
		}
	}
	if (defined($optionalArguments)) {
		foreach my $argument (keys(%{$optionalArguments})) {
			if (!defined($args->{$argument})) {
				$args->{$argument} = $optionalArguments->{$argument};
			}
		}	
	}
	return $args;
}

#utilconf: returns values for configurations specifically relating to these utility functions
sub utilconf {
	my ($var) = @_;
	return Bio::KBase::utilities::conf("UtilConfig",$var);
}

#setconf: sets the value of a specific config parameter
sub setconf {
	my ($serv,$var,$value) = @_;
	if (!defined($config)) {
		Bio::KBase::utilities::read_config();
	}
	$config->{$serv}->{$var} = $value;
}

#conf: returns values for all service configurations
sub conf {
	my ($serv,$var) = @_;
	if (!defined($config)) {
		Bio::KBase::utilities::read_config();
	}
	return $config->{$serv}->{$var};
}

#error: prints an error message
sub error {	
	my ($message) = @_;
    if (Bio::KBase::utilities::utilconf("fulltrace") == 1) {
		Carp::confess($message);
    } else {
    	die $message;
    }
}

sub debug {
	my ($message) = @_;
	if (!defined($debugfile)) {
		open ( $debugfile, ">", Bio::KBase::utilities::utilconf("debugfile"));
	}
	print $debugfile $message;
}

sub close_debug {
	close($debugfile);
	$debugfile = undef;
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
		$kr = new KBaseReport::KBaseReportImpl();
		if (!defined($KBaseReport::KBaseReportServer::CallContext)) {
			$KBaseReport::KBaseReportServer::CallContext = $ctx;
		}
	} else {
		require "KBaseReport/KBaseReportClient.pm";
		$kr = new KBaseReport::KBaseReportClient(Bio::KBase::utilconf("call_back_url"),token => Bio::KBase::utilities::token());
	}
	if (defined(Bio::KBase::utilities::utilconf("debugging")) && Bio::KBase::utilities::utilconf("debugging") == 1) {
		push(@{$parameters->{file_links}},{
			path => Bio::KBase::utilities::utilconf("debugfile"),
	        name => "Debug.txt",
	        description => "Debug file"
		});
	}
	return $kr->create_extended_report({
		message => $parameters->{message},
        objects_created => $objects_created,
        warnings => $parameters->{warnings},
        html_links => $parameters->{html_links},
        direct_html => $parameters->{direct_html},
        direct_html_link_index => $parameters->{direct_html_link_index},
        file_links => $parameters->{file_links},
        report_object_name => $parameters->{report_object_name},
        workspace_name => $parameters->{workspace_name}
	});
}

sub create_context {	
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,["token","user"],{
		method => "unknown",
		provenance => [],
		setcontext => 1
	});
	my $context = LocalCallContext->new($parameters->{token}, $parameters->{user},$parameters->{provenance},$parameters->{method});
	if ($parameters->{setcontext} == 1) {
		Bio::KBase::utilities::set_context($context);
	}
	return $context;
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
	my $context = LocalCallContext->new($config->{authentication}->{token},$config->{authentication}->{user_id},$parameters->{provenance},$parameters->{method});
	if ($parameters->{setcontext} == 1) {
		Bio::KBase::utilities::set_context($context);
	}
	return $context;
}

sub set_context {
	my($context) = @_;
	$ctx = $context;
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

sub get_object {
	my ($ws,$id) = @_;
	my $output = Bio::KBase::utilities::ws_client()->get_objects();
	print "Getting object: ".$ws."/".$id."\n";
	return $output->[0]->{data};
}

sub get_objects {
	my ($args) = @_;
	return Bio::KBase::utilities::ws_client()->get_objects($args);
}

sub get_object_info {
	my ($argone,$argtwo) = @_;
	return Bio::KBase::utilities::ws_client()->get_object_info($argone,$argtwo);
}

sub administer {
	my ($args) = @_;
	return Bio::KBase::utilities::ws_client()->administer($args);
}

sub reset_objects_created {
	$objects_created = [];
}

sub save_objects {
	my ($args) = @_;
	my $output = Bio::KBase::utilities::ws_client()->save_objects($args);
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

sub token {
	return $ctx->token();
}

sub method {
	return $ctx->method();
}

sub provenance {
	return $ctx->provenance();
}

sub user_id {
	return $ctx->user_id();
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

sub timestamp {
	my ($reset) = @_;
	if (defined($reset) && $reset == 1) {
		$timestamp = DateTime->now()->datetime();
	}
	return $timestamp;	
}

sub initialize_call {
	my ($ctx) = @_;
	Bio::KBase::utilities::reset_objects_created();
	Bio::KBase::utilities::timestamp(1);
	Bio::KBase::utilities::set_context($ctx);
	Bio::KBase::utilities::ws_client({refresh => 1});
	print("Starting ".Bio::KBase::utilities::method()." method.\n");
}

{
    package LocalCallContext;
    use strict;
    sub new {
        my($class,$token,$user,$provenance,$method) = @_;
        my $self = {
            token => $token,
            user_id => $user,
            provenance => $provenance,
            method => $method
        };
        return bless $self, $class;
    }
    sub user_id {
        my($self) = @_;
        return $self->{user_id};
    }
    sub token {
        my($self) = @_;
        return $self->{token};
    }
    sub provenance {
        my($self) = @_;
        return $self->{provenance};
    }
    sub method {
        my($self) = @_;
        return $self->{method};
    }
    sub authenticated {
        return 1;
    }
    sub log_debug {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
    sub log_info {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
}

1;
