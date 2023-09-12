package installed_clients::GenomeFileUtilClient;

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

installed_clients::GenomeFileUtilClient

=head1 DESCRIPTION





=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => installed_clients::GenomeFileUtilClient::RpcClient->new,
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
	taxon_id has a value which is a string
	release has a value which is a string
	generate_ids_if_needed has a value which is a string
	genetic_code has a value which is an int
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
	use_existing_assembly has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
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
	taxon_id has a value which is a string
	release has a value which is a string
	generate_ids_if_needed has a value which is a string
	genetic_code has a value which is an int
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
	use_existing_assembly has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
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
	file_path has a value which is a string
	from_cache has a value which is a GenomeFileUtil.boolean

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
	file_path has a value which is a string
	from_cache has a value which is a GenomeFileUtil.boolean


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

 


=head2 metagenome_to_gff

  $result = $obj->metagenome_to_gff($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.MetagenomeToGFFParams
$result is a GenomeFileUtil.MetagenomeToGFFResult
MetagenomeToGFFParams is a reference to a hash where the following keys are defined:
	metagenome_ref has a value which is a string
	ref_path_to_genome has a value which is a reference to a list where each element is a string
	is_gtf has a value which is a GenomeFileUtil.boolean
	target_dir has a value which is a string
boolean is an int
MetagenomeToGFFResult is a reference to a hash where the following keys are defined:
	file_path has a value which is a string
	from_cache has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

$params is a GenomeFileUtil.MetagenomeToGFFParams
$result is a GenomeFileUtil.MetagenomeToGFFResult
MetagenomeToGFFParams is a reference to a hash where the following keys are defined:
	metagenome_ref has a value which is a string
	ref_path_to_genome has a value which is a reference to a list where each element is a string
	is_gtf has a value which is a GenomeFileUtil.boolean
	target_dir has a value which is a string
boolean is an int
MetagenomeToGFFResult is a reference to a hash where the following keys are defined:
	file_path has a value which is a string
	from_cache has a value which is a GenomeFileUtil.boolean


=end text

=item Description



=back

=cut

sub metagenome_to_gff
{
    my($self, @args) = @_;
    my $job_id = $self->_metagenome_to_gff_submit(@args);
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

sub _metagenome_to_gff_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _metagenome_to_gff_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _metagenome_to_gff_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_metagenome_to_gff_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._metagenome_to_gff_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_metagenome_to_gff_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _metagenome_to_gff_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_metagenome_to_gff_submit');
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
	genbank_file has a value which is a GenomeFileUtil.GBFile
	from_cache has a value which is a GenomeFileUtil.boolean
GBFile is a reference to a hash where the following keys are defined:
	file_path has a value which is a string
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
	genbank_file has a value which is a GenomeFileUtil.GBFile
	from_cache has a value which is a GenomeFileUtil.boolean
GBFile is a reference to a hash where the following keys are defined:
	file_path has a value which is a string
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

 


=head2 genome_features_to_fasta

  $result = $obj->genome_features_to_fasta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.GenomeFeaturesToFastaParams
$result is a GenomeFileUtil.FASTAResult
GenomeFeaturesToFastaParams is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string
	feature_lists has a value which is a reference to a list where each element is a string
	filter_ids has a value which is a reference to a list where each element is a string
	include_functions has a value which is a GenomeFileUtil.boolean
	include_aliases has a value which is a GenomeFileUtil.boolean
boolean is an int
FASTAResult is a reference to a hash where the following keys are defined:
	file_path has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.GenomeFeaturesToFastaParams
$result is a GenomeFileUtil.FASTAResult
GenomeFeaturesToFastaParams is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string
	feature_lists has a value which is a reference to a list where each element is a string
	filter_ids has a value which is a reference to a list where each element is a string
	include_functions has a value which is a GenomeFileUtil.boolean
	include_aliases has a value which is a GenomeFileUtil.boolean
boolean is an int
FASTAResult is a reference to a hash where the following keys are defined:
	file_path has a value which is a string


=end text

=item Description



=back

=cut

sub genome_features_to_fasta
{
    my($self, @args) = @_;
    my $job_id = $self->_genome_features_to_fasta_submit(@args);
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

sub _genome_features_to_fasta_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _genome_features_to_fasta_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _genome_features_to_fasta_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_genome_features_to_fasta_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._genome_features_to_fasta_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_genome_features_to_fasta_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _genome_features_to_fasta_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_genome_features_to_fasta_submit');
    }
}

 


=head2 genome_proteins_to_fasta

  $result = $obj->genome_proteins_to_fasta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.GenomeProteinToFastaParams
$result is a GenomeFileUtil.FASTAResult
GenomeProteinToFastaParams is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string
	filter_ids has a value which is a reference to a list where each element is a string
	include_functions has a value which is a GenomeFileUtil.boolean
	include_aliases has a value which is a GenomeFileUtil.boolean
boolean is an int
FASTAResult is a reference to a hash where the following keys are defined:
	file_path has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.GenomeProteinToFastaParams
$result is a GenomeFileUtil.FASTAResult
GenomeProteinToFastaParams is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string
	filter_ids has a value which is a reference to a list where each element is a string
	include_functions has a value which is a GenomeFileUtil.boolean
	include_aliases has a value which is a GenomeFileUtil.boolean
boolean is an int
FASTAResult is a reference to a hash where the following keys are defined:
	file_path has a value which is a string


=end text

=item Description



=back

=cut

sub genome_proteins_to_fasta
{
    my($self, @args) = @_;
    my $job_id = $self->_genome_proteins_to_fasta_submit(@args);
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

sub _genome_proteins_to_fasta_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _genome_proteins_to_fasta_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _genome_proteins_to_fasta_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_genome_proteins_to_fasta_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._genome_proteins_to_fasta_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_genome_proteins_to_fasta_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _genome_proteins_to_fasta_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_genome_proteins_to_fasta_submit');
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

 


=head2 export_genome_as_gff

  $output = $obj->export_genome_as_gff($params)

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

sub export_genome_as_gff
{
    my($self, @args) = @_;
    my $job_id = $self->_export_genome_as_gff_submit(@args);
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

sub _export_genome_as_gff_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _export_genome_as_gff_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _export_genome_as_gff_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_export_genome_as_gff_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._export_genome_as_gff_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_export_genome_as_gff_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _export_genome_as_gff_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_export_genome_as_gff_submit');
    }
}

 


=head2 export_genome_features_protein_to_fasta

  $output = $obj->export_genome_features_protein_to_fasta($params)

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

sub export_genome_features_protein_to_fasta
{
    my($self, @args) = @_;
    my $job_id = $self->_export_genome_features_protein_to_fasta_submit(@args);
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

sub _export_genome_features_protein_to_fasta_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _export_genome_features_protein_to_fasta_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _export_genome_features_protein_to_fasta_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_export_genome_features_protein_to_fasta_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._export_genome_features_protein_to_fasta_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_export_genome_features_protein_to_fasta_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _export_genome_features_protein_to_fasta_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_export_genome_features_protein_to_fasta_submit');
    }
}

 


=head2 export_metagenome_as_gff

  $output = $obj->export_metagenome_as_gff($params)

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

sub export_metagenome_as_gff
{
    my($self, @args) = @_;
    my $job_id = $self->_export_metagenome_as_gff_submit(@args);
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

sub _export_metagenome_as_gff_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _export_metagenome_as_gff_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _export_metagenome_as_gff_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_export_metagenome_as_gff_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._export_metagenome_as_gff_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_export_metagenome_as_gff_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _export_metagenome_as_gff_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_export_metagenome_as_gff_submit');
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
	taxon_id has a value which is a string
	release has a value which is a string
	genetic_code has a value which is an int
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
	existing_assembly_ref has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
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
	taxon_id has a value which is a string
	release has a value which is a string
	genetic_code has a value which is an int
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
	existing_assembly_ref has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
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

 


=head2 fasta_gff_to_genome_json

  $genome = $obj->fasta_gff_to_genome_json($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.FastaGFFToGenomeParams
$genome is an UnspecifiedObject, which can hold any non-null object
FastaGFFToGenomeParams is a reference to a hash where the following keys are defined:
	fasta_file has a value which is a GenomeFileUtil.File
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	taxon_wsname has a value which is a string
	taxon_id has a value which is a string
	release has a value which is a string
	genetic_code has a value which is an int
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
	existing_assembly_ref has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int

</pre>

=end html

=begin text

$params is a GenomeFileUtil.FastaGFFToGenomeParams
$genome is an UnspecifiedObject, which can hold any non-null object
FastaGFFToGenomeParams is a reference to a hash where the following keys are defined:
	fasta_file has a value which is a GenomeFileUtil.File
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	taxon_wsname has a value which is a string
	taxon_id has a value which is a string
	release has a value which is a string
	genetic_code has a value which is an int
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
	existing_assembly_ref has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int


=end text

=item Description

As above but returns the genome instead

=back

=cut

sub fasta_gff_to_genome_json
{
    my($self, @args) = @_;
    my $job_id = $self->_fasta_gff_to_genome_json_submit(@args);
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

sub _fasta_gff_to_genome_json_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _fasta_gff_to_genome_json_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _fasta_gff_to_genome_json_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_fasta_gff_to_genome_json_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._fasta_gff_to_genome_json_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_fasta_gff_to_genome_json_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _fasta_gff_to_genome_json_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_fasta_gff_to_genome_json_submit');
    }
}

 


=head2 fasta_gff_to_metagenome

  $returnVal = $obj->fasta_gff_to_metagenome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.FastaGFFToMetagenomeParams
$returnVal is a GenomeFileUtil.MetagenomeSaveResult
FastaGFFToMetagenomeParams is a reference to a hash where the following keys are defined:
	fasta_file has a value which is a GenomeFileUtil.File
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
	existing_assembly_ref has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
MetagenomeSaveResult is a reference to a hash where the following keys are defined:
	metagenome_ref has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.FastaGFFToMetagenomeParams
$returnVal is a GenomeFileUtil.MetagenomeSaveResult
FastaGFFToMetagenomeParams is a reference to a hash where the following keys are defined:
	fasta_file has a value which is a GenomeFileUtil.File
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
	existing_assembly_ref has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
MetagenomeSaveResult is a reference to a hash where the following keys are defined:
	metagenome_ref has a value which is a string


=end text

=item Description



=back

=cut

sub fasta_gff_to_metagenome
{
    my($self, @args) = @_;
    my $job_id = $self->_fasta_gff_to_metagenome_submit(@args);
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

sub _fasta_gff_to_metagenome_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _fasta_gff_to_metagenome_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _fasta_gff_to_metagenome_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_fasta_gff_to_metagenome_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._fasta_gff_to_metagenome_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_fasta_gff_to_metagenome_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _fasta_gff_to_metagenome_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_fasta_gff_to_metagenome_submit');
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
	upgrade has a value which is a GenomeFileUtil.boolean
Genome is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	warnings has a value which is a reference to a list where each element is a string
	genome_tiers has a value which is a reference to a list where each element is a string
	feature_counts has a value which is a reference to a hash where the key is a string and the value is an int
	genetic_code has a value which is an int
	dna_size has a value which is an int
	num_contigs has a value which is an int
	molecule_type has a value which is a string
	contig_lengths has a value which is a reference to a list where each element is an int
	contig_ids has a value which is a reference to a list where each element is a string
	source has a value which is a string
	source_id has a value which is a KBaseGenomes.source_id
	md5 has a value which is a string
	taxonomy has a value which is a string
	taxon_assignments has a value which is a reference to a hash where the key is a string and the value is a string
	gc_content has a value which is a float
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	ontology_events has a value which is a reference to a list where each element is a KBaseGenomes.Ontology_event
	ontologies_present has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a string
	features has a value which is a reference to a list where each element is a KBaseGenomes.Feature
	non_coding_features has a value which is a reference to a list where each element is a KBaseGenomes.NonCodingFeature
	cdss has a value which is a reference to a list where each element is a KBaseGenomes.CDS
	mrnas has a value which is a reference to a list where each element is a KBaseGenomes.mRNA
	assembly_ref has a value which is a KBaseGenomes.Assembly_ref
	taxon_ref has a value which is a KBaseGenomes.Taxon_ref
	genbank_handle_ref has a value which is a KBaseGenomes.genbank_handle_ref
	gff_handle_ref has a value which is a KBaseGenomes.gff_handle_ref
	external_source_origination_date has a value which is a string
	release has a value which is a string
	original_source_file_name has a value which is a string
	notes has a value which is a string
	quality_scores has a value which is a reference to a list where each element is a KBaseGenomes.GenomeQualityScore
	suspect has a value which is a KBaseGenomes.Bool
	genome_type has a value which is a string
Genome_id is a string
source_id is a string
publication is a reference to a list containing 7 items:
	0: (pubmedid) a float
	1: (source) a string
	2: (title) a string
	3: (url) a string
	4: (year) a string
	5: (authors) a string
	6: (journal) a string
Ontology_event is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ontology_ref has a value which is a KBaseGenomes.Ontology_ref
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	eco has a value which is a string
Ontology_ref is a string
Feature is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Feature_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	functions has a value which is a reference to a list where each element is a string
	functional_descriptions has a value which is a reference to a list where each element is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is an int
	note has a value which is a string
	md5 has a value which is a string
	protein_translation has a value which is a string
	protein_translation_length has a value which is an int
	cdss has a value which is a reference to a list where each element is a string
	mrnas has a value which is a reference to a list where each element is a string
	children has a value which is a reference to a list where each element is a string
	flags has a value which is a reference to a list where each element is a string
	warnings has a value which is a reference to a list where each element is a string
	inference_data has a value which is a reference to a list where each element is a KBaseGenomes.InferenceInfo
	dna_sequence has a value which is a string
	dna_sequence_length has a value which is an int
	aliases has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (fieldname) a string
		1: (alias) a string

	db_xrefs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (db_source) a string
		1: (db_identifier) a string

Feature_id is a string
Contig_id is a string
InferenceInfo is a reference to a hash where the following keys are defined:
	category has a value which is a string
	type has a value which is a string
	evidence has a value which is a string
NonCodingFeature is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Feature_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	type has a value which is a string
	functions has a value which is a reference to a list where each element is a string
	functional_descriptions has a value which is a reference to a list where each element is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is an int
	note has a value which is a string
	md5 has a value which is a string
	parent_gene has a value which is a string
	children has a value which is a reference to a list where each element is a string
	flags has a value which is a reference to a list where each element is a string
	warnings has a value which is a reference to a list where each element is a string
	inference_data has a value which is a reference to a list where each element is a KBaseGenomes.InferenceInfo
	dna_sequence has a value which is a string
	dna_sequence_length has a value which is an int
	aliases has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (fieldname) a string
		1: (alias) a string

	db_xrefs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (db_source) a string
		1: (db_identifier) a string

CDS is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.cds_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	md5 has a value which is a string
	protein_md5 has a value which is a string
	parent_gene has a value which is a KBaseGenomes.Feature_id
	parent_mrna has a value which is a KBaseGenomes.mrna_id
	note has a value which is a string
	functions has a value which is a reference to a list where each element is a string
	functional_descriptions has a value which is a reference to a list where each element is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is an int
	flags has a value which is a reference to a list where each element is a string
	warnings has a value which is a reference to a list where each element is a string
	inference_data has a value which is a reference to a list where each element is a KBaseGenomes.InferenceInfo
	protein_translation has a value which is a string
	protein_translation_length has a value which is an int
	aliases has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (fieldname) a string
		1: (alias) a string

	db_xrefs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (db_source) a string
		1: (db_identifier) a string

	dna_sequence has a value which is a string
	dna_sequence_length has a value which is an int
cds_id is a string
mrna_id is a string
mRNA is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.mrna_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	md5 has a value which is a string
	parent_gene has a value which is a KBaseGenomes.Feature_id
	cds has a value which is a KBaseGenomes.cds_id
	dna_sequence has a value which is a string
	dna_sequence_length has a value which is an int
	note has a value which is a string
	functions has a value which is a reference to a list where each element is a string
	functional_descriptions has a value which is a reference to a list where each element is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is an int
	flags has a value which is a reference to a list where each element is a string
	warnings has a value which is a reference to a list where each element is a string
	inference_data has a value which is a reference to a list where each element is a KBaseGenomes.InferenceInfo
	aliases has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (fieldname) a string
		1: (alias) a string

	db_xrefs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (db_source) a string
		1: (db_identifier) a string

Assembly_ref is a string
Taxon_ref is a string
genbank_handle_ref is a string
gff_handle_ref is a string
GenomeQualityScore is a reference to a hash where the following keys are defined:
	method has a value which is a string
	method_report_ref has a value which is a KBaseGenomes.Method_report_ref
	method_version has a value which is a string
	score has a value which is a string
	score_interpretation has a value which is a string
	timestamp has a value which is a string
Method_report_ref is a string
Bool is an int
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
	upgrade has a value which is a GenomeFileUtil.boolean
Genome is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	warnings has a value which is a reference to a list where each element is a string
	genome_tiers has a value which is a reference to a list where each element is a string
	feature_counts has a value which is a reference to a hash where the key is a string and the value is an int
	genetic_code has a value which is an int
	dna_size has a value which is an int
	num_contigs has a value which is an int
	molecule_type has a value which is a string
	contig_lengths has a value which is a reference to a list where each element is an int
	contig_ids has a value which is a reference to a list where each element is a string
	source has a value which is a string
	source_id has a value which is a KBaseGenomes.source_id
	md5 has a value which is a string
	taxonomy has a value which is a string
	taxon_assignments has a value which is a reference to a hash where the key is a string and the value is a string
	gc_content has a value which is a float
	publications has a value which is a reference to a list where each element is a KBaseGenomes.publication
	ontology_events has a value which is a reference to a list where each element is a KBaseGenomes.Ontology_event
	ontologies_present has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a string
	features has a value which is a reference to a list where each element is a KBaseGenomes.Feature
	non_coding_features has a value which is a reference to a list where each element is a KBaseGenomes.NonCodingFeature
	cdss has a value which is a reference to a list where each element is a KBaseGenomes.CDS
	mrnas has a value which is a reference to a list where each element is a KBaseGenomes.mRNA
	assembly_ref has a value which is a KBaseGenomes.Assembly_ref
	taxon_ref has a value which is a KBaseGenomes.Taxon_ref
	genbank_handle_ref has a value which is a KBaseGenomes.genbank_handle_ref
	gff_handle_ref has a value which is a KBaseGenomes.gff_handle_ref
	external_source_origination_date has a value which is a string
	release has a value which is a string
	original_source_file_name has a value which is a string
	notes has a value which is a string
	quality_scores has a value which is a reference to a list where each element is a KBaseGenomes.GenomeQualityScore
	suspect has a value which is a KBaseGenomes.Bool
	genome_type has a value which is a string
Genome_id is a string
source_id is a string
publication is a reference to a list containing 7 items:
	0: (pubmedid) a float
	1: (source) a string
	2: (title) a string
	3: (url) a string
	4: (year) a string
	5: (authors) a string
	6: (journal) a string
Ontology_event is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ontology_ref has a value which is a KBaseGenomes.Ontology_ref
	method has a value which is a string
	method_version has a value which is a string
	timestamp has a value which is a string
	eco has a value which is a string
Ontology_ref is a string
Feature is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Feature_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	functions has a value which is a reference to a list where each element is a string
	functional_descriptions has a value which is a reference to a list where each element is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is an int
	note has a value which is a string
	md5 has a value which is a string
	protein_translation has a value which is a string
	protein_translation_length has a value which is an int
	cdss has a value which is a reference to a list where each element is a string
	mrnas has a value which is a reference to a list where each element is a string
	children has a value which is a reference to a list where each element is a string
	flags has a value which is a reference to a list where each element is a string
	warnings has a value which is a reference to a list where each element is a string
	inference_data has a value which is a reference to a list where each element is a KBaseGenomes.InferenceInfo
	dna_sequence has a value which is a string
	dna_sequence_length has a value which is an int
	aliases has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (fieldname) a string
		1: (alias) a string

	db_xrefs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (db_source) a string
		1: (db_identifier) a string

Feature_id is a string
Contig_id is a string
InferenceInfo is a reference to a hash where the following keys are defined:
	category has a value which is a string
	type has a value which is a string
	evidence has a value which is a string
NonCodingFeature is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.Feature_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	type has a value which is a string
	functions has a value which is a reference to a list where each element is a string
	functional_descriptions has a value which is a reference to a list where each element is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is an int
	note has a value which is a string
	md5 has a value which is a string
	parent_gene has a value which is a string
	children has a value which is a reference to a list where each element is a string
	flags has a value which is a reference to a list where each element is a string
	warnings has a value which is a reference to a list where each element is a string
	inference_data has a value which is a reference to a list where each element is a KBaseGenomes.InferenceInfo
	dna_sequence has a value which is a string
	dna_sequence_length has a value which is an int
	aliases has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (fieldname) a string
		1: (alias) a string

	db_xrefs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (db_source) a string
		1: (db_identifier) a string

CDS is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.cds_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	md5 has a value which is a string
	protein_md5 has a value which is a string
	parent_gene has a value which is a KBaseGenomes.Feature_id
	parent_mrna has a value which is a KBaseGenomes.mrna_id
	note has a value which is a string
	functions has a value which is a reference to a list where each element is a string
	functional_descriptions has a value which is a reference to a list where each element is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is an int
	flags has a value which is a reference to a list where each element is a string
	warnings has a value which is a reference to a list where each element is a string
	inference_data has a value which is a reference to a list where each element is a KBaseGenomes.InferenceInfo
	protein_translation has a value which is a string
	protein_translation_length has a value which is an int
	aliases has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (fieldname) a string
		1: (alias) a string

	db_xrefs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (db_source) a string
		1: (db_identifier) a string

	dna_sequence has a value which is a string
	dna_sequence_length has a value which is an int
cds_id is a string
mrna_id is a string
mRNA is a reference to a hash where the following keys are defined:
	id has a value which is a KBaseGenomes.mrna_id
	location has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a KBaseGenomes.Contig_id
		1: an int
		2: a string
		3: an int

	md5 has a value which is a string
	parent_gene has a value which is a KBaseGenomes.Feature_id
	cds has a value which is a KBaseGenomes.cds_id
	dna_sequence has a value which is a string
	dna_sequence_length has a value which is an int
	note has a value which is a string
	functions has a value which is a reference to a list where each element is a string
	functional_descriptions has a value which is a reference to a list where each element is a string
	ontology_terms has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is an int
	flags has a value which is a reference to a list where each element is a string
	warnings has a value which is a reference to a list where each element is a string
	inference_data has a value which is a reference to a list where each element is a KBaseGenomes.InferenceInfo
	aliases has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (fieldname) a string
		1: (alias) a string

	db_xrefs has a value which is a reference to a list where each element is a reference to a list containing 2 items:
		0: (db_source) a string
		1: (db_identifier) a string

Assembly_ref is a string
Taxon_ref is a string
genbank_handle_ref is a string
gff_handle_ref is a string
GenomeQualityScore is a reference to a hash where the following keys are defined:
	method has a value which is a string
	method_report_ref has a value which is a KBaseGenomes.Method_report_ref
	method_version has a value which is a string
	score has a value which is a string
	score_interpretation has a value which is a string
	timestamp has a value which is a string
Method_report_ref is a string
Bool is an int
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

 


=head2 ws_obj_gff_to_genome

  $returnVal = $obj->ws_obj_gff_to_genome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.WsObjGFFToGenomeParams
$returnVal is a GenomeFileUtil.GenomeSaveResult
WsObjGFFToGenomeParams is a reference to a hash where the following keys are defined:
	ws_ref has a value which is a string
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	taxon_wsname has a value which is a string
	taxon_id has a value which is a string
	release has a value which is a string
	genetic_code has a value which is an int
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
GenomeSaveResult is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.WsObjGFFToGenomeParams
$returnVal is a GenomeFileUtil.GenomeSaveResult
WsObjGFFToGenomeParams is a reference to a hash where the following keys are defined:
	ws_ref has a value which is a string
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	taxon_wsname has a value which is a string
	taxon_id has a value which is a string
	release has a value which is a string
	genetic_code has a value which is an int
	scientific_name has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
GenomeSaveResult is a reference to a hash where the following keys are defined:
	genome_ref has a value which is a string


=end text

=item Description

This function takes in a workspace object of type KBaseGenomes.Genome or KBaseGenomeAnnotations.Assembly and a gff file and produces a KBaseGenomes.Genome reanotated according to the the input gff file.

=back

=cut

sub ws_obj_gff_to_genome
{
    my($self, @args) = @_;
    my $job_id = $self->_ws_obj_gff_to_genome_submit(@args);
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

sub _ws_obj_gff_to_genome_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _ws_obj_gff_to_genome_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _ws_obj_gff_to_genome_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_ws_obj_gff_to_genome_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._ws_obj_gff_to_genome_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_ws_obj_gff_to_genome_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _ws_obj_gff_to_genome_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_ws_obj_gff_to_genome_submit');
    }
}

 


=head2 ws_obj_gff_to_metagenome

  $returnVal = $obj->ws_obj_gff_to_metagenome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.WsObjGFFToMetagenomeParams
$returnVal is a GenomeFileUtil.MetagenomeSaveResult
WsObjGFFToMetagenomeParams is a reference to a hash where the following keys are defined:
	ws_ref has a value which is a string
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
MetagenomeSaveResult is a reference to a hash where the following keys are defined:
	metagenome_ref has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.WsObjGFFToMetagenomeParams
$returnVal is a GenomeFileUtil.MetagenomeSaveResult
WsObjGFFToMetagenomeParams is a reference to a hash where the following keys are defined:
	ws_ref has a value which is a string
	gff_file has a value which is a GenomeFileUtil.File
	genome_name has a value which is a string
	workspace_name has a value which is a string
	source has a value which is a string
	metadata has a value which is a GenomeFileUtil.usermeta
	generate_missing_genes has a value which is a GenomeFileUtil.boolean
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	ftp_url has a value which is a string
usermeta is a reference to a hash where the key is a string and the value is a string
boolean is an int
MetagenomeSaveResult is a reference to a hash where the following keys are defined:
	metagenome_ref has a value which is a string


=end text

=item Description

This function takes in a workspace object of type KBaseMetagenomes.AnnotatedMetagenomeAssembly or KBaseGenomeAnnotations.Assembly and a gff file and produces a KBaseMetagenomes.AnnotatedMetagenomeAssembly reanotated according to the the input gff file.

=back

=cut

sub ws_obj_gff_to_metagenome
{
    my($self, @args) = @_;
    my $job_id = $self->_ws_obj_gff_to_metagenome_submit(@args);
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

sub _ws_obj_gff_to_metagenome_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _ws_obj_gff_to_metagenome_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _ws_obj_gff_to_metagenome_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_ws_obj_gff_to_metagenome_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._ws_obj_gff_to_metagenome_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_ws_obj_gff_to_metagenome_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _ws_obj_gff_to_metagenome_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_ws_obj_gff_to_metagenome_submit');
    }
}

 


=head2 update_taxon_assignments

  $returnVal = $obj->update_taxon_assignments($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeFileUtil.UpdateTaxonAssignmentsParams
$returnVal is a GenomeFileUtil.UpdateTaxonAssignmentsResult
UpdateTaxonAssignmentsParams is a reference to a hash where the following keys are defined:
	workspace_id has a value which is an int
	object_id has a value which is an int
	taxon_assignments has a value which is a reference to a hash where the key is a string and the value is a string
	remove_assignments has a value which is a reference to a list where each element is a string
UpdateTaxonAssignmentsResult is a reference to a hash where the following keys are defined:
	ws_obj_ref has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeFileUtil.UpdateTaxonAssignmentsParams
$returnVal is a GenomeFileUtil.UpdateTaxonAssignmentsResult
UpdateTaxonAssignmentsParams is a reference to a hash where the following keys are defined:
	workspace_id has a value which is an int
	object_id has a value which is an int
	taxon_assignments has a value which is a reference to a hash where the key is a string and the value is a string
	remove_assignments has a value which is a reference to a list where each element is a string
UpdateTaxonAssignmentsResult is a reference to a hash where the following keys are defined:
	ws_obj_ref has a value which is a string


=end text

=item Description

Add, replace, or remove taxon assignments for a Genome object.

=back

=cut

sub update_taxon_assignments
{
    my($self, @args) = @_;
    my $job_id = $self->_update_taxon_assignments_submit(@args);
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

sub _update_taxon_assignments_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _update_taxon_assignments_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _update_taxon_assignments_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_update_taxon_assignments_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "GenomeFileUtil._update_taxon_assignments_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_update_taxon_assignments_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _update_taxon_assignments_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_update_taxon_assignments_submit');
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
                method_name => 'update_taxon_assignments',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method update_taxon_assignments",
            status_line => $self->{client}->status_line,
            method_name => 'update_taxon_assignments',
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
        warn "New client version available for installed_clients::GenomeFileUtilClient\n";
    }
    if ($sMajor == 0) {
        warn "installed_clients::GenomeFileUtilClient version is $svr_version. API subject to change.\n";
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
taxon_id - if defined, will try to link the Genome to the specified
    taxonomy id in lieu of performing the lookup during upload
release - Release or version number of the data
      per example Ensembl has numbered releases of all their data: Release 31
generate_ids_if_needed - If field used for feature id is not there,
      generate ids (default behavior is raising an exception)
genetic_code - Genetic code of organism. Overwrites determined GC from
      taxon object
scientific_name - will be used to set the scientific name of the genome
    and link to a taxon
generate_missing_genes - If the file has CDS or mRNA with no corresponding
    gene, generate a spoofed gene.
use_existing_assembly - Supply an existing assembly reference


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
taxon_wsname has a value which is a string
taxon_id has a value which is a string
release has a value which is a string
generate_ids_if_needed has a value which is a string
genetic_code has a value which is an int
scientific_name has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean
use_existing_assembly has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
taxon_wsname has a value which is a string
taxon_id has a value which is a string
release has a value which is a string
generate_ids_if_needed has a value which is a string
genetic_code has a value which is an int
scientific_name has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean
use_existing_assembly has a value which is a string


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
file_path has a value which is a string
from_cache has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file_path has a value which is a string
from_cache has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 MetagenomeToGFFParams

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
metagenome_ref has a value which is a string
ref_path_to_genome has a value which is a reference to a list where each element is a string
is_gtf has a value which is a GenomeFileUtil.boolean
target_dir has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
metagenome_ref has a value which is a string
ref_path_to_genome has a value which is a reference to a list where each element is a string
is_gtf has a value which is a GenomeFileUtil.boolean
target_dir has a value which is a string


=end text

=back



=head2 MetagenomeToGFFResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file_path has a value which is a string
from_cache has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file_path has a value which is a string
from_cache has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 MetagenomeSaveResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
metagenome_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
metagenome_ref has a value which is a string


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



=head2 GBFile

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file_path has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file_path has a value which is a string


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
genbank_file has a value which is a GenomeFileUtil.GBFile
from_cache has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genbank_file has a value which is a GenomeFileUtil.GBFile
from_cache has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 FASTAResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file_path has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file_path has a value which is a string


=end text

=back



=head2 GenomeFeaturesToFastaParams

=over 4



=item Description

Produce a FASTA file with the nucleotide sequences of features in a genome.

string genome_ref: reference to a genome object
list<string> feature_lists: Optional, which features lists (features, mrnas, cdss, non_coding_features) to provide sequences. Defaults to "features".
list<string> filter_ids: Optional, if provided only return sequences for matching features.
boolean include_functions: Optional, add function to header line. Defaults to True.
boolean include_aliases: Optional, add aliases to header line. Defaults to True.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_ref has a value which is a string
feature_lists has a value which is a reference to a list where each element is a string
filter_ids has a value which is a reference to a list where each element is a string
include_functions has a value which is a GenomeFileUtil.boolean
include_aliases has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_ref has a value which is a string
feature_lists has a value which is a reference to a list where each element is a string
filter_ids has a value which is a reference to a list where each element is a string
include_functions has a value which is a GenomeFileUtil.boolean
include_aliases has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 GenomeProteinToFastaParams

=over 4



=item Description

Produce a FASTA file with the protein sequences of CDSs in a genome.

string genome_ref: reference to a genome object
list<string> filter_ids: Optional, if provided only return sequences for matching features.
boolean include_functions: Optional, add function to header line. Defaults to True.
boolean include_aliases: Optional, add aliases to header line. Defaults to True.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_ref has a value which is a string
filter_ids has a value which is a reference to a list where each element is a string
include_functions has a value which is a GenomeFileUtil.boolean
include_aliases has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_ref has a value which is a string
filter_ids has a value which is a reference to a list where each element is a string
include_functions has a value which is a GenomeFileUtil.boolean
include_aliases has a value which is a GenomeFileUtil.boolean


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
taxon_id - if defined, will try to link the Genome to the specified
    taxonomy id in lieu of performing the lookup during upload
release - Release or version number of the data
      per example Ensembl has numbered releases of all their data: Release 31
genetic_code - Genetic code of organism. Overwrites determined GC from
      taxon object
scientific_name - will be used to set the scientific name of the genome
    and link to a taxon
generate_missing_genes - If the file has CDS or mRNA with no corresponding
    gene, generate a spoofed gene. Off by default
existing_assembly_ref - a KBase assembly upa, to associate the genome with.
    Avoids saving a new assembly when specified.


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
taxon_id has a value which is a string
release has a value which is a string
genetic_code has a value which is an int
scientific_name has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean
existing_assembly_ref has a value which is a string

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
taxon_id has a value which is a string
release has a value which is a string
genetic_code has a value which is an int
scientific_name has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean
existing_assembly_ref has a value which is a string


=end text

=back



=head2 FastaGFFToMetagenomeParams

=over 4



=item Description

genome_name - becomes the name of the object
workspace_name - the name of the workspace it gets saved to.
source - Source of the file typically something like RefSeq or Ensembl
taxon_ws_name - where the reference taxons are : ReferenceTaxons
taxon_id - if defined, will try to link the Genome to the specified
    taxonomy id in lieu of performing the lookup during upload
release - Release or version number of the data
      per example Ensembl has numbered releases of all their data: Release 31
genetic_code - Genetic code of organism. Overwrites determined GC from
      taxon object
scientific_name - will be used to set the scientific name of the genome
    and link to a taxon
generate_missing_genes - If the file has CDS or mRNA with no corresponding
    gene, generate a spoofed gene. Off by default
existing_assembly_ref - a KBase assembly upa, to associate the metagenome with.
    Avoids saving a new assembly when specified.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fasta_file has a value which is a GenomeFileUtil.File
gff_file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean
existing_assembly_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fasta_file has a value which is a GenomeFileUtil.File
gff_file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean
existing_assembly_ref has a value which is a string


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
upgrade has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a string
name has a value which is a string
data has a value which is a KBaseGenomes.Genome
hidden has a value which is a GenomeFileUtil.boolean
upgrade has a value which is a GenomeFileUtil.boolean


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



=head2 WsObjGFFToGenomeParams

=over 4



=item Description

gff_file - object containing path to gff_file
ws_ref - input Assembly or Genome reference

genome_name - becomes the name of the object
workspace_name - the name of the workspace it gets saved to.
source - Source of the file typically something like RefSeq or Ensembl
taxon_ws_name - where the reference taxons are : ReferenceTaxons
taxon_id - if defined, will try to link the Genome to the specified
    taxonomy id in lieu of performing the lookup during upload
release - Release or version number of the data
      per example Ensembl has numbered releases of all their data: Release 31
genetic_code - Genetic code of organism. Overwrites determined GC from
      taxon object
scientific_name - will be used to set the scientific name of the genome
    and link to a taxon
metadata - any user input metadata
generate_missing_genes - If the file has CDS or mRNA with no corresponding
    gene, generate a spoofed gene. Off by default


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_ref has a value which is a string
gff_file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
taxon_wsname has a value which is a string
taxon_id has a value which is a string
release has a value which is a string
genetic_code has a value which is an int
scientific_name has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_ref has a value which is a string
gff_file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
taxon_wsname has a value which is a string
taxon_id has a value which is a string
release has a value which is a string
genetic_code has a value which is an int
scientific_name has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 WsObjGFFToMetagenomeParams

=over 4



=item Description

gff_file - object containing path to gff_file
ws_ref - input Assembly or AnnotatedMetagenomeAssembly reference

genome_name - becomes the name of the object
workspace_name - the name of the workspace it gets saved to.
source - Source of the file typically something like RefSeq or Ensembl

genetic_code - Genetic code of organism. Overwrites determined GC from
      taxon object
metadata - any user input metadata
generate_missing_genes - If the file has CDS or mRNA with no corresponding
    gene, generate a spoofed gene. Off by default


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_ref has a value which is a string
gff_file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_ref has a value which is a string
gff_file has a value which is a GenomeFileUtil.File
genome_name has a value which is a string
workspace_name has a value which is a string
source has a value which is a string
metadata has a value which is a GenomeFileUtil.usermeta
generate_missing_genes has a value which is a GenomeFileUtil.boolean


=end text

=back



=head2 UpdateTaxonAssignmentsParams

=over 4



=item Description

Parameters for the update_taxon_assignments function.
Fields:
    workspace_id: a workspace UPA of a Genome object
    taxon_assignments: an optional mapping of assignments to add or replace. This will perform a
        merge on the existing assignments. Any new assignments are added, while any existing
        assignments are replaced.
    remove_assignments: an optional list of assignment names to remove.

@optional taxon_assignments remove_assignments


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_id has a value which is an int
object_id has a value which is an int
taxon_assignments has a value which is a reference to a hash where the key is a string and the value is a string
remove_assignments has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_id has a value which is an int
object_id has a value which is an int
taxon_assignments has a value which is a reference to a hash where the key is a string and the value is a string
remove_assignments has a value which is a reference to a list where each element is a string


=end text

=back



=head2 UpdateTaxonAssignmentsResult

=over 4



=item Description

Result of the update_taxon_assignments function.
Fields:
    ws_obj_ref: a workspace UPA of a Genome object


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_obj_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_obj_ref has a value which is a string


=end text

=back



=cut

package installed_clients::GenomeFileUtilClient::RpcClient;
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
