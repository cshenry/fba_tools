package installed_clients::AssemblyUtilClient;

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

installed_clients::AssemblyUtilClient

=head1 DESCRIPTION





=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => installed_clients::AssemblyUtilClient::RpcClient->new,
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
        $service_version = $arg_hash{"service_version"};
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
        method => "AssemblyUtil._check_job",
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




=head2 get_assembly_as_fasta

  $file = $obj->get_assembly_as_fasta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.GetAssemblyParams
$file is an AssemblyUtil.FastaAssemblyFile
GetAssemblyParams is a reference to a hash where the following keys are defined:
	ref has a value which is a string
	filename has a value which is a string
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.GetAssemblyParams
$file is an AssemblyUtil.FastaAssemblyFile
GetAssemblyParams is a reference to a hash where the following keys are defined:
	ref has a value which is a string
	filename has a value which is a string
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string


=end text

=item Description

Given a reference to an Assembly (or legacy ContigSet data object), along with a set of options,
construct a local Fasta file with the sequence data.  If filename is set, attempt to save to the
specified filename.  Otherwise, a random name will be generated.

=back

=cut

sub get_assembly_as_fasta
{
    my($self, @args) = @_;
    my $job_id = $self->_get_assembly_as_fasta_submit(@args);
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

sub _get_assembly_as_fasta_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_assembly_as_fasta_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_assembly_as_fasta_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_assembly_as_fasta_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AssemblyUtil._get_assembly_as_fasta_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_assembly_as_fasta_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_assembly_as_fasta_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_assembly_as_fasta_submit');
    }
}

 


=head2 get_fastas

  $output = $obj->get_fastas($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.KBaseOjbReferences
$output is a reference to a hash where the key is an AssemblyUtil.ref and the value is an AssemblyUtil.ref_fastas
KBaseOjbReferences is a reference to a hash where the following keys are defined:
	ref_lst has a value which is a reference to a list where each element is an AssemblyUtil.ref
ref is a string
ref_fastas is a reference to a hash where the following keys are defined:
	paths has a value which is a reference to a list where each element is a string
	parent_refs has a value which is a reference to a list where each element is an AssemblyUtil.ref
	type has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.KBaseOjbReferences
$output is a reference to a hash where the key is an AssemblyUtil.ref and the value is an AssemblyUtil.ref_fastas
KBaseOjbReferences is a reference to a hash where the following keys are defined:
	ref_lst has a value which is a reference to a list where each element is an AssemblyUtil.ref
ref is a string
ref_fastas is a reference to a hash where the following keys are defined:
	paths has a value which is a reference to a list where each element is a string
	parent_refs has a value which is a reference to a list where each element is an AssemblyUtil.ref
	type has a value which is a string


=end text

=item Description

Given a reference list of KBase objects constructs a local Fasta file with the sequence data for each ref.

=back

=cut

sub get_fastas
{
    my($self, @args) = @_;
    my $job_id = $self->_get_fastas_submit(@args);
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

sub _get_fastas_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _get_fastas_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _get_fastas_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_get_fastas_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AssemblyUtil._get_fastas_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_get_fastas_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _get_fastas_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_get_fastas_submit');
    }
}

 


=head2 export_assembly_as_fasta

  $output = $obj->export_assembly_as_fasta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.ExportParams
$output is an AssemblyUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.ExportParams
$output is an AssemblyUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text

=item Description

A method designed especially for download, this calls 'get_assembly_as_fasta' to do
the work, but then packages the output with WS provenance and object info into
a zip file and saves to shock.

=back

=cut

sub export_assembly_as_fasta
{
    my($self, @args) = @_;
    my $job_id = $self->_export_assembly_as_fasta_submit(@args);
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

sub _export_assembly_as_fasta_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _export_assembly_as_fasta_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _export_assembly_as_fasta_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_export_assembly_as_fasta_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AssemblyUtil._export_assembly_as_fasta_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_export_assembly_as_fasta_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _export_assembly_as_fasta_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_export_assembly_as_fasta_submit');
    }
}

 


=head2 save_assembly_from_fasta2

  $result = $obj->save_assembly_from_fasta2($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.SaveAssemblyParams
$result is an AssemblyUtil.SaveAssemblyResult
SaveAssemblyParams is a reference to a hash where the following keys are defined:
	file has a value which is an AssemblyUtil.FastaAssemblyFile
	shock_id has a value which is an AssemblyUtil.ShockNodeId
	workspace_id has a value which is an int
	workspace_name has a value which is a string
	assembly_name has a value which is a string
	type has a value which is a string
	external_source has a value which is a string
	external_source_id has a value which is a string
	min_contig_length has a value which is an int
	contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string
ShockNodeId is a string
ExtraContigInfo is a reference to a hash where the following keys are defined:
	is_circ has a value which is an int
	description has a value which is a string
SaveAssemblyResult is a reference to a hash where the following keys are defined:
	upa has a value which is an AssemblyUtil.upa
	filtered_input has a value which is a string
upa is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.SaveAssemblyParams
$result is an AssemblyUtil.SaveAssemblyResult
SaveAssemblyParams is a reference to a hash where the following keys are defined:
	file has a value which is an AssemblyUtil.FastaAssemblyFile
	shock_id has a value which is an AssemblyUtil.ShockNodeId
	workspace_id has a value which is an int
	workspace_name has a value which is a string
	assembly_name has a value which is a string
	type has a value which is a string
	external_source has a value which is a string
	external_source_id has a value which is a string
	min_contig_length has a value which is an int
	contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string
ShockNodeId is a string
ExtraContigInfo is a reference to a hash where the following keys are defined:
	is_circ has a value which is an int
	description has a value which is a string
SaveAssemblyResult is a reference to a hash where the following keys are defined:
	upa has a value which is an AssemblyUtil.upa
	filtered_input has a value which is a string
upa is a string


=end text

=item Description

Save a KBase Workspace assembly object from a FASTA file.

=back

=cut

sub save_assembly_from_fasta2
{
    my($self, @args) = @_;
    my $job_id = $self->_save_assembly_from_fasta2_submit(@args);
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

sub _save_assembly_from_fasta2_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _save_assembly_from_fasta2_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _save_assembly_from_fasta2_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_save_assembly_from_fasta2_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AssemblyUtil._save_assembly_from_fasta2_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_save_assembly_from_fasta2_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _save_assembly_from_fasta2_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_save_assembly_from_fasta2_submit');
    }
}

 


=head2 save_assembly_from_fasta

  $ref = $obj->save_assembly_from_fasta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.SaveAssemblyParams
$ref is a string
SaveAssemblyParams is a reference to a hash where the following keys are defined:
	file has a value which is an AssemblyUtil.FastaAssemblyFile
	shock_id has a value which is an AssemblyUtil.ShockNodeId
	workspace_id has a value which is an int
	workspace_name has a value which is a string
	assembly_name has a value which is a string
	type has a value which is a string
	external_source has a value which is a string
	external_source_id has a value which is a string
	min_contig_length has a value which is an int
	contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string
ShockNodeId is a string
ExtraContigInfo is a reference to a hash where the following keys are defined:
	is_circ has a value which is an int
	description has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.SaveAssemblyParams
$ref is a string
SaveAssemblyParams is a reference to a hash where the following keys are defined:
	file has a value which is an AssemblyUtil.FastaAssemblyFile
	shock_id has a value which is an AssemblyUtil.ShockNodeId
	workspace_id has a value which is an int
	workspace_name has a value which is a string
	assembly_name has a value which is a string
	type has a value which is a string
	external_source has a value which is a string
	external_source_id has a value which is a string
	min_contig_length has a value which is an int
	contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string
ShockNodeId is a string
ExtraContigInfo is a reference to a hash where the following keys are defined:
	is_circ has a value which is an int
	description has a value which is a string


=end text

=item Description

@deprecated AssemblyUtil.save_assembly_from_fasta2

=back

=cut

sub save_assembly_from_fasta
{
    my($self, @args) = @_;
    my $job_id = $self->_save_assembly_from_fasta_submit(@args);
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

sub _save_assembly_from_fasta_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _save_assembly_from_fasta_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _save_assembly_from_fasta_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_save_assembly_from_fasta_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AssemblyUtil._save_assembly_from_fasta_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_save_assembly_from_fasta_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _save_assembly_from_fasta_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_save_assembly_from_fasta_submit');
    }
}

 


=head2 save_assemblies_from_fastas

  $results = $obj->save_assemblies_from_fastas($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.SaveAssembliesParams
$results is an AssemblyUtil.SaveAssembliesResults
SaveAssembliesParams is a reference to a hash where the following keys are defined:
	workspace_id has a value which is an int
	inputs has a value which is a reference to a list where each element is an AssemblyUtil.FASTAInput
	min_contig_length has a value which is an int
FASTAInput is a reference to a hash where the following keys are defined:
	file has a value which is a string
	node has a value which is a string
	assembly_name has a value which is a string
	type has a value which is a string
	external_source has a value which is a string
	external_source_id has a value which is a string
	contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo
ExtraContigInfo is a reference to a hash where the following keys are defined:
	is_circ has a value which is an int
	description has a value which is a string
SaveAssembliesResults is a reference to a hash where the following keys are defined:
	results has a value which is a reference to a list where each element is an AssemblyUtil.SaveAssemblyResult
SaveAssemblyResult is a reference to a hash where the following keys are defined:
	upa has a value which is an AssemblyUtil.upa
	filtered_input has a value which is a string
upa is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.SaveAssembliesParams
$results is an AssemblyUtil.SaveAssembliesResults
SaveAssembliesParams is a reference to a hash where the following keys are defined:
	workspace_id has a value which is an int
	inputs has a value which is a reference to a list where each element is an AssemblyUtil.FASTAInput
	min_contig_length has a value which is an int
FASTAInput is a reference to a hash where the following keys are defined:
	file has a value which is a string
	node has a value which is a string
	assembly_name has a value which is a string
	type has a value which is a string
	external_source has a value which is a string
	external_source_id has a value which is a string
	contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo
ExtraContigInfo is a reference to a hash where the following keys are defined:
	is_circ has a value which is an int
	description has a value which is a string
SaveAssembliesResults is a reference to a hash where the following keys are defined:
	results has a value which is a reference to a list where each element is an AssemblyUtil.SaveAssemblyResult
SaveAssemblyResult is a reference to a hash where the following keys are defined:
	upa has a value which is an AssemblyUtil.upa
	filtered_input has a value which is a string
upa is a string


=end text

=item Description

Save multiple assembly objects from FASTA files.
WARNING: The code currently saves all assembly object data in memory before sending it
to the workspace in a single batch. Since the object data doesn't include sequences,
it is typically small and so in most cases this shouldn't cause issues. However, many
assemblies and / or many contigs could conceivably cause memeory issues or could
cause the workspace to reject the data package if the serialized data is > 1GB.

TODO: If this becomes a common issue (not particularly likely?) update the code to
 Save assembly object data on disk if it becomes too large
 Batch uploads to the workspace based on data size

=back

=cut

sub save_assemblies_from_fastas
{
    my($self, @args) = @_;
    my $job_id = $self->_save_assemblies_from_fastas_submit(@args);
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

sub _save_assemblies_from_fastas_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _save_assemblies_from_fastas_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _save_assemblies_from_fastas_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_save_assemblies_from_fastas_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AssemblyUtil._save_assemblies_from_fastas_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_save_assemblies_from_fastas_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _save_assemblies_from_fastas_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_save_assemblies_from_fastas_submit');
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
        method => "AssemblyUtil._status_submit",
        params => \@args, context => $context});
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
        method => "AssemblyUtil.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'save_assemblies_from_fastas',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method save_assemblies_from_fastas",
            status_line => $self->{client}->status_line,
            method_name => 'save_assemblies_from_fastas',
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
        warn "New client version available for installed_clients::AssemblyUtilClient\n";
    }
    if ($sMajor == 0) {
        warn "installed_clients::AssemblyUtilClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 upa

=over 4



=item Description

A Unique Permanent Address for a workspace object, which is of the form W/O/V,
where W is the numeric workspace ID, O is the numeric object ID, and V is the object
version.


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



=head2 FastaAssemblyFile

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a string
assembly_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a string
assembly_name has a value which is a string


=end text

=back



=head2 GetAssemblyParams

=over 4



=item Description

@optional filename


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a string
filename has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a string
filename has a value which is a string


=end text

=back



=head2 ref

=over 4



=item Description

ref: workspace reference.

        KBaseOjbReferences:
            ref_lst: is an object wrapped array of KBase object references, which can be of the following types:
                - KBaseGenomes.Genome
                - KBaseSets.AssemblySet
                - KBaseMetagenome.BinnedContigs
                - KBaseGenomes.ContigSet
                - KBaseGenomeAnnotations.Assembly
                - KBaseSearch.GenomeSet
                - KBaseSets.GenomeSet

        ref_fastas
            paths - list of paths to fasta files associated with workspace object.
            type - workspace object type
            parent_refs - (optional) list of associated workspace object references if different from the output key


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



=head2 KBaseOjbReferences

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref_lst has a value which is a reference to a list where each element is an AssemblyUtil.ref

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref_lst has a value which is a reference to a list where each element is an AssemblyUtil.ref


=end text

=back



=head2 ref_fastas

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
paths has a value which is a reference to a list where each element is a string
parent_refs has a value which is a reference to a list where each element is an AssemblyUtil.ref
type has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
paths has a value which is a reference to a list where each element is a string
parent_refs has a value which is a reference to a list where each element is an AssemblyUtil.ref
type has a value which is a string


=end text

=back



=head2 ExportParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_ref has a value which is a string


=end text

=back



=head2 ExportOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
shock_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
shock_id has a value which is a string


=end text

=back



=head2 ShockNodeId

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



=head2 ExtraContigInfo

=over 4



=item Description

Structure for setting additional Contig information per contig
    is_circ - flag if contig is circular, 0 is false, 1 is true, missing
              indicates unknown
    description - if set, sets the description of the field in the assembly object
                  which may override what was in the fasta file


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
is_circ has a value which is an int
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
is_circ has a value which is an int
description has a value which is a string


=end text

=back



=head2 SaveAssemblyParams

=over 4



=item Description

Required arguments:
    Exactly one of:
        file - a pre-existing FASTA file to import. The 'assembly_name' field in the
            FastaAssemblyFile object is ignored.
        shock_id - an ID of a node in the Blobstore containing the FASTA file.
    Exactly one of:
        workspace_id - the immutable, numeric ID of the target workspace. Always prefer
            providing the ID over the name.
        workspace_name - the name of the target workspace.
    assembly_name - target object name

Optional arguments:
    
    type - should be one of 'isolate', 'metagenome', (maybe 'transcriptome').
        Defaults to 'Unknown'

    min_contig_length - if set and value is greater than 1, this will only
        include sequences with length greater or equal to the min_contig_length
        specified, discarding all other sequences

    contig_info - map from contig_id to a small structure that can be used to set the
        is_circular and description fields for Assemblies (optional)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file has a value which is an AssemblyUtil.FastaAssemblyFile
shock_id has a value which is an AssemblyUtil.ShockNodeId
workspace_id has a value which is an int
workspace_name has a value which is a string
assembly_name has a value which is a string
type has a value which is a string
external_source has a value which is a string
external_source_id has a value which is a string
min_contig_length has a value which is an int
contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file has a value which is an AssemblyUtil.FastaAssemblyFile
shock_id has a value which is an AssemblyUtil.ShockNodeId
workspace_id has a value which is an int
workspace_name has a value which is a string
assembly_name has a value which is a string
type has a value which is a string
external_source has a value which is a string
external_source_id has a value which is a string
min_contig_length has a value which is an int
contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo


=end text

=back



=head2 SaveAssemblyResult

=over 4



=item Description

Results from saving an assembly.
upa - the address of the resulting workspace object.
filtered_input - the filtered input file if the minimum contig length parameter is
   present and > 0. null otherwise.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
upa has a value which is an AssemblyUtil.upa
filtered_input has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
upa has a value which is an AssemblyUtil.upa
filtered_input has a value which is a string


=end text

=back



=head2 FASTAInput

=over 4



=item Description

An input FASTA file and metadata for import.
Required arguments:
    Exactly one of:
        file - a path to an input FASTA file. Must be accessible inside the AssemblyUtil
            docker continer.
        node - a node ID for a Blobstore (formerly Shock) node containing an input FASTA
            file.
    assembly_name - the workspace name under which to save the Assembly object.
Optional arguments:
    type - should be one of 'isolate', 'metagenome', (maybe 'transcriptome').
        Defaults to 'Unknown'
    external_source - the source of the input data. E.g. JGI, NCBI, etc.
    external_source_id - the ID of the input data at the source.
    contig_info - map from contig_id to a small structure that can be used to set the
        is_circular and description fields for Assemblies


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file has a value which is a string
node has a value which is a string
assembly_name has a value which is a string
type has a value which is a string
external_source has a value which is a string
external_source_id has a value which is a string
contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file has a value which is a string
node has a value which is a string
assembly_name has a value which is a string
type has a value which is a string
external_source has a value which is a string
external_source_id has a value which is a string
contig_info has a value which is a reference to a hash where the key is a string and the value is an AssemblyUtil.ExtraContigInfo


=end text

=back



=head2 SaveAssembliesParams

=over 4



=item Description

Input for the save_assemblies_from_fastas function.
Required arguments:
    workspace_id - the numerical ID of the workspace in which to save the Assemblies.
    inputs - a list of FASTA files to import. All of the files must be from the same
        source - either all local files or all Blobstore nodes.
Optional arguments:
    min_contig_length - an integer > 1. If present, sequences of lesser length will
        be removed from the input FASTA files.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_id has a value which is an int
inputs has a value which is a reference to a list where each element is an AssemblyUtil.FASTAInput
min_contig_length has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_id has a value which is an int
inputs has a value which is a reference to a list where each element is an AssemblyUtil.FASTAInput
min_contig_length has a value which is an int


=end text

=back



=head2 SaveAssembliesResults

=over 4



=item Description

Results for the save_assemblies_from_fastas function.
results - the results of the save operation in the same order as the input.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
results has a value which is a reference to a list where each element is an AssemblyUtil.SaveAssemblyResult

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
results has a value which is a reference to a list where each element is an AssemblyUtil.SaveAssemblyResult


=end text

=back



=cut

package installed_clients::AssemblyUtilClient::RpcClient;
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
