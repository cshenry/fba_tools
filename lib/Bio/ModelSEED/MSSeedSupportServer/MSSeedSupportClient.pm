package Bio::ModelSEED::MSSeedSupportServer::MSSeedSupportClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

Bio::ModelSEED::MSSeedSupportServer::MSSeedSupportClient

=head1 DESCRIPTION


=head1 MSSeedSupportServer

=head2 SYNOPSIS

=head2 EXAMPLE OF API USE IN PERL

=head2 AUTHENTICATION

=head2 MSSEEDSUPPORTSERVER


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => Bio::ModelSEED::MSSeedSupportServer::MSSeedSupportClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my $token = Bio::KBase::AuthToken->new(@args);
	
	if (!$token->error_message)
	{
	    $self->{token} = $token->token;
	    $self->{client}->{token} = $token->token;
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 getRastGenomeData

  $output = $obj->getRastGenomeData($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a getRastGenomeData_params
$output is a RastGenome
getRastGenomeData_params is a reference to a hash where the following keys are defined:
	username has a value which is a string
	password has a value which is a string
	genome has a value which is a string
	getSequences has a value which is an int
	getDNASequence has a value which is an int
RastGenome is a reference to a hash where the following keys are defined:
	source has a value which is a string
	genome has a value which is a string
	features has a value which is a reference to a list where each element is a string
	DNAsequence has a value which is a reference to a list where each element is a string
	name has a value which is a string
	taxonomy has a value which is a string
	size has a value which is an int
	owner has a value which is a string

</pre>

=end html

=begin text

$params is a getRastGenomeData_params
$output is a RastGenome
getRastGenomeData_params is a reference to a hash where the following keys are defined:
	username has a value which is a string
	password has a value which is a string
	genome has a value which is a string
	getSequences has a value which is an int
	getDNASequence has a value which is an int
RastGenome is a reference to a hash where the following keys are defined:
	source has a value which is a string
	genome has a value which is a string
	features has a value which is a reference to a list where each element is a string
	DNAsequence has a value which is a reference to a list where each element is a string
	name has a value which is a string
	taxonomy has a value which is a string
	size has a value which is an int
	owner has a value which is a string


=end text

=item Description

Retrieves a RAST genome based on the input genome ID

=back

=cut

sub getRastGenomeData
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function getRastGenomeData (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to getRastGenomeData:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'getRastGenomeData');
	}
    }

    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
	method => "MSSeedSupportServer.getRastGenomeData",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'getRastGenomeData',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method getRastGenomeData",
					    status_line => $self->{client}->status_line,
					    method_name => 'getRastGenomeData',
				       );
    }
}



=head2 load_model_to_modelseed

  $success = $obj->load_model_to_modelseed($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a load_model_to_modelseed_params
$success is an int
load_model_to_modelseed_params is a reference to a hash where the following keys are defined:
	username has a value which is a string
	password has a value which is a string
	owner has a value which is a string
	genome has a value which is a string
	reactions has a value which is a reference to a list where each element is a string
	biomass has a value which is a string

</pre>

=end html

=begin text

$params is a load_model_to_modelseed_params
$success is an int
load_model_to_modelseed_params is a reference to a hash where the following keys are defined:
	username has a value which is a string
	password has a value which is a string
	owner has a value which is a string
	genome has a value which is a string
	reactions has a value which is a reference to a list where each element is a string
	biomass has a value which is a string


=end text

=item Description

Loads the input model to the model seed database

=back

=cut

sub load_model_to_modelseed
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function load_model_to_modelseed (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to load_model_to_modelseed:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'load_model_to_modelseed');
	}
    }

    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
	method => "MSSeedSupportServer.load_model_to_modelseed",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'load_model_to_modelseed',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method load_model_to_modelseed",
					    status_line => $self->{client}->status_line,
					    method_name => 'load_model_to_modelseed',
				       );
    }
}



=head2 list_rast_jobs

  $output = $obj->list_rast_jobs($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a list_rast_jobs_params
$output is a reference to a list where each element is a RASTJob
list_rast_jobs_params is a reference to a hash where the following keys are defined:
	owner has a value which is a string
RASTJob is a reference to a hash where the following keys are defined:
	owner has a value which is a string
	project has a value which is a string
	id has a value which is a string
	creation_time has a value which is a string
	mod_time has a value which is a string
	genome_size has a value which is an int
	contig_count has a value which is an int
	genome_id has a value which is a string
	genome_name has a value which is a string
	type has a value which is a string

</pre>

=end html

=begin text

$input is a list_rast_jobs_params
$output is a reference to a list where each element is a RASTJob
list_rast_jobs_params is a reference to a hash where the following keys are defined:
	owner has a value which is a string
RASTJob is a reference to a hash where the following keys are defined:
	owner has a value which is a string
	project has a value which is a string
	id has a value which is a string
	creation_time has a value which is a string
	mod_time has a value which is a string
	genome_size has a value which is an int
	contig_count has a value which is an int
	genome_id has a value which is a string
	genome_name has a value which is a string
	type has a value which is a string


=end text

=item Description

Retrieves a list of jobs owned by the specified RAST user

=back

=cut

sub list_rast_jobs
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_rast_jobs (received $n, expecting 1)");
    }
    {
	my($input) = @args;

	my @_bad_arguments;
        (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"input\" (value was \"$input\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_rast_jobs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_rast_jobs');
	}
    }

    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
	method => "MSSeedSupportServer.list_rast_jobs",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_rast_jobs',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_rast_jobs",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_rast_jobs',
				       );
    }
}



sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "MSSeedSupportServer.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'list_rast_jobs',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method list_rast_jobs",
            status_line => $self->{client}->status_line,
            method_name => 'list_rast_jobs',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for Bio::ModelSEED::MSSeedSupportServer::MSSeedSupportClient\n";
    }
    if ($sMajor == 0) {
        warn "Bio::ModelSEED::MSSeedSupportServer::MSSeedSupportClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 RASTJob

=over 4



=item Description

RAST job data

string owner - owner of the job
string project - project name
string id - ID of the job
string creation_time - time of creation
string mod_time - time of modification
int genome_size - size of genome
int contig_count - number of contigs
string genome_id - ID of the genome created by the job
string genome_name - name of genome
string type - type of job


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
owner has a value which is a string
project has a value which is a string
id has a value which is a string
creation_time has a value which is a string
mod_time has a value which is a string
genome_size has a value which is an int
contig_count has a value which is an int
genome_id has a value which is a string
genome_name has a value which is a string
type has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
owner has a value which is a string
project has a value which is a string
id has a value which is a string
creation_time has a value which is a string
mod_time has a value which is a string
genome_size has a value which is an int
contig_count has a value which is an int
genome_id has a value which is a string
genome_name has a value which is a string
type has a value which is a string


=end text

=back



=head2 RastGenome

=over 4



=item Description

RAST genome data

        string source;
        string genome;
        list<string> features;
        list<string> DNAsequence;
        string name;
        string taxonomy;
        int size;
        string owner;


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
source has a value which is a string
genome has a value which is a string
features has a value which is a reference to a list where each element is a string
DNAsequence has a value which is a reference to a list where each element is a string
name has a value which is a string
taxonomy has a value which is a string
size has a value which is an int
owner has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
source has a value which is a string
genome has a value which is a string
features has a value which is a reference to a list where each element is a string
DNAsequence has a value which is a reference to a list where each element is a string
name has a value which is a string
taxonomy has a value which is a string
size has a value which is an int
owner has a value which is a string


=end text

=back



=head2 getRastGenomeData_params

=over 4



=item Description

Input parameters for the "getRastGenomeData" function.

        string genome;
        int getSequences;
        int getDNASequence;
        string username;
        string password;


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
username has a value which is a string
password has a value which is a string
genome has a value which is a string
getSequences has a value which is an int
getDNASequence has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
username has a value which is a string
password has a value which is a string
genome has a value which is a string
getSequences has a value which is an int
getDNASequence has a value which is an int


=end text

=back



=head2 load_model_to_modelseed_params

=over 4



=item Description

Input parameters for the "load_model_to_modelseed" function.

        string token;


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
username has a value which is a string
password has a value which is a string
owner has a value which is a string
genome has a value which is a string
reactions has a value which is a reference to a list where each element is a string
biomass has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
username has a value which is a string
password has a value which is a string
owner has a value which is a string
genome has a value which is a string
reactions has a value which is a reference to a list where each element is a string
biomass has a value which is a string


=end text

=back



=head2 list_rast_jobs_params

=over 4



=item Description

Output for the "list_rast_jobs_params" function.

        string owner - user for whom jobs should be listed (optional - default is authenticated user)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
owner has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
owner has a value which is a string


=end text

=back



=cut

package Bio::ModelSEED::MSSeedSupportServer::MSSeedSupportClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
