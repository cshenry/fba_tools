package Bio::ModelSEED::ProbModelSEED::ProbModelSEEDImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

ProbModelSEED

=head1 DESCRIPTION

=head1 ProbModelSEED

=cut

#BEGIN_HEADER

use JSON::XS;
use Data::Dumper;
use Config::Simple;
use Plack::Request;
use Bio::ModelSEED::ProbModelSEED::ProbModelSEEDHelper;

#
# Alias our context variable.
#
*Bio::ModelSEED::ProbModelSEED::ProbModelSEEDImpl::CallContext = *Bio::ModelSEED::ProbModelSEED::Service::CallContext;
our $CallContext;

#Returns the authentication token supplied to the service in the context object
sub token {
	my($self) = @_;
	return $CallContext->token;
}

#Returns the username supplied to the service in the context object
sub user_id {
	my ($self) = @_;
	return $CallContext->user_id;
}

sub workspace_url {
	my ($self) = @_;
	if (!defined($CallContext->{"_workspace-url"})) {
		return $self->config()->{"workspace-url"};
	}
	return $CallContext->{"_workspace-url"};
}

sub adminmode {
	my ($self) = @_;
	if (!defined($CallContext->{_adminmode})) {
		return 0;
	}
	return $CallContext->{_adminmode};
}

#Initialization function for call
sub initialize_call {
	my ($self,$params) = @_;
	Bio::KBase::ObjectAPI::utilities::elaspedtime();
	if (defined($params->{adminmode})) {
		$CallContext->{_adminmode} = $params->{adminmode};
	}
	if (defined($params->{wsurl})) {
		$CallContext->{"_workspace-url"} = $params->{wsurl};
	}
	return $params;
}

#Returns the method supplied to the service in the context object
sub current_method {
	my ($self) = @_;
	return $CallContext->method;
}

sub config {
	my ($self) = @_;
	return $self->{_config};
}

sub helper {
	my ($self) = @_;
	if (!defined($CallContext->{_helper})) {
		my $targets = [split(/;/,$self->config()->{cache_targets})];
		$CallContext->{_helper} = Bio::ModelSEED::ProbModelSEED::ProbModelSEEDHelper->new({
			token => $self->token(),
			username => $self->user_id(),
			fbajobcache => $self->config()->{fbajobcache},
    		fbajobdir => $self->config()->{fbajobdir},
    		mfatoolkitbin => $self->config()->{mfatoolkitbin},
			logfile => $self->config()->{logfile},
			data_api_url => $self->config()->{data_api_url},
			"workspace-url" => $self->workspace_url(),
			"shock-url" => $self->config()->{shock_url},
			adminmode => $self->adminmode(),
			method => $self->current_method(),
			file_cache => $self->config()->{file_cache},
			cache_targets => $targets,
			biochemistry => $self->config()->{biochemistry},
			default_media => $self->config()->{default_media},
			classifier => $self->config()->{classifier},
			template_dir => $self->config()->{template_dir}
		});
	}
	return $CallContext->{_helper};
}

sub _list_fba_studies {
	my ($self,$input) = @_;
	$input = $self->helper()->validate_args($input,["model"],{});
    $input->{model_meta} = $self->helper()->get_model_meta($input->{model});
    my $list = $self->helper()->workspace_service()->ls({
		paths => [$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/fba"],
		excludeDirectories => 1,
		excludeObjects => 0,
		recursive => 1,
		query => {type => "fba"}
	});
	my $output = {};
	if (defined($list->{$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/fba"})) {
		$list = $list->{$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/fba"};
		for (my $i=0; $i < @{$list}; $i++) {
			my $element = {
				rundate => $list->[$i]->[3],
				id => $list->[$i]->[0],
				"ref" => $list->[$i]->[2].$list->[$i]->[0],
				media_ref => $list->[$i]->[7]->{media},
				objective => $list->[$i]->[7]->{objective},
				objective_function => $list->[$i]->[8]->{objective_function},				
			};
			$output->{$list->[$i]->[0]} = $element;
		}
	}
	# Output is sorted by rundate (newest first).
	return $output;
}

sub _list_models {
	my ($self,$input) = @_;
	$input = $self->helper()->validate_args($input,[],{path => undef});
    my $list;
    my $output = {};
    if (defined($input->{path})) {
    	$list = [["",undef,$input->{path}]];
    } else {
    	$list = $self->helper()->workspace_service()->ls({
			paths => ["/".$self->user_id()."/"],
			adminmode => $self->adminmode()
		});
		if (!defined($list->{"/".$self->user_id()."/"})) {
			# Just return an empty list if there is no workspace for the user.
			return $output;
		}
		$list = $list->{"/".$self->user_id()."/"};
    }
	for (my $i=0; $i < @{$list}; $i++) {
		my $currentlist = $self->helper()->workspace_service()->ls({
			paths => [$list->[$i]->[2].$list->[$i]->[0]],
			excludeDirectories => 1,
			excludeObjects => 0,
			recursive => 1,
			query => {type => ["model","fba"]},
			adminmode => $self->adminmode()
		});
		if (defined($currentlist->{$list->[$i]->[2].$list->[$i]->[0]})) {
			$currentlist = $currentlist->{$list->[$i]->[2].$list->[$i]->[0]};
			my $newlist = [];
			my $fbalist = [];
			for (my $k=0; $k < @{$currentlist}; $k++) {
				if ($currentlist->[$k]->[1] eq "fba") {
					push(@{$fbalist},$currentlist->[$k]);
				} elsif ($currentlist->[$k]->[1] eq "model") {
					push(@{$newlist},$currentlist->[$k]);
				}
			}
			my $fbahash = {};
			for (my $k=0; $k < @{$fbalist}; $k++) {
				push(@{$fbahash->{$fbalist->[$k]->[2]}},$fbalist->[$k]); 
			}
			for (my $j=0; $j < @{$newlist}; $j++) {
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]} = $newlist->[$j]->[8];
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{rundate} = $newlist->[$j]->[3];
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{id} = $newlist->[$j]->[0];
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{"ref"} = $newlist->[$j]->[2].$newlist->[$j]->[0];
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{gene_associated_reactions} = ($output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{num_reactions} - 22);
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{gapfilled_reactions} = 0;
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{fba_count} = 0;
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{integrated_gapfills} = 0;
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{unintegrated_gapfills} = 0;
				if (defined($fbahash->{$newlist->[$j]->[2].".".$newlist->[$j]->[0]."/fba/"})) {
					$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{fba_count} = @{$fbahash->{$newlist->[$j]->[2].".".$newlist->[$j]->[0]."/fba/"}};
				}
				if (defined($fbahash->{$newlist->[$j]->[2].".".$newlist->[$j]->[0]."/gapfilling/"})) {
					for (my $k=0; $k < @{$fbahash->{$newlist->[$j]->[2].".".$newlist->[$j]->[0]."/gapfilling/"}}; $k++) {
						my $item = $fbahash->{$newlist->[$j]->[2].".".$newlist->[$j]->[0]."/gapfilling/"}->[$k];
						if ($item->[7]->{integrated} == 1) {
							$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{integrated_gapfills}++;
						} else {
							$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{unintegrated_gapfills}++;
						}
					}
				}
				delete $output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{reactions};
				delete $output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{genes};
				delete $output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{biomasses};		
				$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{num_biomass_compounds} = split(/\//,$output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{biomasscpds});
				delete $output->{$newlist->[$j]->[2].$newlist->[$j]->[0]}->{biomasscpds};
			}
		}
	}
	return $output;
}

sub _list_gapfill_solutions {
	my ($self,$input) = @_;
	$input = $self->helper()->validate_args($input,["model"],{include_meta => 0});
    $input->{model_meta} = $self->helper()->get_model_meta($input->{model});
    my $gflist = $self->helper()->workspace_service()->ls({
		paths => [$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/gapfilling"],
		excludeDirectories => 1,
		excludeObjects => 0,
		recursive => 1,
		query => {type => "fba"}
	});
	my $output = {};
	if (defined($gflist->{$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/gapfilling"})) {
		$gflist = $gflist->{$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/gapfilling"};
		for (my $i=0; $i < @{$gflist}; $i++) {
			my $id = $gflist->[$i]->[0];
			$output->{$id} = {
				rundate => $gflist->[$i]->[3],
				id => $id,
				"ref" => $gflist->[$i]->[2].$gflist->[$i]->[0],
				media_ref => $gflist->[$i]->[7]->{media},
				integrated => $gflist->[$i]->[7]->{integrated},
				integrated_solution => $gflist->[$i]->[7]->{integrated_solution},
				solution_reactions => []
			};
			if (defined($gflist->[$i]->[7]->{solutiondata})) {
				$output->{$id}->{solution_reactions} = Bio::KBase::ObjectAPI::utilities::FROMJSON($gflist->[$i]->[7]->{solutiondata});
				for (my $j=0; $j < @{$output->{$id}->{solution_reactions}}; $j++) {
					for (my $k=0; $k < @{$output->{$id}->{solution_reactions}->[$j]}; $k++) {
						my $comp = "c";
						if ($output->{$id}->{solution_reactions}->[$j]->[$k]->{compartment_ref} =~ m/\/([^\/]+)$/) {
							$comp = $1;
						}
						$output->{$id}->{solution_reactions}->[$j]->[$k] = {
							direction => $output->{$id}->{solution_reactions}->[$j]->[$k]->{direction},
							reaction => $output->{$id}->{solution_reactions}->[$j]->[$k]->{reaction_ref},
							compartment => $comp.$output->{$id}->{solution_reactions}->[$j]->[$k]->{compartmentIndex}
						};
					}
				}
			}
			if ($input->{include_meta}) {
				$output->{$id}->{metadata} = $gflist->[$i]->[7];
			}
		}
	}
	return $output;
}

sub _list_model_edits {
	my ($self,$input) = @_;
	$input = $self->helper()->validate_args($input,["model"],{});
    $input->{model_meta} = $self->helper()->get_model_meta($input->{model});
    my $list = $self->helper()->workspace_service()->ls({
		paths => [$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/edits"],
		excludeDirectories => 1,
		excludeObjects => 0,
		recursive => 1,
		query => {type => "model_edit"}
	});
	my $output = {};
	if (defined($list->{$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/edits"})) {
		$list = $list->{$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/edits"};
		for (my $i=0; $i < @{$list}; $i++) {
			my $data = Bio::KBase::ObjectAPI::utilities::FROMJSON($list->[$i]->[7]->{editdata});
			my $id = $list->[$i]->[0];
			$output->{$id} = {
				rundate => $list->[$i]->[3],
				integrated => $list->[$i]->[7]->{integrated},
				id => $id,
				"ref" => $list->[$i]->[2].$list->[$i]->[0],
				reactions_to_delete => $data->{reactions_to_delete},
				altered_directions => $data->{altered_directions},
				altered_gpr => $data->{altered_gpr},
				reactions_to_add => $data->{reactions_to_add},
				altered_biomass_compound => $data->{altered_biomass_compound}
			};
		}
	}
	return $output;
}

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    my $params = Bio::KBase::ObjectAPI::utilities::load_config({
    	service => "ProbModelSEED"
    });
    if (defined($args[0])) {
    	foreach my $key (keys(%{$args[0]})) {
    		$params->{$key} = $args[0]->{$key};
    	}
    }
	$params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["fbajobcache","fbajobdir","mfatoolkitbin"],{
		"workspace-url" => "http://p3.theseed.org/services/Workspace",
		"mssserver-url" => "http://bio-data-1.mcs.anl.gov/services/ms_fba",
	});
	print Data::Dumper->Dump([$params]);
	$self->{_config} = $params;
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 list_gapfill_solutions

  $output = $obj->list_gapfill_solutions($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a list_gapfill_solutions_params
$output is a reference to a list where each element is a gapfill_data
list_gapfill_solutions_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
gapfill_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a gapfill_id
	ref has a value which is a reference
	media_ref has a value which is a reference
	integrated has a value which is a bool
	integrated_solution has a value which is an int
	solution_reactions has a value which is a reference to a list where each element is a reference to a list where each element is a gapfill_reaction
Timestamp is a string
gapfill_id is a string
bool is an int
gapfill_reaction is a reference to a hash where the following keys are defined:
	reaction has a value which is a reference
	direction has a value which is a reaction_direction
	compartment has a value which is a string
reaction_direction is a string

</pre>

=end html

=begin text

$input is a list_gapfill_solutions_params
$output is a reference to a list where each element is a gapfill_data
list_gapfill_solutions_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
gapfill_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a gapfill_id
	ref has a value which is a reference
	media_ref has a value which is a reference
	integrated has a value which is a bool
	integrated_solution has a value which is an int
	solution_reactions has a value which is a reference to a list where each element is a reference to a list where each element is a gapfill_reaction
Timestamp is a string
gapfill_id is a string
bool is an int
gapfill_reaction is a reference to a hash where the following keys are defined:
	reaction has a value which is a reference
	direction has a value which is a reaction_direction
	compartment has a value which is a string
reaction_direction is a string


=end text



=item Description



=back

=cut

sub list_gapfill_solutions
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to list_gapfill_solutions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_gapfill_solutions');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN list_gapfill_solutions
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["model"],{});
	my $hash = $self->_list_gapfill_solutions($input);
	my $output = [];
	foreach my $key (keys(%{$hash})) {
		push(@{$output},$hash->{$key});
	}
    $output = [sort { $b->{rundate} cmp $a->{rundate} } @{$output}];
    #END list_gapfill_solutions
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_gapfill_solutions:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_gapfill_solutions');
    }
    return($output);
}




=head2 manage_gapfill_solutions

  $output = $obj->manage_gapfill_solutions($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a manage_gapfill_solutions_params
$output is a reference to a hash where the key is a gapfill_id and the value is a gapfill_data
manage_gapfill_solutions_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	commands has a value which is a reference to a hash where the key is a gapfill_id and the value is a gapfill_command
	selected_solutions has a value which is a reference to a hash where the key is a gapfill_id and the value is an int
reference is a string
gapfill_id is a string
gapfill_command is a string
gapfill_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a gapfill_id
	ref has a value which is a reference
	media_ref has a value which is a reference
	integrated has a value which is a bool
	integrated_solution has a value which is an int
	solution_reactions has a value which is a reference to a list where each element is a reference to a list where each element is a gapfill_reaction
Timestamp is a string
bool is an int
gapfill_reaction is a reference to a hash where the following keys are defined:
	reaction has a value which is a reference
	direction has a value which is a reaction_direction
	compartment has a value which is a string
reaction_direction is a string

</pre>

=end html

=begin text

$input is a manage_gapfill_solutions_params
$output is a reference to a hash where the key is a gapfill_id and the value is a gapfill_data
manage_gapfill_solutions_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	commands has a value which is a reference to a hash where the key is a gapfill_id and the value is a gapfill_command
	selected_solutions has a value which is a reference to a hash where the key is a gapfill_id and the value is an int
reference is a string
gapfill_id is a string
gapfill_command is a string
gapfill_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a gapfill_id
	ref has a value which is a reference
	media_ref has a value which is a reference
	integrated has a value which is a bool
	integrated_solution has a value which is an int
	solution_reactions has a value which is a reference to a list where each element is a reference to a list where each element is a gapfill_reaction
Timestamp is a string
bool is an int
gapfill_reaction is a reference to a hash where the following keys are defined:
	reaction has a value which is a reference
	direction has a value which is a reaction_direction
	compartment has a value which is a string
reaction_direction is a string


=end text



=item Description



=back

=cut

sub manage_gapfill_solutions
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to manage_gapfill_solutions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'manage_gapfill_solutions');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN manage_gapfill_solutions
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["model","commands"],{
    	selected_solutions => {},
    	include_meta => 1
    });
    my $gflist = $self->_list_gapfill_solutions($input);
    my $rmlist = [];
    my $updatelist = [];
    $output = {};
    foreach my $gf (keys(%{$input->{commands}})) {
    	if (defined($gflist->{$gf})) {
    		$output->{$gf} = $gflist->{$gf};
    		if (lc($input->{commands}->{$gf}) eq "d") {
    			$ctx->log_debug("Deleting gapfill ".$gflist->{$gf}->{"ref"});
    			push(@{$rmlist},$gflist->{$gf}->{"ref"});
    		} elsif (lc($input->{commands}->{$gf}) eq "i") {
    			if (!defined($input->{selected_solutions}->{$gf})) {
    				$input->{selected_solutions}->{$gf} = 0;
    			}
    			$ctx->log_debug("Integrating gapfill ".$gflist->{$gf}->{"ref"}." solution ".$input->{selected_solutions}->{$gf});
    			$output->{$gf}->{integrated} = 1;
    			$output->{$gf}->{integrated_solution} = $input->{selected_solutions}->{$gf};
    			push(@{$updatelist},[$gflist->{$gf}->{"ref"},{
    				integrated => 1,
    				integrated_solution => $input->{selected_solutions}->{$gf},
    				media => $gflist->{$gf}->{metadata}->{media},
    				solutiondata => $gflist->{$gf}->{metadata}->{solutiondata}
    			}]);
    		} elsif (lc($input->{commands}->{$gf}) eq "u") {
    			$ctx->log_debug("Unintegrating gapfill ".$gflist->{$gf}->{"ref"});
    			$output->{$gf}->{integrated} = 0;
    			$output->{$gf}->{integrated_solution} = -1;
    			push(@{$updatelist},[$gflist->{$gf}->{"ref"},{
    				integrated => 0,
    				integrated_solution => -1,
    				media => $gflist->{$gf}->{metadata}->{media},
    				solutiondata => $gflist->{$gf}->{metadata}->{solutiondata}
    			}]);
    		} else {
    			$self->helper()->error("Specified command ".$input->{commands}->{$gf}." is not supported!");
    		}
    		delete $output->{$gf}->{metadata};
    	} else {
    		$self->helper()->error("Specified gapfilling does not exist!");
    	}
    }
    if (@{$updatelist} > 0) {
	    $self->helper()->workspace_service()->update_metadata({
			objects => $updatelist,
			adminmode => $self->adminmode()
	    });
    }
    if (@{$rmlist} > 0) {
	    $self->helper()->workspace_service()->delete({
			objects => $rmlist,
			deleteDirectories => 1,
			force => 1,
			adminmode => $self->adminmode()
	    });
    }
    #END manage_gapfill_solutions
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to manage_gapfill_solutions:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'manage_gapfill_solutions');
    }
    return($output);
}




=head2 list_fba_studies

  $output = $obj->list_fba_studies($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a list_fba_studies_params
$output is a reference to a list where each element is a fba_data
list_fba_studies_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
fba_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a fba_id
	ref has a value which is a reference
	objective has a value which is a float
	media_ref has a value which is a reference
	objective_function has a value which is a string
Timestamp is a string
fba_id is a string

</pre>

=end html

=begin text

$input is a list_fba_studies_params
$output is a reference to a list where each element is a fba_data
list_fba_studies_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
fba_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a fba_id
	ref has a value which is a reference
	objective has a value which is a float
	media_ref has a value which is a reference
	objective_function has a value which is a string
Timestamp is a string
fba_id is a string


=end text



=item Description



=back

=cut

sub list_fba_studies
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to list_fba_studies:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_fba_studies');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN list_fba_studies
    $input = $self->initialize_call($input);
    my $hash = $self->_list_fba_studies($input);
	my $output = [];
	foreach my $key (keys(%{$hash})) {
		push(@{$output},$hash->{$key});
	}
    $output = [sort { $b->{rundate} cmp $a->{rundate} } @{$output}];
    #END list_fba_studies
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_fba_studies:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_fba_studies');
    }
    return($output);
}




=head2 delete_fba_studies

  $output = $obj->delete_fba_studies($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a delete_fba_studies_params
$output is a reference to a hash where the key is a fba_id and the value is a fba_data
delete_fba_studies_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	commands has a value which is a reference to a hash where the key is a gapfill_id and the value is a gapfill_command
reference is a string
gapfill_id is a string
gapfill_command is a string
fba_id is a string
fba_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a fba_id
	ref has a value which is a reference
	objective has a value which is a float
	media_ref has a value which is a reference
	objective_function has a value which is a string
Timestamp is a string

</pre>

=end html

=begin text

$input is a delete_fba_studies_params
$output is a reference to a hash where the key is a fba_id and the value is a fba_data
delete_fba_studies_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	commands has a value which is a reference to a hash where the key is a gapfill_id and the value is a gapfill_command
reference is a string
gapfill_id is a string
gapfill_command is a string
fba_id is a string
fba_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a fba_id
	ref has a value which is a reference
	objective has a value which is a float
	media_ref has a value which is a reference
	objective_function has a value which is a string
Timestamp is a string


=end text



=item Description



=back

=cut

sub delete_fba_studies
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to delete_fba_studies:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'delete_fba_studies');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN delete_fba_studies
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["model","fbas"],{});
    my $fbalist = $self->_list_fba_studies($input);
    my $rmlist = [];
    $output = {};
    for (my $i=0; $i < @{$input->{fbas}}; $i++) {
    	if (defined($fbalist->{$input->{fbas}->[$i]})) {
    		$output->{$input->{fbas}->[$i]} = $fbalist->{$input->{fbas}->[$i]};
    		push(@{$rmlist},$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/fba/".$input->{fbas}->[$i]);
    		push(@{$rmlist},$input->{model_meta}->[2].".".$input->{model_meta}->[0]."/fba/".$input->{fbas}->[$i].".fluxtbl");
    	} else {
    		$self->helper()->error("Specified FBA does not exist!");
    	}
    }
    if (@{$rmlist} > 0) {
	    $self->helper()->workspace_service()->delete({
			objects => $rmlist,
			deleteDirectories => 1,
			force => 1,
			adminmode => $self->adminmode()
	    });
    }
    #END delete_fba_studies
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to delete_fba_studies:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'delete_fba_studies');
    }
    return($output);
}




=head2 export_model

  $output = $obj->export_model($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is an export_model_params
$output is a string
export_model_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	format has a value which is a string
	to_shock has a value which is a bool
reference is a string
bool is an int

</pre>

=end html

=begin text

$input is an export_model_params
$output is a string
export_model_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	format has a value which is a string
	to_shock has a value which is a bool
reference is a string
bool is an int


=end text



=item Description



=back

=cut

sub export_model
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN export_model
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["model"],{
		format => "sbml",
		to_shock => 0
    });
    my $model = $self->helper()->get_model($input->{model});
    $output = $model->export({format => $input->{format}});
    if ($input->{to_shock} == 1) {
    	$output = $self->helper()->load_to_shock($output);
    }
    #END export_model
    my @_bad_returns;
    (!ref($output)) or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model');
    }
    return($output);
}




=head2 export_media

  $output = $obj->export_media($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is an export_media_params
$output is a string
export_media_params is a reference to a hash where the following keys are defined:
	media has a value which is a reference
	to_shock has a value which is a bool
reference is a string
bool is an int

</pre>

=end html

=begin text

$input is an export_media_params
$output is a string
export_media_params is a reference to a hash where the following keys are defined:
	media has a value which is a reference
	to_shock has a value which is a bool
reference is a string
bool is an int


=end text



=item Description



=back

=cut

sub export_media
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN export_media
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["media"],{
		to_shock => 0
    });
    my $media = $self->helper()->get_object($input->{media},"media");
    $output = "id\tname\tconcentration\tminflux\tmaxflux\n";
    my $mediacpds = $media->mediacompounds();
    for (my $i=0; $i < @{$mediacpds}; $i++) {
    	if ($mediacpds->[$i]->compound_ref() =~ m/(cpd\d+)$/) {
    		$output .= $1."\t".$mediacpds->[$i]->name()."\t".$mediacpds->[$i]->concentration()."\t".$mediacpds->[$i]->minFlux()."\t".$mediacpds->[$i]->maxFlux()."\n";
    	}    	
    }
    if ($input->{to_shock} == 1) {
    	$output = $self->helper()->load_to_shock($output);
    }
    #END export_media
    my @_bad_returns;
    (!ref($output)) or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_media:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media');
    }
    return($output);
}




=head2 get_model

  $output = $obj->get_model($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a get_model_params
$output is a model_data
get_model_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
model_data is a reference to a hash where the following keys are defined:
	ref has a value which is a reference
	reactions has a value which is a reference to a list where each element is a model_reaction
	compounds has a value which is a reference to a list where each element is a model_compound
	genes has a value which is a reference to a list where each element is a model_gene
	compartments has a value which is a reference to a list where each element is a model_compartment
	biomasses has a value which is a reference to a list where each element is a model_biomass
model_reaction is a reference to a hash where the following keys are defined:
	id has a value which is a reaction_id
	name has a value which is a string
	stoichiometry has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: (coefficient) a float
	1: (id) a compound_id
	2: (compartment) a compartment_id
	3: (compartment_index) an int
	4: (name) a string

	direction has a value which is a string
	gpr has a value which is a string
	genes has a value which is a reference to a list where each element is a gene_id
reaction_id is a string
compound_id is a string
compartment_id is a string
gene_id is a string
model_compound is a reference to a hash where the following keys are defined:
	id has a value which is a compound_id
	name has a value which is a string
	formula has a value which is a string
	charge has a value which is a float
model_gene is a reference to a hash where the following keys are defined:
	id has a value which is a gene_id
	reactions has a value which is a reference to a list where each element is a reaction_id
model_compartment is a reference to a hash where the following keys are defined:
	id has a value which is a compartment_id
	name has a value which is a string
	pH has a value which is a float
	potential has a value which is a float
model_biomass is a reference to a hash where the following keys are defined:
	id has a value which is a biomass_id
	compounds has a value which is a reference to a list where each element is a reference to a list containing 3 items:
	0: (compound) a compound_id
	1: (coefficient) a float
	2: (compartment) a compartment_id

biomass_id is a string

</pre>

=end html

=begin text

$input is a get_model_params
$output is a model_data
get_model_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
model_data is a reference to a hash where the following keys are defined:
	ref has a value which is a reference
	reactions has a value which is a reference to a list where each element is a model_reaction
	compounds has a value which is a reference to a list where each element is a model_compound
	genes has a value which is a reference to a list where each element is a model_gene
	compartments has a value which is a reference to a list where each element is a model_compartment
	biomasses has a value which is a reference to a list where each element is a model_biomass
model_reaction is a reference to a hash where the following keys are defined:
	id has a value which is a reaction_id
	name has a value which is a string
	stoichiometry has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: (coefficient) a float
	1: (id) a compound_id
	2: (compartment) a compartment_id
	3: (compartment_index) an int
	4: (name) a string

	direction has a value which is a string
	gpr has a value which is a string
	genes has a value which is a reference to a list where each element is a gene_id
reaction_id is a string
compound_id is a string
compartment_id is a string
gene_id is a string
model_compound is a reference to a hash where the following keys are defined:
	id has a value which is a compound_id
	name has a value which is a string
	formula has a value which is a string
	charge has a value which is a float
model_gene is a reference to a hash where the following keys are defined:
	id has a value which is a gene_id
	reactions has a value which is a reference to a list where each element is a reaction_id
model_compartment is a reference to a hash where the following keys are defined:
	id has a value which is a compartment_id
	name has a value which is a string
	pH has a value which is a float
	potential has a value which is a float
model_biomass is a reference to a hash where the following keys are defined:
	id has a value which is a biomass_id
	compounds has a value which is a reference to a list where each element is a reference to a list containing 3 items:
	0: (compound) a compound_id
	1: (coefficient) a float
	2: (compartment) a compartment_id

biomass_id is a string


=end text



=item Description



=back

=cut

sub get_model
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_model');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN get_model
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["model"],{to => 0});
    if ($input->{to} == 1) {
    	$output = $self->helper()->get_model($input->{model})->serializeToDB();
    } else {
    	$output = $self->helper()->get_model_data($input->{model});
    }
    #END get_model
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_model');
    }
    return($output);
}




=head2 delete_model

  $output = $obj->delete_model($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a delete_model_params
$output is an ObjectMeta
delete_model_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
ObjectMeta is a reference to a list containing 12 items:
	0: an ObjectName
	1: an ObjectType
	2: a FullObjectPath
	3: (creation_time) a Timestamp
	4: an ObjectID
	5: (object_owner) a Username
	6: an ObjectSize
	7: a UserMetadata
	8: an AutoMetadata
	9: (user_permission) a WorkspacePerm
	10: (global_permission) a WorkspacePerm
	11: (shockurl) a string
ObjectName is a string
ObjectType is a string
FullObjectPath is a string
Timestamp is a string
ObjectID is a string
Username is a string
ObjectSize is an int
UserMetadata is a reference to a hash where the key is a string and the value is a string
AutoMetadata is a reference to a hash where the key is a string and the value is a string
WorkspacePerm is a string

</pre>

=end html

=begin text

$input is a delete_model_params
$output is an ObjectMeta
delete_model_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
ObjectMeta is a reference to a list containing 12 items:
	0: an ObjectName
	1: an ObjectType
	2: a FullObjectPath
	3: (creation_time) a Timestamp
	4: an ObjectID
	5: (object_owner) a Username
	6: an ObjectSize
	7: a UserMetadata
	8: an AutoMetadata
	9: (user_permission) a WorkspacePerm
	10: (global_permission) a WorkspacePerm
	11: (shockurl) a string
ObjectName is a string
ObjectType is a string
FullObjectPath is a string
Timestamp is a string
ObjectID is a string
Username is a string
ObjectSize is an int
UserMetadata is a reference to a hash where the key is a string and the value is a string
AutoMetadata is a reference to a hash where the key is a string and the value is a string
WorkspacePerm is a string


=end text



=item Description



=back

=cut

sub delete_model
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to delete_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'delete_model');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN delete_model
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["model"],{});
    $output = $self->helper()->delete_model($input->{model});
    #END delete_model
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to delete_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'delete_model');
    }
    return($output);
}




=head2 list_models

  $output = $obj->list_models($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a list_models_params
$output is a reference to a list where each element is a ModelStats
list_models_params is a reference to a hash where the following keys are defined:
	path has a value which is a reference
reference is a string
ModelStats is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a string
	source has a value which is a string
	source_id has a value which is a string
	name has a value which is a string
	type has a value which is a string
	ref has a value which is a reference
	genome_ref has a value which is a reference
	template_ref has a value which is a reference
	fba_count has a value which is an int
	integrated_gapfills has a value which is an int
	unintegrated_gapfills has a value which is an int
	gene_associated_reactions has a value which is an int
	gapfilled_reactions has a value which is an int
	num_genes has a value which is an int
	num_compounds has a value which is an int
	num_reactions has a value which is an int
	num_biomasses has a value which is an int
	num_biomass_compounds has a value which is an int
	num_compartments has a value which is an int
Timestamp is a string

</pre>

=end html

=begin text

$input is a list_models_params
$output is a reference to a list where each element is a ModelStats
list_models_params is a reference to a hash where the following keys are defined:
	path has a value which is a reference
reference is a string
ModelStats is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a string
	source has a value which is a string
	source_id has a value which is a string
	name has a value which is a string
	type has a value which is a string
	ref has a value which is a reference
	genome_ref has a value which is a reference
	template_ref has a value which is a reference
	fba_count has a value which is an int
	integrated_gapfills has a value which is an int
	unintegrated_gapfills has a value which is an int
	gene_associated_reactions has a value which is an int
	gapfilled_reactions has a value which is an int
	num_genes has a value which is an int
	num_compounds has a value which is an int
	num_reactions has a value which is an int
	num_biomasses has a value which is an int
	num_biomass_compounds has a value which is an int
	num_compartments has a value which is an int
Timestamp is a string


=end text



=item Description



=back

=cut

sub list_models
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to list_models:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_models');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN list_models
    $input = $self->initialize_call($input);
    my $hash = $self->_list_models($input);
	my $output = [];
	foreach my $key (keys(%{$hash})) {
		push(@{$output},$hash->{$key});
	}
    $output = [sort { $b->{rundate} cmp $a->{rundate} } @{$output}];
    #END list_models
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_models:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_models');
    }
    return($output);
}




=head2 copy_model

  $output = $obj->copy_model($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a copy_model_params
$output is a ModelStats
copy_model_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	destination has a value which is a reference
	destname has a value which is a string
	copy_genome has a value which is a bool
	to_kbase has a value which is a bool
	workspace_url has a value which is a string
	kbase_username has a value which is a string
	kbase_password has a value which is a string
	plantseed has a value which is a bool
reference is a string
bool is an int
ModelStats is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a string
	source has a value which is a string
	source_id has a value which is a string
	name has a value which is a string
	type has a value which is a string
	ref has a value which is a reference
	genome_ref has a value which is a reference
	template_ref has a value which is a reference
	fba_count has a value which is an int
	integrated_gapfills has a value which is an int
	unintegrated_gapfills has a value which is an int
	gene_associated_reactions has a value which is an int
	gapfilled_reactions has a value which is an int
	num_genes has a value which is an int
	num_compounds has a value which is an int
	num_reactions has a value which is an int
	num_biomasses has a value which is an int
	num_biomass_compounds has a value which is an int
	num_compartments has a value which is an int
Timestamp is a string

</pre>

=end html

=begin text

$input is a copy_model_params
$output is a ModelStats
copy_model_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	destination has a value which is a reference
	destname has a value which is a string
	copy_genome has a value which is a bool
	to_kbase has a value which is a bool
	workspace_url has a value which is a string
	kbase_username has a value which is a string
	kbase_password has a value which is a string
	plantseed has a value which is a bool
reference is a string
bool is an int
ModelStats is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a string
	source has a value which is a string
	source_id has a value which is a string
	name has a value which is a string
	type has a value which is a string
	ref has a value which is a reference
	genome_ref has a value which is a reference
	template_ref has a value which is a reference
	fba_count has a value which is an int
	integrated_gapfills has a value which is an int
	unintegrated_gapfills has a value which is an int
	gene_associated_reactions has a value which is an int
	gapfilled_reactions has a value which is an int
	num_genes has a value which is an int
	num_compounds has a value which is an int
	num_reactions has a value which is an int
	num_biomasses has a value which is an int
	num_biomass_compounds has a value which is an int
	num_compartments has a value which is an int
Timestamp is a string


=end text



=item Description



=back

=cut

sub copy_model
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to copy_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'copy_model');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN copy_model
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["model"],{
    	destination => undef,
    	destname => undef,
		plantseed => 0,
		copy_genome => 1,
		to_kbase => 0,
		workspace_url => undef,
		kbase_username => undef,
		kbase_password => undef,
		kbase_token => undef
    });
    $output = $self->helper()->copy_model($input);
    #END copy_model
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to copy_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'copy_model');
    }
    return($output);
}




=head2 copy_genome

  $output = $obj->copy_genome($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a copy_genome_params
$output is an ObjectMeta
copy_genome_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
	destination has a value which is a reference
	destname has a value which is a string
	to_kbase has a value which is a bool
	workspace_url has a value which is a string
	kbase_username has a value which is a string
	kbase_password has a value which is a string
	plantseed has a value which is a bool
reference is a string
bool is an int
ObjectMeta is a reference to a list containing 12 items:
	0: an ObjectName
	1: an ObjectType
	2: a FullObjectPath
	3: (creation_time) a Timestamp
	4: an ObjectID
	5: (object_owner) a Username
	6: an ObjectSize
	7: a UserMetadata
	8: an AutoMetadata
	9: (user_permission) a WorkspacePerm
	10: (global_permission) a WorkspacePerm
	11: (shockurl) a string
ObjectName is a string
ObjectType is a string
FullObjectPath is a string
Timestamp is a string
ObjectID is a string
Username is a string
ObjectSize is an int
UserMetadata is a reference to a hash where the key is a string and the value is a string
AutoMetadata is a reference to a hash where the key is a string and the value is a string
WorkspacePerm is a string

</pre>

=end html

=begin text

$input is a copy_genome_params
$output is an ObjectMeta
copy_genome_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
	destination has a value which is a reference
	destname has a value which is a string
	to_kbase has a value which is a bool
	workspace_url has a value which is a string
	kbase_username has a value which is a string
	kbase_password has a value which is a string
	plantseed has a value which is a bool
reference is a string
bool is an int
ObjectMeta is a reference to a list containing 12 items:
	0: an ObjectName
	1: an ObjectType
	2: a FullObjectPath
	3: (creation_time) a Timestamp
	4: an ObjectID
	5: (object_owner) a Username
	6: an ObjectSize
	7: a UserMetadata
	8: an AutoMetadata
	9: (user_permission) a WorkspacePerm
	10: (global_permission) a WorkspacePerm
	11: (shockurl) a string
ObjectName is a string
ObjectType is a string
FullObjectPath is a string
Timestamp is a string
ObjectID is a string
Username is a string
ObjectSize is an int
UserMetadata is a reference to a hash where the key is a string and the value is a string
AutoMetadata is a reference to a hash where the key is a string and the value is a string
WorkspacePerm is a string


=end text



=item Description



=back

=cut

sub copy_genome
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to copy_genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'copy_genome');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN copy_genome
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["genome"],{
    	destination => undef,
		destname => undef,
		plantseed => 0,
		to_kbase => 0,
		workspace_url => undef,
		kbase_username => undef,
		kbase_password => undef,
		kbase_token => undef
    });
    $output = $self->helper()->copy_genome($input);
    #END copy_genome
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to copy_genome:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'copy_genome');
    }
    return($output);
}




=head2 list_model_edits

  $output = $obj->list_model_edits($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a list_model_edits_params
$output is a reference to a list where each element is an edit_data
list_model_edits_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
edit_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is an edit_id
	ref has a value which is a reference
	reactions_to_delete has a value which is a reference to a list where each element is a reaction_id
	altered_directions has a value which is a reference to a hash where the key is a reaction_id and the value is a reaction_direction
	altered_gpr has a value which is a reference to a hash where the key is a reaction_id and the value is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
	reactions_to_add has a value which is a reference to a list where each element is an edit_reaction
	altered_biomass_compound has a value which is a reference to a hash where the key is a compound_id and the value is a reference to a list containing 2 items:
	0: a float
	1: a compartment_id

Timestamp is a string
edit_id is a string
reaction_id is a string
reaction_direction is a string
feature_id is a string
edit_reaction is a reference to a hash where the following keys are defined:
	id has a value which is a reaction_id
	reagents has a value which is a reference to a list where each element is a reference to a list containing 3 items:
	0: (compound) a string
	1: (coefficient) a float
	2: (compartment) a string

	gpr has a value which is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
	direction has a value which is a reaction_direction
compound_id is a string
compartment_id is a string

</pre>

=end html

=begin text

$input is a list_model_edits_params
$output is a reference to a list where each element is an edit_data
list_model_edits_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
edit_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is an edit_id
	ref has a value which is a reference
	reactions_to_delete has a value which is a reference to a list where each element is a reaction_id
	altered_directions has a value which is a reference to a hash where the key is a reaction_id and the value is a reaction_direction
	altered_gpr has a value which is a reference to a hash where the key is a reaction_id and the value is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
	reactions_to_add has a value which is a reference to a list where each element is an edit_reaction
	altered_biomass_compound has a value which is a reference to a hash where the key is a compound_id and the value is a reference to a list containing 2 items:
	0: a float
	1: a compartment_id

Timestamp is a string
edit_id is a string
reaction_id is a string
reaction_direction is a string
feature_id is a string
edit_reaction is a reference to a hash where the following keys are defined:
	id has a value which is a reaction_id
	reagents has a value which is a reference to a list where each element is a reference to a list containing 3 items:
	0: (compound) a string
	1: (coefficient) a float
	2: (compartment) a string

	gpr has a value which is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
	direction has a value which is a reaction_direction
compound_id is a string
compartment_id is a string


=end text



=item Description



=back

=cut

sub list_model_edits
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to list_model_edits:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_model_edits');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN list_model_edits
    $input = $self->initialize_call($input);
    my $hash = $self->_list_model_edits($input);
	my $output = [];
	foreach my $key (keys(%{$hash})) {
		push(@{$output},$hash->{$key});
	}
    $output = [sort { $b->{rundate} cmp $a->{rundate} } @{$output}];
    #END list_model_edits
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_model_edits:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_model_edits');
    }
    return($output);
}




=head2 manage_model_edits

  $output = $obj->manage_model_edits($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a manage_model_edits_params
$output is a reference to a hash where the key is an edit_id and the value is an edit_data
manage_model_edits_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	commands has a value which is a reference to a hash where the key is an edit_id and the value is a gapfill_command
	new_edit has a value which is an edit_data
reference is a string
edit_id is a string
gapfill_command is a string
edit_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is an edit_id
	ref has a value which is a reference
	reactions_to_delete has a value which is a reference to a list where each element is a reaction_id
	altered_directions has a value which is a reference to a hash where the key is a reaction_id and the value is a reaction_direction
	altered_gpr has a value which is a reference to a hash where the key is a reaction_id and the value is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
	reactions_to_add has a value which is a reference to a list where each element is an edit_reaction
	altered_biomass_compound has a value which is a reference to a hash where the key is a compound_id and the value is a reference to a list containing 2 items:
	0: a float
	1: a compartment_id

Timestamp is a string
reaction_id is a string
reaction_direction is a string
feature_id is a string
edit_reaction is a reference to a hash where the following keys are defined:
	id has a value which is a reaction_id
	reagents has a value which is a reference to a list where each element is a reference to a list containing 3 items:
	0: (compound) a string
	1: (coefficient) a float
	2: (compartment) a string

	gpr has a value which is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
	direction has a value which is a reaction_direction
compound_id is a string
compartment_id is a string

</pre>

=end html

=begin text

$input is a manage_model_edits_params
$output is a reference to a hash where the key is an edit_id and the value is an edit_data
manage_model_edits_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
	commands has a value which is a reference to a hash where the key is an edit_id and the value is a gapfill_command
	new_edit has a value which is an edit_data
reference is a string
edit_id is a string
gapfill_command is a string
edit_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is an edit_id
	ref has a value which is a reference
	reactions_to_delete has a value which is a reference to a list where each element is a reaction_id
	altered_directions has a value which is a reference to a hash where the key is a reaction_id and the value is a reaction_direction
	altered_gpr has a value which is a reference to a hash where the key is a reaction_id and the value is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
	reactions_to_add has a value which is a reference to a list where each element is an edit_reaction
	altered_biomass_compound has a value which is a reference to a hash where the key is a compound_id and the value is a reference to a list containing 2 items:
	0: a float
	1: a compartment_id

Timestamp is a string
reaction_id is a string
reaction_direction is a string
feature_id is a string
edit_reaction is a reference to a hash where the following keys are defined:
	id has a value which is a reaction_id
	reagents has a value which is a reference to a list where each element is a reference to a list containing 3 items:
	0: (compound) a string
	1: (coefficient) a float
	2: (compartment) a string

	gpr has a value which is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
	direction has a value which is a reaction_direction
compound_id is a string
compartment_id is a string


=end text



=item Description



=back

=cut

sub manage_model_edits
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to manage_model_edits:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'manage_model_edits');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN manage_model_edits
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["model","commands"],{
    	new_edit => {}
    });
    my $list = $self->_list_model_edits($input);
    my $rmlist = [];
    my $updatelist = [];
    $output = {};
    foreach my $edit (keys(%{$input->{commands}})) {
    	if (defined($list->{$edit})) {
    		$output->{$edit} = $list->{$edit};
    		if (lc($input->{commands}->{$edit}) eq "d") {
    			push(@{$rmlist},$input->{model_meta}->[2]."edits/".$edit.".model_edit");
    		} elsif (lc($input->{commands}->{$edit}) eq "i") {
    			$output->{$edit}->{integrated} = 1;
    			push(@{$updatelist},[$input->{model_meta}->[2]."edits/".$edit.".model_edit",{
    				integrated => 1,
    			}]);
    		} elsif (lc($input->{commands}->{$edit}) eq "u") {
    			$output->{$edit}->{integrated} = 0;
    			push(@{$updatelist},[$input->{model_meta}->[2]."edits/".$edit.".model_edit",{
    				integrated => 0,
    			}]);
    		}
    	} else {
    		$self->helper()->error("Specified edit does not exist!");
    	}
    }
    if (@{$updatelist} > 0) {
	    $self->helper()->workspace_service()->update_metadata({
			objects => $updatelist,
			adminmode => $self->adminmode()
	    });
    }
    if (@{$rmlist} > 0) {
	    $self->helper()->workspace_service()->delete({
			objects => $rmlist,
			deleteDirectories => 1,
			force => 1,
			adminmode => $self->adminmode()
	    });
    }
    if (defined($input->{new_edit})) {
    	my $editmeta = {
    		integrated => 1,
    	};
    	my $editobj = $self->helper()->validate_args($input->{new_edit},["id"],{
	    	reactions_to_delete => [],
	    	altered_directions => {},
	    	altered_gpr => {},
	    	reactions_to_add => [],
	    	altered_biomass_compound => {}
	    });
	    $editmeta->{editdata} = Bio::KBase::ObjectAPI::utilities::TOJSON($editobj);
    	$self->helper()->workspace_service()->create({
    		objects => [[
    			$input->{model_meta}->[2]."edits/".$input->{new_edit}->{id}.".model_edit",
    			"model_edit",
    			$editmeta,
    			$editobj
    		]],
    		overwrite => 1,
    		adminmode => $self->adminmode()
    	});
    	$output->{$editobj->{id}} = $editobj;
    };
    #END manage_model_edits
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to manage_model_edits:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'manage_model_edits');
    }
    return($output);
}




=head2 get_feature

  $output = $obj->get_feature($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a get_feature_params
$output is a feature_data
get_feature_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
	feature has a value which is a feature_id
reference is a string
feature_id is a string
feature_data is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	function has a value which is a string
	protein_translation has a value which is a string
	subsystems has a value which is a reference to a list where each element is a string
	plant_similarities has a value which is a reference to a list where each element is a similarity
	prokaryotic_similarities has a value which is a reference to a list where each element is a similarity
similarity is a reference to a hash where the following keys are defined:
	hit_id has a value which is a string
	percent_id has a value which is a float
	e_value has a value which is a float
	bit_score has a value which is an int

</pre>

=end html

=begin text

$input is a get_feature_params
$output is a feature_data
get_feature_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
	feature has a value which is a feature_id
reference is a string
feature_id is a string
feature_data is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	function has a value which is a string
	protein_translation has a value which is a string
	subsystems has a value which is a reference to a list where each element is a string
	plant_similarities has a value which is a reference to a list where each element is a similarity
	prokaryotic_similarities has a value which is a reference to a list where each element is a similarity
similarity is a reference to a hash where the following keys are defined:
	hit_id has a value which is a string
	percent_id has a value which is a float
	e_value has a value which is a float
	bit_score has a value which is an int


=end text



=item Description



=back

=cut

sub get_feature
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_feature:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_feature');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN get_feature
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["genome","feature"],{});

    my $genome = $self->helper()->get_object($input->{genome},"genome");
    if(!$genome){
	$self->helper()->error("Genome not found using reference ".$input->{genome}."!");
    }

    my $output=undef;
    foreach my $ftr (@{$genome->{features}}){
	if($ftr->{data}{id} eq $input->{feature}){
	    $output = $ftr->{data};
	}
    }

    #Retrieve details for plants
    my $ftr_lu = $self->helper()->get_object("/plantseed/Genomes/feature_lookup","unspecified");
    $ftr_lu = Bio::KBase::ObjectAPI::utilities::FROMJSON($ftr_lu);

    $output->{subsystems} = [keys %{$ftr_lu->{$output->{id}}{'subsystems'}}];
    $output->{aliases}={'SEED' => $ftr_lu->{$output->{id}}{'seed'}};
    $output->{aliases}{'transcript'} = $ftr_lu->{$output->{id}}{'transcript'} if exists($ftr_lu->{$output->{id}}{'transcript'});

    if(!$output){
	$self->helper()->error("Feature (".$input->{feature}.") not found in genome!");
    }

    #Retrieve Minimal Genome object (unspecified type)
    my @path = split(/\//, $input->{genome});
    my $genome = pop @path;
    my $root = join("/",@path)."/";
    my $min_genome = $root.".".$genome."/minimal_genome";

    $min_genome = $self->helper()->get_object($min_genome,"unspecified");
    $min_genome = Bio::KBase::ObjectAPI::utilities::FROMJSON($min_genome);

    #Retrieve sims object containing hits for feature
    my $sim_index = $min_genome->{similarities_index}{$input->{feature}};
    $output->{plant_similarities}=[];
    $output->{prokaryotic_similarities}=[];
    if(!defined($sim_index)){
	print STDERR ("Feature (".$input->{feature}.") doesn't have a sims index in minimal genome!\n");
	return $output;
    }

    my $sim_file = $root.".".$genome."/Sims_".$sim_index;
    $sim_file = $self->helper()->get_object($sim_file,"unspecified");
    $sim_file = Bio::KBase::ObjectAPI::utilities::FROMJSON($sim_file);
    
    #Iterate through hits and separate them out into plant and prokaryote hits
    #By rule, prokaryote hits still have their peg identifiers and plants dont
    #percent_id|hit_id|bit_score|e_value
    my ($plant_count,$prokaryotic_count)=(0,0);
    foreach my $hit (@{$sim_file->{$input->{feature}}}){
	last if $plant_count>=10 && $prokaryotic_count>=10;

	if($hit->{hit_id} =~ /^fig\|\d+\.\d+\.peg\.\d+/ && $prokaryotic_count<10){
	    push(@{$output->{prokaryotic_similarities}},$hit);
	    $prokaryotic_count++;
	}elsif($plant_count<10){
	    push(@{$output->{plant_similarities}},$hit);
	    $plant_count++;
	}
    }

    my @Plants = @{$output->{plant_similarities}};
    undef(@{$output->{plant_similarities}});
    foreach my $plant ( @Plants ){
	my $Obj = { hit_id => $plant->{hit_id}, percent_id => $plant->{percent_id},
		    genome => $ftr_lu->{$plant->{hit_id}}{genome}, aliases => { 'SEED' => $ftr_lu->{$plant->{hit_id}}{'seed'} },
		    function => $ftr_lu->{$plant->{hit_id}}{function} };
	push(@{$output->{plant_similarities}},$Obj);
    }

    use Bio::ModelSEED::Client::SAP;
    my $sapsvr = Bio::ModelSEED::Client::SAP->new();

    my @Proks = @{$output->{prokaryotic_similarities}};
    undef(@{$output->{prokaryotic_similarities}});
    
    #Collect Bulk
    my %Prok_Genomes = ();
    my %Prok_IDs = ();
    foreach my $prok (@Proks){
	$Prok_IDs{$prok->{hit_id}}=1;

	my $genome_id = $prok->{hit_id};
	$genome_id =~ s/\.peg\.\d+$//;
	$genome_id =~ s/^fig\|//;
	$Prok_Genomes{$genome_id}{$prok->{hit_id}}=1;
    }

    my $names = $sapsvr->genome_data({ -ids => [ keys %Prok_Genomes ], -data => [ 'name' ] });
    my $functions = $sapsvr->ids_to_functions({ -ids => [ keys %Prok_IDs ] });

    foreach my $prok (@Proks){
	my $Obj = { hit_id => $prok->{hit_id}, percent_id => $prok->{percent_id},
		    genome => '', aliases => {}, function => '' };

	my $genome_id = $prok->{hit_id};
	$genome_id =~ s/\.peg\.\d+$//;
	$genome_id =~ s/^fig\|//;
	
	my $name = $names->{$genome_id}[0];
	$Obj->{genome}=$name;
	
	my $function = $functions->{$prok->{hit_id}};
	$Obj->{function}=$function;
	
	push(@{$output->{prokaryotic_similarities}},$Obj);
    }

    #END get_feature
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_feature:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_feature');
    }
    return($output);
}




=head2 save_feature_function

  $obj->save_feature_function($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a save_feature_function_params
save_feature_function_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
	feature has a value which is a feature_id
	function has a value which is a string
reference is a string
feature_id is a string

</pre>

=end html

=begin text

$input is a save_feature_function_params
save_feature_function_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
	feature has a value which is a feature_id
	function has a value which is a string
reference is a string
feature_id is a string


=end text



=item Description



=back

=cut

sub save_feature_function
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to save_feature_function:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'save_feature_function');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    #BEGIN save_feature_function
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["genome","feature","function"],{"user"=>undef});

    my $genome_obj = $self->helper()->get_object($input->{genome},"genome");
    if(!$genome_obj){
	$self->helper()->error("Genome not found using reference ".$input->{genome}."!");
    }

    my $found_ftr=undef;
    foreach my $ftr (@{$genome_obj->{features}}){
	if($ftr->{data}{id} eq $input->{feature}){
	    $ftr->{data}{function} = $input->{function};
	    $found_ftr = 1;

	    if(defined($input->{user})){
		my @Annotation = ($input->{user},$input->{function},scalar(localtime()));
		push(@{$ftr->{data}{annotations}},\@Annotation);
	    }

	    last;
	}
    }

    if(!$found_ftr){
	$self->helper()->error("Feature (".$input->{feature}.") not found in genome!");
    }

    #Retrieve Minimal Genome object (unspecified type)
    my @path = split(/\//, $input->{genome});
    my $genome = pop @path;
    my $root = join("/",@path)."/";
    my $min_genome = $root.".".$genome."/minimal_genome";

    my $min_genome_obj = $self->helper()->get_object($min_genome,"unspecified");
    $min_genome_obj = Bio::KBase::ObjectAPI::utilities::FROMJSON($min_genome_obj);

    $found_ftr = undef;
    foreach my $ftr (@{$min_genome_obj->{features}}){
	if($ftr->{id} eq $input->{feature}){
	    $ftr->{function} = $input->{function};
	    $found_ftr=1;
	    last;
	}
    }

    if(!$found_ftr){
	$self->helper()->error("Feature (".$input->{feature}.") not found in minimal genome!");
    }

    #Save objects
    $self->helper->save_object($input->{genome},$genome_obj,"genome",{});
    $self->helper->save_object($min_genome, $min_genome_obj,"unspecified",{});

    #END save_feature_function
    return();
}




=head2 compare_regions

  $output = $obj->compare_regions($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a get_feature_params
$output is a regions_data
get_feature_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
	feature has a value which is a feature_id
reference is a string
feature_id is a string
regions_data is a reference to a hash where the following keys are defined:
	size has a value which is an int
	number has a value which is an int
	regions has a value which is a reference to a hash where the key is a string and the value is a region
region is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	begin has a value which is an int
	end has a value which is an int
	features has a value which is a reference to a list where each element is a feature
feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	function has a value which is a string
	aliases has a value which is a string
	contig has a value which is a string
	begin has a value which is an int
	end has a value which is an int

</pre>

=end html

=begin text

$input is a get_feature_params
$output is a regions_data
get_feature_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
	feature has a value which is a feature_id
reference is a string
feature_id is a string
regions_data is a reference to a hash where the following keys are defined:
	size has a value which is an int
	number has a value which is an int
	regions has a value which is a reference to a hash where the key is a string and the value is a region
region is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	begin has a value which is an int
	end has a value which is an int
	features has a value which is a reference to a list where each element is a feature
feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	function has a value which is a string
	aliases has a value which is a string
	contig has a value which is a string
	begin has a value which is an int
	end has a value which is an int


=end text



=item Description



=back

=cut

sub compare_regions
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to compare_regions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_regions');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN compare_regions
    $input = $self->initialize_call($input);
    $input = $self->helper()->validate_args($input,["similarities"],{number_regions=>10,region_size=>15000});

    use Bio::ModelSEED::Client::SAP;
    my $sapsvr = Bio::ModelSEED::Client::SAP->new();
    
    #The sims are already sorted
    #1 Iterate through them and compress to same genomes
    my %Regions = ();
    my @Regions = ();
    my $Half_Region_Size = int($input->{region_size}/2);

    my %All_Ftrs = ();
    foreach my $prokaryote (@{$input->{similarities}}){
	last if $#Regions == $input->{number_regions};

	my $prok_id = $prokaryote->{hit_id};
	
	my $genome_id = $prok_id;
	$genome_id =~ s/\.peg\.\d+$//;
	
	my $sap_genome = $genome_id;
	$sap_genome =~ s/^fig\|//;

	if(!exists($Regions{$genome_id})){
	    push(@Regions,$genome_id);

	    $Regions{$genome_id}={ 'id' => $sap_genome, 'name' => '', 'order' => $#Regions, 'begin' => 0, 'end' => 0, 'features' => [] };

	    #Retrieve genome name
	    my $name = $sapsvr->genome_data({ -ids => [ $sap_genome ], -data => [ 'name' ] })->{$sap_genome}[0];
	    $Regions{$genome_id}{'name'}=$name;
	}

	#Retrieve prokaryotes in region size
	#Assuming only one contig here
	my $location = $sapsvr->fid_locations({ -ids => [ $prok_id ] })->{$prok_id};
	my ( $contig, $beg, $length ) = $location->[ 0] =~ /^\d+\.\d+:(\S+)_(\d+)([+-]\d+)$/;
	my $end = $beg + $length;
	( my $strand, $length) = $length =~ /^([+-])(\d+)$/;

	if(!exists($All_Ftrs{$prok_id})){
	    my $aliases = $sapsvr->fids_to_ids({ -ids => [ $prok_id ]})->{$prok_id};
	    $aliases = join(";", map { my $key = $_; $key.":".join("|",@{$aliases->{$key}}) } grep { $_ ne "SEED" } keys %$aliases);
	    my $function = $sapsvr->ids_to_functions({ -ids => [ $prok_id ], -genome => $sap_genome })->{$prok_id};    
	    my ($type) = $prok_id =~ /^fig\|\d+\.\d+\.(\w+)\.\d+/; 

	    $All_Ftrs{$prok_id}= {'id' => $prok_id, 'contig' => $contig, 'begin' => $beg, 'end' => $end,
				  'strand' => $strand, 'aliases' => $aliases, 'function' => $function, 'type' => $type};
	}
	push(@{$Regions{$genome_id}{'features'}}, $All_Ftrs{$prok_id});

	my $region_mid = int(($beg + $end)/2);
	my $region_beg = $region_mid - $Half_Region_Size;
	my $region_end = $region_mid + $Half_Region_Size;
	$Regions{$genome_id}{'begin'}=$region_beg;
	$Regions{$genome_id}{'end'}=$region_end;

	my $Region_Location = $sap_genome.":".$contig."_".$region_beg."_".$region_end;
	my $locs = $sapsvr->genes_in_region({ -locations => [ $Region_Location ], -includeLocation => 1 })->{$Region_Location};

	foreach my $ftr (keys %$locs){
	    if(!exists($All_Ftrs{$ftr})){
		my $location = $locs->{$ftr};
		my ( $contig, $beg, $length ) = $location->[ 0] =~ /^\d+\.\d+:(\S+)_(\d+)([+-]\d+)$/;
		my $end = $beg + $length;
		( my $strand, $length ) = $length =~ /^([+-])(\d+)$/;
		
		my $aliases = $sapsvr->fids_to_ids({ -ids => [ $ftr ]})->{$ftr};
		$aliases = join(";", map { my $key = $_; $key.":".join("|",@{$aliases->{$key}}) } grep { $_ ne "SEED" } keys %$aliases);
		my $function = $sapsvr->ids_to_functions({ -ids => [ $ftr ], -genome => $sap_genome })->{$ftr};    
		my ($type) = $ftr =~ /^fig\|\d+\.\d+\.(\w+)\.\d+/; 
		
		$All_Ftrs{$ftr}= {'id'=>$ftr, 'contig' => $contig, 'begin' => $beg, 'end' => $end,
				  'strand' => $strand, 'aliases' => $aliases, 'function' => $function, 'type' => $type};
	    }
	    push(@{$Regions{$genome_id}{'features'}}, $All_Ftrs{$ftr});
	}
    }

    @Regions = map { $Regions{$_} } @Regions;
    my $output = {'size' => $input->{region_size}, 'number' => $input->{number_regions}, 'regions' => \@Regions};

    #END compare_regions
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to compare_regions:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_regions');
    }
    return($output);
}




=head2 plant_annotation_overview

  $output = $obj->plant_annotation_overview($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a plant_annotation_overview_params
$output is an annotation_overview
plant_annotation_overview_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
reference is a string
annotation_overview is a reference to a hash where the following keys are defined:
	roles has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is a feature
feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	function has a value which is a string
	aliases has a value which is a string
	contig has a value which is a string
	begin has a value which is an int
	end has a value which is an int

</pre>

=end html

=begin text

$input is a plant_annotation_overview_params
$output is an annotation_overview
plant_annotation_overview_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
reference is a string
annotation_overview is a reference to a hash where the following keys are defined:
	roles has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is a feature
feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	function has a value which is a string
	aliases has a value which is a string
	contig has a value which is a string
	begin has a value which is an int
	end has a value which is an int


=end text



=item Description



=back

=cut

sub plant_annotation_overview
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to plant_annotation_overview:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'plant_annotation_overview');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN plant_annotation_overview
    $input = $self->helper()->validate_args($input,["genome"],{});

    my $genome_obj = $self->helper()->get_object($input->{genome},"genome");
    if(!$genome_obj){
        $self->helper()->error("Genome not found using reference ".$input->{genome}."!");
    }

    #Find Missing annotation
    my $annotation = $self->helper()->get_object("/plantseed/Genomes/annotation_overview","unspecified");
    $annotation = decode_json($annotation);

    my %Exemplar_Roles=();
    foreach my $row (@{$annotation}){
	foreach my $ftr (keys %{$row->{features}}){
	    $Exemplar_Roles{$row->{role}}{$ftr}=1;
	}
	if(!exists($output->{$row->{role}})){
	    $output->{$row->{role}}={};
	}
    }

    #Collect Genome annotation
    foreach my $ftr (@{$genome_obj->{features}}){
	foreach my $role (split(/\s*;\s+|\s+[\@\/]\s+/,$ftr->{data}{function})){
	    next unless exists($output->{$role});
	    $output->{$role}{'kmer-features'}{$ftr->{data}{id}}=1;
	}
    }

    #Add exemplars found in BLAST results
    #Stored in Minimal Genome object
    my @path = split(/\//, $input->{genome});
    my $genome = pop @path;
    my $root = join("/",@path)."/";
    my $min_genome = $root.".".$genome."/minimal_genome";

    $min_genome = $self->helper()->get_object($min_genome,"unspecified");
    $min_genome = Bio::KBase::ObjectAPI::utilities::FROMJSON($min_genome);
    
    foreach my $role (keys %$output){
	foreach my $exemplar ( grep { exists($min_genome->{exemplars}{$_}) } keys %{$Exemplar_Roles{$role}}){
	    foreach my $query (keys %{$min_genome->{exemplars}{$exemplar}}){
		$output->{$role}{'blast-features'}{$query}=1;
	    }
	}
    }

    foreach my $role (keys %$output){
	$output->{$role}{'kmer-features'} = [sort keys %{$output->{$role}{'kmer-features'}}];
	$output->{$role}{'blast-features'} = [sort keys %{$output->{$role}{'blast-features'}}];
    }

    #END plant_annotation_overview
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to plant_annotation_overview:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'plant_annotation_overview');
    }
    return($output);
}




=head2 ModelReconstruction

  $output = $obj->ModelReconstruction($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a ModelReconstruction_params
$output is a ModelStats
ModelReconstruction_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
reference is a string
ModelStats is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a string
	source has a value which is a string
	source_id has a value which is a string
	name has a value which is a string
	type has a value which is a string
	ref has a value which is a reference
	genome_ref has a value which is a reference
	template_ref has a value which is a reference
	fba_count has a value which is an int
	integrated_gapfills has a value which is an int
	unintegrated_gapfills has a value which is an int
	gene_associated_reactions has a value which is an int
	gapfilled_reactions has a value which is an int
	num_genes has a value which is an int
	num_compounds has a value which is an int
	num_reactions has a value which is an int
	num_biomasses has a value which is an int
	num_biomass_compounds has a value which is an int
	num_compartments has a value which is an int
Timestamp is a string

</pre>

=end html

=begin text

$input is a ModelReconstruction_params
$output is a ModelStats
ModelReconstruction_params is a reference to a hash where the following keys are defined:
	genome has a value which is a reference
reference is a string
ModelStats is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a string
	source has a value which is a string
	source_id has a value which is a string
	name has a value which is a string
	type has a value which is a string
	ref has a value which is a reference
	genome_ref has a value which is a reference
	template_ref has a value which is a reference
	fba_count has a value which is an int
	integrated_gapfills has a value which is an int
	unintegrated_gapfills has a value which is an int
	gene_associated_reactions has a value which is an int
	gapfilled_reactions has a value which is an int
	num_genes has a value which is an int
	num_compounds has a value which is an int
	num_reactions has a value which is an int
	num_biomasses has a value which is an int
	num_biomass_compounds has a value which is an int
	num_compartments has a value which is an int
Timestamp is a string


=end text



=item Description



=back

=cut

sub ModelReconstruction
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to ModelReconstruction:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'ModelReconstruction');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN ModelReconstruction
    $input = $self->initialize_call($input);
    $output = $self->helper()->ModelReconstruction($input);
    #END ModelReconstruction
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to ModelReconstruction:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'ModelReconstruction');
    }
    return($output);
}




=head2 FluxBalanceAnalysis

  $output = $obj->FluxBalanceAnalysis($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a FluxBalanceAnalysis_params
$output is a fba_data
FluxBalanceAnalysis_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
fba_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a fba_id
	ref has a value which is a reference
	objective has a value which is a float
	media_ref has a value which is a reference
	objective_function has a value which is a string
Timestamp is a string
fba_id is a string

</pre>

=end html

=begin text

$input is a FluxBalanceAnalysis_params
$output is a fba_data
FluxBalanceAnalysis_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
fba_data is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a fba_id
	ref has a value which is a reference
	objective has a value which is a float
	media_ref has a value which is a reference
	objective_function has a value which is a string
Timestamp is a string
fba_id is a string


=end text



=item Description



=back

=cut

sub FluxBalanceAnalysis
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to FluxBalanceAnalysis:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'FluxBalanceAnalysis');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN FluxBalanceAnalysis
    $input = $self->initialize_call($input);
    my $fbaoutput = $self->helper()->FluxBalanceAnalysis($input);
    $output = {
    	rundate => $fbaoutput->[3],
    	id => $fbaoutput->[0],
    	"ref" => $fbaoutput->[2].$fbaoutput->[0],
    	media_ref => $fbaoutput->[7]->{media},
		objective => $fbaoutput->[7]->{objective},
		objective_function => ""
    };
    #END FluxBalanceAnalysis
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to FluxBalanceAnalysis:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'FluxBalanceAnalysis');
    }
    return($output);
}




=head2 GapfillModel

  $output = $obj->GapfillModel($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a GapfillModel_params
$output is a ModelStats
GapfillModel_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
ModelStats is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a string
	source has a value which is a string
	source_id has a value which is a string
	name has a value which is a string
	type has a value which is a string
	ref has a value which is a reference
	genome_ref has a value which is a reference
	template_ref has a value which is a reference
	fba_count has a value which is an int
	integrated_gapfills has a value which is an int
	unintegrated_gapfills has a value which is an int
	gene_associated_reactions has a value which is an int
	gapfilled_reactions has a value which is an int
	num_genes has a value which is an int
	num_compounds has a value which is an int
	num_reactions has a value which is an int
	num_biomasses has a value which is an int
	num_biomass_compounds has a value which is an int
	num_compartments has a value which is an int
Timestamp is a string

</pre>

=end html

=begin text

$input is a GapfillModel_params
$output is a ModelStats
GapfillModel_params is a reference to a hash where the following keys are defined:
	model has a value which is a reference
reference is a string
ModelStats is a reference to a hash where the following keys are defined:
	rundate has a value which is a Timestamp
	id has a value which is a string
	source has a value which is a string
	source_id has a value which is a string
	name has a value which is a string
	type has a value which is a string
	ref has a value which is a reference
	genome_ref has a value which is a reference
	template_ref has a value which is a reference
	fba_count has a value which is an int
	integrated_gapfills has a value which is an int
	unintegrated_gapfills has a value which is an int
	gene_associated_reactions has a value which is an int
	gapfilled_reactions has a value which is an int
	num_genes has a value which is an int
	num_compounds has a value which is an int
	num_reactions has a value which is an int
	num_biomasses has a value which is an int
	num_biomass_compounds has a value which is an int
	num_compartments has a value which is an int
Timestamp is a string


=end text



=item Description



=back

=cut

sub GapfillModel
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to GapfillModel:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'GapfillModel');
    }

    my $ctx = $Bio::ModelSEED::ProbModelSEED::Service::CallContext;
    my($output);
    #BEGIN GapfillModel
    $input = $self->initialize_call($input);
    $output = $self->helper()->GapfillModel($input);
    #END GapfillModel
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to GapfillModel:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'GapfillModel');
    }
    return($output);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 bool

=over 4



=item Description

********************************************************************************
    Universal simple type definitions
   	********************************************************************************


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



=head2 reference

=over 4



=item Description

Reference to location in PATRIC workspace (e.g. /home/chenry/models/MyModel)


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



=head2 Timestamp

=over 4



=item Description

Standard perl timestamp (e.g. 2015-03-21-02:14:53)


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



=head2 gapfill_id

=over 4



=item Description

ID of gapfilling solution


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



=head2 fba_id

=over 4



=item Description

ID of FBA study


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



=head2 edit_id

=over 4



=item Description

ID of model edits


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



=head2 gapfill_command

=over 4



=item Description

An enum of commands to manage gapfilling solutions [D/I/U]; D = delete, I = integrate, U = unintegrate


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



=head2 reaction_id

=over 4



=item Description

ID of reaction in model


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



=head2 compound_id

=over 4



=item Description

ID of compound in model


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



=head2 feature_id

=over 4



=item Description

ID of feature in model


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



=head2 compartment_id

=over 4



=item Description

ID of compartment in model


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



=head2 gene_id

=over 4



=item Description

ID of gene in model


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



=head2 biomass_id

=over 4



=item Description

ID of biomass reaction in model


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



=head2 reaction_direction

=over 4



=item Description

An enum of directions for reactions [</=/>]; < = reverse, = = reversible, > = forward


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



=head2 Username

=over 4



=item Description

Login name for user


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



=head2 ObjectName

=over 4



=item Description

Name assigned to an object saved to a workspace


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



=head2 ObjectID

=over 4



=item Description

Unique UUID assigned to every object in a workspace on save - IDs never reused


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



=head2 ObjectType

=over 4



=item Description

Specified type of an object (e.g. Genome)


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



=head2 ObjectSize

=over 4



=item Description

Size of the object


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



=head2 ObjectData

=over 4



=item Description

Generic type containing object data


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



=head2 FullObjectPath

=over 4



=item Description

Path to any object in workspace database


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



=head2 UserMetadata

=over 4



=item Description

This is a key value hash of user-specified metadata


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



=head2 AutoMetadata

=over 4



=item Description

This is a key value hash of automated metadata populated based on object type


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



=head2 WorkspacePerm

=over 4



=item Description

User permission in worksace (e.g. w - write, r - read, a - admin, n - none)


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



=head2 gapfill_reaction

=over 4



=item Description

********************************************************************************
    Complex data structures to support functions
   	********************************************************************************


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
reaction has a value which is a reference
direction has a value which is a reaction_direction
compartment has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
reaction has a value which is a reference
direction has a value which is a reaction_direction
compartment has a value which is a string


=end text

=back



=head2 gapfill_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
rundate has a value which is a Timestamp
id has a value which is a gapfill_id
ref has a value which is a reference
media_ref has a value which is a reference
integrated has a value which is a bool
integrated_solution has a value which is an int
solution_reactions has a value which is a reference to a list where each element is a reference to a list where each element is a gapfill_reaction

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
rundate has a value which is a Timestamp
id has a value which is a gapfill_id
ref has a value which is a reference
media_ref has a value which is a reference
integrated has a value which is a bool
integrated_solution has a value which is an int
solution_reactions has a value which is a reference to a list where each element is a reference to a list where each element is a gapfill_reaction


=end text

=back



=head2 fba_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
rundate has a value which is a Timestamp
id has a value which is a fba_id
ref has a value which is a reference
objective has a value which is a float
media_ref has a value which is a reference
objective_function has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
rundate has a value which is a Timestamp
id has a value which is a fba_id
ref has a value which is a reference
objective has a value which is a float
media_ref has a value which is a reference
objective_function has a value which is a string


=end text

=back



=head2 edit_reaction

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a reaction_id
reagents has a value which is a reference to a list where each element is a reference to a list containing 3 items:
0: (compound) a string
1: (coefficient) a float
2: (compartment) a string

gpr has a value which is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
direction has a value which is a reaction_direction

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a reaction_id
reagents has a value which is a reference to a list where each element is a reference to a list containing 3 items:
0: (compound) a string
1: (coefficient) a float
2: (compartment) a string

gpr has a value which is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
direction has a value which is a reaction_direction


=end text

=back



=head2 edit_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
rundate has a value which is a Timestamp
id has a value which is an edit_id
ref has a value which is a reference
reactions_to_delete has a value which is a reference to a list where each element is a reaction_id
altered_directions has a value which is a reference to a hash where the key is a reaction_id and the value is a reaction_direction
altered_gpr has a value which is a reference to a hash where the key is a reaction_id and the value is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
reactions_to_add has a value which is a reference to a list where each element is an edit_reaction
altered_biomass_compound has a value which is a reference to a hash where the key is a compound_id and the value is a reference to a list containing 2 items:
0: a float
1: a compartment_id


</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
rundate has a value which is a Timestamp
id has a value which is an edit_id
ref has a value which is a reference
reactions_to_delete has a value which is a reference to a list where each element is a reaction_id
altered_directions has a value which is a reference to a hash where the key is a reaction_id and the value is a reaction_direction
altered_gpr has a value which is a reference to a hash where the key is a reaction_id and the value is a reference to a list where each element is a reference to a list where each element is a reference to a list where each element is a feature_id
reactions_to_add has a value which is a reference to a list where each element is an edit_reaction
altered_biomass_compound has a value which is a reference to a hash where the key is a compound_id and the value is a reference to a list containing 2 items:
0: a float
1: a compartment_id



=end text

=back



=head2 ModelStats

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
rundate has a value which is a Timestamp
id has a value which is a string
source has a value which is a string
source_id has a value which is a string
name has a value which is a string
type has a value which is a string
ref has a value which is a reference
genome_ref has a value which is a reference
template_ref has a value which is a reference
fba_count has a value which is an int
integrated_gapfills has a value which is an int
unintegrated_gapfills has a value which is an int
gene_associated_reactions has a value which is an int
gapfilled_reactions has a value which is an int
num_genes has a value which is an int
num_compounds has a value which is an int
num_reactions has a value which is an int
num_biomasses has a value which is an int
num_biomass_compounds has a value which is an int
num_compartments has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
rundate has a value which is a Timestamp
id has a value which is a string
source has a value which is a string
source_id has a value which is a string
name has a value which is a string
type has a value which is a string
ref has a value which is a reference
genome_ref has a value which is a reference
template_ref has a value which is a reference
fba_count has a value which is an int
integrated_gapfills has a value which is an int
unintegrated_gapfills has a value which is an int
gene_associated_reactions has a value which is an int
gapfilled_reactions has a value which is an int
num_genes has a value which is an int
num_compounds has a value which is an int
num_reactions has a value which is an int
num_biomasses has a value which is an int
num_biomass_compounds has a value which is an int
num_compartments has a value which is an int


=end text

=back



=head2 model_reaction

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a reaction_id
name has a value which is a string
stoichiometry has a value which is a reference to a list where each element is a reference to a list containing 5 items:
0: (coefficient) a float
1: (id) a compound_id
2: (compartment) a compartment_id
3: (compartment_index) an int
4: (name) a string

direction has a value which is a string
gpr has a value which is a string
genes has a value which is a reference to a list where each element is a gene_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a reaction_id
name has a value which is a string
stoichiometry has a value which is a reference to a list where each element is a reference to a list containing 5 items:
0: (coefficient) a float
1: (id) a compound_id
2: (compartment) a compartment_id
3: (compartment_index) an int
4: (name) a string

direction has a value which is a string
gpr has a value which is a string
genes has a value which is a reference to a list where each element is a gene_id


=end text

=back



=head2 model_compound

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a compound_id
name has a value which is a string
formula has a value which is a string
charge has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a compound_id
name has a value which is a string
formula has a value which is a string
charge has a value which is a float


=end text

=back



=head2 model_gene

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a gene_id
reactions has a value which is a reference to a list where each element is a reaction_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a gene_id
reactions has a value which is a reference to a list where each element is a reaction_id


=end text

=back



=head2 model_compartment

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a compartment_id
name has a value which is a string
pH has a value which is a float
potential has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a compartment_id
name has a value which is a string
pH has a value which is a float
potential has a value which is a float


=end text

=back



=head2 model_biomass

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a biomass_id
compounds has a value which is a reference to a list where each element is a reference to a list containing 3 items:
0: (compound) a compound_id
1: (coefficient) a float
2: (compartment) a compartment_id


</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a biomass_id
compounds has a value which is a reference to a list where each element is a reference to a list containing 3 items:
0: (compound) a compound_id
1: (coefficient) a float
2: (compartment) a compartment_id



=end text

=back



=head2 model_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a reference
reactions has a value which is a reference to a list where each element is a model_reaction
compounds has a value which is a reference to a list where each element is a model_compound
genes has a value which is a reference to a list where each element is a model_gene
compartments has a value which is a reference to a list where each element is a model_compartment
biomasses has a value which is a reference to a list where each element is a model_biomass

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a reference
reactions has a value which is a reference to a list where each element is a model_reaction
compounds has a value which is a reference to a list where each element is a model_compound
genes has a value which is a reference to a list where each element is a model_gene
compartments has a value which is a reference to a list where each element is a model_compartment
biomasses has a value which is a reference to a list where each element is a model_biomass


=end text

=back



=head2 ObjectMeta

=over 4



=item Description

ObjectMeta: tuple containing information about an object in the workspace 

        ObjectName - name selected for object in workspace
        ObjectType - type of the object in the workspace
        FullObjectPath - full path to object in workspace, including object name
        Timestamp creation_time - time when the object was created
        ObjectID - a globally unique UUID assigned to every object that will never change even if the object is moved
        Username object_owner - name of object owner
        ObjectSize - size of the object in bytes or if object is directory, the number of objects in directory
        UserMetadata - arbitrary user metadata associated with object
        AutoMetadata - automatically populated metadata generated from object data in automated way
        WorkspacePerm user_permission - permissions for the authenticated user of this workspace.
        WorkspacePerm global_permission - whether this workspace is globally readable.
        string shockurl - shockurl included if object is a reference to a shock node


=item Definition

=begin html

<pre>
a reference to a list containing 12 items:
0: an ObjectName
1: an ObjectType
2: a FullObjectPath
3: (creation_time) a Timestamp
4: an ObjectID
5: (object_owner) a Username
6: an ObjectSize
7: a UserMetadata
8: an AutoMetadata
9: (user_permission) a WorkspacePerm
10: (global_permission) a WorkspacePerm
11: (shockurl) a string

</pre>

=end html

=begin text

a reference to a list containing 12 items:
0: an ObjectName
1: an ObjectType
2: a FullObjectPath
3: (creation_time) a Timestamp
4: an ObjectID
5: (object_owner) a Username
6: an ObjectSize
7: a UserMetadata
8: an AutoMetadata
9: (user_permission) a WorkspacePerm
10: (global_permission) a WorkspacePerm
11: (shockurl) a string


=end text

=back



=head2 list_gapfill_solutions_params

=over 4



=item Description

********************************************************************************
    Functions for managing gapfilling studies
   	********************************************************************************


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference


=end text

=back



=head2 manage_gapfill_solutions_params

=over 4



=item Description

FUNCTION: manage_gapfill_solutions
DESCRIPTION: This function manages the gapfill solutions for a model and returns gapfill solution data

REQUIRED INPUTS:
reference model - reference to model to integrate solutions for
mapping<gapfill_id,gapfill_command> commands - commands to manage gapfill solutions

OPTIONAL INPUTS:
mapping<gapfill_id,int> selected_solutions - solutions to integrate


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference
commands has a value which is a reference to a hash where the key is a gapfill_id and the value is a gapfill_command
selected_solutions has a value which is a reference to a hash where the key is a gapfill_id and the value is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference
commands has a value which is a reference to a hash where the key is a gapfill_id and the value is a gapfill_command
selected_solutions has a value which is a reference to a hash where the key is a gapfill_id and the value is an int


=end text

=back



=head2 list_fba_studies_params

=over 4



=item Description

********************************************************************************
    Functions for managing FBA studies
   	********************************************************************************


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference


=end text

=back



=head2 delete_fba_studies_params

=over 4



=item Description

FUNCTION: delete_fba_studies
DESCRIPTION: This function deletes fba studies associated with model

REQUIRED INPUTS:
reference model - reference to model to integrate solutions for
list<fba_id> fbas - list of FBA studies to delete


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference
commands has a value which is a reference to a hash where the key is a gapfill_id and the value is a gapfill_command

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference
commands has a value which is a reference to a hash where the key is a gapfill_id and the value is a gapfill_command


=end text

=back



=head2 export_model_params

=over 4



=item Description

********************************************************************************
    Functions for export of model data
   	********************************************************************************


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference
format has a value which is a string
to_shock has a value which is a bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference
format has a value which is a string
to_shock has a value which is a bool


=end text

=back



=head2 export_media_params

=over 4



=item Description

FUNCTION: export_media
DESCRIPTION: This function exports a media in TSV format

REQUIRED INPUTS:
reference media - reference to media to export
bool to_shock - load exported file to shock and return shock url


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
media has a value which is a reference
to_shock has a value which is a bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
media has a value which is a reference
to_shock has a value which is a bool


=end text

=back



=head2 get_model_params

=over 4



=item Description

********************************************************************************
    Functions for managing models
   	********************************************************************************


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference


=end text

=back



=head2 delete_model_params

=over 4



=item Description

FUNCTION: delete_model
DESCRIPTION: This function deletes a model specified by the user

REQUIRED INPUTS:
    reference model - reference to model to delete


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference


=end text

=back



=head2 list_models_params

=over 4



=item Description

FUNCTION: list_models
DESCRIPTION: This function lists all models owned by the user

REQUIRED INPUTS:
    
    OPTIONAL INPUTS:
    reference path;


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a reference


=end text

=back



=head2 copy_model_params

=over 4



=item Description

FUNCTION: copy_model
DESCRIPTION: This function copies the specified model to another location or even workspace

REQUIRED INPUTS:
    reference model - reference to model to copy
    
    OPTIONAL INPUTS:
    reference destination - location where the model should be copied to
    bool copy_genome - set this to copy the genome associated with the model
    bool to_kbase - set to one to copy the model to KBase
    string workspace_url - URL of workspace to which data should be copied
    string kbase_username - kbase username for copying models to kbase
    string kbase_password - kbase password for copying models to kbase


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference
destination has a value which is a reference
destname has a value which is a string
copy_genome has a value which is a bool
to_kbase has a value which is a bool
workspace_url has a value which is a string
kbase_username has a value which is a string
kbase_password has a value which is a string
plantseed has a value which is a bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference
destination has a value which is a reference
destname has a value which is a string
copy_genome has a value which is a bool
to_kbase has a value which is a bool
workspace_url has a value which is a string
kbase_username has a value which is a string
kbase_password has a value which is a string
plantseed has a value which is a bool


=end text

=back



=head2 copy_genome_params

=over 4



=item Description

FUNCTION: copy_genome
DESCRIPTION: This function copies the specified genome to another location or even workspace

REQUIRED INPUTS:
    reference genome - reference to genome to copy
    
    OPTIONAL INPUTS:
    reference destination - location where the genome should be copied to
    bool to_kbase - set to one to copy the genome to KBase
    string workspace_url - URL of workspace to which data should be copied
    string kbase_username - kbase username for copying models to kbase
    string kbase_password - kbase password for copying models to kbase


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome has a value which is a reference
destination has a value which is a reference
destname has a value which is a string
to_kbase has a value which is a bool
workspace_url has a value which is a string
kbase_username has a value which is a string
kbase_password has a value which is a string
plantseed has a value which is a bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome has a value which is a reference
destination has a value which is a reference
destname has a value which is a string
to_kbase has a value which is a bool
workspace_url has a value which is a string
kbase_username has a value which is a string
kbase_password has a value which is a string
plantseed has a value which is a bool


=end text

=back



=head2 list_model_edits_params

=over 4



=item Description

********************************************************************************
    Functions for editing models
   	********************************************************************************


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference


=end text

=back



=head2 manage_model_edits_params

=over 4



=item Description

FUNCTION: manage_model_edits
DESCRIPTION: This function manages edits to model submitted by user

REQUIRED INPUTS:
reference model - reference to model to integrate solutions for
mapping<edit_id,gapfill_command> commands - list of edit commands

OPTIONAL INPUTS:
edit_data new_edit - list of new edits to add


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference
commands has a value which is a reference to a hash where the key is an edit_id and the value is a gapfill_command
new_edit has a value which is an edit_data

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference
commands has a value which is a reference to a hash where the key is an edit_id and the value is a gapfill_command
new_edit has a value which is an edit_data


=end text

=back



=head2 similarity

=over 4



=item Description

********************************************************************************
	Functions corresponding to use of PlantSEED web-pages
   	********************************************************************************


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
hit_id has a value which is a string
percent_id has a value which is a float
e_value has a value which is a float
bit_score has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
hit_id has a value which is a string
percent_id has a value which is a float
e_value has a value which is a float
bit_score has a value which is an int


=end text

=back



=head2 feature_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a feature_id
function has a value which is a string
protein_translation has a value which is a string
subsystems has a value which is a reference to a list where each element is a string
plant_similarities has a value which is a reference to a list where each element is a similarity
prokaryotic_similarities has a value which is a reference to a list where each element is a similarity

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a feature_id
function has a value which is a string
protein_translation has a value which is a string
subsystems has a value which is a reference to a list where each element is a string
plant_similarities has a value which is a reference to a list where each element is a similarity
prokaryotic_similarities has a value which is a reference to a list where each element is a similarity


=end text

=back



=head2 get_feature_params

=over 4



=item Description

FUNCTION: get_feature
DESCRIPTION: This function retrieves an individual Plant feature

REQUIRED INPUTS:
reference genome - reference of genome that contains feature
feature_id feature - identifier of feature to get


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome has a value which is a reference
feature has a value which is a feature_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome has a value which is a reference
feature has a value which is a feature_id


=end text

=back



=head2 save_feature_function_params

=over 4



=item Description

FUNCTION: save_feature_function
DESCRIPTION: This function saves the newly assigned function in a feature
             thereby updating the annotation of a genome

REQUIRED INPUTS:
reference genome - reference of genome that contains feature
feature_id feature - identifier of feature to get
string function - the new annotation to assign to a feature


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome has a value which is a reference
feature has a value which is a feature_id
function has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome has a value which is a reference
feature has a value which is a feature_id
function has a value which is a string


=end text

=back



=head2 feature

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is a string
function has a value which is a string
aliases has a value which is a string
contig has a value which is a string
begin has a value which is an int
end has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is a string
function has a value which is a string
aliases has a value which is a string
contig has a value which is a string
begin has a value which is an int
end has a value which is an int


=end text

=back



=head2 region

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
name has a value which is a string
begin has a value which is an int
end has a value which is an int
features has a value which is a reference to a list where each element is a feature

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
name has a value which is a string
begin has a value which is an int
end has a value which is an int
features has a value which is a reference to a list where each element is a feature


=end text

=back



=head2 regions_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
size has a value which is an int
number has a value which is an int
regions has a value which is a reference to a hash where the key is a string and the value is a region

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
size has a value which is an int
number has a value which is an int
regions has a value which is a reference to a hash where the key is a string and the value is a region


=end text

=back



=head2 compare_regions_params

=over 4



=item Description

FUNCTION: compare_regions
DESCRIPTION: This function retrieves the data required to build the CompareRegions view

REQUIRED INPUTS:
list<string> similarities - list of peg identifiers

OPTIONAL INPUTS:
int region_size - width of regions (in bp) to cover. Defaults to 15000
int number_regions - number of regions to show. Defaults to 10


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
similarities has a value which is a reference to a list where each element is a string
region_size has a value which is an int
number_regions has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
similarities has a value which is a reference to a list where each element is a string
region_size has a value which is an int
number_regions has a value which is an int


=end text

=back



=head2 annotation_overview

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
roles has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is a feature

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
roles has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a reference to a list where each element is a feature


=end text

=back



=head2 plant_annotation_overview_params

=over 4



=item Description

FUNCTION: plant_annotation_overview
DESCRIPTION: This function retrieves the annotation_overview required to summarize a genome's PlantSEED annotation

REQUIRED INPUTS:
reference genome - annotated genome to explore


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome has a value which is a reference


=end text

=back



=head2 ModelReconstruction_params

=over 4



=item Description

********************************************************************************
	Functions corresponding to modeling apps
   	********************************************************************************


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome has a value which is a reference


=end text

=back



=head2 FluxBalanceAnalysis_params

=over 4



=item Description

FUNCTION: FluxBalanceAnalysis
DESCRIPTION: This function runs the flux balance analysis app directly. See app service for detailed specs.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference


=end text

=back



=head2 GapfillModel_params

=over 4



=item Description

FUNCTION: GapfillModel
DESCRIPTION: This function runs the gapfilling app directly. See app service for detailed specs.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model has a value which is a reference

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model has a value which is a reference


=end text

=back



=cut

1;
