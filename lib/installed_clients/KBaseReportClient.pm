package installed_clients::KBaseReportClient;

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

installed_clients::KBaseReportClient

=head1 DESCRIPTION


Module for workspace data object reports, which show the results of running a job in an SDK app.


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => installed_clients::KBaseReportClient::RpcClient->new,
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
        method => "KBaseReport._check_job",
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




=head2 create

  $info = $obj->create($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a KBaseReport.CreateParams
$info is a KBaseReport.ReportInfo
CreateParams is a reference to a hash where the following keys are defined:
	report has a value which is a KBaseReport.SimpleReport
	workspace_name has a value which is a string
	workspace_id has a value which is an int
SimpleReport is a reference to a hash where the following keys are defined:
	text_message has a value which is a string
	direct_html has a value which is a string
	template has a value which is a KBaseReport.TemplateParams
	warnings has a value which is a reference to a list where each element is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
TemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	template_data_json has a value which is a string
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string

</pre>

=end html

=begin text

$params is a KBaseReport.CreateParams
$info is a KBaseReport.ReportInfo
CreateParams is a reference to a hash where the following keys are defined:
	report has a value which is a KBaseReport.SimpleReport
	workspace_name has a value which is a string
	workspace_id has a value which is an int
SimpleReport is a reference to a hash where the following keys are defined:
	text_message has a value which is a string
	direct_html has a value which is a string
	template has a value which is a KBaseReport.TemplateParams
	warnings has a value which is a reference to a list where each element is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
TemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	template_data_json has a value which is a string
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string


=end text

=item Description

Function signature for the create() method -- generate a simple,
text-based report for an app run.
@deprecated KBaseReport.create_extended_report

=back

=cut

sub create
{
    my($self, @args) = @_;
    my $job_id = $self->_create_submit(@args);
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

sub _create_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _create_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _create_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_create_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "KBaseReport._create_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_create_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _create_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_create_submit');
    }
}

 


=head2 create_extended_report

  $info = $obj->create_extended_report($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a KBaseReport.CreateExtendedReportParams
$info is a KBaseReport.ReportInfo
CreateExtendedReportParams is a reference to a hash where the following keys are defined:
	message has a value which is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
	warnings has a value which is a reference to a list where each element is a string
	html_links has a value which is a reference to a list where each element is a KBaseReport.File
	template has a value which is a KBaseReport.TemplateParams
	direct_html has a value which is a string
	direct_html_link_index has a value which is an int
	file_links has a value which is a reference to a list where each element is a KBaseReport.File
	report_object_name has a value which is a string
	html_window_height has a value which is a float
	summary_window_height has a value which is a float
	workspace_name has a value which is a string
	workspace_id has a value which is an int
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	template has a value which is a KBaseReport.TemplateParams
	name has a value which is a string
	label has a value which is a string
	description has a value which is a string
TemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	template_data_json has a value which is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string

</pre>

=end html

=begin text

$params is a KBaseReport.CreateExtendedReportParams
$info is a KBaseReport.ReportInfo
CreateExtendedReportParams is a reference to a hash where the following keys are defined:
	message has a value which is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
	warnings has a value which is a reference to a list where each element is a string
	html_links has a value which is a reference to a list where each element is a KBaseReport.File
	template has a value which is a KBaseReport.TemplateParams
	direct_html has a value which is a string
	direct_html_link_index has a value which is an int
	file_links has a value which is a reference to a list where each element is a KBaseReport.File
	report_object_name has a value which is a string
	html_window_height has a value which is a float
	summary_window_height has a value which is a float
	workspace_name has a value which is a string
	workspace_id has a value which is an int
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	template has a value which is a KBaseReport.TemplateParams
	name has a value which is a string
	label has a value which is a string
	description has a value which is a string
TemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	template_data_json has a value which is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string


=end text

=item Description

Create a report for the results of an app run. This method handles file
and HTML zipping, uploading, and linking as well as HTML rendering.

=back

=cut

sub create_extended_report
{
    my($self, @args) = @_;
    my $job_id = $self->_create_extended_report_submit(@args);
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

sub _create_extended_report_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _create_extended_report_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _create_extended_report_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_create_extended_report_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "KBaseReport._create_extended_report_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_create_extended_report_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _create_extended_report_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_create_extended_report_submit');
    }
}

 


=head2 render_template

  $output_file_path = $obj->render_template($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a KBaseReport.RenderTemplateParams
$output_file_path is a KBaseReport.File
RenderTemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	output_file has a value which is a string
	template_data_json has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	template has a value which is a KBaseReport.TemplateParams
	name has a value which is a string
	label has a value which is a string
	description has a value which is a string
TemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	template_data_json has a value which is a string

</pre>

=end html

=begin text

$params is a KBaseReport.RenderTemplateParams
$output_file_path is a KBaseReport.File
RenderTemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	output_file has a value which is a string
	template_data_json has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	template has a value which is a KBaseReport.TemplateParams
	name has a value which is a string
	label has a value which is a string
	description has a value which is a string
TemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	template_data_json has a value which is a string


=end text

=item Description

Render a file from a template. This method takes a template file and
a data structure, renders the template, and saves the results to a file.
It returns the output file path in the form
{ 'path': '/path/to/file' }

To ensure that the template and the output file are accessible to both
the KBaseReport service and the app requesting the template rendering, the
template file should be copied into the shared `scratch` directory and the
output_file location should also be in `scratch`.

See https://github.com/kbaseIncubator/kbase_report_templates for sample
page templates, standard includes, and instructions on creating your own
templates.

=back

=cut

sub render_template
{
    my($self, @args) = @_;
    my $job_id = $self->_render_template_submit(@args);
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

sub _render_template_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _render_template_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _render_template_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_render_template_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "KBaseReport._render_template_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_render_template_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _render_template_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_render_template_submit');
    }
}

 


=head2 render_templates

  $output_paths = $obj->render_templates($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a reference to a list where each element is a KBaseReport.RenderTemplateParams
$output_paths is a reference to a list where each element is a KBaseReport.File
RenderTemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	output_file has a value which is a string
	template_data_json has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	template has a value which is a KBaseReport.TemplateParams
	name has a value which is a string
	label has a value which is a string
	description has a value which is a string
TemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	template_data_json has a value which is a string

</pre>

=end html

=begin text

$params is a reference to a list where each element is a KBaseReport.RenderTemplateParams
$output_paths is a reference to a list where each element is a KBaseReport.File
RenderTemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	output_file has a value which is a string
	template_data_json has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	template has a value which is a KBaseReport.TemplateParams
	name has a value which is a string
	label has a value which is a string
	description has a value which is a string
TemplateParams is a reference to a hash where the following keys are defined:
	template_file has a value which is a string
	template_data_json has a value which is a string


=end text

=item Description

Render files from a list of template specifications. Input is a list of dicts
with the keys 'template_file', 'output_file', and 'template_data_json', and output
is a list of dicts containing the path of the rendered files, returned in the order
that the input was specified. All 'output_file' paths must be unique.

If any template fails to render, the endpoint will return an error.

=back

=cut

sub render_templates
{
    my($self, @args) = @_;
    my $job_id = $self->_render_templates_submit(@args);
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

sub _render_templates_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _render_templates_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _render_templates_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_render_templates_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "KBaseReport._render_templates_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_render_templates_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _render_templates_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_render_templates_submit');
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
        method => "KBaseReport._status_submit",
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
        method => "KBaseReport.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'render_templates',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method render_templates",
            status_line => $self->{client}->status_line,
            method_name => 'render_templates',
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
        warn "New client version available for installed_clients::KBaseReportClient\n";
    }
    if ($sMajor == 0) {
        warn "installed_clients::KBaseReportClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 ws_id

=over 4



=item Description

* Workspace ID reference in the format 'workspace_id/object_id/version'
* @id ws


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



=head2 TemplateParams

=over 4



=item Description

* Structure representing a template to be rendered. 'template_file' must be provided,
* 'template_data_json' is optional


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
template_file has a value which is a string
template_data_json has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
template_file has a value which is a string
template_data_json has a value which is a string


=end text

=back



=head2 WorkspaceObject

=over 4



=item Description

* Represents a Workspace object with some brief description text
* that can be associated with the object.
* Required arguments:
*     ws_id ref - workspace ID in the format 'workspace_id/object_id/version'
* Optional arguments:
*     string description - A plaintext, human-readable description of the
*         object created


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a KBaseReport.ws_id
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a KBaseReport.ws_id
description has a value which is a string


=end text

=back



=head2 SimpleReport

=over 4



=item Description

* A simple report for use in create()
* Optional arguments:
*     string text_message - Readable plain-text report message
*     string direct_html - Simple HTML text that will be rendered within the report widget
*     TemplateParams template - a template file and template data to be rendered and displayed
*         as HTML. Use in place of 'direct_html'
*     list<string> warnings - A list of plain-text warning messages
*     list<WorkspaceObject> objects_created - List of result workspace objects that this app
*         has created. They will get linked in the report view


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
text_message has a value which is a string
direct_html has a value which is a string
template has a value which is a KBaseReport.TemplateParams
warnings has a value which is a reference to a list where each element is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
text_message has a value which is a string
direct_html has a value which is a string
template has a value which is a KBaseReport.TemplateParams
warnings has a value which is a reference to a list where each element is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject


=end text

=back



=head2 CreateParams

=over 4



=item Description

* Parameters for the create() method
*
* Pass in *either* workspace_name or workspace_id -- only one is needed.
* Note that workspace_id is preferred over workspace_name because workspace_id immutable. If
* both are provided, the workspace_id will be used.
*
* Required arguments:
*     SimpleReport report - See the structure above
*     string workspace_name - Workspace name of the running app. Required
*         if workspace_id is absent
*     int workspace_id - Workspace ID of the running app. Required if
*         workspace_name is absent


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report has a value which is a KBaseReport.SimpleReport
workspace_name has a value which is a string
workspace_id has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report has a value which is a KBaseReport.SimpleReport
workspace_name has a value which is a string
workspace_id has a value which is an int


=end text

=back



=head2 ReportInfo

=over 4



=item Description

* The reference to the saved KBaseReport. This is the return object for
* both create() and create_extended()
* Returned data:
*    ws_id ref - reference to a workspace object in the form of
*        'workspace_id/object_id/version'. This is a reference to a saved
*        Report object (see KBaseReportWorkspace.spec)
*    string name - Plaintext unique name for the report. In
*        create_extended, this can optionally be set in a parameter


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a KBaseReport.ws_id
name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a KBaseReport.ws_id
name has a value which is a string


=end text

=back



=head2 File

=over 4



=item Description

* A file to be linked in the report. Pass in *either* a shock_id or a
* path. If a path to a file is given, then the file will be uploaded. If a
* path to a directory is given, then it will be zipped and uploaded.
* Required arguments:
*     string name - Plain-text filename (eg. "results.zip") -- shown to the user
*  One of the following identifiers is required:
*     string path - Can be a file or directory path.
*     string shock_id - Shock node ID.
*     TemplateParams template - template to be rendered and saved as a file.
* Optional arguments:
*     string label - A short description for the file (eg. "Filter results")
*     string description - A more detailed, human-readable description of the file


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string
template has a value which is a KBaseReport.TemplateParams
name has a value which is a string
label has a value which is a string
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string
template has a value which is a KBaseReport.TemplateParams
name has a value which is a string
label has a value which is a string
description has a value which is a string


=end text

=back



=head2 CreateExtendedReportParams

=over 4



=item Description

* Parameters used to create a more complex report with file and HTML links
*
* Pass in *either* workspace_name or workspace_id -- only one is needed.
* Note that workspace_id is preferred over workspace_name because workspace_id immutable.
*
* Note that it is possible to pass both 'html_links'/'direct_html_link_index' and 'direct_html'
* as parameters for an extended report; in such cases, the file specified by the
* 'direct_html_link_links' parameter is used for the report and the 'direct_html' is ignored.
*
* Required arguments:
*     string workspace_name - Name of the workspace where the report
*         should be saved. Required if workspace_id is absent
*     int workspace_id - ID of workspace where the report should be saved.
*         Required if workspace_name is absent
* Optional arguments:
*     string message - Simple text message to store in the report object
*     list<WorkspaceObject> objects_created - List of result workspace objects that this app
*         has created. They will be linked in the report view
*     list<string> warnings - A list of plain-text warning messages
*     string direct_html - Simple HTML text content to be rendered within the report widget.
*         Set only one of 'direct_html', 'template', and 'html_links'/'direct_html_link_index'.
*         Setting both 'template' and 'direct_html' will generate an error.
*     TemplateParams template - render a template to produce HTML text content that will be
*         rendered within the report widget. Setting 'template' and 'direct_html' or
*         'html_links'/'direct_html_link_index' will generate an error.
*     list<File> html_links - A list of paths, shock IDs, or template specs pointing to HTML files or directories.
*         If you pass in paths to directories, they will be zipped and uploaded
*     int direct_html_link_index - Index in html_links to set the direct/default view in the report.
*         Set only one of 'direct_html', 'template', and 'html_links'/'direct_html_link_index'.
*         Setting both 'template' and 'html_links'/'direct_html_link_index' will generate an error.
*     list<File> file_links - Allows the user to specify files that the report widget
*         should link for download. If you pass in paths to directories, they will be zipped.
*         Each entry should be a path, shock ID, or template specification.
*     string report_object_name - Name to use for the report object (will
*         be auto-generated if unspecified)
*     html_window_height - Fixed height in pixels of the HTML window for the report
*     summary_window_height - Fixed height in pixels of the summary window for the report


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
message has a value which is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
warnings has a value which is a reference to a list where each element is a string
html_links has a value which is a reference to a list where each element is a KBaseReport.File
template has a value which is a KBaseReport.TemplateParams
direct_html has a value which is a string
direct_html_link_index has a value which is an int
file_links has a value which is a reference to a list where each element is a KBaseReport.File
report_object_name has a value which is a string
html_window_height has a value which is a float
summary_window_height has a value which is a float
workspace_name has a value which is a string
workspace_id has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
message has a value which is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
warnings has a value which is a reference to a list where each element is a string
html_links has a value which is a reference to a list where each element is a KBaseReport.File
template has a value which is a KBaseReport.TemplateParams
direct_html has a value which is a string
direct_html_link_index has a value which is an int
file_links has a value which is a reference to a list where each element is a KBaseReport.File
report_object_name has a value which is a string
html_window_height has a value which is a float
summary_window_height has a value which is a float
workspace_name has a value which is a string
workspace_id has a value which is an int


=end text

=back



=head2 RenderTemplateParams

=over 4



=item Description

* Render a template using the supplied data, saving the results to an output
* file in the scratch directory.
*
* Required arguments:
*     string template_file  -  Path to the template file to be rendered.
*     string output_file    -  Path to the file where the rendered template
*                              should be saved. Must be in the scratch directory.
* Optional:
*     string template_data_json -  Data for rendering in the template.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
template_file has a value which is a string
output_file has a value which is a string
template_data_json has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
template_file has a value which is a string
output_file has a value which is a string
template_data_json has a value which is a string


=end text

=back



=cut

package installed_clients::KBaseReportClient::RpcClient;
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
