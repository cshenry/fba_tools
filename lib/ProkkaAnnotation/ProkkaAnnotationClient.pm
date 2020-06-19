package ProkkaAnnotation::ProkkaAnnotationClient;

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

ProkkaAnnotation::ProkkaAnnotationClient

=head1 DESCRIPTION


A KBase module: ProkkaAnnotation


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => ProkkaAnnotation::ProkkaAnnotationClient::RpcClient->new,
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
        method => "ProkkaAnnotation._check_job",
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




=head2 annotate

  $return = $obj->annotate($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a ProkkaAnnotation.AnnotateParams
$return is a ProkkaAnnotation.AnnotateOutput
AnnotateParams is a reference to a hash where the following keys are defined:
	object_ref has a value which is a ProkkaAnnotation.data_obj_ref
	output_workspace has a value which is a string
	output_genome_name has a value which is a string
	scientific_name has a value which is a string
	kingdom has a value which is a string
	genus has a value which is a string
	gcode has a value which is an int
	metagenome has a value which is a ProkkaAnnotation.boolean
	rawproduct has a value which is a ProkkaAnnotation.boolean
	fast has a value which is a ProkkaAnnotation.boolean
	mincontiglen has a value which is an int
	evalue has a value which is a string
	rfam has a value which is a ProkkaAnnotation.boolean
	norrna has a value which is a ProkkaAnnotation.boolean
	notrna has a value which is a ProkkaAnnotation.boolean
data_obj_ref is a string
boolean is an int
AnnotateOutput is a reference to a hash where the following keys are defined:
	output_genome_ref has a value which is a ProkkaAnnotation.genome_ref
	report_name has a value which is a string
	report_ref has a value which is a string
genome_ref is a string

</pre>

=end html

=begin text

$params is a ProkkaAnnotation.AnnotateParams
$return is a ProkkaAnnotation.AnnotateOutput
AnnotateParams is a reference to a hash where the following keys are defined:
	object_ref has a value which is a ProkkaAnnotation.data_obj_ref
	output_workspace has a value which is a string
	output_genome_name has a value which is a string
	scientific_name has a value which is a string
	kingdom has a value which is a string
	genus has a value which is a string
	gcode has a value which is an int
	metagenome has a value which is a ProkkaAnnotation.boolean
	rawproduct has a value which is a ProkkaAnnotation.boolean
	fast has a value which is a ProkkaAnnotation.boolean
	mincontiglen has a value which is an int
	evalue has a value which is a string
	rfam has a value which is a ProkkaAnnotation.boolean
	norrna has a value which is a ProkkaAnnotation.boolean
	notrna has a value which is a ProkkaAnnotation.boolean
data_obj_ref is a string
boolean is an int
AnnotateOutput is a reference to a hash where the following keys are defined:
	output_genome_ref has a value which is a ProkkaAnnotation.genome_ref
	report_name has a value which is a string
	report_ref has a value which is a string
genome_ref is a string


=end text

=item Description



=back

=cut

sub annotate
{
    my($self, @args) = @_;
    my $job_id = $self->_annotate_submit(@args);
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

sub _annotate_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _annotate_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _annotate_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_annotate_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "ProkkaAnnotation._annotate_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_annotate_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _annotate_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_annotate_submit');
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
        method => "ProkkaAnnotation._status_submit",
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
        method => "ProkkaAnnotation.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'annotate',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method annotate",
            status_line => $self->{client}->status_line,
            method_name => 'annotate',
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
        warn "New client version available for ProkkaAnnotation::ProkkaAnnotationClient\n";
    }
    if ($sMajor == 0) {
        warn "ProkkaAnnotation::ProkkaAnnotationClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 boolean

=over 4



=item Description

A boolean. 0 = false, anything else = true.


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



=head2 data_obj_ref

=over 4



=item Description

Reference to an Assembly or Genome object in the workspace
@id ws KBaseGenomeAnnotations.Assembly
@id ws KBaseGenomes.Genome


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



=head2 genome_ref

=over 4



=item Description

Reference to an Genome object in the workspace
@id ws KBaseGenomes.Genome


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



=head2 AnnotateParams

=over 4



=item Description

Required parameters:
    object_ref - reference to Assembly or Genome object,
    output_workspace - output workspace name,
    output_genome_name - output object name,
Optional parameters (correspond to PROKKA command line arguments):
  --scientific_name Genome scientific name (default 'Unknown')
  --kingdom [X]     Annotation mode: Archaea|Bacteria|Mitochondria|Viruses (default 'Bacteria')
  --genus [X]       Genus name (triggers to use --usegenus)
  --gcode [N]       Genetic code / Translation table (set if --kingdom is set) (default '11')
  --metagenome      Improve gene predictions for highly fragmented genomes (default OFF)
  --rawproduct      Do not clean up /product annotation (default OFF)
  --fast            Fast mode - skip CDS /product searching (default OFF)
  --mincontiglen [N] Minimum contig size [NCBI needs 200] (default '1')
  --evalue [n.n]    Similarity e-value cut-off (default '1e-06')
  --rfam            Enable searching for ncRNAs with Infernal+Rfam (SLOW!) (default OFF)
  --norrna          Don't run rRNA search (default OFF)
  --notrna          Don't run tRNA search (default OFF)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
object_ref has a value which is a ProkkaAnnotation.data_obj_ref
output_workspace has a value which is a string
output_genome_name has a value which is a string
scientific_name has a value which is a string
kingdom has a value which is a string
genus has a value which is a string
gcode has a value which is an int
metagenome has a value which is a ProkkaAnnotation.boolean
rawproduct has a value which is a ProkkaAnnotation.boolean
fast has a value which is a ProkkaAnnotation.boolean
mincontiglen has a value which is an int
evalue has a value which is a string
rfam has a value which is a ProkkaAnnotation.boolean
norrna has a value which is a ProkkaAnnotation.boolean
notrna has a value which is a ProkkaAnnotation.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
object_ref has a value which is a ProkkaAnnotation.data_obj_ref
output_workspace has a value which is a string
output_genome_name has a value which is a string
scientific_name has a value which is a string
kingdom has a value which is a string
genus has a value which is a string
gcode has a value which is an int
metagenome has a value which is a ProkkaAnnotation.boolean
rawproduct has a value which is a ProkkaAnnotation.boolean
fast has a value which is a ProkkaAnnotation.boolean
mincontiglen has a value which is an int
evalue has a value which is a string
rfam has a value which is a ProkkaAnnotation.boolean
norrna has a value which is a ProkkaAnnotation.boolean
notrna has a value which is a ProkkaAnnotation.boolean


=end text

=back



=head2 AnnotateOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
output_genome_ref has a value which is a ProkkaAnnotation.genome_ref
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
output_genome_ref has a value which is a ProkkaAnnotation.genome_ref
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=cut

package ProkkaAnnotation::ProkkaAnnotationClient::RpcClient;
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
