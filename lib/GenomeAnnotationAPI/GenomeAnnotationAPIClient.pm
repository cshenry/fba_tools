package GenomeAnnotationAPI::GenomeAnnotationAPIClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
use Time::HiRes;
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

GenomeAnnotationAPI::GenomeAnnotationAPIClient

=head1 DESCRIPTION





=cut

sub new
{
    my($class, $url, @args) = @_;
    
    if (!defined($url))
    {
	$url = 'https://kbase.us/services/njs_wrapper';
    }

    my $self = {
	client => GenomeAnnotationAPI::GenomeAnnotationAPIClient::RpcClient->new,
	url => $url,
	headers => [],
    };
    my %arg_hash = @args;
    $self->{async_job_check_time} = 0.1;
    if (exists $arg_hash{"async_job_check_time_ms"}) {
        $self->{async_job_check_time} = $arg_hash{"async_job_check_time_ms"} / 1000.0;
    }
    $self->{async_job_check_time_scale_percent} = 150;
    if (exists $arg_hash{"async_job_check_time_scale_percent"}) {
        $self->{async_job_check_time_scale_percent} = $arg_hash{"async_job_check_time_scale_percent"};
    }
    $self->{async_job_check_max_time} = 300;  # 5 minutes
    if (exists $arg_hash{"async_job_check_max_time_ms"}) {
        $self->{async_job_check_max_time} = $arg_hash{"async_job_check_max_time_ms"} / 1000.0;
    }
    my $service_version = 'release';
    if (exists $arg_hash{"service_version"}) {
        $service_version = $arg_hash{"async_version"};
    }
    $self->{service_version} = $service_version;

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

sub _check_job {
    my($self, @args) = @_;
# Authentication: ${method.authentication}
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _check_job (received $n, expecting 1)");
    }
    {
        my($job_id) = @args;
        my @_bad_arguments;
        (!ref($job_id)) or push(@_bad_arguments, "Invalid type for argument 0 \"job_id\" (it should be a string)");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _check_job:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_check_job');
        }
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._check_job",
        params => \@args});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_check_job',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _check_job",
                        status_line => $self->{client}->status_line,
                        method_name => '_check_job');
    }
}




=head2 get_taxon

  $return = $obj->get_taxon($inputs_get_taxon)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_taxon is a GenomeAnnotationAPI.inputs_get_taxon
$return is a GenomeAnnotationAPI.ObjectReference
inputs_get_taxon is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_taxon is a GenomeAnnotationAPI.inputs_get_taxon
$return is a GenomeAnnotationAPI.ObjectReference
inputs_get_taxon is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_taxon
{
    my($self, @args) = @_;
    my $job_id = $self->_get_taxon_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_taxon_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_taxon_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_taxon) = @args;
        my @_bad_arguments;
        (ref($inputs_get_taxon) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_taxon\" (value was \"$inputs_get_taxon\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_taxon_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_taxon_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_taxon_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_taxon_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_taxon_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_taxon_submit');
    }
}

 


=head2 get_assembly

  $return = $obj->get_assembly($inputs_get_assembly)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_assembly is a GenomeAnnotationAPI.inputs_get_assembly
$return is a GenomeAnnotationAPI.ObjectReference
inputs_get_assembly is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_assembly is a GenomeAnnotationAPI.inputs_get_assembly
$return is a GenomeAnnotationAPI.ObjectReference
inputs_get_assembly is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_assembly
{
    my($self, @args) = @_;
    my $job_id = $self->_get_assembly_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_assembly_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_assembly_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_assembly) = @args;
        my @_bad_arguments;
        (ref($inputs_get_assembly) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_assembly\" (value was \"$inputs_get_assembly\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_assembly_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_assembly_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_assembly_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_assembly_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_assembly_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_assembly_submit');
    }
}

 


=head2 get_feature_types

  $return = $obj->get_feature_types($inputs_get_feature_types)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_types is a GenomeAnnotationAPI.inputs_get_feature_types
$return is a reference to a list where each element is a string
inputs_get_feature_types is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_feature_types is a GenomeAnnotationAPI.inputs_get_feature_types
$return is a reference to a list where each element is a string
inputs_get_feature_types is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_feature_types
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_types_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_types_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_types_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_types) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_types) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_types\" (value was \"$inputs_get_feature_types\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_types_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_types_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_types_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_types_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_types_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_types_submit');
    }
}

 


=head2 get_feature_type_descriptions

  $return = $obj->get_feature_type_descriptions($inputs_get_feature_type_descriptions)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_type_descriptions is a GenomeAnnotationAPI.inputs_get_feature_type_descriptions
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_feature_type_descriptions is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_type_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_feature_type_descriptions is a GenomeAnnotationAPI.inputs_get_feature_type_descriptions
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_feature_type_descriptions is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_type_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_feature_type_descriptions
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_type_descriptions_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_type_descriptions_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_type_descriptions_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_type_descriptions) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_type_descriptions) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_type_descriptions\" (value was \"$inputs_get_feature_type_descriptions\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_type_descriptions_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_type_descriptions_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_type_descriptions_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_type_descriptions_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_type_descriptions_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_type_descriptions_submit');
    }
}

 


=head2 get_feature_type_counts

  $return = $obj->get_feature_type_counts($inputs_get_feature_type_counts)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_type_counts is a GenomeAnnotationAPI.inputs_get_feature_type_counts
$return is a reference to a hash where the key is a string and the value is an int
inputs_get_feature_type_counts is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_type_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_feature_type_counts is a GenomeAnnotationAPI.inputs_get_feature_type_counts
$return is a reference to a hash where the key is a string and the value is an int
inputs_get_feature_type_counts is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_type_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_feature_type_counts
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_type_counts_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_type_counts_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_type_counts_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_type_counts) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_type_counts) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_type_counts\" (value was \"$inputs_get_feature_type_counts\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_type_counts_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_type_counts_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_type_counts_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_type_counts_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_type_counts_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_type_counts_submit');
    }
}

 


=head2 get_feature_ids

  $return = $obj->get_feature_ids($inputs_get_feature_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_ids is a GenomeAnnotationAPI.inputs_get_feature_ids
$return is a GenomeAnnotationAPI.Feature_id_mapping
inputs_get_feature_ids is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	filters has a value which is a GenomeAnnotationAPI.Feature_id_filters
	group_by has a value which is a string
ObjectReference is a string
Feature_id_filters is a reference to a hash where the following keys are defined:
	type_list has a value which is a reference to a list where each element is a string
	region_list has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	function_list has a value which is a reference to a list where each element is a string
	alias_list has a value which is a reference to a list where each element is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int
Feature_id_mapping is a reference to a hash where the following keys are defined:
	by_type has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	by_region has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	by_function has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	by_alias has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string

</pre>

=end html

=begin text

$inputs_get_feature_ids is a GenomeAnnotationAPI.inputs_get_feature_ids
$return is a GenomeAnnotationAPI.Feature_id_mapping
inputs_get_feature_ids is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	filters has a value which is a GenomeAnnotationAPI.Feature_id_filters
	group_by has a value which is a string
ObjectReference is a string
Feature_id_filters is a reference to a hash where the following keys are defined:
	type_list has a value which is a reference to a list where each element is a string
	region_list has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	function_list has a value which is a reference to a list where each element is a string
	alias_list has a value which is a reference to a list where each element is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int
Feature_id_mapping is a reference to a hash where the following keys are defined:
	by_type has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	by_region has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	by_function has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	by_alias has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string


=end text

=item Description



=back

=cut

sub get_feature_ids
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_ids_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_ids_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_ids_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_ids) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_ids) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_ids\" (value was \"$inputs_get_feature_ids\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_ids_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_ids_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_ids_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_ids_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_ids_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_ids_submit');
    }
}

 


=head2 get_features

  $return = $obj->get_features($inputs_get_features)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_features is a GenomeAnnotationAPI.inputs_get_features
$return is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Feature_data
inputs_get_features is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
	exclude_sequence has a value which is a GenomeAnnotationAPI.boolean
ObjectReference is a string
boolean is an int
Feature_data is a reference to a hash where the following keys are defined:
	feature_id has a value which is a string
	feature_type has a value which is a string
	feature_function has a value which is a string
	feature_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	feature_dna_sequence_length has a value which is an int
	feature_dna_sequence has a value which is a string
	feature_md5 has a value which is a string
	feature_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	feature_publications has a value which is a reference to a list where each element is a string
	feature_quality_warnings has a value which is a reference to a list where each element is a string
	feature_quality_score has a value which is a reference to a list where each element is a string
	feature_notes has a value which is a string
	feature_inference has a value which is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int

</pre>

=end html

=begin text

$inputs_get_features is a GenomeAnnotationAPI.inputs_get_features
$return is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Feature_data
inputs_get_features is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
	exclude_sequence has a value which is a GenomeAnnotationAPI.boolean
ObjectReference is a string
boolean is an int
Feature_data is a reference to a hash where the following keys are defined:
	feature_id has a value which is a string
	feature_type has a value which is a string
	feature_function has a value which is a string
	feature_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	feature_dna_sequence_length has a value which is an int
	feature_dna_sequence has a value which is a string
	feature_md5 has a value which is a string
	feature_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	feature_publications has a value which is a reference to a list where each element is a string
	feature_quality_warnings has a value which is a reference to a list where each element is a string
	feature_quality_score has a value which is a reference to a list where each element is a string
	feature_notes has a value which is a string
	feature_inference has a value which is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int


=end text

=item Description



=back

=cut

sub get_features
{
    my($self, @args) = @_;
    my $job_id = $self->_get_features_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_features_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_features_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_features) = @args;
        my @_bad_arguments;
        (ref($inputs_get_features) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_features\" (value was \"$inputs_get_features\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_features_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_features_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_features_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_features_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_features_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_features_submit');
    }
}

 


=head2 get_features2

  $return = $obj->get_features2($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeAnnotationAPI.GetFeatures2Params
$return is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Feature_data
GetFeatures2Params is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
	exclude_sequence has a value which is a GenomeAnnotationAPI.boolean
ObjectReference is a string
boolean is an int
Feature_data is a reference to a hash where the following keys are defined:
	feature_id has a value which is a string
	feature_type has a value which is a string
	feature_function has a value which is a string
	feature_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	feature_dna_sequence_length has a value which is an int
	feature_dna_sequence has a value which is a string
	feature_md5 has a value which is a string
	feature_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	feature_publications has a value which is a reference to a list where each element is a string
	feature_quality_warnings has a value which is a reference to a list where each element is a string
	feature_quality_score has a value which is a reference to a list where each element is a string
	feature_notes has a value which is a string
	feature_inference has a value which is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int

</pre>

=end html

=begin text

$params is a GenomeAnnotationAPI.GetFeatures2Params
$return is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Feature_data
GetFeatures2Params is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
	exclude_sequence has a value which is a GenomeAnnotationAPI.boolean
ObjectReference is a string
boolean is an int
Feature_data is a reference to a hash where the following keys are defined:
	feature_id has a value which is a string
	feature_type has a value which is a string
	feature_function has a value which is a string
	feature_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	feature_dna_sequence_length has a value which is an int
	feature_dna_sequence has a value which is a string
	feature_md5 has a value which is a string
	feature_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	feature_publications has a value which is a reference to a list where each element is a string
	feature_quality_warnings has a value which is a reference to a list where each element is a string
	feature_quality_score has a value which is a reference to a list where each element is a string
	feature_notes has a value which is a string
	feature_inference has a value which is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int


=end text

=item Description

Retrieve Feature data, v2.

@param feature_id_list List of Features to retrieve.
  If None, returns all Feature data.
@return Mapping from Feature IDs to dicts of available data.

=back

=cut

sub get_features2
{
    my($self, @args) = @_;
    my $job_id = $self->_get_features2_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_features2_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_features2_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_features2_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_features2_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_features2_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_features2_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_features2_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_features2_submit');
    }
}

 


=head2 get_proteins

  $return = $obj->get_proteins($inputs_get_proteins)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_proteins is a GenomeAnnotationAPI.inputs_get_proteins
$return is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Protein_data
inputs_get_proteins is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string
Protein_data is a reference to a hash where the following keys are defined:
	protein_id has a value which is a string
	protein_amino_acid_sequence has a value which is a string
	protein_function has a value which is a string
	protein_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	protein_md5 has a value which is a string
	protein_domain_locations has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$inputs_get_proteins is a GenomeAnnotationAPI.inputs_get_proteins
$return is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Protein_data
inputs_get_proteins is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string
Protein_data is a reference to a hash where the following keys are defined:
	protein_id has a value which is a string
	protein_amino_acid_sequence has a value which is a string
	protein_function has a value which is a string
	protein_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	protein_md5 has a value which is a string
	protein_domain_locations has a value which is a reference to a list where each element is a string


=end text

=item Description



=back

=cut

sub get_proteins
{
    my($self, @args) = @_;
    my $job_id = $self->_get_proteins_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_proteins_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_proteins_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_proteins) = @args;
        my @_bad_arguments;
        (ref($inputs_get_proteins) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_proteins\" (value was \"$inputs_get_proteins\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_proteins_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_proteins_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_proteins_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_proteins_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_proteins_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_proteins_submit');
    }
}

 


=head2 get_feature_locations

  $return = $obj->get_feature_locations($inputs_get_feature_locations)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_locations is a GenomeAnnotationAPI.inputs_get_feature_locations
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a GenomeAnnotationAPI.Region
inputs_get_feature_locations is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int

</pre>

=end html

=begin text

$inputs_get_feature_locations is a GenomeAnnotationAPI.inputs_get_feature_locations
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a GenomeAnnotationAPI.Region
inputs_get_feature_locations is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int


=end text

=item Description



=back

=cut

sub get_feature_locations
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_locations_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_locations_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_locations_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_locations) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_locations) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_locations\" (value was \"$inputs_get_feature_locations\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_locations_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_locations_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_locations_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_locations_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_locations_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_locations_submit');
    }
}

 


=head2 get_feature_publications

  $return = $obj->get_feature_publications($inputs_get_feature_publications)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_publications is a GenomeAnnotationAPI.inputs_get_feature_publications
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
inputs_get_feature_publications is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_feature_publications is a GenomeAnnotationAPI.inputs_get_feature_publications
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
inputs_get_feature_publications is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_feature_publications
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_publications_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_publications_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_publications_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_publications) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_publications) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_publications\" (value was \"$inputs_get_feature_publications\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_publications_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_publications_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_publications_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_publications_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_publications_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_publications_submit');
    }
}

 


=head2 get_feature_dna

  $return = $obj->get_feature_dna($inputs_get_feature_dna)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_dna is a GenomeAnnotationAPI.inputs_get_feature_dna
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_feature_dna is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_feature_dna is a GenomeAnnotationAPI.inputs_get_feature_dna
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_feature_dna is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_feature_dna
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_dna_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_dna_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_dna_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_dna) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_dna) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_dna\" (value was \"$inputs_get_feature_dna\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_dna_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_dna_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_dna_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_dna_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_dna_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_dna_submit');
    }
}

 


=head2 get_feature_functions

  $return = $obj->get_feature_functions($inputs_get_feature_functions)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_functions is a GenomeAnnotationAPI.inputs_get_feature_functions
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_feature_functions is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_feature_functions is a GenomeAnnotationAPI.inputs_get_feature_functions
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_feature_functions is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_feature_functions
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_functions_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_functions_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_functions_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_functions) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_functions) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_functions\" (value was \"$inputs_get_feature_functions\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_functions_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_functions_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_functions_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_functions_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_functions_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_functions_submit');
    }
}

 


=head2 get_feature_aliases

  $return = $obj->get_feature_aliases($inputs_get_feature_aliases)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_feature_aliases is a GenomeAnnotationAPI.inputs_get_feature_aliases
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
inputs_get_feature_aliases is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_feature_aliases is a GenomeAnnotationAPI.inputs_get_feature_aliases
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
inputs_get_feature_aliases is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	feature_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_feature_aliases
{
    my($self, @args) = @_;
    my $job_id = $self->_get_feature_aliases_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_feature_aliases_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_feature_aliases_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_feature_aliases) = @args;
        my @_bad_arguments;
        (ref($inputs_get_feature_aliases) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_feature_aliases\" (value was \"$inputs_get_feature_aliases\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_feature_aliases_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_feature_aliases_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_feature_aliases_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_feature_aliases_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_feature_aliases_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_feature_aliases_submit');
    }
}

 


=head2 get_cds_by_gene

  $return = $obj->get_cds_by_gene($inputs_get_cds_by_gene)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_cds_by_gene is a GenomeAnnotationAPI.inputs_get_cds_by_gene
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
inputs_get_cds_by_gene is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	gene_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_cds_by_gene is a GenomeAnnotationAPI.inputs_get_cds_by_gene
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
inputs_get_cds_by_gene is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	gene_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_cds_by_gene
{
    my($self, @args) = @_;
    my $job_id = $self->_get_cds_by_gene_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_cds_by_gene_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_cds_by_gene_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_cds_by_gene) = @args;
        my @_bad_arguments;
        (ref($inputs_get_cds_by_gene) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_cds_by_gene\" (value was \"$inputs_get_cds_by_gene\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_cds_by_gene_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_cds_by_gene_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_cds_by_gene_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_cds_by_gene_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_cds_by_gene_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_cds_by_gene_submit');
    }
}

 


=head2 get_cds_by_mrna

  $return = $obj->get_cds_by_mrna($inputs_mrna_id_list)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_mrna_id_list is a GenomeAnnotationAPI.inputs_mrna_id_list
$return is a reference to a hash where the key is a string and the value is a string
inputs_mrna_id_list is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	mrna_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_mrna_id_list is a GenomeAnnotationAPI.inputs_mrna_id_list
$return is a reference to a hash where the key is a string and the value is a string
inputs_mrna_id_list is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	mrna_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_cds_by_mrna
{
    my($self, @args) = @_;
    my $job_id = $self->_get_cds_by_mrna_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_cds_by_mrna_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_cds_by_mrna_submit (received $n, expecting 1)");
    }
    {
        my($inputs_mrna_id_list) = @args;
        my @_bad_arguments;
        (ref($inputs_mrna_id_list) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_mrna_id_list\" (value was \"$inputs_mrna_id_list\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_cds_by_mrna_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_cds_by_mrna_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_cds_by_mrna_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_cds_by_mrna_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_cds_by_mrna_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_cds_by_mrna_submit');
    }
}

 


=head2 get_gene_by_cds

  $return = $obj->get_gene_by_cds($inputs_get_gene_by_cds)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_gene_by_cds is a GenomeAnnotationAPI.inputs_get_gene_by_cds
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_gene_by_cds is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	cds_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_gene_by_cds is a GenomeAnnotationAPI.inputs_get_gene_by_cds
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_gene_by_cds is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	cds_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_gene_by_cds
{
    my($self, @args) = @_;
    my $job_id = $self->_get_gene_by_cds_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_gene_by_cds_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_gene_by_cds_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_gene_by_cds) = @args;
        my @_bad_arguments;
        (ref($inputs_get_gene_by_cds) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_gene_by_cds\" (value was \"$inputs_get_gene_by_cds\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_gene_by_cds_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_gene_by_cds_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_gene_by_cds_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_gene_by_cds_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_gene_by_cds_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_gene_by_cds_submit');
    }
}

 


=head2 get_gene_by_mrna

  $return = $obj->get_gene_by_mrna($inputs_get_gene_by_mrna)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_gene_by_mrna is a GenomeAnnotationAPI.inputs_get_gene_by_mrna
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_gene_by_mrna is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	mrna_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_gene_by_mrna is a GenomeAnnotationAPI.inputs_get_gene_by_mrna
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_gene_by_mrna is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	mrna_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_gene_by_mrna
{
    my($self, @args) = @_;
    my $job_id = $self->_get_gene_by_mrna_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_gene_by_mrna_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_gene_by_mrna_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_gene_by_mrna) = @args;
        my @_bad_arguments;
        (ref($inputs_get_gene_by_mrna) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_gene_by_mrna\" (value was \"$inputs_get_gene_by_mrna\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_gene_by_mrna_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_gene_by_mrna_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_gene_by_mrna_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_gene_by_mrna_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_gene_by_mrna_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_gene_by_mrna_submit');
    }
}

 


=head2 get_mrna_by_cds

  $return = $obj->get_mrna_by_cds($inputs_get_mrna_by_cds)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_mrna_by_cds is a GenomeAnnotationAPI.inputs_get_mrna_by_cds
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_mrna_by_cds is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	cds_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_mrna_by_cds is a GenomeAnnotationAPI.inputs_get_mrna_by_cds
$return is a reference to a hash where the key is a string and the value is a string
inputs_get_mrna_by_cds is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	cds_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_mrna_by_cds
{
    my($self, @args) = @_;
    my $job_id = $self->_get_mrna_by_cds_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_mrna_by_cds_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_mrna_by_cds_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_mrna_by_cds) = @args;
        my @_bad_arguments;
        (ref($inputs_get_mrna_by_cds) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_mrna_by_cds\" (value was \"$inputs_get_mrna_by_cds\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_mrna_by_cds_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_mrna_by_cds_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_mrna_by_cds_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_mrna_by_cds_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_mrna_by_cds_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_mrna_by_cds_submit');
    }
}

 


=head2 get_mrna_by_gene

  $return = $obj->get_mrna_by_gene($inputs_get_mrna_by_gene)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_mrna_by_gene is a GenomeAnnotationAPI.inputs_get_mrna_by_gene
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
inputs_get_mrna_by_gene is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	gene_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string

</pre>

=end html

=begin text

$inputs_get_mrna_by_gene is a GenomeAnnotationAPI.inputs_get_mrna_by_gene
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
inputs_get_mrna_by_gene is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	gene_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string


=end text

=item Description



=back

=cut

sub get_mrna_by_gene
{
    my($self, @args) = @_;
    my $job_id = $self->_get_mrna_by_gene_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_mrna_by_gene_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_mrna_by_gene_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_mrna_by_gene) = @args;
        my @_bad_arguments;
        (ref($inputs_get_mrna_by_gene) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_mrna_by_gene\" (value was \"$inputs_get_mrna_by_gene\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_mrna_by_gene_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_mrna_by_gene_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_mrna_by_gene_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_mrna_by_gene_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_mrna_by_gene_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_mrna_by_gene_submit');
    }
}

 


=head2 get_mrna_exons

  $return = $obj->get_mrna_exons($inputs_get_mrna_exons)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_mrna_exons is a GenomeAnnotationAPI.inputs_get_mrna_exons
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a GenomeAnnotationAPI.Exon_data
inputs_get_mrna_exons is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	mrna_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string
Exon_data is a reference to a hash where the following keys are defined:
	exon_location has a value which is a GenomeAnnotationAPI.Region
	exon_dna_sequence has a value which is a string
	exon_ordinal has a value which is an int
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int

</pre>

=end html

=begin text

$inputs_get_mrna_exons is a GenomeAnnotationAPI.inputs_get_mrna_exons
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a GenomeAnnotationAPI.Exon_data
inputs_get_mrna_exons is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	mrna_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string
Exon_data is a reference to a hash where the following keys are defined:
	exon_location has a value which is a GenomeAnnotationAPI.Region
	exon_dna_sequence has a value which is a string
	exon_ordinal has a value which is an int
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int


=end text

=item Description



=back

=cut

sub get_mrna_exons
{
    my($self, @args) = @_;
    my $job_id = $self->_get_mrna_exons_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_mrna_exons_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_mrna_exons_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_mrna_exons) = @args;
        my @_bad_arguments;
        (ref($inputs_get_mrna_exons) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_mrna_exons\" (value was \"$inputs_get_mrna_exons\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_mrna_exons_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_mrna_exons_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_mrna_exons_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_mrna_exons_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_mrna_exons_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_mrna_exons_submit');
    }
}

 


=head2 get_mrna_utrs

  $return = $obj->get_mrna_utrs($inputs_get_mrna_utrs)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_mrna_utrs is a GenomeAnnotationAPI.inputs_get_mrna_utrs
$return is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.UTR_data
inputs_get_mrna_utrs is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	mrna_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string
UTR_data is a reference to a hash where the following keys are defined:
	utr_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	utr_dna_sequence has a value which is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int

</pre>

=end html

=begin text

$inputs_get_mrna_utrs is a GenomeAnnotationAPI.inputs_get_mrna_utrs
$return is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.UTR_data
inputs_get_mrna_utrs is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	mrna_id_list has a value which is a reference to a list where each element is a string
ObjectReference is a string
UTR_data is a reference to a hash where the following keys are defined:
	utr_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	utr_dna_sequence has a value which is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int


=end text

=item Description



=back

=cut

sub get_mrna_utrs
{
    my($self, @args) = @_;
    my $job_id = $self->_get_mrna_utrs_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_mrna_utrs_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_mrna_utrs_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_mrna_utrs) = @args;
        my @_bad_arguments;
        (ref($inputs_get_mrna_utrs) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_mrna_utrs\" (value was \"$inputs_get_mrna_utrs\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_mrna_utrs_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_mrna_utrs_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_mrna_utrs_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_mrna_utrs_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_mrna_utrs_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_mrna_utrs_submit');
    }
}

 


=head2 get_summary

  $return = $obj->get_summary($inputs_get_summary)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_get_summary is a GenomeAnnotationAPI.inputs_get_summary
$return is a GenomeAnnotationAPI.Summary_data
inputs_get_summary is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string
Summary_data is a reference to a hash where the following keys are defined:
	scientific_name has a value which is a string
	taxonomy_id has a value which is an int
	kingdom has a value which is a string
	scientific_lineage has a value which is a reference to a list where each element is a string
	genetic_code has a value which is an int
	organism_aliases has a value which is a reference to a list where each element is a string
	assembly_source has a value which is a string
	assembly_source_id has a value which is a string
	assembly_source_date has a value which is a string
	gc_content has a value which is a float
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contig_ids has a value which is a reference to a list where each element is a string
	external_source has a value which is a string
	external_source_date has a value which is a string
	release has a value which is a string
	original_source_filename has a value which is a string
	feature_type_counts has a value which is a reference to a hash where the key is a string and the value is an int

</pre>

=end html

=begin text

$inputs_get_summary is a GenomeAnnotationAPI.inputs_get_summary
$return is a GenomeAnnotationAPI.Summary_data
inputs_get_summary is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string
Summary_data is a reference to a hash where the following keys are defined:
	scientific_name has a value which is a string
	taxonomy_id has a value which is an int
	kingdom has a value which is a string
	scientific_lineage has a value which is a reference to a list where each element is a string
	genetic_code has a value which is an int
	organism_aliases has a value which is a reference to a list where each element is a string
	assembly_source has a value which is a string
	assembly_source_id has a value which is a string
	assembly_source_date has a value which is a string
	gc_content has a value which is a float
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contig_ids has a value which is a reference to a list where each element is a string
	external_source has a value which is a string
	external_source_date has a value which is a string
	release has a value which is a string
	original_source_filename has a value which is a string
	feature_type_counts has a value which is a reference to a hash where the key is a string and the value is an int


=end text

=item Description



=back

=cut

sub get_summary
{
    my($self, @args) = @_;
    my $job_id = $self->_get_summary_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_summary_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_summary_submit (received $n, expecting 1)");
    }
    {
        my($inputs_get_summary) = @args;
        my @_bad_arguments;
        (ref($inputs_get_summary) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_get_summary\" (value was \"$inputs_get_summary\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_summary_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_summary_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_summary_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_summary_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_summary_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_summary_submit');
    }
}

 


=head2 save_summary

  $return_1, $return_2 = $obj->save_summary($inputs_save_summary)

=over 4

=item Parameter and return types

=begin html

<pre>
$inputs_save_summary is a GenomeAnnotationAPI.inputs_save_summary
$return_1 is an int
$return_2 is a GenomeAnnotationAPI.Summary_data
inputs_save_summary is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string
Summary_data is a reference to a hash where the following keys are defined:
	scientific_name has a value which is a string
	taxonomy_id has a value which is an int
	kingdom has a value which is a string
	scientific_lineage has a value which is a reference to a list where each element is a string
	genetic_code has a value which is an int
	organism_aliases has a value which is a reference to a list where each element is a string
	assembly_source has a value which is a string
	assembly_source_id has a value which is a string
	assembly_source_date has a value which is a string
	gc_content has a value which is a float
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contig_ids has a value which is a reference to a list where each element is a string
	external_source has a value which is a string
	external_source_date has a value which is a string
	release has a value which is a string
	original_source_filename has a value which is a string
	feature_type_counts has a value which is a reference to a hash where the key is a string and the value is an int

</pre>

=end html

=begin text

$inputs_save_summary is a GenomeAnnotationAPI.inputs_save_summary
$return_1 is an int
$return_2 is a GenomeAnnotationAPI.Summary_data
inputs_save_summary is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
ObjectReference is a string
Summary_data is a reference to a hash where the following keys are defined:
	scientific_name has a value which is a string
	taxonomy_id has a value which is an int
	kingdom has a value which is a string
	scientific_lineage has a value which is a reference to a list where each element is a string
	genetic_code has a value which is an int
	organism_aliases has a value which is a reference to a list where each element is a string
	assembly_source has a value which is a string
	assembly_source_id has a value which is a string
	assembly_source_date has a value which is a string
	gc_content has a value which is a float
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contig_ids has a value which is a reference to a list where each element is a string
	external_source has a value which is a string
	external_source_date has a value which is a string
	release has a value which is a string
	original_source_filename has a value which is a string
	feature_type_counts has a value which is a reference to a hash where the key is a string and the value is an int


=end text

=item Description



=back

=cut

sub save_summary
{
    my($self, @args) = @_;
    my $job_id = $self->_save_summary_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _save_summary_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _save_summary_submit (received $n, expecting 1)");
    }
    {
        my($inputs_save_summary) = @args;
        my @_bad_arguments;
        (ref($inputs_save_summary) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"inputs_save_summary\" (value was \"$inputs_save_summary\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _save_summary_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_save_summary_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._save_summary_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_save_summary_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _save_summary_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_save_summary_submit');
    }
}

 


=head2 get_combined_data

  $return = $obj->get_combined_data($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeAnnotationAPI.GetCombinedDataParams
$return is a GenomeAnnotationAPI.GenomeAnnotation_data
GetCombinedDataParams is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	exclude_genes has a value which is a GenomeAnnotationAPI.boolean
	include_mrnas has a value which is a GenomeAnnotationAPI.boolean
	exclude_cdss has a value which is a GenomeAnnotationAPI.boolean
	include_features_by_type has a value which is a reference to a list where each element is a string
	exclude_protein_by_cds_id has a value which is a GenomeAnnotationAPI.boolean
	include_mrna_ids_by_gene_id has a value which is a GenomeAnnotationAPI.boolean
	exclude_cds_ids_by_gene_id has a value which is a GenomeAnnotationAPI.boolean
	include_cds_id_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
	include_exons_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
	include_utr_by_utr_type_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
	exclude_summary has a value which is a GenomeAnnotationAPI.boolean
ObjectReference is a string
boolean is an int
GenomeAnnotation_data is a reference to a hash where the following keys are defined:
	gene_type has a value which is a string
	mrna_type has a value which is a string
	cds_type has a value which is a string
	feature_types has a value which is a reference to a list where each element is a string
	feature_by_id_by_type has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Feature_data
	protein_by_cds_id has a value which is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Protein_data
	mrna_ids_by_gene_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	cds_ids_by_gene_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	cds_id_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a string
	exons_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a GenomeAnnotationAPI.Exon_data
	utr_by_utr_type_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.UTR_data
	summary has a value which is a GenomeAnnotationAPI.Summary_data
Feature_data is a reference to a hash where the following keys are defined:
	feature_id has a value which is a string
	feature_type has a value which is a string
	feature_function has a value which is a string
	feature_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	feature_dna_sequence_length has a value which is an int
	feature_dna_sequence has a value which is a string
	feature_md5 has a value which is a string
	feature_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	feature_publications has a value which is a reference to a list where each element is a string
	feature_quality_warnings has a value which is a reference to a list where each element is a string
	feature_quality_score has a value which is a reference to a list where each element is a string
	feature_notes has a value which is a string
	feature_inference has a value which is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int
Protein_data is a reference to a hash where the following keys are defined:
	protein_id has a value which is a string
	protein_amino_acid_sequence has a value which is a string
	protein_function has a value which is a string
	protein_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	protein_md5 has a value which is a string
	protein_domain_locations has a value which is a reference to a list where each element is a string
Exon_data is a reference to a hash where the following keys are defined:
	exon_location has a value which is a GenomeAnnotationAPI.Region
	exon_dna_sequence has a value which is a string
	exon_ordinal has a value which is an int
UTR_data is a reference to a hash where the following keys are defined:
	utr_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	utr_dna_sequence has a value which is a string
Summary_data is a reference to a hash where the following keys are defined:
	scientific_name has a value which is a string
	taxonomy_id has a value which is an int
	kingdom has a value which is a string
	scientific_lineage has a value which is a reference to a list where each element is a string
	genetic_code has a value which is an int
	organism_aliases has a value which is a reference to a list where each element is a string
	assembly_source has a value which is a string
	assembly_source_id has a value which is a string
	assembly_source_date has a value which is a string
	gc_content has a value which is a float
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contig_ids has a value which is a reference to a list where each element is a string
	external_source has a value which is a string
	external_source_date has a value which is a string
	release has a value which is a string
	original_source_filename has a value which is a string
	feature_type_counts has a value which is a reference to a hash where the key is a string and the value is an int

</pre>

=end html

=begin text

$params is a GenomeAnnotationAPI.GetCombinedDataParams
$return is a GenomeAnnotationAPI.GenomeAnnotation_data
GetCombinedDataParams is a reference to a hash where the following keys are defined:
	ref has a value which is a GenomeAnnotationAPI.ObjectReference
	exclude_genes has a value which is a GenomeAnnotationAPI.boolean
	include_mrnas has a value which is a GenomeAnnotationAPI.boolean
	exclude_cdss has a value which is a GenomeAnnotationAPI.boolean
	include_features_by_type has a value which is a reference to a list where each element is a string
	exclude_protein_by_cds_id has a value which is a GenomeAnnotationAPI.boolean
	include_mrna_ids_by_gene_id has a value which is a GenomeAnnotationAPI.boolean
	exclude_cds_ids_by_gene_id has a value which is a GenomeAnnotationAPI.boolean
	include_cds_id_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
	include_exons_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
	include_utr_by_utr_type_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
	exclude_summary has a value which is a GenomeAnnotationAPI.boolean
ObjectReference is a string
boolean is an int
GenomeAnnotation_data is a reference to a hash where the following keys are defined:
	gene_type has a value which is a string
	mrna_type has a value which is a string
	cds_type has a value which is a string
	feature_types has a value which is a reference to a list where each element is a string
	feature_by_id_by_type has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Feature_data
	protein_by_cds_id has a value which is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Protein_data
	mrna_ids_by_gene_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	cds_ids_by_gene_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	cds_id_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a string
	exons_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a GenomeAnnotationAPI.Exon_data
	utr_by_utr_type_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.UTR_data
	summary has a value which is a GenomeAnnotationAPI.Summary_data
Feature_data is a reference to a hash where the following keys are defined:
	feature_id has a value which is a string
	feature_type has a value which is a string
	feature_function has a value which is a string
	feature_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	feature_dna_sequence_length has a value which is an int
	feature_dna_sequence has a value which is a string
	feature_md5 has a value which is a string
	feature_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	feature_publications has a value which is a reference to a list where each element is a string
	feature_quality_warnings has a value which is a reference to a list where each element is a string
	feature_quality_score has a value which is a reference to a list where each element is a string
	feature_notes has a value which is a string
	feature_inference has a value which is a string
Region is a reference to a hash where the following keys are defined:
	contig_id has a value which is a string
	strand has a value which is a string
	start has a value which is an int
	length has a value which is an int
Protein_data is a reference to a hash where the following keys are defined:
	protein_id has a value which is a string
	protein_amino_acid_sequence has a value which is a string
	protein_function has a value which is a string
	protein_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
	protein_md5 has a value which is a string
	protein_domain_locations has a value which is a reference to a list where each element is a string
Exon_data is a reference to a hash where the following keys are defined:
	exon_location has a value which is a GenomeAnnotationAPI.Region
	exon_dna_sequence has a value which is a string
	exon_ordinal has a value which is an int
UTR_data is a reference to a hash where the following keys are defined:
	utr_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
	utr_dna_sequence has a value which is a string
Summary_data is a reference to a hash where the following keys are defined:
	scientific_name has a value which is a string
	taxonomy_id has a value which is an int
	kingdom has a value which is a string
	scientific_lineage has a value which is a reference to a list where each element is a string
	genetic_code has a value which is an int
	organism_aliases has a value which is a reference to a list where each element is a string
	assembly_source has a value which is a string
	assembly_source_id has a value which is a string
	assembly_source_date has a value which is a string
	gc_content has a value which is a float
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contig_ids has a value which is a reference to a list where each element is a string
	external_source has a value which is a string
	external_source_date has a value which is a string
	release has a value which is a string
	original_source_filename has a value which is a string
	feature_type_counts has a value which is a reference to a hash where the key is a string and the value is an int


=end text

=item Description

Retrieve any part of GenomeAnnotation. Please don't use this method in full mode (with all parts included) in cases
of large eukaryotic datasets. It may lead to out-of-memory errors.

=back

=cut

sub get_combined_data
{
    my($self, @args) = @_;
    my $job_id = $self->_get_combined_data_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_combined_data_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_combined_data_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_combined_data_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_combined_data_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_combined_data_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_combined_data_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_combined_data_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_combined_data_submit');
    }
}

 


=head2 get_genome_v1

  $data = $obj->get_genome_v1($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeAnnotationAPI.GetGenomeParamsV1
$data is a GenomeAnnotationAPI.GenomeDataSetV1
GetGenomeParamsV1 is a reference to a hash where the following keys are defined:
	genomes has a value which is a reference to a list where each element is a GenomeAnnotationAPI.GenomeSelectorV1
	included_fields has a value which is a reference to a list where each element is a string
	included_feature_fields has a value which is a reference to a list where each element is a string
	ignore_errors has a value which is a GenomeAnnotationAPI.boolean
	no_data has a value which is a GenomeAnnotationAPI.boolean
	no_metadata has a value which is a GenomeAnnotationAPI.boolean
GenomeSelectorV1 is a reference to a hash where the following keys are defined:
	ref has a value which is a string
	included_feature_position_index has a value which is a reference to a list where each element is an int
	ref_path_to_genome has a value which is a reference to a list where each element is a string
boolean is an int
GenomeDataSetV1 is a reference to a hash where the following keys are defined:
	genomes has a value which is a reference to a list where each element is a GenomeAnnotationAPI.GenomeDataV1
GenomeDataV1 is a reference to a hash where the following keys are defined:
	data has a value which is a KBaseGenomes.Genome
	info has a value which is a Workspace.object_info
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a string
	orig_wsid has a value which is a string
	copied has a value which is a string
	copy_source_inaccessible has a value which is a GenomeAnnotationAPI.boolean
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a string
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
Genome is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contigs has a value which is a reference to a list where each element is a KBaseGenomes.Contig
	contig_lengths has a value which is a reference to a list where each element is an int
	contig_ids has a value which is a reference to a list where each element is a KBaseGenomes.Contig_id
	source has a value which is a string
	source_id has a value which is a KBaseGenomes.source_id
	md5 has a value which is a string
	taxonomy has a value which is a string
	gc_content has a value which is a float
	complete has a value which is an int
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	features has a value which is a reference to a list where each element is a KBaseGenomes.Feature
	contigset_ref has a value which is a KBaseGenomes.ContigSet_ref
	assembly_ref has a value which is a KBaseGenomes.Assembly_ref
	quality has a value which is a KBaseGenomes.Genome_quality_measure
	close_genomes has a value which is a reference to a list where each element is a KBaseGenomes.Close_genome
	analysis_events has a value which is a reference to a list where each element is a KBaseGenomes.Analysis_event
Genome_id is a string
Contig is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Contig_id
	length has a value which is an int
	md5 has a value which is a string
	sequence has a value which is a string
	genetic_code has a value which is an int
	cell_compartment has a value which is a string
	replicon_type has a value which is a string
	replicon_geometry has a value which is a string
	name has a value which is a string
	description has a value which is a string
	complete has a value which is a KBaseGenomes.Bool
Contig_id is a string
Bool is an int
source_id is a string
publication is a reference to a list containing 7 items:
	0: (id) an int
	1: (source_db) a string
	2: (article_title) a string
	3: (link) a string
	4: (pubdate) a string
	5: (authors) a string
	6: (journal_name) a string
Feature is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Feature_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	type has a value which is a string
	function has a value which is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a KBaseGenomes.OntologyData
	md5 has a value which is a string
	protein_translation has a value which is a string
	dna_sequence has a value which is a string
	protein_translation_length has a value which is an int
	dna_sequence_length has a value which is an int
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	subsystems has a value which is a reference to a list where each element is a string
	protein_families has a value which is a reference to a list where each element is a KBaseGenomes.ProteinFamily
	aliases has a value which is a reference to a list where each element is a string
	orthologs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: a string
		1: a float

	annotations has a value which is a reference to a list where each element is a KBaseGenomes.annotation
	subsystem_data has a value which is a reference to a list where each element is a KBaseGenomes.subsystem_data
	regulon_data has a value which is a reference to a list where each element is a KBaseGenomes.regulon_data
	atomic_regulons has a value which is a reference to a list where each element is a KBaseGenomes.atomic_regulon
	coexpressed_fids has a value which is a reference to a list where each element is a KBaseGenomes.coexpressed_fid
	co_occurring_fids has a value which is a reference to a list where each element is a KBaseGenomes.co_occurring_fid
	quality has a value which is a KBaseGenomes.Feature_quality_measure
	feature_creation_event has a value which is a KBaseGenomes.Analysis_event
Feature_id is a string
OntologyData is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ontology_ref has a value which is a string
	term_lineage has a value which is a reference to a list where each element is a string
	term_name has a value which is a string
	evidence has a value which is a reference to a list where each element is a KBaseGenomes.OntologyEvidence
OntologyEvidence is a reference to a hash where the following keys are defined:
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	translation_provenance has a value which is a reference to a list containing 3 items:
		0: (ontologytranslation_ref) a string
		1: (namespace) a string
		2: (source_term) a string

	alignment_evidence has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: (start) an int
		1: (stop) an int
		2: (align_length) an int
		3: (identify) a float

ProteinFamily is a reference to a hash where the following keys are defined:
	id has a value which is a string
	subject_db has a value which is a string
	release_version has a value which is a string
	subject_description has a value which is a string
	query_begin has a value which is an int
	query_end has a value which is an int
	subject_begin has a value which is an int
	subject_end has a value which is an int
	score has a value which is a float
	evalue has a value which is a float
annotation is a reference to a list containing 3 items:
	0: (comment) a string
	1: (annotator) a string
	2: (annotation_time) a float
subsystem_data is a reference to a list containing 3 items:
	0: (subsystem) a string
	1: (variant) a string
	2: (role) a string
regulon_data is a reference to a list containing 3 items:
	0: (regulon_id) a string
	1: (regulon_set) a reference to a list where each element is a KBaseGenomes.Feature_id
	2: (tfs) a reference to a list where each element is a KBaseGenomes.Feature_id
atomic_regulon is a reference to a list containing 2 items:
	0: (atomic_regulon_id) a string
	1: (atomic_regulon_size) an int
coexpressed_fid is a reference to a list containing 2 items:
	0: (scored_fid) a KBaseGenomes.Feature_id
	1: (score) a float
co_occurring_fid is a reference to a list containing 2 items:
	0: (scored_fid) a KBaseGenomes.Feature_id
	1: (score) a float
Feature_quality_measure is a reference to a hash where the following keys are defined:
	truncated_begin has a value which is a KBaseGenomes.Bool
	truncated_end has a value which is a KBaseGenomes.Bool
	existence_confidence has a value which is a float
	frameshifted has a value which is a KBaseGenomes.Bool
	selenoprotein has a value which is a KBaseGenomes.Bool
	pyrrolysylprotein has a value which is a KBaseGenomes.Bool
	overlap_rules has a value which is a reference to a list where each element is a string
	existence_priority has a value which is a float
	hit_count has a value which is a float
	weighted_hit_count has a value which is a float
Analysis_event is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Analysis_event_id
	tool_name has a value which is a string
	execution_time has a value which is a float
	parameters has a value which is a reference to a list where each element is a string
	hostname has a value which is a string
Analysis_event_id is a string
ContigSet_ref is a string
Assembly_ref is a string
Genome_quality_measure is a reference to a hash where the following keys are defined:
	frameshift_error_rate has a value which is a float
	sequence_error_rate has a value which is a float
Close_genome is a reference to a hash where the following keys are defined:
	genome has a value which is a KBaseGenomes.Genome_id
	closeness_measure has a value which is a float
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
obj_id is an int
obj_name is a string
type_string is a string
timestamp is a string
username is a string
ws_id is an int
ws_name is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
obj_ref is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
id_type is a string
extracted_id is a string

</pre>

=end html

=begin text

$params is a GenomeAnnotationAPI.GetGenomeParamsV1
$data is a GenomeAnnotationAPI.GenomeDataSetV1
GetGenomeParamsV1 is a reference to a hash where the following keys are defined:
	genomes has a value which is a reference to a list where each element is a GenomeAnnotationAPI.GenomeSelectorV1
	included_fields has a value which is a reference to a list where each element is a string
	included_feature_fields has a value which is a reference to a list where each element is a string
	ignore_errors has a value which is a GenomeAnnotationAPI.boolean
	no_data has a value which is a GenomeAnnotationAPI.boolean
	no_metadata has a value which is a GenomeAnnotationAPI.boolean
GenomeSelectorV1 is a reference to a hash where the following keys are defined:
	ref has a value which is a string
	included_feature_position_index has a value which is a reference to a list where each element is an int
	ref_path_to_genome has a value which is a reference to a list where each element is a string
boolean is an int
GenomeDataSetV1 is a reference to a hash where the following keys are defined:
	genomes has a value which is a reference to a list where each element is a GenomeAnnotationAPI.GenomeDataV1
GenomeDataV1 is a reference to a hash where the following keys are defined:
	data has a value which is a KBaseGenomes.Genome
	info has a value which is a Workspace.object_info
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a string
	orig_wsid has a value which is a string
	copied has a value which is a string
	copy_source_inaccessible has a value which is a GenomeAnnotationAPI.boolean
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a string
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
Genome is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contigs has a value which is a reference to a list where each element is a KBaseGenomes.Contig
	contig_lengths has a value which is a reference to a list where each element is an int
	contig_ids has a value which is a reference to a list where each element is a KBaseGenomes.Contig_id
	source has a value which is a string
	source_id has a value which is a KBaseGenomes.source_id
	md5 has a value which is a string
	taxonomy has a value which is a string
	gc_content has a value which is a float
	complete has a value which is an int
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	features has a value which is a reference to a list where each element is a KBaseGenomes.Feature
	contigset_ref has a value which is a KBaseGenomes.ContigSet_ref
	assembly_ref has a value which is a KBaseGenomes.Assembly_ref
	quality has a value which is a KBaseGenomes.Genome_quality_measure
	close_genomes has a value which is a reference to a list where each element is a KBaseGenomes.Close_genome
	analysis_events has a value which is a reference to a list where each element is a KBaseGenomes.Analysis_event
Genome_id is a string
Contig is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Contig_id
	length has a value which is an int
	md5 has a value which is a string
	sequence has a value which is a string
	genetic_code has a value which is an int
	cell_compartment has a value which is a string
	replicon_type has a value which is a string
	replicon_geometry has a value which is a string
	name has a value which is a string
	description has a value which is a string
	complete has a value which is a KBaseGenomes.Bool
Contig_id is a string
Bool is an int
source_id is a string
publication is a reference to a list containing 7 items:
	0: (id) an int
	1: (source_db) a string
	2: (article_title) a string
	3: (link) a string
	4: (pubdate) a string
	5: (authors) a string
	6: (journal_name) a string
Feature is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Feature_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	type has a value which is a string
	function has a value which is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a KBaseGenomes.OntologyData
	md5 has a value which is a string
	protein_translation has a value which is a string
	dna_sequence has a value which is a string
	protein_translation_length has a value which is an int
	dna_sequence_length has a value which is an int
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	subsystems has a value which is a reference to a list where each element is a string
	protein_families has a value which is a reference to a list where each element is a KBaseGenomes.ProteinFamily
	aliases has a value which is a reference to a list where each element is a string
	orthologs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: a string
		1: a float

	annotations has a value which is a reference to a list where each element is a KBaseGenomes.annotation
	subsystem_data has a value which is a reference to a list where each element is a KBaseGenomes.subsystem_data
	regulon_data has a value which is a reference to a list where each element is a KBaseGenomes.regulon_data
	atomic_regulons has a value which is a reference to a list where each element is a KBaseGenomes.atomic_regulon
	coexpressed_fids has a value which is a reference to a list where each element is a KBaseGenomes.coexpressed_fid
	co_occurring_fids has a value which is a reference to a list where each element is a KBaseGenomes.co_occurring_fid
	quality has a value which is a KBaseGenomes.Feature_quality_measure
	feature_creation_event has a value which is a KBaseGenomes.Analysis_event
Feature_id is a string
OntologyData is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ontology_ref has a value which is a string
	term_lineage has a value which is a reference to a list where each element is a string
	term_name has a value which is a string
	evidence has a value which is a reference to a list where each element is a KBaseGenomes.OntologyEvidence
OntologyEvidence is a reference to a hash where the following keys are defined:
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	translation_provenance has a value which is a reference to a list containing 3 items:
		0: (ontologytranslation_ref) a string
		1: (namespace) a string
		2: (source_term) a string

	alignment_evidence has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: (start) an int
		1: (stop) an int
		2: (align_length) an int
		3: (identify) a float

ProteinFamily is a reference to a hash where the following keys are defined:
	id has a value which is a string
	subject_db has a value which is a string
	release_version has a value which is a string
	subject_description has a value which is a string
	query_begin has a value which is an int
	query_end has a value which is an int
	subject_begin has a value which is an int
	subject_end has a value which is an int
	score has a value which is a float
	evalue has a value which is a float
annotation is a reference to a list containing 3 items:
	0: (comment) a string
	1: (annotator) a string
	2: (annotation_time) a float
subsystem_data is a reference to a list containing 3 items:
	0: (subsystem) a string
	1: (variant) a string
	2: (role) a string
regulon_data is a reference to a list containing 3 items:
	0: (regulon_id) a string
	1: (regulon_set) a reference to a list where each element is a KBaseGenomes.Feature_id
	2: (tfs) a reference to a list where each element is a KBaseGenomes.Feature_id
atomic_regulon is a reference to a list containing 2 items:
	0: (atomic_regulon_id) a string
	1: (atomic_regulon_size) an int
coexpressed_fid is a reference to a list containing 2 items:
	0: (scored_fid) a KBaseGenomes.Feature_id
	1: (score) a float
co_occurring_fid is a reference to a list containing 2 items:
	0: (scored_fid) a KBaseGenomes.Feature_id
	1: (score) a float
Feature_quality_measure is a reference to a hash where the following keys are defined:
	truncated_begin has a value which is a KBaseGenomes.Bool
	truncated_end has a value which is a KBaseGenomes.Bool
	existence_confidence has a value which is a float
	frameshifted has a value which is a KBaseGenomes.Bool
	selenoprotein has a value which is a KBaseGenomes.Bool
	pyrrolysylprotein has a value which is a KBaseGenomes.Bool
	overlap_rules has a value which is a reference to a list where each element is a string
	existence_priority has a value which is a float
	hit_count has a value which is a float
	weighted_hit_count has a value which is a float
Analysis_event is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Analysis_event_id
	tool_name has a value which is a string
	execution_time has a value which is a float
	parameters has a value which is a reference to a list where each element is a string
	hostname has a value which is a string
Analysis_event_id is a string
ContigSet_ref is a string
Assembly_ref is a string
Genome_quality_measure is a reference to a hash where the following keys are defined:
	frameshift_error_rate has a value which is a float
	sequence_error_rate has a value which is a float
Close_genome is a reference to a hash where the following keys are defined:
	genome has a value which is a KBaseGenomes.Genome_id
	closeness_measure has a value which is a float
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
obj_id is an int
obj_name is a string
type_string is a string
timestamp is a string
username is a string
ws_id is an int
ws_name is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
obj_ref is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
id_type is a string
extracted_id is a string


=end text

=item Description

A reasonably simple wrapper on get_objects2, but with Genome specific
filters instead of arbitrary get subdata included paths.

=back

=cut

sub get_genome_v1
{
    my($self, @args) = @_;
    my $job_id = $self->_get_genome_v1_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _get_genome_v1_submit {
    my($self, @args) = @_;
# Authentication: optional
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_genome_v1_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_genome_v1_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_genome_v1_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._get_genome_v1_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_genome_v1_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_genome_v1_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_genome_v1_submit');
    }
}

 


=head2 save_one_genome_v1

  $result = $obj->save_one_genome_v1($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeAnnotationAPI.SaveOneGenomeParamsV1
$result is a GenomeAnnotationAPI.SaveGenomeResultV1
SaveOneGenomeParamsV1 is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	name has a value which is a string
	data has a value which is a KBaseGenomes.Genome
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	hidden has a value which is a GenomeAnnotationAPI.boolean
Genome is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contigs has a value which is a reference to a list where each element is a KBaseGenomes.Contig
	contig_lengths has a value which is a reference to a list where each element is an int
	contig_ids has a value which is a reference to a list where each element is a KBaseGenomes.Contig_id
	source has a value which is a string
	source_id has a value which is a KBaseGenomes.source_id
	md5 has a value which is a string
	taxonomy has a value which is a string
	gc_content has a value which is a float
	complete has a value which is an int
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	features has a value which is a reference to a list where each element is a KBaseGenomes.Feature
	contigset_ref has a value which is a KBaseGenomes.ContigSet_ref
	assembly_ref has a value which is a KBaseGenomes.Assembly_ref
	quality has a value which is a KBaseGenomes.Genome_quality_measure
	close_genomes has a value which is a reference to a list where each element is a KBaseGenomes.Close_genome
	analysis_events has a value which is a reference to a list where each element is a KBaseGenomes.Analysis_event
Genome_id is a string
Contig is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Contig_id
	length has a value which is an int
	md5 has a value which is a string
	sequence has a value which is a string
	genetic_code has a value which is an int
	cell_compartment has a value which is a string
	replicon_type has a value which is a string
	replicon_geometry has a value which is a string
	name has a value which is a string
	description has a value which is a string
	complete has a value which is a KBaseGenomes.Bool
Contig_id is a string
Bool is an int
source_id is a string
publication is a reference to a list containing 7 items:
	0: (id) an int
	1: (source_db) a string
	2: (article_title) a string
	3: (link) a string
	4: (pubdate) a string
	5: (authors) a string
	6: (journal_name) a string
Feature is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Feature_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	type has a value which is a string
	function has a value which is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a KBaseGenomes.OntologyData
	md5 has a value which is a string
	protein_translation has a value which is a string
	dna_sequence has a value which is a string
	protein_translation_length has a value which is an int
	dna_sequence_length has a value which is an int
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	subsystems has a value which is a reference to a list where each element is a string
	protein_families has a value which is a reference to a list where each element is a KBaseGenomes.ProteinFamily
	aliases has a value which is a reference to a list where each element is a string
	orthologs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: a string
		1: a float

	annotations has a value which is a reference to a list where each element is a KBaseGenomes.annotation
	subsystem_data has a value which is a reference to a list where each element is a KBaseGenomes.subsystem_data
	regulon_data has a value which is a reference to a list where each element is a KBaseGenomes.regulon_data
	atomic_regulons has a value which is a reference to a list where each element is a KBaseGenomes.atomic_regulon
	coexpressed_fids has a value which is a reference to a list where each element is a KBaseGenomes.coexpressed_fid
	co_occurring_fids has a value which is a reference to a list where each element is a KBaseGenomes.co_occurring_fid
	quality has a value which is a KBaseGenomes.Feature_quality_measure
	feature_creation_event has a value which is a KBaseGenomes.Analysis_event
Feature_id is a string
OntologyData is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ontology_ref has a value which is a string
	term_lineage has a value which is a reference to a list where each element is a string
	term_name has a value which is a string
	evidence has a value which is a reference to a list where each element is a KBaseGenomes.OntologyEvidence
OntologyEvidence is a reference to a hash where the following keys are defined:
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	translation_provenance has a value which is a reference to a list containing 3 items:
		0: (ontologytranslation_ref) a string
		1: (namespace) a string
		2: (source_term) a string

	alignment_evidence has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: (start) an int
		1: (stop) an int
		2: (align_length) an int
		3: (identify) a float

ProteinFamily is a reference to a hash where the following keys are defined:
	id has a value which is a string
	subject_db has a value which is a string
	release_version has a value which is a string
	subject_description has a value which is a string
	query_begin has a value which is an int
	query_end has a value which is an int
	subject_begin has a value which is an int
	subject_end has a value which is an int
	score has a value which is a float
	evalue has a value which is a float
annotation is a reference to a list containing 3 items:
	0: (comment) a string
	1: (annotator) a string
	2: (annotation_time) a float
subsystem_data is a reference to a list containing 3 items:
	0: (subsystem) a string
	1: (variant) a string
	2: (role) a string
regulon_data is a reference to a list containing 3 items:
	0: (regulon_id) a string
	1: (regulon_set) a reference to a list where each element is a KBaseGenomes.Feature_id
	2: (tfs) a reference to a list where each element is a KBaseGenomes.Feature_id
atomic_regulon is a reference to a list containing 2 items:
	0: (atomic_regulon_id) a string
	1: (atomic_regulon_size) an int
coexpressed_fid is a reference to a list containing 2 items:
	0: (scored_fid) a KBaseGenomes.Feature_id
	1: (score) a float
co_occurring_fid is a reference to a list containing 2 items:
	0: (scored_fid) a KBaseGenomes.Feature_id
	1: (score) a float
Feature_quality_measure is a reference to a hash where the following keys are defined:
	truncated_begin has a value which is a KBaseGenomes.Bool
	truncated_end has a value which is a KBaseGenomes.Bool
	existence_confidence has a value which is a float
	frameshifted has a value which is a KBaseGenomes.Bool
	selenoprotein has a value which is a KBaseGenomes.Bool
	pyrrolysylprotein has a value which is a KBaseGenomes.Bool
	overlap_rules has a value which is a reference to a list where each element is a string
	existence_priority has a value which is a float
	hit_count has a value which is a float
	weighted_hit_count has a value which is a float
Analysis_event is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Analysis_event_id
	tool_name has a value which is a string
	execution_time has a value which is a float
	parameters has a value which is a reference to a list where each element is a string
	hostname has a value which is a string
Analysis_event_id is a string
ContigSet_ref is a string
Assembly_ref is a string
Genome_quality_measure is a reference to a hash where the following keys are defined:
	frameshift_error_rate has a value which is a float
	sequence_error_rate has a value which is a float
Close_genome is a reference to a hash where the following keys are defined:
	genome has a value which is a KBaseGenomes.Genome_id
	closeness_measure has a value which is a float
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
timestamp is a string
epoch is an int
obj_ref is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
SaveGenomeResultV1 is a reference to a hash where the following keys are defined:
	info has a value which is a Workspace.object_info
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
obj_id is an int
obj_name is a string
type_string is a string
username is a string
ws_id is an int
ws_name is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$params is a GenomeAnnotationAPI.SaveOneGenomeParamsV1
$result is a GenomeAnnotationAPI.SaveGenomeResultV1
SaveOneGenomeParamsV1 is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	name has a value which is a string
	data has a value which is a KBaseGenomes.Genome
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	hidden has a value which is a GenomeAnnotationAPI.boolean
Genome is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	dna_size has a value which is an int
	num_contigs has a value which is an int
	contigs has a value which is a reference to a list where each element is a KBaseGenomes.Contig
	contig_lengths has a value which is a reference to a list where each element is an int
	contig_ids has a value which is a reference to a list where each element is a KBaseGenomes.Contig_id
	source has a value which is a string
	source_id has a value which is a KBaseGenomes.source_id
	md5 has a value which is a string
	taxonomy has a value which is a string
	gc_content has a value which is a float
	complete has a value which is an int
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	features has a value which is a reference to a list where each element is a KBaseGenomes.Feature
	contigset_ref has a value which is a KBaseGenomes.ContigSet_ref
	assembly_ref has a value which is a KBaseGenomes.Assembly_ref
	quality has a value which is a KBaseGenomes.Genome_quality_measure
	close_genomes has a value which is a reference to a list where each element is a KBaseGenomes.Close_genome
	analysis_events has a value which is a reference to a list where each element is a KBaseGenomes.Analysis_event
Genome_id is a string
Contig is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Contig_id
	length has a value which is an int
	md5 has a value which is a string
	sequence has a value which is a string
	genetic_code has a value which is an int
	cell_compartment has a value which is a string
	replicon_type has a value which is a string
	replicon_geometry has a value which is a string
	name has a value which is a string
	description has a value which is a string
	complete has a value which is a KBaseGenomes.Bool
Contig_id is a string
Bool is an int
source_id is a string
publication is a reference to a list containing 7 items:
	0: (id) an int
	1: (source_db) a string
	2: (article_title) a string
	3: (link) a string
	4: (pubdate) a string
	5: (authors) a string
	6: (journal_name) a string
Feature is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Feature_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	type has a value which is a string
	function has a value which is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a KBaseGenomes.OntologyData
	md5 has a value which is a string
	protein_translation has a value which is a string
	dna_sequence has a value which is a string
	protein_translation_length has a value which is an int
	dna_sequence_length has a value which is an int
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	subsystems has a value which is a reference to a list where each element is a string
	protein_families has a value which is a reference to a list where each element is a KBaseGenomes.ProteinFamily
	aliases has a value which is a reference to a list where each element is a string
	orthologs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: a string
		1: a float

	annotations has a value which is a reference to a list where each element is a KBaseGenomes.annotation
	subsystem_data has a value which is a reference to a list where each element is a KBaseGenomes.subsystem_data
	regulon_data has a value which is a reference to a list where each element is a KBaseGenomes.regulon_data
	atomic_regulons has a value which is a reference to a list where each element is a KBaseGenomes.atomic_regulon
	coexpressed_fids has a value which is a reference to a list where each element is a KBaseGenomes.coexpressed_fid
	co_occurring_fids has a value which is a reference to a list where each element is a KBaseGenomes.co_occurring_fid
	quality has a value which is a KBaseGenomes.Feature_quality_measure
	feature_creation_event has a value which is a KBaseGenomes.Analysis_event
Feature_id is a string
OntologyData is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ontology_ref has a value which is a string
	term_lineage has a value which is a reference to a list where each element is a string
	term_name has a value which is a string
	evidence has a value which is a reference to a list where each element is a KBaseGenomes.OntologyEvidence
OntologyEvidence is a reference to a hash where the following keys are defined:
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	translation_provenance has a value which is a reference to a list containing 3 items:
		0: (ontologytranslation_ref) a string
		1: (namespace) a string
		2: (source_term) a string

	alignment_evidence has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: (start) an int
		1: (stop) an int
		2: (align_length) an int
		3: (identify) a float

ProteinFamily is a reference to a hash where the following keys are defined:
	id has a value which is a string
	subject_db has a value which is a string
	release_version has a value which is a string
	subject_description has a value which is a string
	query_begin has a value which is an int
	query_end has a value which is an int
	subject_begin has a value which is an int
	subject_end has a value which is an int
	score has a value which is a float
	evalue has a value which is a float
annotation is a reference to a list containing 3 items:
	0: (comment) a string
	1: (annotator) a string
	2: (annotation_time) a float
subsystem_data is a reference to a list containing 3 items:
	0: (subsystem) a string
	1: (variant) a string
	2: (role) a string
regulon_data is a reference to a list containing 3 items:
	0: (regulon_id) a string
	1: (regulon_set) a reference to a list where each element is a KBaseGenomes.Feature_id
	2: (tfs) a reference to a list where each element is a KBaseGenomes.Feature_id
atomic_regulon is a reference to a list containing 2 items:
	0: (atomic_regulon_id) a string
	1: (atomic_regulon_size) an int
coexpressed_fid is a reference to a list containing 2 items:
	0: (scored_fid) a KBaseGenomes.Feature_id
	1: (score) a float
co_occurring_fid is a reference to a list containing 2 items:
	0: (scored_fid) a KBaseGenomes.Feature_id
	1: (score) a float
Feature_quality_measure is a reference to a hash where the following keys are defined:
	truncated_begin has a value which is a KBaseGenomes.Bool
	truncated_end has a value which is a KBaseGenomes.Bool
	existence_confidence has a value which is a float
	frameshifted has a value which is a KBaseGenomes.Bool
	selenoprotein has a value which is a KBaseGenomes.Bool
	pyrrolysylprotein has a value which is a KBaseGenomes.Bool
	overlap_rules has a value which is a reference to a list where each element is a string
	existence_priority has a value which is a float
	hit_count has a value which is a float
	weighted_hit_count has a value which is a float
Analysis_event is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Analysis_event_id
	tool_name has a value which is a string
	execution_time has a value which is a float
	parameters has a value which is a reference to a list where each element is a string
	hostname has a value which is a string
Analysis_event_id is a string
ContigSet_ref is a string
Assembly_ref is a string
Genome_quality_measure is a reference to a hash where the following keys are defined:
	frameshift_error_rate has a value which is a float
	sequence_error_rate has a value which is a float
Close_genome is a reference to a hash where the following keys are defined:
	genome has a value which is a KBaseGenomes.Genome_id
	closeness_measure has a value which is a float
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
timestamp is a string
epoch is an int
obj_ref is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
SaveGenomeResultV1 is a reference to a hash where the following keys are defined:
	info has a value which is a Workspace.object_info
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
obj_id is an int
obj_name is a string
type_string is a string
username is a string
ws_id is an int
ws_name is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description



=back

=cut

sub save_one_genome_v1
{
    my($self, @args) = @_;
    my $job_id = $self->_save_one_genome_v1_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _save_one_genome_v1_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _save_one_genome_v1_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _save_one_genome_v1_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_save_one_genome_v1_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._save_one_genome_v1_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_save_one_genome_v1_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _save_one_genome_v1_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_save_one_genome_v1_submit');
    }
}

 
 
sub status
{
    my($self, @args) = @_;
    my $job_id = undef;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI._status_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_status_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            $job_id = $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _status_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_status_submit');
    }
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeAnnotationAPI.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'save_one_genome_v1',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method save_one_genome_v1",
            status_line => $self->{client}->status_line,
            method_name => 'save_one_genome_v1',
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
        warn "New client version available for GenomeAnnotationAPI::GenomeAnnotationAPIClient\n";
    }
    if ($sMajor == 0) {
        warn "GenomeAnnotationAPI::GenomeAnnotationAPIClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 ObjectReference

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 boolean

=over 4



=item Description

A boolean - 0 for false, 1 for true.
@range (0, 1)


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 Region

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
contig_id has a value which is a string
strand has a value which is a string
start has a value which is an int
length has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
contig_id has a value which is a string
strand has a value which is a string
start has a value which is an int
length has a value which is an int


=end text

=back



=head2 Feature_id_filters

=over 4



=item Description

*
* Filters passed to :meth:`get_feature_ids`
* @optional type_list region_list function_list alias_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
type_list has a value which is a reference to a list where each element is a string
region_list has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
function_list has a value which is a reference to a list where each element is a string
alias_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
type_list has a value which is a reference to a list where each element is a string
region_list has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
function_list has a value which is a reference to a list where each element is a string
alias_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 Feature_id_mapping

=over 4



=item Description

@optional by_type by_region by_function by_alias


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
by_type has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
by_region has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
by_function has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
by_alias has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
by_type has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
by_region has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
by_function has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
by_alias has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string


=end text

=back



=head2 Feature_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
feature_id has a value which is a string
feature_type has a value which is a string
feature_function has a value which is a string
feature_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
feature_dna_sequence_length has a value which is an int
feature_dna_sequence has a value which is a string
feature_md5 has a value which is a string
feature_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
feature_publications has a value which is a reference to a list where each element is a string
feature_quality_warnings has a value which is a reference to a list where each element is a string
feature_quality_score has a value which is a reference to a list where each element is a string
feature_notes has a value which is a string
feature_inference has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
feature_id has a value which is a string
feature_type has a value which is a string
feature_function has a value which is a string
feature_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
feature_dna_sequence_length has a value which is an int
feature_dna_sequence has a value which is a string
feature_md5 has a value which is a string
feature_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
feature_publications has a value which is a reference to a list where each element is a string
feature_quality_warnings has a value which is a reference to a list where each element is a string
feature_quality_score has a value which is a reference to a list where each element is a string
feature_notes has a value which is a string
feature_inference has a value which is a string


=end text

=back



=head2 Protein_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
protein_id has a value which is a string
protein_amino_acid_sequence has a value which is a string
protein_function has a value which is a string
protein_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
protein_md5 has a value which is a string
protein_domain_locations has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
protein_id has a value which is a string
protein_amino_acid_sequence has a value which is a string
protein_function has a value which is a string
protein_aliases has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
protein_md5 has a value which is a string
protein_domain_locations has a value which is a reference to a list where each element is a string


=end text

=back



=head2 Exon_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
exon_location has a value which is a GenomeAnnotationAPI.Region
exon_dna_sequence has a value which is a string
exon_ordinal has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
exon_location has a value which is a GenomeAnnotationAPI.Region
exon_dna_sequence has a value which is a string
exon_ordinal has a value which is an int


=end text

=back



=head2 UTR_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
utr_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
utr_dna_sequence has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
utr_locations has a value which is a reference to a list where each element is a GenomeAnnotationAPI.Region
utr_dna_sequence has a value which is a string


=end text

=back



=head2 Summary_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
scientific_name has a value which is a string
taxonomy_id has a value which is an int
kingdom has a value which is a string
scientific_lineage has a value which is a reference to a list where each element is a string
genetic_code has a value which is an int
organism_aliases has a value which is a reference to a list where each element is a string
assembly_source has a value which is a string
assembly_source_id has a value which is a string
assembly_source_date has a value which is a string
gc_content has a value which is a float
dna_size has a value which is an int
num_contigs has a value which is an int
contig_ids has a value which is a reference to a list where each element is a string
external_source has a value which is a string
external_source_date has a value which is a string
release has a value which is a string
original_source_filename has a value which is a string
feature_type_counts has a value which is a reference to a hash where the key is a string and the value is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
scientific_name has a value which is a string
taxonomy_id has a value which is an int
kingdom has a value which is a string
scientific_lineage has a value which is a reference to a list where each element is a string
genetic_code has a value which is an int
organism_aliases has a value which is a reference to a list where each element is a string
assembly_source has a value which is a string
assembly_source_id has a value which is a string
assembly_source_date has a value which is a string
gc_content has a value which is a float
dna_size has a value which is an int
num_contigs has a value which is an int
contig_ids has a value which is a reference to a list where each element is a string
external_source has a value which is a string
external_source_date has a value which is a string
release has a value which is a string
original_source_filename has a value which is a string
feature_type_counts has a value which is a reference to a hash where the key is a string and the value is an int


=end text

=back



=head2 GenomeAnnotation_data

=over 4



=item Description

gene_id is a feature id of a gene feature.
mrna_id is a feature id of a mrna feature.
cds_id is a feature id of a cds feature.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
gene_type has a value which is a string
mrna_type has a value which is a string
cds_type has a value which is a string
feature_types has a value which is a reference to a list where each element is a string
feature_by_id_by_type has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Feature_data
protein_by_cds_id has a value which is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Protein_data
mrna_ids_by_gene_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
cds_ids_by_gene_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
cds_id_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a string
exons_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a GenomeAnnotationAPI.Exon_data
utr_by_utr_type_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.UTR_data
summary has a value which is a GenomeAnnotationAPI.Summary_data

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
gene_type has a value which is a string
mrna_type has a value which is a string
cds_type has a value which is a string
feature_types has a value which is a reference to a list where each element is a string
feature_by_id_by_type has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Feature_data
protein_by_cds_id has a value which is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.Protein_data
mrna_ids_by_gene_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
cds_ids_by_gene_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a string
cds_id_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a string
exons_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a reference to a list where each element is a GenomeAnnotationAPI.Exon_data
utr_by_utr_type_by_mrna_id has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a GenomeAnnotationAPI.UTR_data
summary has a value which is a GenomeAnnotationAPI.Summary_data


=end text

=back



=head2 inputs_get_taxon

=over 4



=item Description

*
* Retrieve the Taxon associated with this GenomeAnnotation.
*
* @return Reference to TaxonAPI object


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference


=end text

=back



=head2 inputs_get_assembly

=over 4



=item Description

*
* Retrieve the Assembly associated with this GenomeAnnotation.
*
* @return Reference to AssemblyAPI object


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference


=end text

=back



=head2 inputs_get_feature_types

=over 4



=item Description

*
* Retrieve the list of Feature types.
*
* @return List of feature type identifiers (strings)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference


=end text

=back



=head2 inputs_get_feature_type_descriptions

=over 4



=item Description

optional feature_type_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_type_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_type_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_feature_type_counts

=over 4



=item Description

@optional feature_type_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_type_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_type_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_feature_ids

=over 4



=item Description

@optional filters group_by


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
filters has a value which is a GenomeAnnotationAPI.Feature_id_filters
group_by has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
filters has a value which is a GenomeAnnotationAPI.Feature_id_filters
group_by has a value which is a string


=end text

=back



=head2 inputs_get_features

=over 4



=item Description

@optional feature_id_list exclude_sequence


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string
exclude_sequence has a value which is a GenomeAnnotationAPI.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string
exclude_sequence has a value which is a GenomeAnnotationAPI.boolean


=end text

=back



=head2 GetFeatures2Params

=over 4



=item Description

exclude_sequence = set to 1 (true) or 0 (false) to indicate if sequences
should be included.  Defautl is false.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string
exclude_sequence has a value which is a GenomeAnnotationAPI.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string
exclude_sequence has a value which is a GenomeAnnotationAPI.boolean


=end text

=back



=head2 inputs_get_proteins

=over 4



=item Description

*
* Retrieve Protein data.
*
* @return Mapping from protein ID to data about the protein.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference


=end text

=back



=head2 inputs_get_feature_locations

=over 4



=item Description

optional feature_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_feature_publications

=over 4



=item Description

optional feature_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_feature_dna

=over 4



=item Description

*
* Retrieve Feature DNA sequences.
*
* @param feature_id_list List of Feature IDs for which to retrieve sequences.
*     If empty, returns data for all features.
* @return Mapping of Feature IDs to their DNA sequence.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_feature_functions

=over 4



=item Description

@optional feature_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_feature_aliases

=over 4



=item Description

@optional feature_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
feature_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_cds_by_gene

=over 4



=item Description

*
* Retrieves coding sequence Features (cds) for given gene Feature IDs.
*
* @param gene_id_list List of gene Feature IDS for which to retrieve CDS.
*     If empty, returns data for all features.
* @return Mapping of gene Feature IDs to a list of CDS Feature IDs.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
gene_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
gene_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_mrna_id_list

=over 4



=item Description

@optional mrna_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
mrna_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
mrna_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_gene_by_cds

=over 4



=item Description

@optional cds_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
cds_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
cds_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_gene_by_mrna

=over 4



=item Description

@optional mrna_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
mrna_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
mrna_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_mrna_by_cds

=over 4



=item Description

@optional cds_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
cds_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
cds_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_mrna_by_gene

=over 4



=item Description

@optional gene_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
gene_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
gene_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_mrna_exons

=over 4



=item Description

@optional mrna_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
mrna_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
mrna_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_mrna_utrs

=over 4



=item Description

@optional mrna_id_list


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
mrna_id_list has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
mrna_id_list has a value which is a reference to a list where each element is a string


=end text

=back



=head2 inputs_get_summary

=over 4



=item Description

*
* Retrieve a summary representation of this GenomeAnnotation.
*
* @return summary data


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference


=end text

=back



=head2 inputs_save_summary

=over 4



=item Description

*
* Retrieve a summary representation of this GenomeAnnotation.
*
* @return (int, Summary_data)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference


=end text

=back



=head2 GetCombinedDataParams

=over 4



=item Description

* Retrieve any part of GenomeAnnotation.
* Any of exclude_genes, include_mrnas and exclude_cdss flags override values listed in include_features_by_type.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
exclude_genes has a value which is a GenomeAnnotationAPI.boolean
include_mrnas has a value which is a GenomeAnnotationAPI.boolean
exclude_cdss has a value which is a GenomeAnnotationAPI.boolean
include_features_by_type has a value which is a reference to a list where each element is a string
exclude_protein_by_cds_id has a value which is a GenomeAnnotationAPI.boolean
include_mrna_ids_by_gene_id has a value which is a GenomeAnnotationAPI.boolean
exclude_cds_ids_by_gene_id has a value which is a GenomeAnnotationAPI.boolean
include_cds_id_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
include_exons_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
include_utr_by_utr_type_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
exclude_summary has a value which is a GenomeAnnotationAPI.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a GenomeAnnotationAPI.ObjectReference
exclude_genes has a value which is a GenomeAnnotationAPI.boolean
include_mrnas has a value which is a GenomeAnnotationAPI.boolean
exclude_cdss has a value which is a GenomeAnnotationAPI.boolean
include_features_by_type has a value which is a reference to a list where each element is a string
exclude_protein_by_cds_id has a value which is a GenomeAnnotationAPI.boolean
include_mrna_ids_by_gene_id has a value which is a GenomeAnnotationAPI.boolean
exclude_cds_ids_by_gene_id has a value which is a GenomeAnnotationAPI.boolean
include_cds_id_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
include_exons_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
include_utr_by_utr_type_by_mrna_id has a value which is a GenomeAnnotationAPI.boolean
exclude_summary has a value which is a GenomeAnnotationAPI.boolean


=end text

=back



=head2 GenomeSelectorV1

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a string
included_feature_position_index has a value which is a reference to a list where each element is an int
ref_path_to_genome has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a string
included_feature_position_index has a value which is a reference to a list where each element is an int
ref_path_to_genome has a value which is a reference to a list where each element is a string


=end text

=back



=head2 GetGenomeParamsV1

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genomes has a value which is a reference to a list where each element is a GenomeAnnotationAPI.GenomeSelectorV1
included_fields has a value which is a reference to a list where each element is a string
included_feature_fields has a value which is a reference to a list where each element is a string
ignore_errors has a value which is a GenomeAnnotationAPI.boolean
no_data has a value which is a GenomeAnnotationAPI.boolean
no_metadata has a value which is a GenomeAnnotationAPI.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genomes has a value which is a reference to a list where each element is a GenomeAnnotationAPI.GenomeSelectorV1
included_fields has a value which is a reference to a list where each element is a string
included_feature_fields has a value which is a reference to a list where each element is a string
ignore_errors has a value which is a GenomeAnnotationAPI.boolean
no_data has a value which is a GenomeAnnotationAPI.boolean
no_metadata has a value which is a GenomeAnnotationAPI.boolean


=end text

=back



=head2 GenomeDataV1

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
data has a value which is a KBaseGenomes.Genome
info has a value which is a Workspace.object_info
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
creator has a value which is a string
orig_wsid has a value which is a string
copied has a value which is a string
copy_source_inaccessible has a value which is a GenomeAnnotationAPI.boolean
created has a value which is a Workspace.timestamp
epoch has a value which is a Workspace.epoch
refs has a value which is a reference to a list where each element is a string
extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
handle_error has a value which is a string
handle_stacktrace has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
data has a value which is a KBaseGenomes.Genome
info has a value which is a Workspace.object_info
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
creator has a value which is a string
orig_wsid has a value which is a string
copied has a value which is a string
copy_source_inaccessible has a value which is a GenomeAnnotationAPI.boolean
created has a value which is a Workspace.timestamp
epoch has a value which is a Workspace.epoch
refs has a value which is a reference to a list where each element is a string
extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
handle_error has a value which is a string
handle_stacktrace has a value which is a string


=end text

=back



=head2 GenomeDataSetV1

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genomes has a value which is a reference to a list where each element is a GenomeAnnotationAPI.GenomeDataV1

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genomes has a value which is a reference to a list where each element is a GenomeAnnotationAPI.GenomeDataV1


=end text

=back



=head2 SaveOneGenomeParamsV1

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a string
name has a value which is a string
data has a value which is a KBaseGenomes.Genome
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
hidden has a value which is a GenomeAnnotationAPI.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a string
name has a value which is a string
data has a value which is a KBaseGenomes.Genome
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
hidden has a value which is a GenomeAnnotationAPI.boolean


=end text

=back



=head2 SaveGenomeResultV1

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
info has a value which is a Workspace.object_info

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
info has a value which is a Workspace.object_info


=end text

=back



=cut

package GenomeAnnotationAPI::GenomeAnnotationAPIClient::RpcClient;
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
