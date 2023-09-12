package installed_clients::RAST_SDKClient;

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

installed_clients::RAST_SDKClient

=head1 DESCRIPTION


The SDK version of the KBaase Genome Annotation Service.
This wraps genome_annotation which is based off of the SEED annotations.


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => installed_clients::RAST_SDKClient::RpcClient->new,
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
        method => "RAST_SDK._check_job",
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




=head2 annotate_genome

  $return = $obj->annotate_genome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RAST_SDK.AnnotateGenomeParams
$return is a RAST_SDK.AnnotateGenomeResults
AnnotateGenomeParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	input_genome has a value which is a RAST_SDK.genome_id
	input_contigset has a value which is a RAST_SDK.contigset_id
	genetic_code has a value which is an int
	domain has a value which is a string
	ncbi_taxon_id has a value which is an int
	relation_engine_timestamp_ms has a value which is an int
	scientific_name has a value which is a string
	output_genome has a value which is a string
	call_features_rRNA_SEED has a value which is a RAST_SDK.bool
	call_features_tRNA_trnascan has a value which is a RAST_SDK.bool
	call_selenoproteins has a value which is a RAST_SDK.bool
	call_pyrrolysoproteins has a value which is a RAST_SDK.bool
	call_features_repeat_region_SEED has a value which is a RAST_SDK.bool
	call_features_insertion_sequences has a value which is a RAST_SDK.bool
	call_features_strep_suis_repeat has a value which is a RAST_SDK.bool
	call_features_strep_pneumo_repeat has a value which is a RAST_SDK.bool
	call_features_crispr has a value which is a RAST_SDK.bool
	call_features_CDS_glimmer3 has a value which is a RAST_SDK.bool
	call_features_CDS_prodigal has a value which is a RAST_SDK.bool
	call_features_CDS_genemark has a value which is a RAST_SDK.bool
	annotate_proteins_kmer_v2 has a value which is a RAST_SDK.bool
	kmer_v1_parameters has a value which is a RAST_SDK.bool
	annotate_proteins_similarity has a value which is a RAST_SDK.bool
	resolve_overlapping_features has a value which is a RAST_SDK.bool
	call_features_prophage_phispy has a value which is a RAST_SDK.bool
	retain_old_anno_for_hypotheticals has a value which is a RAST_SDK.bool
genome_id is a string
contigset_id is a string
bool is an int
AnnotateGenomeResults is a reference to a hash where the following keys are defined:
	workspace has a value which is a RAST_SDK.workspace_name
	id has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string
workspace_name is a string

</pre>

=end html

=begin text

$params is a RAST_SDK.AnnotateGenomeParams
$return is a RAST_SDK.AnnotateGenomeResults
AnnotateGenomeParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	input_genome has a value which is a RAST_SDK.genome_id
	input_contigset has a value which is a RAST_SDK.contigset_id
	genetic_code has a value which is an int
	domain has a value which is a string
	ncbi_taxon_id has a value which is an int
	relation_engine_timestamp_ms has a value which is an int
	scientific_name has a value which is a string
	output_genome has a value which is a string
	call_features_rRNA_SEED has a value which is a RAST_SDK.bool
	call_features_tRNA_trnascan has a value which is a RAST_SDK.bool
	call_selenoproteins has a value which is a RAST_SDK.bool
	call_pyrrolysoproteins has a value which is a RAST_SDK.bool
	call_features_repeat_region_SEED has a value which is a RAST_SDK.bool
	call_features_insertion_sequences has a value which is a RAST_SDK.bool
	call_features_strep_suis_repeat has a value which is a RAST_SDK.bool
	call_features_strep_pneumo_repeat has a value which is a RAST_SDK.bool
	call_features_crispr has a value which is a RAST_SDK.bool
	call_features_CDS_glimmer3 has a value which is a RAST_SDK.bool
	call_features_CDS_prodigal has a value which is a RAST_SDK.bool
	call_features_CDS_genemark has a value which is a RAST_SDK.bool
	annotate_proteins_kmer_v2 has a value which is a RAST_SDK.bool
	kmer_v1_parameters has a value which is a RAST_SDK.bool
	annotate_proteins_similarity has a value which is a RAST_SDK.bool
	resolve_overlapping_features has a value which is a RAST_SDK.bool
	call_features_prophage_phispy has a value which is a RAST_SDK.bool
	retain_old_anno_for_hypotheticals has a value which is a RAST_SDK.bool
genome_id is a string
contigset_id is a string
bool is an int
AnnotateGenomeResults is a reference to a hash where the following keys are defined:
	workspace has a value which is a RAST_SDK.workspace_name
	id has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string
workspace_name is a string


=end text

=item Description

annotate genome
params - a param hash that includes the workspace id and options

=back

=cut

sub annotate_genome
{
    my($self, @args) = @_;
    my $job_id = $self->_annotate_genome_submit(@args);
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

sub _annotate_genome_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _annotate_genome_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _annotate_genome_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_annotate_genome_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "RAST_SDK._annotate_genome_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_annotate_genome_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _annotate_genome_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_annotate_genome_submit');
    }
}

 


=head2 annotate_genomes

  $return = $obj->annotate_genomes($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RAST_SDK.AnnotateGenomesParams
$return is a RAST_SDK.AnnotateGenomesResults
AnnotateGenomesParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	input_genomes has a value which is a reference to a list where each element is a RAST_SDK.GenomeParams
	genetic_code has a value which is an int
	domain has a value which is a string
	ncbi_taxon_id has a value which is an int
	relation_engine_timestamp_ms has a value which is an int
	scientific_name has a value which is a string
	genome_text has a value which is a string
	output_genome has a value which is a string
	call_features_rRNA_SEED has a value which is a RAST_SDK.bool
	call_features_tRNA_trnascan has a value which is a RAST_SDK.bool
	call_selenoproteins has a value which is a RAST_SDK.bool
	call_pyrrolysoproteins has a value which is a RAST_SDK.bool
	call_features_repeat_region_SEED has a value which is a RAST_SDK.bool
	call_features_insertion_sequences has a value which is a RAST_SDK.bool
	call_features_strep_suis_repeat has a value which is a RAST_SDK.bool
	call_features_strep_pneumo_repeat has a value which is a RAST_SDK.bool
	call_features_crispr has a value which is a RAST_SDK.bool
	call_features_CDS_glimmer3 has a value which is a RAST_SDK.bool
	call_features_CDS_prodigal has a value which is a RAST_SDK.bool
	call_features_CDS_genemark has a value which is a RAST_SDK.bool
	annotate_proteins_kmer_v2 has a value which is a RAST_SDK.bool
	kmer_v1_parameters has a value which is a RAST_SDK.bool
	annotate_proteins_similarity has a value which is a RAST_SDK.bool
	resolve_overlapping_features has a value which is a RAST_SDK.bool
	call_features_prophage_phispy has a value which is a RAST_SDK.bool
	retain_old_anno_for_hypotheticals has a value which is a RAST_SDK.bool
GenomeParams is a reference to a hash where the following keys are defined:
	input_contigset has a value which is a RAST_SDK.contigset_id
	input_genome has a value which is a RAST_SDK.genome_id
	output_genome has a value which is a RAST_SDK.genome_id
	genetic_code has a value which is an int
	domain has a value which is a string
	scientific_name has a value which is a string
contigset_id is a string
genome_id is a string
bool is an int
AnnotateGenomesResults is a reference to a hash where the following keys are defined:
	workspace has a value which is a RAST_SDK.workspace_name
	report_name has a value which is a string
	report_ref has a value which is a string
workspace_name is a string

</pre>

=end html

=begin text

$params is a RAST_SDK.AnnotateGenomesParams
$return is a RAST_SDK.AnnotateGenomesResults
AnnotateGenomesParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	input_genomes has a value which is a reference to a list where each element is a RAST_SDK.GenomeParams
	genetic_code has a value which is an int
	domain has a value which is a string
	ncbi_taxon_id has a value which is an int
	relation_engine_timestamp_ms has a value which is an int
	scientific_name has a value which is a string
	genome_text has a value which is a string
	output_genome has a value which is a string
	call_features_rRNA_SEED has a value which is a RAST_SDK.bool
	call_features_tRNA_trnascan has a value which is a RAST_SDK.bool
	call_selenoproteins has a value which is a RAST_SDK.bool
	call_pyrrolysoproteins has a value which is a RAST_SDK.bool
	call_features_repeat_region_SEED has a value which is a RAST_SDK.bool
	call_features_insertion_sequences has a value which is a RAST_SDK.bool
	call_features_strep_suis_repeat has a value which is a RAST_SDK.bool
	call_features_strep_pneumo_repeat has a value which is a RAST_SDK.bool
	call_features_crispr has a value which is a RAST_SDK.bool
	call_features_CDS_glimmer3 has a value which is a RAST_SDK.bool
	call_features_CDS_prodigal has a value which is a RAST_SDK.bool
	call_features_CDS_genemark has a value which is a RAST_SDK.bool
	annotate_proteins_kmer_v2 has a value which is a RAST_SDK.bool
	kmer_v1_parameters has a value which is a RAST_SDK.bool
	annotate_proteins_similarity has a value which is a RAST_SDK.bool
	resolve_overlapping_features has a value which is a RAST_SDK.bool
	call_features_prophage_phispy has a value which is a RAST_SDK.bool
	retain_old_anno_for_hypotheticals has a value which is a RAST_SDK.bool
GenomeParams is a reference to a hash where the following keys are defined:
	input_contigset has a value which is a RAST_SDK.contigset_id
	input_genome has a value which is a RAST_SDK.genome_id
	output_genome has a value which is a RAST_SDK.genome_id
	genetic_code has a value which is an int
	domain has a value which is a string
	scientific_name has a value which is a string
contigset_id is a string
genome_id is a string
bool is an int
AnnotateGenomesResults is a reference to a hash where the following keys are defined:
	workspace has a value which is a RAST_SDK.workspace_name
	report_name has a value which is a string
	report_ref has a value which is a string
workspace_name is a string


=end text

=item Description

annotate genomes
params - a param hash that includes the workspace id and options

=back

=cut

sub annotate_genomes
{
    my($self, @args) = @_;
    my $job_id = $self->_annotate_genomes_submit(@args);
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

sub _annotate_genomes_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _annotate_genomes_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _annotate_genomes_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_annotate_genomes_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "RAST_SDK._annotate_genomes_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_annotate_genomes_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _annotate_genomes_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_annotate_genomes_submit');
    }
}

 


=head2 annotate_proteins

  $return = $obj->annotate_proteins($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RAST_SDK.AnnotateProteinParams
$return is a RAST_SDK.AnnotateProteinResults
AnnotateProteinParams is a reference to a hash where the following keys are defined:
	proteins has a value which is a reference to a list where each element is a string
AnnotateProteinResults is a reference to a hash where the following keys are defined:
	functions has a value which is a reference to a list where each element is a reference to a list where each element is a string

</pre>

=end html

=begin text

$params is a RAST_SDK.AnnotateProteinParams
$return is a RAST_SDK.AnnotateProteinResults
AnnotateProteinParams is a reference to a hash where the following keys are defined:
	proteins has a value which is a reference to a list where each element is a string
AnnotateProteinResults is a reference to a hash where the following keys are defined:
	functions has a value which is a reference to a list where each element is a reference to a list where each element is a string


=end text

=item Description

annotate proteins - returns a list of the RAST annotations for the input protein sequences

=back

=cut

sub annotate_proteins
{
    my($self, @args) = @_;
    my $job_id = $self->_annotate_proteins_submit(@args);
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

sub _annotate_proteins_submit {
    my($self, @args) = @_;
# Authentication: none
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _annotate_proteins_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _annotate_proteins_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_annotate_proteins_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "RAST_SDK._annotate_proteins_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_annotate_proteins_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _annotate_proteins_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_annotate_proteins_submit');
    }
}

 


=head2 annotate_metagenome

  $output = $obj->annotate_metagenome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RAST_SDK.MetagenomeAnnotateParams
$output is a RAST_SDK.MetagenomeAnnotateOutput
MetagenomeAnnotateParams is a reference to a hash where the following keys are defined:
	object_ref has a value which is a RAST_SDK.data_obj_ref
	output_workspace has a value which is a string
	output_metagenome_name has a value which is a string
	create_report has a value which is a RAST_SDK.bool
data_obj_ref is a string
bool is an int
MetagenomeAnnotateOutput is a reference to a hash where the following keys are defined:
	output_metagenome_ref has a value which is a RAST_SDK.metagenome_ref
	output_workspace has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string
metagenome_ref is a string

</pre>

=end html

=begin text

$params is a RAST_SDK.MetagenomeAnnotateParams
$output is a RAST_SDK.MetagenomeAnnotateOutput
MetagenomeAnnotateParams is a reference to a hash where the following keys are defined:
	object_ref has a value which is a RAST_SDK.data_obj_ref
	output_workspace has a value which is a string
	output_metagenome_name has a value which is a string
	create_report has a value which is a RAST_SDK.bool
data_obj_ref is a string
bool is an int
MetagenomeAnnotateOutput is a reference to a hash where the following keys are defined:
	output_metagenome_ref has a value which is a RAST_SDK.metagenome_ref
	output_workspace has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string
metagenome_ref is a string


=end text

=item Description



=back

=cut

sub annotate_metagenome
{
    my($self, @args) = @_;
    my $job_id = $self->_annotate_metagenome_submit(@args);
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

sub _annotate_metagenome_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _annotate_metagenome_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _annotate_metagenome_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_annotate_metagenome_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "RAST_SDK._annotate_metagenome_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_annotate_metagenome_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _annotate_metagenome_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_annotate_metagenome_submit');
    }
}

 


=head2 annotate_metagenomes

  $output = $obj->annotate_metagenomes($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RAST_SDK.BulkAnnotateMetagenomesParams
$output is a RAST_SDK.BulkMetagenomesAnnotateOutput
BulkAnnotateMetagenomesParams is a reference to a hash where the following keys are defined:
	input_AMAs has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
	input_assemblies has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
	input_text has a value which is a string
	output_workspace has a value which is a string
	output_AMASet_name has a value which is a string
	create_report has a value which is a RAST_SDK.bool
data_obj_ref is a string
bool is an int
BulkMetagenomesAnnotateOutput is a reference to a hash where the following keys are defined:
	output_AMASet_ref has a value which is a RAST_SDK.data_obj_ref
	output_workspace has a value which is a string

</pre>

=end html

=begin text

$params is a RAST_SDK.BulkAnnotateMetagenomesParams
$output is a RAST_SDK.BulkMetagenomesAnnotateOutput
BulkAnnotateMetagenomesParams is a reference to a hash where the following keys are defined:
	input_AMAs has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
	input_assemblies has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
	input_text has a value which is a string
	output_workspace has a value which is a string
	output_AMASet_name has a value which is a string
	create_report has a value which is a RAST_SDK.bool
data_obj_ref is a string
bool is an int
BulkMetagenomesAnnotateOutput is a reference to a hash where the following keys are defined:
	output_AMASet_ref has a value which is a RAST_SDK.data_obj_ref
	output_workspace has a value which is a string


=end text

=item Description



=back

=cut

sub annotate_metagenomes
{
    my($self, @args) = @_;
    my $job_id = $self->_annotate_metagenomes_submit(@args);
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

sub _annotate_metagenomes_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _annotate_metagenomes_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _annotate_metagenomes_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_annotate_metagenomes_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "RAST_SDK._annotate_metagenomes_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_annotate_metagenomes_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _annotate_metagenomes_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_annotate_metagenomes_submit');
    }
}

 


=head2 rast_genome_assembly

  $output = $obj->rast_genome_assembly($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RAST_SDK.RastGenomeAssemblyParams
$output is a RAST_SDK.RastGenomeAssemblyOutput
RastGenomeAssemblyParams is a reference to a hash where the following keys are defined:
	object_ref has a value which is a RAST_SDK.data_obj_ref
	output_workspace has a value which is a string
	genetic_code has a value which is an int
	domain has a value which is a string
	ncbi_taxon_id has a value which is an int
	relation_engine_timestamp_ms has a value which is an int
	scientific_name has a value which is a string
	output_genome_name has a value which is a string
	create_report has a value which is a RAST_SDK.bool
data_obj_ref is a string
bool is an int
RastGenomeAssemblyOutput is a reference to a hash where the following keys are defined:
	output_genome_ref has a value which is a RAST_SDK.genome_id
	output_workspace has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string
genome_id is a string

</pre>

=end html

=begin text

$params is a RAST_SDK.RastGenomeAssemblyParams
$output is a RAST_SDK.RastGenomeAssemblyOutput
RastGenomeAssemblyParams is a reference to a hash where the following keys are defined:
	object_ref has a value which is a RAST_SDK.data_obj_ref
	output_workspace has a value which is a string
	genetic_code has a value which is an int
	domain has a value which is a string
	ncbi_taxon_id has a value which is an int
	relation_engine_timestamp_ms has a value which is an int
	scientific_name has a value which is a string
	output_genome_name has a value which is a string
	create_report has a value which is a RAST_SDK.bool
data_obj_ref is a string
bool is an int
RastGenomeAssemblyOutput is a reference to a hash where the following keys are defined:
	output_genome_ref has a value which is a RAST_SDK.genome_id
	output_workspace has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string
genome_id is a string


=end text

=item Description



=back

=cut

sub rast_genome_assembly
{
    my($self, @args) = @_;
    my $job_id = $self->_rast_genome_assembly_submit(@args);
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

sub _rast_genome_assembly_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _rast_genome_assembly_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _rast_genome_assembly_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_rast_genome_assembly_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "RAST_SDK._rast_genome_assembly_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_rast_genome_assembly_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _rast_genome_assembly_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_rast_genome_assembly_submit');
    }
}

 


=head2 rast_genomes_assemblies

  $output = $obj->rast_genomes_assemblies($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RAST_SDK.BulkRastGenomesAssembliesParams
$output is a RAST_SDK.BulkRastGenomesAssembliesOutput
BulkRastGenomesAssembliesParams is a reference to a hash where the following keys are defined:
	input_genomes has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
	input_assemblies has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
	input_genomeset has a value which is a RAST_SDK.genomeSet_ref
	input_text has a value which is a string
	scientific_name has a value which is a string
	genetic_code has a value which is an int
	domain has a value which is a string
	ncbi_taxon_id has a value which is an int
	relation_engine_timestamp_ms has a value which is an int
	output_workspace has a value which is a string
	output_GenomeSet_name has a value which is a string
data_obj_ref is a string
genomeSet_ref is a string
BulkRastGenomesAssembliesOutput is a reference to a hash where the following keys are defined:
	output_GenomeSet_ref has a value which is a RAST_SDK.genomeSet_ref
	output_workspace has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a RAST_SDK.BulkRastGenomesAssembliesParams
$output is a RAST_SDK.BulkRastGenomesAssembliesOutput
BulkRastGenomesAssembliesParams is a reference to a hash where the following keys are defined:
	input_genomes has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
	input_assemblies has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
	input_genomeset has a value which is a RAST_SDK.genomeSet_ref
	input_text has a value which is a string
	scientific_name has a value which is a string
	genetic_code has a value which is an int
	domain has a value which is a string
	ncbi_taxon_id has a value which is an int
	relation_engine_timestamp_ms has a value which is an int
	output_workspace has a value which is a string
	output_GenomeSet_name has a value which is a string
data_obj_ref is a string
genomeSet_ref is a string
BulkRastGenomesAssembliesOutput is a reference to a hash where the following keys are defined:
	output_GenomeSet_ref has a value which is a RAST_SDK.genomeSet_ref
	output_workspace has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

sub rast_genomes_assemblies
{
    my($self, @args) = @_;
    my $job_id = $self->_rast_genomes_assemblies_submit(@args);
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

sub _rast_genomes_assemblies_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _rast_genomes_assemblies_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _rast_genomes_assemblies_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_rast_genomes_assemblies_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "RAST_SDK._rast_genomes_assemblies_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_rast_genomes_assemblies_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _rast_genomes_assemblies_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_rast_genomes_assemblies_submit');
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
        method => "RAST_SDK._status_submit",
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
        method => "RAST_SDK.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'rast_genomes_assemblies',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method rast_genomes_assemblies",
            status_line => $self->{client}->status_line,
            method_name => 'rast_genomes_assemblies',
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
        warn "New client version available for installed_clients::RAST_SDKClient\n";
    }
    if ($sMajor == 0) {
        warn "installed_clients::RAST_SDKClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 bool

=over 4



=item Description

A binary boolean


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



=head2 genome_id

=over 4



=item Description

A string representing a genome id.


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



=head2 contigset_id

=over 4



=item Description

A string representing a ContigSet id.


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



=head2 workspace_name

=over 4



=item Description

A string representing a workspace name.


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



=head2 AnnotateGenomeParams

=over 4



=item Description

Parameters for the annotate_genome method.

                ncbi_taxon_id - the numeric ID of the NCBI taxon to which this genome belongs. If this
                        is included scientific_name is ignored.
                relation_engine_timestamp_ms - the timestamp to send to the Relation Engine when looking
                        up taxon information in milliseconds since the epoch.
                scientific_name - the scientific name of the genome. Overridden by ncbi_taxon_id.

                TODO: document remainder of parameters.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a string
input_genome has a value which is a RAST_SDK.genome_id
input_contigset has a value which is a RAST_SDK.contigset_id
genetic_code has a value which is an int
domain has a value which is a string
ncbi_taxon_id has a value which is an int
relation_engine_timestamp_ms has a value which is an int
scientific_name has a value which is a string
output_genome has a value which is a string
call_features_rRNA_SEED has a value which is a RAST_SDK.bool
call_features_tRNA_trnascan has a value which is a RAST_SDK.bool
call_selenoproteins has a value which is a RAST_SDK.bool
call_pyrrolysoproteins has a value which is a RAST_SDK.bool
call_features_repeat_region_SEED has a value which is a RAST_SDK.bool
call_features_insertion_sequences has a value which is a RAST_SDK.bool
call_features_strep_suis_repeat has a value which is a RAST_SDK.bool
call_features_strep_pneumo_repeat has a value which is a RAST_SDK.bool
call_features_crispr has a value which is a RAST_SDK.bool
call_features_CDS_glimmer3 has a value which is a RAST_SDK.bool
call_features_CDS_prodigal has a value which is a RAST_SDK.bool
call_features_CDS_genemark has a value which is a RAST_SDK.bool
annotate_proteins_kmer_v2 has a value which is a RAST_SDK.bool
kmer_v1_parameters has a value which is a RAST_SDK.bool
annotate_proteins_similarity has a value which is a RAST_SDK.bool
resolve_overlapping_features has a value which is a RAST_SDK.bool
call_features_prophage_phispy has a value which is a RAST_SDK.bool
retain_old_anno_for_hypotheticals has a value which is a RAST_SDK.bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a string
input_genome has a value which is a RAST_SDK.genome_id
input_contigset has a value which is a RAST_SDK.contigset_id
genetic_code has a value which is an int
domain has a value which is a string
ncbi_taxon_id has a value which is an int
relation_engine_timestamp_ms has a value which is an int
scientific_name has a value which is a string
output_genome has a value which is a string
call_features_rRNA_SEED has a value which is a RAST_SDK.bool
call_features_tRNA_trnascan has a value which is a RAST_SDK.bool
call_selenoproteins has a value which is a RAST_SDK.bool
call_pyrrolysoproteins has a value which is a RAST_SDK.bool
call_features_repeat_region_SEED has a value which is a RAST_SDK.bool
call_features_insertion_sequences has a value which is a RAST_SDK.bool
call_features_strep_suis_repeat has a value which is a RAST_SDK.bool
call_features_strep_pneumo_repeat has a value which is a RAST_SDK.bool
call_features_crispr has a value which is a RAST_SDK.bool
call_features_CDS_glimmer3 has a value which is a RAST_SDK.bool
call_features_CDS_prodigal has a value which is a RAST_SDK.bool
call_features_CDS_genemark has a value which is a RAST_SDK.bool
annotate_proteins_kmer_v2 has a value which is a RAST_SDK.bool
kmer_v1_parameters has a value which is a RAST_SDK.bool
annotate_proteins_similarity has a value which is a RAST_SDK.bool
resolve_overlapping_features has a value which is a RAST_SDK.bool
call_features_prophage_phispy has a value which is a RAST_SDK.bool
retain_old_anno_for_hypotheticals has a value which is a RAST_SDK.bool


=end text

=back



=head2 AnnotateGenomeResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a RAST_SDK.workspace_name
id has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a RAST_SDK.workspace_name
id has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 GenomeParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_contigset has a value which is a RAST_SDK.contigset_id
input_genome has a value which is a RAST_SDK.genome_id
output_genome has a value which is a RAST_SDK.genome_id
genetic_code has a value which is an int
domain has a value which is a string
scientific_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_contigset has a value which is a RAST_SDK.contigset_id
input_genome has a value which is a RAST_SDK.genome_id
output_genome has a value which is a RAST_SDK.genome_id
genetic_code has a value which is an int
domain has a value which is a string
scientific_name has a value which is a string


=end text

=back



=head2 AnnotateGenomesParams

=over 4



=item Description

Parameters for the annotate_genomes method.

                ncbi_taxon_id - the numeric ID of the NCBI taxon to which this genome belongs. If this
                        is included scientific_name is ignored.
                relation_engine_timestamp_ms - the timestamp to send to the Relation Engine when looking
                        up taxon information in milliseconds since the epoch.
                scientific_name - the scientific name of the genome. Overridden by ncbi_taxon_id.
                
                TODO: document remainder of parameters.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a string
input_genomes has a value which is a reference to a list where each element is a RAST_SDK.GenomeParams
genetic_code has a value which is an int
domain has a value which is a string
ncbi_taxon_id has a value which is an int
relation_engine_timestamp_ms has a value which is an int
scientific_name has a value which is a string
genome_text has a value which is a string
output_genome has a value which is a string
call_features_rRNA_SEED has a value which is a RAST_SDK.bool
call_features_tRNA_trnascan has a value which is a RAST_SDK.bool
call_selenoproteins has a value which is a RAST_SDK.bool
call_pyrrolysoproteins has a value which is a RAST_SDK.bool
call_features_repeat_region_SEED has a value which is a RAST_SDK.bool
call_features_insertion_sequences has a value which is a RAST_SDK.bool
call_features_strep_suis_repeat has a value which is a RAST_SDK.bool
call_features_strep_pneumo_repeat has a value which is a RAST_SDK.bool
call_features_crispr has a value which is a RAST_SDK.bool
call_features_CDS_glimmer3 has a value which is a RAST_SDK.bool
call_features_CDS_prodigal has a value which is a RAST_SDK.bool
call_features_CDS_genemark has a value which is a RAST_SDK.bool
annotate_proteins_kmer_v2 has a value which is a RAST_SDK.bool
kmer_v1_parameters has a value which is a RAST_SDK.bool
annotate_proteins_similarity has a value which is a RAST_SDK.bool
resolve_overlapping_features has a value which is a RAST_SDK.bool
call_features_prophage_phispy has a value which is a RAST_SDK.bool
retain_old_anno_for_hypotheticals has a value which is a RAST_SDK.bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a string
input_genomes has a value which is a reference to a list where each element is a RAST_SDK.GenomeParams
genetic_code has a value which is an int
domain has a value which is a string
ncbi_taxon_id has a value which is an int
relation_engine_timestamp_ms has a value which is an int
scientific_name has a value which is a string
genome_text has a value which is a string
output_genome has a value which is a string
call_features_rRNA_SEED has a value which is a RAST_SDK.bool
call_features_tRNA_trnascan has a value which is a RAST_SDK.bool
call_selenoproteins has a value which is a RAST_SDK.bool
call_pyrrolysoproteins has a value which is a RAST_SDK.bool
call_features_repeat_region_SEED has a value which is a RAST_SDK.bool
call_features_insertion_sequences has a value which is a RAST_SDK.bool
call_features_strep_suis_repeat has a value which is a RAST_SDK.bool
call_features_strep_pneumo_repeat has a value which is a RAST_SDK.bool
call_features_crispr has a value which is a RAST_SDK.bool
call_features_CDS_glimmer3 has a value which is a RAST_SDK.bool
call_features_CDS_prodigal has a value which is a RAST_SDK.bool
call_features_CDS_genemark has a value which is a RAST_SDK.bool
annotate_proteins_kmer_v2 has a value which is a RAST_SDK.bool
kmer_v1_parameters has a value which is a RAST_SDK.bool
annotate_proteins_similarity has a value which is a RAST_SDK.bool
resolve_overlapping_features has a value which is a RAST_SDK.bool
call_features_prophage_phispy has a value which is a RAST_SDK.bool
retain_old_anno_for_hypotheticals has a value which is a RAST_SDK.bool


=end text

=back



=head2 AnnotateGenomesResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a RAST_SDK.workspace_name
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a RAST_SDK.workspace_name
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 AnnotateProteinParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
proteins has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
proteins has a value which is a reference to a list where each element is a string


=end text

=back



=head2 AnnotateProteinResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
functions has a value which is a reference to a list where each element is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
functions has a value which is a reference to a list where each element is a reference to a list where each element is a string


=end text

=back



=head2 data_obj_ref

=over 4



=item Description

For RAST annotating metagenomes (borrowed and simplied from ProkkaAnnotation moduel)

Reference to an Assembly or Genome object in the workspace
@id ws KBaseGenomeAnnotations.Assembly
@id ws KBaseGenomes.Genome
@id ws KBaseMetagenomes.AnnotatedMetagenomeAssembly


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



=head2 metagenome_ref

=over 4



=item Description

Reference to a Annotated Metagenome Assembly object in the workspace
@id ws KBaseMetagenomes.AnnotatedMetagenomeAssembly


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



=head2 MetagenomeAnnotateParams

=over 4



=item Description

Required parameters:
    object_ref - reference to Assembly or Genome object,
    output_workspace - output workspace name,
    output_metagenome_name - output object name,


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
object_ref has a value which is a RAST_SDK.data_obj_ref
output_workspace has a value which is a string
output_metagenome_name has a value which is a string
create_report has a value which is a RAST_SDK.bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
object_ref has a value which is a RAST_SDK.data_obj_ref
output_workspace has a value which is a string
output_metagenome_name has a value which is a string
create_report has a value which is a RAST_SDK.bool


=end text

=back



=head2 MetagenomeAnnotateOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
output_metagenome_ref has a value which is a RAST_SDK.metagenome_ref
output_workspace has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
output_metagenome_ref has a value which is a RAST_SDK.metagenome_ref
output_workspace has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 BulkAnnotateMetagenomesParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_AMAs has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
input_assemblies has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
input_text has a value which is a string
output_workspace has a value which is a string
output_AMASet_name has a value which is a string
create_report has a value which is a RAST_SDK.bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_AMAs has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
input_assemblies has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
input_text has a value which is a string
output_workspace has a value which is a string
output_AMASet_name has a value which is a string
create_report has a value which is a RAST_SDK.bool


=end text

=back



=head2 BulkMetagenomesAnnotateOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
output_AMASet_ref has a value which is a RAST_SDK.data_obj_ref
output_workspace has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
output_AMASet_ref has a value which is a RAST_SDK.data_obj_ref
output_workspace has a value which is a string


=end text

=back



=head2 RastGenomeAssemblyParams

=over 4



=item Description

Required parameters for rast_genome_assembly:
    object_ref - reference to a Genome or Assembly object,
    output_workspace - output workspace name,
    output_genome_name - output object name

Optional parameters for rast_genome_assembly:
    ncbi_taxon_id - the numeric ID of the NCBI taxon to which this genome belongs. If this
                    is included scientific_name is ignored.
    relation_engine_timestamp_ms - the timestamp to send to the Relation Engine when looking
            up taxon information in milliseconds since the epoch.
    scientific_name - the scientific name of the genome. Overridden by ncbi_taxon_id.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
object_ref has a value which is a RAST_SDK.data_obj_ref
output_workspace has a value which is a string
genetic_code has a value which is an int
domain has a value which is a string
ncbi_taxon_id has a value which is an int
relation_engine_timestamp_ms has a value which is an int
scientific_name has a value which is a string
output_genome_name has a value which is a string
create_report has a value which is a RAST_SDK.bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
object_ref has a value which is a RAST_SDK.data_obj_ref
output_workspace has a value which is a string
genetic_code has a value which is an int
domain has a value which is a string
ncbi_taxon_id has a value which is an int
relation_engine_timestamp_ms has a value which is an int
scientific_name has a value which is a string
output_genome_name has a value which is a string
create_report has a value which is a RAST_SDK.bool


=end text

=back



=head2 RastGenomeAssemblyOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
output_genome_ref has a value which is a RAST_SDK.genome_id
output_workspace has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
output_genome_ref has a value which is a RAST_SDK.genome_id
output_workspace has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 genomeSet_ref

=over 4



=item Description

For RAST annotating genomes/assemblies
 
Reference to a set of annotated Genome and/or Assembly objects in the workspace
@id ws KBaseSearch.GenomeSet


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



=head2 BulkRastGenomesAssembliesParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_genomes has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
input_assemblies has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
input_genomeset has a value which is a RAST_SDK.genomeSet_ref
input_text has a value which is a string
scientific_name has a value which is a string
genetic_code has a value which is an int
domain has a value which is a string
ncbi_taxon_id has a value which is an int
relation_engine_timestamp_ms has a value which is an int
output_workspace has a value which is a string
output_GenomeSet_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_genomes has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
input_assemblies has a value which is a reference to a list where each element is a RAST_SDK.data_obj_ref
input_genomeset has a value which is a RAST_SDK.genomeSet_ref
input_text has a value which is a string
scientific_name has a value which is a string
genetic_code has a value which is an int
domain has a value which is a string
ncbi_taxon_id has a value which is an int
relation_engine_timestamp_ms has a value which is an int
output_workspace has a value which is a string
output_GenomeSet_name has a value which is a string


=end text

=back



=head2 BulkRastGenomesAssembliesOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
output_GenomeSet_ref has a value which is a RAST_SDK.genomeSet_ref
output_workspace has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
output_GenomeSet_ref has a value which is a RAST_SDK.genomeSet_ref
output_workspace has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=cut

package installed_clients::RAST_SDKClient::RpcClient;
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
