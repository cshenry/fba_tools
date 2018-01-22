package GenomeFileUtil::GenomeFileUtilClient;

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

GenomeFileUtil::GenomeFileUtilClient

=head1 DESCRIPTION





=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => GenomeFileUtil::GenomeFileUtilClient::RpcClient->new,
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
        method => "GenomeFileUtil._check_job",
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




=head2 genbank_to_genome

  $result = $obj->genbank_to_genome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.GenbankToGenomeParams
$result is a GenomeFileUtil.GenomeSaveResult
GenbankToGenomeParams is a reference to a hash where the following keys are defined:
	file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	taxon_wsname has a value which is a string
	taxon_reference has a value which is a string
	release has a value which is a string
	generate_ids_if_needed has a value which is a string
	genetic_code has a value which is an int
	type has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
GenomeSaveResult is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.GenbankToGenomeParams
$result is a GenomeFileUtil.GenomeSaveResult
GenbankToGenomeParams is a reference to a hash where the following keys are defined:
	file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	taxon_wsname has a value which is a string
	taxon_reference has a value which is a string
	release has a value which is a string
	generate_ids_if_needed has a value which is a string
	genetic_code has a value which is an int
	type has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
GenomeSaveResult is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string


=end text

=item Description



=back

=cut

sub genbank_to_genome
{
    my($self, @args) = @_;
    my $job_id = $self->_genbank_to_genome_submit(@args);
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

sub _genbank_to_genome_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _genbank_to_genome_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _genbank_to_genome_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_genbank_to_genome_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._genbank_to_genome_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_genbank_to_genome_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _genbank_to_genome_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_genbank_to_genome_submit');
    }
}

 


=head2 genome_to_gff

  $result = $obj->genome_to_gff($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.GenomeToGFFParams
$result is a GenomeFileUtil.GenomeToGFFResult
GenomeToGFFParams is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string
	ref_path_to_genome has a value which is a reference to a list where each element is a string
	is_gtf has a value which is a GenomeFileUtil.boolean
	target_dir has a value which is a string
boolean is an int
GenomeToGFFResult is a reference to a hash where the following keys are defined:
	gff_file has a value which is a GenomeFileUtil.File
	from_cache has a value which is a GenomeFileUtil.boolean
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.GenomeToGFFParams
$result is a GenomeFileUtil.GenomeToGFFResult
GenomeToGFFParams is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string
	ref_path_to_genome has a value which is a reference to a list where each element is a string
	is_gtf has a value which is a GenomeFileUtil.boolean
	target_dir has a value which is a string
boolean is an int
GenomeToGFFResult is a reference to a hash where the following keys are defined:
	gff_file has a value which is a GenomeFileUtil.File
	from_cache has a value which is a GenomeFileUtil.boolean
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string


=end text

=item Description



=back

=cut

sub genome_to_gff
{
    my($self, @args) = @_;
    my $job_id = $self->_genome_to_gff_submit(@args);
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

sub _genome_to_gff_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _genome_to_gff_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _genome_to_gff_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_genome_to_gff_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._genome_to_gff_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_genome_to_gff_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _genome_to_gff_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_genome_to_gff_submit');
    }
}

 


=head2 genome_to_genbank

  $result = $obj->genome_to_genbank($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.GenomeToGenbankParams
$result is a GenomeFileUtil.GenomeToGenbankResult
GenomeToGenbankParams is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string
	ref_path_to_genome has a value which is a reference to a list where each element is a string
GenomeToGenbankResult is a reference to a hash where the following keys are defined:
	genbank_file has a value which is a GenomeFileUtil.File
	from_cache has a value which is a GenomeFileUtil.boolean
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
boolean is an int

</pre>

=end html

=begin text

$params is a GenomeFileUtil.GenomeToGenbankParams
$result is a GenomeFileUtil.GenomeToGenbankResult
GenomeToGenbankParams is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string
	ref_path_to_genome has a value which is a reference to a list where each element is a string
GenomeToGenbankResult is a reference to a hash where the following keys are defined:
	genbank_file has a value which is a GenomeFileUtil.File
	from_cache has a value which is a GenomeFileUtil.boolean
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
boolean is an int


=end text

=item Description



=back

=cut

sub genome_to_genbank
{
    my($self, @args) = @_;
    my $job_id = $self->_genome_to_genbank_submit(@args);
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

sub _genome_to_genbank_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _genome_to_genbank_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _genome_to_genbank_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_genome_to_genbank_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._genome_to_genbank_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_genome_to_genbank_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _genome_to_genbank_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_genome_to_genbank_submit');
    }
}

 


=head2 export_genome_as_genbank

  $output = $obj->export_genome_as_genbank($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.ExportParams
$output is a GenomeFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.ExportParams
$output is a GenomeFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text

=item Description



=back

=cut

sub export_genome_as_genbank
{
    my($self, @args) = @_;
    my $job_id = $self->_export_genome_as_genbank_submit(@args);
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

sub _export_genome_as_genbank_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _export_genome_as_genbank_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _export_genome_as_genbank_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_export_genome_as_genbank_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._export_genome_as_genbank_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_export_genome_as_genbank_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _export_genome_as_genbank_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_export_genome_as_genbank_submit');
    }
}

 


=head2 fasta_gff_to_genome

  $returnVal = $obj->fasta_gff_to_genome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.FastaGFFToGenomeParams
$returnVal is a GenomeFileUtil.GenomeSaveResult
FastaGFFToGenomeParams is a reference to a hash where the following keys are defined:
	fasta_file has a value which is a GenomeFileUtil.File
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	taxon_wsname has a value which is a string
	taxon_reference has a value which is a string
	release has a value which is a string
	genetic_code has a value which is an int
	type has a value which is a string
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
GenomeSaveResult is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.FastaGFFToGenomeParams
$returnVal is a GenomeFileUtil.GenomeSaveResult
FastaGFFToGenomeParams is a reference to a hash where the following keys are defined:
	fasta_file has a value which is a GenomeFileUtil.File
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	taxon_wsname has a value which is a string
	taxon_reference has a value which is a string
	release has a value which is a string
	genetic_code has a value which is an int
	type has a value which is a string
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
GenomeSaveResult is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string


=end text

=item Description



=back

=cut

sub fasta_gff_to_genome
{
    my($self, @args) = @_;
    my $job_id = $self->_fasta_gff_to_genome_submit(@args);
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

sub _fasta_gff_to_genome_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _fasta_gff_to_genome_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _fasta_gff_to_genome_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_fasta_gff_to_genome_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._fasta_gff_to_genome_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_fasta_gff_to_genome_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _fasta_gff_to_genome_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_fasta_gff_to_genome_submit');
    }
}

 


=head2 save_one_genome

  $returnVal = $obj->save_one_genome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.SaveOneGenomeParams
$returnVal is a GenomeFileUtil.SaveGenomeResult
SaveOneGenomeParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	name has a value which is a string
	data has a value which is a KBaseGenomes.Genome
	hidden has a value which is a GenomeFileUtil.boolean
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
boolean is an int
SaveGenomeResult is a reference to a hash where the following keys are defined:
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
timestamp is a string
username is a string
ws_id is an int
ws_name is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.SaveOneGenomeParams
$returnVal is a GenomeFileUtil.SaveGenomeResult
SaveOneGenomeParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	name has a value which is a string
	data has a value which is a KBaseGenomes.Genome
	hidden has a value which is a GenomeFileUtil.boolean
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
boolean is an int
SaveGenomeResult is a reference to a hash where the following keys are defined:
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
timestamp is a string
username is a string
ws_id is an int
ws_name is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description



=back

=cut

sub save_one_genome
{
    my($self, @args) = @_;
    my $job_id = $self->_save_one_genome_submit(@args);
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

sub _save_one_genome_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _save_one_genome_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _save_one_genome_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_save_one_genome_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._save_one_genome_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_save_one_genome_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _save_one_genome_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_save_one_genome_submit');
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
        method => "GenomeFileUtil._status_submit",
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
        method => "GenomeFileUtil.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'save_one_genome',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method save_one_genome",
            status_line => $self->{client}->status_line,
            method_name => 'save_one_genome',
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
        warn "New client version available for GenomeFileUtil::GenomeFileUtilClient\n";
    }
    if ($sMajor == 0) {
        warn "GenomeFileUtil::GenomeFileUtilClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



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



=head2 File

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string
ftp_url has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string
ftp_url has a value which is a string


=end text

=back



=head2 usermeta

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the key is a string and the value is a string
</pre>

=end html

=begin text

a reference to a hash where the key is a string and the value is a string

=end text

=back



=head2 GenbankToGenomeParams

=over 4



=item Description

genome_name - becomes the name of the object
workspace_name - the name of the workspace it gets saved to.
source - Source of the file typically something like RefSeq or Ensembl
taxon_ws_name - where the reference taxons are : ReferenceTaxons
taxon_reference - if defined, will try to link the Genome to the specified
    taxonomy object insteas of performing the lookup during upload
release - Release or version number of the data 
      per example Ensembl has numbered releases of all their data: Release 31
generate_ids_if_needed - If field used for feature id is not there, 
      generate ids (default behavior is raising an exception)
genetic_code - Genetic code of organism. Overwrites determined GC from 
      taxon object
type - Reference, Representative or User upload


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
taxon_wsname has a value which is a string
taxon_reference has a value which is a string
release has a value which is a string
generate_ids_if_needed has a value which is a string
genetic_code has a value which is an int
type has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
taxon_wsname has a value which is a string
taxon_reference has a value which is a string
release has a value which is a string
generate_ids_if_needed has a value which is a string
genetic_code has a value which is an int
type has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta


=end text

=back



=head2 GenomeSaveResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_ref has a value which is a string


=end text

=back



=head2 GenomeToGFFParams

=over 4



=item Description

is_gtf - optional flag switching export to GTF format (default is 0, 
    which means GFF)
target_dir - optional target directory to create file in (default is
    temporary folder with name 'gff_<timestamp>' created in scratch)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_ref has a value which is a string
ref_path_to_genome has a value which is a reference to a list where each element is a string
is_gtf has a value which is a GenomeFileUtil.boolean
target_dir has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_ref has a value which is a string
ref_path_to_genome has a value which is a reference to a list where each element is a string
is_gtf has a value which is a GenomeFileUtil.boolean
target_dir has a value which is a string


=end text

=back



=head2 GenomeToGFFResult

=over 4



=item Description

from_cache is 1 if the file already exists and was just returned, 0 if
the file was generated during this call.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
gff_file has a value which is a GenomeFileUtil.File
from_cache has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
gff_file has a value which is a GenomeFileUtil.File
from_cache has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 GenomeToGenbankParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_ref has a value which is a string
ref_path_to_genome has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_ref has a value which is a string
ref_path_to_genome has a value which is a reference to a list where each element is a string


=end text

=back



=head2 GenomeToGenbankResult

=over 4



=item Description

from_cache is 1 if the file already exists and was just returned, 0 if
the file was generated during this call.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genbank_file has a value which is a GenomeFileUtil.File
from_cache has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genbank_file has a value which is a GenomeFileUtil.File
from_cache has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 ExportParams

=over 4



=item Description

input and output structure functions for standard downloaders


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



=head2 FastaGFFToGenomeParams

=over 4



=item Description

genome_name - becomes the name of the object
workspace_name - the name of the workspace it gets saved to.
source - Source of the file typically something like RefSeq or Ensembl
taxon_ws_name - where the reference taxons are : ReferenceTaxons
taxon_reference - if defined, will try to link the Genome to the specified
    taxonomy object insteas of performing the lookup during upload
release - Release or version number of the data 
      per example Ensembl has numbered releases of all their data: Release 31
genetic_code - Genetic code of organism. Overwrites determined GC from 
      taxon object
type - Reference, Representative or User upload


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fasta_file has a value which is a GenomeFileUtil.File
gff_file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
taxon_wsname has a value which is a string
taxon_reference has a value which is a string
release has a value which is a string
genetic_code has a value which is an int
type has a value which is a string
scientific_name has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fasta_file has a value which is a GenomeFileUtil.File
gff_file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
taxon_wsname has a value which is a string
taxon_reference has a value which is a string
release has a value which is a string
genetic_code has a value which is an int
type has a value which is a string
scientific_name has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta


=end text

=back



=head2 SaveOneGenomeParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a string
name has a value which is a string
data has a value which is a KBaseGenomes.Genome
hidden has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a string
name has a value which is a string
data has a value which is a KBaseGenomes.Genome
hidden has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 SaveGenomeResult

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

package GenomeFileUtil::GenomeFileUtilClient::RpcClient;
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
