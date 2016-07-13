package Bio::KBase::ObjectAPI::config;
use strict;

our $useoldmodels = 0;
our $setowner = "";
our $username = "";
our $method = "";
our $adminmode = 0;
our $token = undef;
our $configfile_loaded = undef;
our $service_config = undef;
our $provenance = undef;

sub old_models {
	my $input = shift;
	if (defined($input)) {
		$useoldmodels = $input;
	}
	return $useoldmodels;
}

sub home_dir {
	my $input = shift;
	if (defined($input)) {
		$service_config->{home_dir} = $input;
	}
	return $service_config->{home_dir};
}

sub bin_directory {
	my $input = shift;
	if (defined($input)) {
		$service_config->{bin_directory} = $input;#
	}
	return $service_config->{bin_directory};
}

sub config_directory {
	my $input = shift;
	if (defined($input)) {
		$service_config->{configdir} = $input;
	}
	return $service_config->{configdir};
}

sub username {
	my $input = shift;
	if (defined($input)) {
		$username = $input;
	}
	return $username;
}

sub mfatoolkit_binary {
	my $input = shift;
	if (defined($input)) {
		$service_config->{mfatoolkitbin} = $input;
	}
	return $service_config->{mfatoolkitbin};
}

sub mfatoolkit_job_dir {
	my $input = shift;
	if (defined($input)) {
		$service_config->{fbajobdir} = $input;
	}
	return $service_config->{fbajobdir};
}

sub source {
	my $input = shift;
	if (defined($input)) {
		$service_config->{source} = $input;
	}
	return $service_config->{source};
}

sub default_biochemistry {
	my $input = shift;
	if (defined($input)) {
		$service_config->{biochemistry} = $input;
	}
	return $service_config->{biochemistry};
}

sub FinalJobCache {
	my $input = shift;
	if (defined($input)) {
		$service_config->{fbajobcache} = $input;
	}
	return $service_config->{fbajobcache};
}

sub run_as_app {
	my $input = shift;
	if (defined($input)) {
		$service_config->{run_as_app} = $input;
	}
	return $service_config->{run_as_app};
}

sub method {
	my $input = shift;
	if (defined($input)) {
		$method = $input;
	}
	return $method;
}

sub adminmode {
	my $input = shift;
	if (defined($input)) {
		$adminmode = $input;
	}
	return $adminmode;
}

sub setowner {
	my $input = shift;
	if (defined($input)) {
		$setowner = $input;
	}
	return $setowner;
}

sub shock_url {
	my $input = shift;
	if (defined($input)) {
		$service_config->{"shock-url"} = $input;
	}
	return $service_config->{"shock-url"};
}

sub kbwsurl {
	my $input = shift;
	if (defined($input)) {
		$service_config->{kbwsurl} = $input;
	}
	return $service_config->{kbwsurl};
}

sub workspace_url {
	my $input = shift;
	if (defined($input)) {
		$service_config->{"workspace-url"} = $input;
	}
	return $service_config->{"workspace-url"};
}

sub mssserver_url {
	my $input = shift;
	if (defined($input)) {
		$service_config->{"mssserver-url"} = $input;
	}
	return $service_config->{"mssserver-url"};
}

sub appservice_url {
	my $input = shift;
	if (defined($input)) {
		$service_config->{"appservice_ur"} = $input;
	}
	return $service_config->{"appservice_url"};
}

sub template_dir {
	my $input = shift;
	if (defined($input)) {
		$service_config->{template_dir} = $input;
	}
	return $service_config->{template_dir};
}

sub classifier {
	my $input = shift;
	if (defined($input)) {
		$service_config->{classifier} = $input;
	}
	return $service_config->{classifier};
}

sub cache_targets {
	my $input = shift;
	if (defined($input)) {
		$service_config->{cache_targets} = $input;
	}
	if (!ref($service_config->{cache_targets})) {
		$service_config->{cache_targets} = [split(/;/,$service_config->{cache_targets})];
	}
	return $service_config->{cache_targets};
}

sub file_cache {
	my $input = shift;
	if (defined($input)) {
		$service_config->{file_cache} = $input;
	}
	return $service_config->{file_cache};
}

sub token {
	my $input = shift;
	if (defined($input)) {
		$token = $input;
	}
	return $token;
}

sub data_api_url {
	my $input = shift;
	if (defined($input)) {
		$service_config->{data_api_url} = $input;
	}
	return $service_config->{data_api_url};
}

sub default_plant_media {
	my $input = shift;
	if (defined($input)) {
		$service_config->{default_plant_media} = $input;
	}
	return $service_config->{default_plant_media};
}

sub default_microbial_media {
	my $input = shift;
	if (defined($input)) {
		$service_config->{default_microbial_media} = $input;
	}
	return $service_config->{default_microbial_media};
}

sub default_media_workspace {
	my $input = shift;
	if (defined($input)) {
		$service_config->{default_media_workspace} = $input;
	}
	return $service_config->{default_media_workspace};
}

sub configfile_loaded {
	my $input = shift;
	if (defined($input)) {
		$configfile_loaded = $input;
	}
	return $configfile_loaded;
}

sub load_config {
	my ($args) = @_;
	$args = Bio::KBase::ObjectAPI::utilities::ARGS($args,[],{
		filename => $ENV{KB_DEPLOYMENT_CONFIG},
		service => $ENV{KB_SERVICE_NAME},
	});
	if (!defined($args->{service})) {
		Bio::KBase::ObjectAPI::utilities::error("No service specified!");
	}
	if (!defined($args->{filename})) {
		Bio::KBase::ObjectAPI::utilities::error("No config file specified!");
	}
	if (!-e $args->{filename}) {
		Bio::KBase::ObjectAPI::utilities::error("Specified config file ".$args->{filename}." doesn't exist!");
	}
	my $c = Config::Simple->new();
	$c->read($args->{filename});
	my $hash = $c->vars();
	$service_config = {};
	foreach my $key (keys(%{$hash})) {
		my $array = [split(/\./,$key)];
		if ($array->[0] eq $args->{service}) {
			if ($hash->{$key} ne "null") {
				$service_config->{$array->[1]} = $hash->{$key};
			}
		}
	}
	$service_config = Bio::KBase::ObjectAPI::utilities::ARGS($service_config,["fbajobcache","fbajobdir","mfatoolkitbin"],{
    	source => "PATRIC",
    	kbwsurl => "https://kbase.us/services/ws",
    	data_api_url => "https://www.patricbrc.org/api/",
    	"mssserver-url" => "http://bio-data-1.mcs.anl.gov/services/ms_fba",
    	"workspace-url" => "http://p3.theseed.org/services/Workspace",
    	appservice_url => "http://p3.theseed.org/services/app_service",
    	"shock-url" => "http://p3.theseed.org/services/shock_api",
      	run_as_app => 1,
    	home_dir => "modelseed",
    	file_cache => "/disks/p3/fba/filecache/",
    	cache_targets => ["/chenry/public/modelsupport/biochemistry/default.biochem"],
    	biochemistry => "/chenry/public/modelsupport/biochemistry/default.biochem",
    	default_media => "/chenry/public/modelsupport/patric-media/Complete",
    	classifier => "/chenry/public/modelsupport/classifiers/gramclassifier.string",
    	template_dir => "/chenry/public/modelsupport/templates/"
     });	
	Bio::KBase::ObjectAPI::config::configfile_loaded($args->{filename});
}

sub all_params {
	my $input = shift;
	if (defined($input)) {
		$service_config = $input;
	}
	return $service_config;
}

sub provenance {
	my $input = shift;
	return $provenance;
}

1;
