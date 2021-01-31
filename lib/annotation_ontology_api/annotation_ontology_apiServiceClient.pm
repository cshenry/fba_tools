package annotation_ontology_api::annotation_ontology_apiServiceClient;

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

annotation_ontology_api::annotation_ontology_apiServiceClient

=head1 DESCRIPTION


A KBase module: annotation_ontology_api


=cut

sub new
{
    my($class, $url, @args) = @_;
    
    if (!defined($url))
    {
	$url = 'https://kbase.us/services/service_wizard';
    }

    my $self = {
	client => annotation_ontology_api::annotation_ontology_apiServiceClient::RpcClient->new,
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
	my %arg_hash2 = @args;
	if (exists $arg_hash2{"token"}) {
	    $self->{token} = $arg_hash2{"token"};
	} elsif (exists $arg_hash2{"user_id"}) {
	    my $token = Bio::KBase::AuthToken->new(@args);
	    if (!$token->error_message) {
	        $self->{token} = $token->token;
	    }
	}
	
	if (exists $self->{token})
	{
	    $self->{client}->{token} = $self->{token};
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 get_annotation_ontology_events

  $output = $obj->get_annotation_ontology_events($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an annotation_ontology_api.GetAnnotationOntologyEventsParams
$output is an annotation_ontology_api.GetAnnotationOntologyEventsOutput
GetAnnotationOntologyEventsParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
	input_workspace has a value which is a string
	query_events has a value which is a reference to a list where each element is a string
	query_genes has a value which is a reference to a list where each element is a string
	standardize_modelseed_ids has a value which is an int
GetAnnotationOntologyEventsOutput is a reference to a hash where the following keys are defined:
	events has a value which is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyEvent
AnnotationOntologyEvent is a reference to a hash where the following keys are defined:
	event_id has a value which is a string
	description has a value which is a string
	ontology_id has a value which is a string
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	feature_types has a value which is a reference to a hash where the key is a string and the value is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyTerm
AnnotationOntologyTerm is a reference to a hash where the following keys are defined:
	term has a value which is a string
	modelseed_ids has a value which is a reference to a list where each element is a string
	evidence has a value which is a string

</pre>

=end html

=begin text

$params is an annotation_ontology_api.GetAnnotationOntologyEventsParams
$output is an annotation_ontology_api.GetAnnotationOntologyEventsOutput
GetAnnotationOntologyEventsParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
	input_workspace has a value which is a string
	query_events has a value which is a reference to a list where each element is a string
	query_genes has a value which is a reference to a list where each element is a string
	standardize_modelseed_ids has a value which is an int
GetAnnotationOntologyEventsOutput is a reference to a hash where the following keys are defined:
	events has a value which is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyEvent
AnnotationOntologyEvent is a reference to a hash where the following keys are defined:
	event_id has a value which is a string
	description has a value which is a string
	ontology_id has a value which is a string
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	feature_types has a value which is a reference to a hash where the key is a string and the value is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyTerm
AnnotationOntologyTerm is a reference to a hash where the following keys are defined:
	term has a value which is a string
	modelseed_ids has a value which is a reference to a list where each element is a string
	evidence has a value which is a string


=end text

=item Description

Retrieves annotation ontology events in a standardized form cleaning up inconsistencies in underlying data

=back

=cut

 sub get_annotation_ontology_events
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_annotation_ontology_events (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_annotation_ontology_events:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_annotation_ontology_events');
	}
    }

    my $service_state = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "ServiceWizard.get_service_status",
        params => [{module_name=>"annotation_ontology_api", version=>$self->{service_version}}]});
    if ($service_state->is_error) {
        Bio::KBase::Exceptions::JSONRPC->throw(error => $service_state->error_message,
                           code => $service_state->content->{error}->{code},
                           method_name => 'ServiceWizard.get_service_status',
                           data => $service_state->content->{error}->{error}
                          );
    }
    my $url = $service_state->result->[0]->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "annotation_ontology_api.get_annotation_ontology_events",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_annotation_ontology_events',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_annotation_ontology_events",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_annotation_ontology_events',
				       );
    }
}
 


=head2 add_annotation_ontology_events

  $output = $obj->add_annotation_ontology_events($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an annotation_ontology_api.AddAnnotationOntologyEventsParams
$output is an annotation_ontology_api.AddAnnotationOntologyEventsOutput
AddAnnotationOntologyEventsParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
	input_workspace has a value which is a string
	output_name has a value which is a string
	output_workspace has a value which is a string
	clear_existing has a value which is an int
	overwrite_matching has a value which is an int
	events has a value which is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyEvent
AnnotationOntologyEvent is a reference to a hash where the following keys are defined:
	event_id has a value which is a string
	description has a value which is a string
	ontology_id has a value which is a string
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	feature_types has a value which is a reference to a hash where the key is a string and the value is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyTerm
AnnotationOntologyTerm is a reference to a hash where the following keys are defined:
	term has a value which is a string
	modelseed_ids has a value which is a reference to a list where each element is a string
	evidence has a value which is a string
AddAnnotationOntologyEventsOutput is a reference to a hash where the following keys are defined:
	output_ref has a value which is a string

</pre>

=end html

=begin text

$params is an annotation_ontology_api.AddAnnotationOntologyEventsParams
$output is an annotation_ontology_api.AddAnnotationOntologyEventsOutput
AddAnnotationOntologyEventsParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
	input_workspace has a value which is a string
	output_name has a value which is a string
	output_workspace has a value which is a string
	clear_existing has a value which is an int
	overwrite_matching has a value which is an int
	events has a value which is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyEvent
AnnotationOntologyEvent is a reference to a hash where the following keys are defined:
	event_id has a value which is a string
	description has a value which is a string
	ontology_id has a value which is a string
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	feature_types has a value which is a reference to a hash where the key is a string and the value is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyTerm
AnnotationOntologyTerm is a reference to a hash where the following keys are defined:
	term has a value which is a string
	modelseed_ids has a value which is a reference to a list where each element is a string
	evidence has a value which is a string
AddAnnotationOntologyEventsOutput is a reference to a hash where the following keys are defined:
	output_ref has a value which is a string


=end text

=item Description

Adds a new annotation ontology event to a genome or AMA

=back

=cut

 sub add_annotation_ontology_events
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function add_annotation_ontology_events (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to add_annotation_ontology_events:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'add_annotation_ontology_events');
	}
    }

    my $service_state = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "ServiceWizard.get_service_status",
        params => [{module_name=>"annotation_ontology_api", version=>$self->{service_version}}]});
    if ($service_state->is_error) {
        Bio::KBase::Exceptions::JSONRPC->throw(error => $service_state->error_message,
                           code => $service_state->content->{error}->{code},
                           method_name => 'ServiceWizard.get_service_status',
                           data => $service_state->content->{error}->{error}
                          );
    }
    my $url = $service_state->result->[0]->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "annotation_ontology_api.add_annotation_ontology_events",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'add_annotation_ontology_events',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method add_annotation_ontology_events",
					    status_line => $self->{client}->status_line,
					    method_name => 'add_annotation_ontology_events',
				       );
    }
}
 
  
sub status
{
    my($self, @args) = @_;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $service_state = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "ServiceWizard.get_service_status",
        params => [{module_name=>"annotation_ontology_api", version=>$self->{service_version}}]});
    if ($service_state->is_error) {
        Bio::KBase::Exceptions::JSONRPC->throw(error => $service_state->error_message,
                           code => $service_state->content->{error}->{code},
                           method_name => 'ServiceWizard.get_service_status',
                           data => $service_state->content->{error}->{error}
                          );
    }
    my $url = $service_state->result->[0]->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
        method => "annotation_ontology_api.status",
        params => \@args,
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => 'status',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method status",
                        status_line => $self->{client}->status_line,
                        method_name => 'status',
                       );
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "annotation_ontology_api.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'add_annotation_ontology_events',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method add_annotation_ontology_events",
            status_line => $self->{client}->status_line,
            method_name => 'add_annotation_ontology_events',
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
        warn "New client version available for annotation_ontology_api::annotation_ontology_apiServiceClient\n";
    }
    if ($sMajor == 0) {
        warn "annotation_ontology_api::annotation_ontology_apiServiceClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 AnnotationOntologyTerm

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
term has a value which is a string
modelseed_ids has a value which is a reference to a list where each element is a string
evidence has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
term has a value which is a string
modelseed_ids has a value which is a reference to a list where each element is a string
evidence has a value which is a string


=end text

=back



=head2 AnnotationOntologyEvent

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
event_id has a value which is a string
description has a value which is a string
ontology_id has a value which is a string
method has a value which is a string
method_version has a value which is a string
timestamp has a value which is a string
feature_types has a value which is a reference to a hash where the key is a string and the value is a string
ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyTerm

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
event_id has a value which is a string
description has a value which is a string
ontology_id has a value which is a string
method has a value which is a string
method_version has a value which is a string
timestamp has a value which is a string
feature_types has a value which is a reference to a hash where the key is a string and the value is a string
ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyTerm


=end text

=back



=head2 GetAnnotationOntologyEventsParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_ref has a value which is a string
input_workspace has a value which is a string
query_events has a value which is a reference to a list where each element is a string
query_genes has a value which is a reference to a list where each element is a string
standardize_modelseed_ids has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_ref has a value which is a string
input_workspace has a value which is a string
query_events has a value which is a reference to a list where each element is a string
query_genes has a value which is a reference to a list where each element is a string
standardize_modelseed_ids has a value which is an int


=end text

=back



=head2 GetAnnotationOntologyEventsOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
events has a value which is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyEvent

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
events has a value which is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyEvent


=end text

=back



=head2 AddAnnotationOntologyEventsParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_ref has a value which is a string
input_workspace has a value which is a string
output_name has a value which is a string
output_workspace has a value which is a string
clear_existing has a value which is an int
overwrite_matching has a value which is an int
events has a value which is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyEvent

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_ref has a value which is a string
input_workspace has a value which is a string
output_name has a value which is a string
output_workspace has a value which is a string
clear_existing has a value which is an int
overwrite_matching has a value which is an int
events has a value which is a reference to a list where each element is an annotation_ontology_api.AnnotationOntologyEvent


=end text

=back



=head2 AddAnnotationOntologyEventsOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
output_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
output_ref has a value which is a string


=end text

=back



=cut

package annotation_ontology_api::annotation_ontology_apiServiceClient::RpcClient;
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
