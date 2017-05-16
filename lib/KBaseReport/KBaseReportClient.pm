package KBaseReport::KBaseReportClient;

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

KBaseReport::KBaseReportClient

=head1 DESCRIPTION


Module for a simple WS data object report type.


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => KBaseReport::KBaseReportClient::RpcClient->new,
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
	report has a value which is a KBaseReport.Report
	workspace_name has a value which is a string
Report is a reference to a hash where the following keys are defined:
	text_message has a value which is a string
	warnings has a value which is a reference to a list where each element is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
	file_links has a value which is a reference to a list where each element is a KBaseReport.LinkedFile
	html_links has a value which is a reference to a list where each element is a KBaseReport.LinkedFile
	direct_html has a value which is a string
	direct_html_link_index has a value which is an int
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
LinkedFile is a reference to a hash where the following keys are defined:
	handle has a value which is a KBaseReport.handle_ref
	description has a value which is a string
	name has a value which is a string
	label has a value which is a string
	URL has a value which is a string
handle_ref is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string

</pre>

=end html

=begin text

$params is a KBaseReport.CreateParams
$info is a KBaseReport.ReportInfo
CreateParams is a reference to a hash where the following keys are defined:
	report has a value which is a KBaseReport.Report
	workspace_name has a value which is a string
Report is a reference to a hash where the following keys are defined:
	text_message has a value which is a string
	warnings has a value which is a reference to a list where each element is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
	file_links has a value which is a reference to a list where each element is a KBaseReport.LinkedFile
	html_links has a value which is a reference to a list where each element is a KBaseReport.LinkedFile
	direct_html has a value which is a string
	direct_html_link_index has a value which is an int
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
LinkedFile is a reference to a hash where the following keys are defined:
	handle has a value which is a KBaseReport.handle_ref
	description has a value which is a string
	name has a value which is a string
	label has a value which is a string
	URL has a value which is a string
handle_ref is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string


=end text

=item Description

Create a KBaseReport with a brief summary of an App run.

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
	direct_html has a value which is a string
	direct_html_link_index has a value which is an int
	file_links has a value which is a reference to a list where each element is a KBaseReport.File
	report_object_name has a value which is a string
	html_window_height has a value which is a float
	summary_window_height has a value which is a float
	workspace_name has a value which is a string
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	name has a value which is a string
	description has a value which is a string
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
	direct_html has a value which is a string
	direct_html_link_index has a value which is an int
	file_links has a value which is a reference to a list where each element is a KBaseReport.File
	report_object_name has a value which is a string
	html_window_height has a value which is a float
	summary_window_height has a value which is a float
	workspace_name has a value which is a string
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	name has a value which is a string
	description has a value which is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string


=end text

=item Description

A more complex function to create a report that enables the user to specify files and html view that the report should link to

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
                method_name => 'create_extended_report',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method create_extended_report",
            status_line => $self->{client}->status_line,
            method_name => 'create_extended_report',
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
        warn "New client version available for KBaseReport::KBaseReportClient\n";
    }
    if ($sMajor == 0) {
        warn "KBaseReport::KBaseReportClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 ws_id

=over 4



=item Description

@id ws


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



=head2 handle_ref

=over 4



=item Description

Reference to a handle
@id handle


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



=head2 WorkspaceObject

=over 4



=item Description

Represents a Workspace object with some brief description text
that can be associated with the object.
@optional description


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



=head2 LinkedFile

=over 4



=item Description

Represents a file or html archive that the report should like to
@optional description label


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
handle has a value which is a KBaseReport.handle_ref
description has a value which is a string
name has a value which is a string
label has a value which is a string
URL has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
handle has a value which is a KBaseReport.handle_ref
description has a value which is a string
name has a value which is a string
label has a value which is a string
URL has a value which is a string


=end text

=back



=head2 Report

=over 4



=item Description

A simple Report of a method run in KBase.
It only provides for now a way to display a fixed width text output summary message, a
list of warnings, and a list of objects created (each with descriptions).
@optional warnings file_links html_links direct_html direct_html_link_index
@metadata ws length(warnings) as Warnings
@metadata ws length(text_message) as Size(characters)
@metadata ws length(objects_created) as Objects Created


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
text_message has a value which is a string
warnings has a value which is a reference to a list where each element is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
file_links has a value which is a reference to a list where each element is a KBaseReport.LinkedFile
html_links has a value which is a reference to a list where each element is a KBaseReport.LinkedFile
direct_html has a value which is a string
direct_html_link_index has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
text_message has a value which is a string
warnings has a value which is a reference to a list where each element is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
file_links has a value which is a reference to a list where each element is a KBaseReport.LinkedFile
html_links has a value which is a reference to a list where each element is a KBaseReport.LinkedFile
direct_html has a value which is a string
direct_html_link_index has a value which is an int


=end text

=back



=head2 CreateParams

=over 4



=item Description

Provide the report information.  The structure is:
    params = {
        report: {
            text_message: '',
            warnings: ['w1'],
            objects_created: [ {
                ref: 'ws/objid',
                description: ''
            }]
        },
        workspace_name: 'ws'
    }


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report has a value which is a KBaseReport.Report
workspace_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report has a value which is a KBaseReport.Report
workspace_name has a value which is a string


=end text

=back



=head2 ReportInfo

=over 4



=item Description

The reference to the saved KBaseReport.  The structure is:
    reportInfo = {
        ref: 'ws/objid/ver',
        name: 'myreport.2262323452'
    }


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



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string
name has a value which is a string
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string
name has a value which is a string
description has a value which is a string


=end text

=back



=head2 CreateExtendedReportParams

=over 4



=item Description

Parameters used to create a more complex report with file and html links
The following arguments allow the user to specify the classical data fields in the report object:
string message - simple text message to store in report object
list <WorkspaceObject> objects_created;
list <string> warnings - a list of warning messages in simple text
The following argument allows the user to specify the location of html files/directories that the report widget will render <or> link to:
list <fileRef> html_links - a list of paths or shock node IDs pointing to a single flat html file or to the top level directory of a website
The report widget can render one html view directly. Set one of the following fields to decide which view to render:
string direct_html - simple html text that will be rendered within the report widget
int  direct_html_link_index - use this to specify the index of the page in html_links to view directly in the report widget (ignored if html_string is set)
The following argument allows the user to specify the location of files that the report widget should link for download:
list <fileRef> file_links - a list of paths or shock node IDs pointing to a single flat file
The following parameters indicate where the report object should be saved in the workspace:
string report_object_name - name to use for the report object (job ID is used if left unspecified)
html_window_height - height of the html window in the narrative output widget
summary_window_height - height of summary window in the narrative output widget
string workspace_name - name of workspace where object should be saved


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
message has a value which is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
warnings has a value which is a reference to a list where each element is a string
html_links has a value which is a reference to a list where each element is a KBaseReport.File
direct_html has a value which is a string
direct_html_link_index has a value which is an int
file_links has a value which is a reference to a list where each element is a KBaseReport.File
report_object_name has a value which is a string
html_window_height has a value which is a float
summary_window_height has a value which is a float
workspace_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
message has a value which is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
warnings has a value which is a reference to a list where each element is a string
html_links has a value which is a reference to a list where each element is a KBaseReport.File
direct_html has a value which is a string
direct_html_link_index has a value which is an int
file_links has a value which is a reference to a list where each element is a KBaseReport.File
report_object_name has a value which is a string
html_window_height has a value which is a float
summary_window_height has a value which is a float
workspace_name has a value which is a string


=end text

=back



=cut

package KBaseReport::KBaseReportClient::RpcClient;
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
