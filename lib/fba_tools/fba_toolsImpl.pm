package fba_tools::fba_toolsImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = '1.7.5';
our $GIT_URL = 'git@github.com:kbaseapps/fba_tools.git';
our $GIT_COMMIT_HASH = '68247fe4d7a77cc59995e6d0a7cb74c449ff6b01';

=head1 NAME

fba_tools

=head1 DESCRIPTION

A KBase module: fba_tools
This module contains the implementation for the primary methods in KBase for metabolic model reconstruction, gapfilling, and analysis

=cut

#BEGIN_HEADER
use Bio::KBase::AuthToken;
use Bio::KBase::ObjectAPI::KBaseStore;
use Bio::KBase::ObjectAPI::functions;
use Bio::KBase::utilities;
use Bio::KBase::kbaseenv;
use DataFileUtil::DataFileUtilClient;
use Bio::KBase::HandleService;
use Archive::Zip;
use Data::Dumper;

#Initialization function for call
sub util_initialize_call {
	my ($self,$params,$ctx) = @_;
	print "Import parameters:".Bio::KBase::ObjectAPI::utilities::TOJSON($params,1);
	if (defined($ctx)) {
		Bio::KBase::kbaseenv::initialize_call($ctx);
	}
	delete($self->{_kbase_store});
	return $params;
}

sub util_finalize_call {
	my ($self,$params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","report_name"],{
		output => {},
		direct_html_link_index => undef,
	});
	if ((!defined(Bio::KBase::utilities::report_html()) || length(Bio::KBase::utilities::report_html()) == 0) && defined(Bio::KBase::utilities::report_message()) && length(Bio::KBase::utilities::report_message()) > 0) {
		Bio::KBase::utilities::print_report_message({message => "<p>".Bio::KBase::utilities::report_message()."</p>",append => 1,html => 1});
	}
	my $reportout = Bio::KBase::kbaseenv::create_report({
    	workspace_name => $params->{workspace},
    	report_object_name => $params->{report_name},
    	direct_html_link_index => $params->{direct_html_link_index}
    });
    $params->{output}->{report_ref} = $reportout->{"ref"};
	$params->{output}->{report_name} = $params->{report_name};
	if (defined($params->{output}->{new_fbamodel})) {
		delete $params->{output}->{new_fbamodel};
	}
}

sub util_store {
	my ($self,$store) = @_;
    if (defined($store)) {
		$self->{_kbase_store} = $store;
	}
    if (!defined($self->{_kbase_store})) {
    	$self->{_kbase_store} = Bio::KBase::ObjectAPI::KBaseStore->new();
    }
	return $self->{_kbase_store};
}

sub util_log {
	my($self,$message,$tag) = @_;
	Bio::KBase::kbaseenv::log($message,$tag);
}

sub util_get_object {
	my($self,$ref,$parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{});
	return $self->util_store()->get_object($ref,$parameters);
}

sub util_save_object {
	my($self,$object,$ref,$parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,[],{
		hash => 0,
		type => undef,
		hidden => 0
	});
	return $self->util_store()->save_object($object,$ref,$parameters);
}

sub util_list_objects {
	my($self,$args) = @_;
	return Bio::KBase::kbaseenv::list_objects($args);
}

sub util_package_for_download {
	my($self,$params) = @_;
	my $dataUtil = Bio::KBase::kbaseenv::data_file_client();
	my $package_details = $dataUtil->package_for_download($params);
    return { shock_id => $package_details->{shock_id} };
}

sub util_file_to_shock {
	my($self,$params) = @_;
	my $dataUtil = Bio::KBase::kbaseenv::data_file_client();
	my $f = $dataUtil->file_to_shock($params);
    return $f;
}

sub util_get_file_path {
	my($self,$file,$target_dir) = @_;
    if(exists $file->{shock_id} && $file->{shock_id} ne "") {
        # file has a shock id, so try to fetch it 
        my $dataUtil = Bio::KBase::kbaseenv::data_file_client();
        my $f = $dataUtil->shock_to_file({ 
			shock_id=>$file->{shock_id},
			file_path=>$target_dir,
			unpack=>0
		});
        return $target_dir.'/'.$f->{node_file_name};
    }
    return $file->{path};
}

sub util_parse_input_table {
	my($self,$filename,$columns) = @_;
	# $columns is a list(string column_name, bool required, ? default_value)
	if (!-e $filename) {
		Bio::KBase::utilities::error("Could not find input file:".$filename."!\n");
	}
	open(my $fh, "<", $filename) || die "Could not open file ".$filename;
	my $headingline = <$fh>;
	my @split_text;
	if (eof $fh){
		print('Useing alternate parseing');
		@split_text = split(/\r/, $headingline);
		$headingline = shift(@split_text)
	}
	$headingline =~ tr/\r\n_//d;#This line removes line endings from nix and windows files and underscores
	my $delim = undef;
	if ($headingline =~ m/\t/) {
		$delim = "\\t";
	} elsif ($headingline =~ m/,/) {
		$delim = ",";
	}
	if (!defined($delim)) {
		Bio::KBase::utilities::error("$filename either does not use commas or tabs as a separator!");
	}
	# remove capitalization for column matching
	my $headings = [split(/$delim/,lc($headingline))];
	my $data = [];
	while (my $line = <$fh>) {
		$line =~ tr/\r\n//d;#This line removes line endings from nix and windows files
		#chop up line while accounting for blank lines and leading and trailing spaces
		push(@{$data},[map{(my $s = $_) =~ s/^\s+|\s+$//g; $s} split(/$delim/,$line)])  if $line;
	}
	close($fh);
	# fix for \r delimeted files that perl's fh does not recognize
	if (@split_text) {
		while (my $line = shift(@split_text)) {
			$line =~ tr/\r\n//d;#This line removes line endings from nix and windows files
			#chop up line while accounting for blank lines and leading and trailing spaces
			push(@{$data}, [map{(my $s = $_) =~ s/^\s+|\s+$//g; $s} split(/$delim/, $line)]) if $line;
		}
	}
	my $headingColumns;
	for (my $i=0;$i < @{$headings}; $i++) {
		$headingColumns->{$headings->[$i]} = $i;
	}
	my $error = 0;
	for (my $j=0;$j < @{$columns}; $j++) {
		if (!defined($headingColumns->{$columns->[$j]->[0]})){
			if (defined($columns->[$j]->[1]) && $columns->[$j]->[1] == 1) {
				$error = 1;
				print "ERROR: Model file missing required column '" . $columns->[$j]->[0] . "'!\n";
			} else {
				print "WARNING: Import file missing optional column '" .
					$columns->[$j]->[0] . "' Defaults may be used.\n";
			}
		}
	}
	if ($error == 1) {
		exit();
	}
	my $objects = [];
	foreach my $item (@{$data}) {
		my $object = [];
		for (my $j=0;$j < @{$columns}; $j++) {
			$object->[$j] = undef;
			# if default defined, start with default value
			if (defined($columns->[$j]->[2])) {
				$object->[$j] = $columns->[$j]->[2];
			}
			#if value defiend in $item, copy it over
			if (defined($headingColumns->{$columns->[$j]->[0]}) && defined($item->[$headingColumns->{$columns->[$j]->[0]}])) {
				$object->[$j] = $item->[$headingColumns->{$columns->[$j]->[0]}];
			}
			# ? this may have something to do with lists...
			if (defined($columns->[$j]->[3])) {
				if (defined($object->[$j]) && length($object->[$j]) > 0) {
					my $d = $columns->[$j]->[3];
					$object->[$j] = [split(/$d/,$object->[$j])];
				} else {
					$object->[$j] = [];
				}
			};
		}
		push(@{$objects},$object);
	}
	return $objects;
}

sub util_parse_excel {
	my($self,$filename) = @_;
    if(!$filename || !-f $filename){
		Bio::KBase::utilities::error("Cannot find $filename");
    }
    if($filename !~ /\.xlsx?$/){
		Bio::KBase::utilities::error("$filename does not have excel suffix (.xls or .xlsx)");
    }

    my $excel = '';
    if($filename =~ /\.xlsx$/){
    	require "Spreadsheet/ParseXLSX.pm";
		$excel = Spreadsheet::ParseXLSX->new();
    }else{
    	require "Spreadsheet/ParseExcel.pm";
		$excel = Spreadsheet::ParseExcel->new();
    }	

    my $workbook = $excel->parse($filename);
    if(!defined $workbook){
		Bio::KBase::utilities::error("Unable to parse $filename\n");
    }

    $filename =~ s/\.xlsx?//;

    my @worksheets = $workbook->worksheets();
    my $sheets = {};
    foreach my $sheet (@worksheets){
		my $File="";
		my $Filename = $filename;
		foreach my $row ($sheet->{MinRow}..$sheet->{MaxRow}){
		    my $rowData = [];
		    foreach my $col ($sheet->{MinCol}..$sheet->{MaxCol}) {
				my $cell = $sheet->{Cells}[$row][$col];
				if(!$cell || !defined($cell->{Val})){
				    push(@{$rowData},"");
				}else{
				    push(@{$rowData},$cell->{Val});
				}
		    }
		    $File .= join("\t",@$rowData)."\n";
		}
	
		$Filename.="_".$sheet->{Name};
		$Filename.="_".join("",localtime()).".txt";
	
		open(OUT, "> $Filename");
		print OUT $File;
		close(OUT);
	
		$sheets->{$sheet->{Name}}=$Filename;
    }
    return $sheets;
}

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    Bio::KBase::utilities::read_config({
		filename => $ENV{KB_DEPLOYMENT_CONFIG},
		service => "fba_tools"
	});
    Bio::KBase::utilities::setconf("fba_tools","call_back_url",$ENV{ SDK_CALLBACK_URL });
    Bio::KBase::ObjectAPI::functions::set_handler($self);
    Bio::KBase::utilities::set_handler($self);
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 build_metabolic_model

  $return = $obj->build_metabolic_model($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.BuildMetabolicModelParams
$return is a fba_tools.BuildMetabolicModelResults
BuildMetabolicModelParams is a reference to a hash where the following keys are defined:
	genome_id has a value which is a fba_tools.genome_id
	genome_workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	template_id has a value which is a fba_tools.template_id
	template_workspace has a value which is a fba_tools.workspace_name
	coremodel has a value which is a fba_tools.bool
	gapfill_model has a value which is a fba_tools.bool
	thermodynamic_constraints has a value which is a fba_tools.bool
	comprehensive_gapfill has a value which is a fba_tools.bool
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	minimum_target_flux has a value which is a float
	number_of_solutions has a value which is an int
genome_id is a string
workspace_name is a string
media_id is a string
fbamodel_id is a string
template_id is a string
bool is an int
compound_id is a string
expseries_id is a string
BuildMetabolicModelResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
	new_fba_ref has a value which is a fba_tools.ws_fba_id
	number_gapfilled_reactions has a value which is an int
	number_removed_biomass_compounds has a value which is an int
ws_fbamodel_id is a string
ws_fba_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.BuildMetabolicModelParams
$return is a fba_tools.BuildMetabolicModelResults
BuildMetabolicModelParams is a reference to a hash where the following keys are defined:
	genome_id has a value which is a fba_tools.genome_id
	genome_workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	template_id has a value which is a fba_tools.template_id
	template_workspace has a value which is a fba_tools.workspace_name
	coremodel has a value which is a fba_tools.bool
	gapfill_model has a value which is a fba_tools.bool
	thermodynamic_constraints has a value which is a fba_tools.bool
	comprehensive_gapfill has a value which is a fba_tools.bool
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	minimum_target_flux has a value which is a float
	number_of_solutions has a value which is an int
genome_id is a string
workspace_name is a string
media_id is a string
fbamodel_id is a string
template_id is a string
bool is an int
compound_id is a string
expseries_id is a string
BuildMetabolicModelResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
	new_fba_ref has a value which is a fba_tools.ws_fba_id
	number_gapfilled_reactions has a value which is an int
	number_removed_biomass_compounds has a value which is an int
ws_fbamodel_id is a string
ws_fba_id is a string


=end text



=item Description

Build a genome-scale metabolic model based on annotations in an input genome typed object

=back

=cut

sub build_metabolic_model
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to build_metabolic_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_metabolic_model');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN build_metabolic_model
    $self->util_initialize_call($params,$ctx);
	$return = Bio::KBase::ObjectAPI::functions::func_build_metabolic_model($params);
	$self->util_finalize_call({
		output => $return,
		workspace => $params->{workspace},
		report_name => $params->{fbamodel_output_id}.".report",
	});
    #END build_metabolic_model
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to build_metabolic_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_metabolic_model');
    }
    return($return);
}




=head2 build_multiple_metabolic_models

  $return = $obj->build_multiple_metabolic_models($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.BuildMultipleMetabolicModelsParams
$return is a fba_tools.BuildMultipleMetabolicModelsResults
BuildMultipleMetabolicModelsParams is a reference to a hash where the following keys are defined:
	genome_ids has a value which is a reference to a list where each element is a fba_tools.genome_id
	genome_text has a value which is a string
	genome_workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	template_id has a value which is a fba_tools.template_id
	template_workspace has a value which is a fba_tools.workspace_name
	coremodel has a value which is a fba_tools.bool
	gapfill_model has a value which is a fba_tools.bool
	thermodynamic_constraints has a value which is a fba_tools.bool
	comprehensive_gapfill has a value which is a fba_tools.bool
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	minimum_target_flux has a value which is a float
	number_of_solutions has a value which is an int
genome_id is a string
workspace_name is a string
media_id is a string
fbamodel_id is a string
template_id is a string
bool is an int
compound_id is a string
expseries_id is a string
BuildMultipleMetabolicModelsResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
	new_fba_ref has a value which is a fba_tools.ws_fba_id
ws_fbamodel_id is a string
ws_fba_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.BuildMultipleMetabolicModelsParams
$return is a fba_tools.BuildMultipleMetabolicModelsResults
BuildMultipleMetabolicModelsParams is a reference to a hash where the following keys are defined:
	genome_ids has a value which is a reference to a list where each element is a fba_tools.genome_id
	genome_text has a value which is a string
	genome_workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	template_id has a value which is a fba_tools.template_id
	template_workspace has a value which is a fba_tools.workspace_name
	coremodel has a value which is a fba_tools.bool
	gapfill_model has a value which is a fba_tools.bool
	thermodynamic_constraints has a value which is a fba_tools.bool
	comprehensive_gapfill has a value which is a fba_tools.bool
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	minimum_target_flux has a value which is a float
	number_of_solutions has a value which is an int
genome_id is a string
workspace_name is a string
media_id is a string
fbamodel_id is a string
template_id is a string
bool is an int
compound_id is a string
expseries_id is a string
BuildMultipleMetabolicModelsResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
	new_fba_ref has a value which is a fba_tools.ws_fba_id
ws_fbamodel_id is a string
ws_fba_id is a string


=end text



=item Description

Build multiple genome-scale metabolic models based on annotations in an input genome typed object

=back

=cut

sub build_multiple_metabolic_models
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to build_multiple_metabolic_models:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_multiple_metabolic_models');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN build_multiple_metabolic_models
    $self->util_initialize_call($params,$ctx);
	my $orig_genome_workspace = $params->{genome_workspace};
	my $genomes = $params->{genome_ids};
	# If user provides a list of genomes in text form, append these to the existing gemome ids
	my $new_genome_list = [split(/[\n;\|]+/,$params->{genome_text})];
	for (my $i=0; $i < @{$new_genome_list}; $i++) {
		push(@{$genomes},$new_genome_list->[$i]);
	}
	my $htmlmessage = "<p>";
    # run build metabolic model
	for (my $i=0; $i < @{$genomes}; $i++) {
		$params->{genome_workspace} = $orig_genome_workspace;
		$params->{genome_id} = $genomes->[$i];
		$params->{fbamodel_output_id} = undef;
		print "Now building model of ".$params->{genome_id}."\n";
		eval {
			my $output = Bio::KBase::ObjectAPI::functions::func_build_metabolic_model($params);
		};
		if ($@) {
			print $@."\n";
			$htmlmessage .= $genomes->[$i]." failed!<br>";
		} else {
			$htmlmessage .= $genomes->[$i]." succeeded!<br>";
		}
	}
	$htmlmessage .= "</p>";
	Bio::KBase::utilities::print_report_message({
		message => $htmlmessage,html=>1,append => 0
	});
	$return = {};
	$self->util_finalize_call({
		output => $return,
		workspace => $params->{workspace},
		report_name => Bio::KBase::utilities::processid(),
	});
    #END build_multiple_metabolic_models
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to build_multiple_metabolic_models:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_multiple_metabolic_models');
    }
    return($return);
}




=head2 gapfill_metabolic_model

  $results = $obj->gapfill_metabolic_model($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.GapfillMetabolicModelParams
$results is a fba_tools.GapfillMetabolicModelResults
GapfillMetabolicModelParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	target_reaction has a value which is a fba_tools.reaction_id
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	thermodynamic_constraints has a value which is a fba_tools.bool
	comprehensive_gapfill has a value which is a fba_tools.bool
	source_fbamodel_id has a value which is a fba_tools.fbamodel_id
	source_fbamodel_workspace has a value which is a fba_tools.workspace_name
	feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
	reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	minimum_target_flux has a value which is a float
	number_of_solutions has a value which is an int
fbamodel_id is a string
workspace_name is a string
media_id is a string
reaction_id is a string
bool is an int
feature_id is a string
compound_id is a string
expseries_id is a string
GapfillMetabolicModelResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
	new_fba_ref has a value which is a fba_tools.ws_fba_id
	number_gapfilled_reactions has a value which is an int
	number_removed_biomass_compounds has a value which is an int
ws_fbamodel_id is a string
ws_fba_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.GapfillMetabolicModelParams
$results is a fba_tools.GapfillMetabolicModelResults
GapfillMetabolicModelParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	target_reaction has a value which is a fba_tools.reaction_id
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	thermodynamic_constraints has a value which is a fba_tools.bool
	comprehensive_gapfill has a value which is a fba_tools.bool
	source_fbamodel_id has a value which is a fba_tools.fbamodel_id
	source_fbamodel_workspace has a value which is a fba_tools.workspace_name
	feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
	reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	minimum_target_flux has a value which is a float
	number_of_solutions has a value which is an int
fbamodel_id is a string
workspace_name is a string
media_id is a string
reaction_id is a string
bool is an int
feature_id is a string
compound_id is a string
expseries_id is a string
GapfillMetabolicModelResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
	new_fba_ref has a value which is a fba_tools.ws_fba_id
	number_gapfilled_reactions has a value which is an int
	number_removed_biomass_compounds has a value which is an int
ws_fbamodel_id is a string
ws_fba_id is a string


=end text



=item Description

Gapfills a metabolic model to induce flux in a specified reaction

=back

=cut

sub gapfill_metabolic_model
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to gapfill_metabolic_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'gapfill_metabolic_model');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN gapfill_metabolic_model
    $self->util_initialize_call($params,$ctx);
	$results = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model($params);
	$self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $params->{fbamodel_output_id}.".report",
	});
    #END gapfill_metabolic_model
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to gapfill_metabolic_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'gapfill_metabolic_model');
    }
    return($results);
}




=head2 run_flux_balance_analysis

  $results = $obj->run_flux_balance_analysis($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.RunFluxBalanceAnalysisParams
$results is a fba_tools.RunFluxBalanceAnalysisResults
RunFluxBalanceAnalysisParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	target_reaction has a value which is a fba_tools.reaction_id
	fba_output_id has a value which is a fba_tools.fba_id
	workspace has a value which is a fba_tools.workspace_name
	thermodynamic_constraints has a value which is a fba_tools.bool
	fva has a value which is a fba_tools.bool
	minimize_flux has a value which is a fba_tools.bool
	simulate_ko has a value which is a fba_tools.bool
	find_min_media has a value which is a fba_tools.bool
	all_reversible has a value which is a fba_tools.bool
	feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
	reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	max_c_uptake has a value which is a float
	max_n_uptake has a value which is a float
	max_p_uptake has a value which is a float
	max_s_uptake has a value which is a float
	max_o_uptake has a value which is a float
	default_max_uptake has a value which is a float
	notes has a value which is a string
	massbalance has a value which is a string
fbamodel_id is a string
workspace_name is a string
media_id is a string
reaction_id is a string
fba_id is a string
bool is an int
feature_id is a string
compound_id is a string
expseries_id is a string
RunFluxBalanceAnalysisResults is a reference to a hash where the following keys are defined:
	new_fba_ref has a value which is a fba_tools.ws_fba_id
	objective has a value which is an int
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
ws_fba_id is a string
ws_report_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.RunFluxBalanceAnalysisParams
$results is a fba_tools.RunFluxBalanceAnalysisResults
RunFluxBalanceAnalysisParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	target_reaction has a value which is a fba_tools.reaction_id
	fba_output_id has a value which is a fba_tools.fba_id
	workspace has a value which is a fba_tools.workspace_name
	thermodynamic_constraints has a value which is a fba_tools.bool
	fva has a value which is a fba_tools.bool
	minimize_flux has a value which is a fba_tools.bool
	simulate_ko has a value which is a fba_tools.bool
	find_min_media has a value which is a fba_tools.bool
	all_reversible has a value which is a fba_tools.bool
	feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
	reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	max_c_uptake has a value which is a float
	max_n_uptake has a value which is a float
	max_p_uptake has a value which is a float
	max_s_uptake has a value which is a float
	max_o_uptake has a value which is a float
	default_max_uptake has a value which is a float
	notes has a value which is a string
	massbalance has a value which is a string
fbamodel_id is a string
workspace_name is a string
media_id is a string
reaction_id is a string
fba_id is a string
bool is an int
feature_id is a string
compound_id is a string
expseries_id is a string
RunFluxBalanceAnalysisResults is a reference to a hash where the following keys are defined:
	new_fba_ref has a value which is a fba_tools.ws_fba_id
	objective has a value which is an int
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
ws_fba_id is a string
ws_report_id is a string


=end text



=item Description

Run flux balance analysis and return ID of FBA object with results

=back

=cut

sub run_flux_balance_analysis
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_flux_balance_analysis:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_flux_balance_analysis');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN run_flux_balance_analysis
    $self->util_initialize_call($params,$ctx);
	$results = Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis($params);
	$self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $params->{fba_output_id}.".report",
	});
    #END run_flux_balance_analysis
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to run_flux_balance_analysis:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_flux_balance_analysis');
    }
    return($results);
}




=head2 compare_fba_solutions

  $results = $obj->compare_fba_solutions($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.CompareFBASolutionsParams
$results is a fba_tools.CompareFBASolutionsResults
CompareFBASolutionsParams is a reference to a hash where the following keys are defined:
	fba_id_list has a value which is a reference to a list where each element is a fba_tools.fba_id
	fba_workspace has a value which is a fba_tools.workspace_name
	fbacomparison_output_id has a value which is a fba_tools.fbacomparison_id
	workspace has a value which is a fba_tools.workspace_name
fba_id is a string
workspace_name is a string
fbacomparison_id is a string
CompareFBASolutionsResults is a reference to a hash where the following keys are defined:
	new_fbacomparison_ref has a value which is a fba_tools.ws_fbacomparison_id
ws_fbacomparison_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.CompareFBASolutionsParams
$results is a fba_tools.CompareFBASolutionsResults
CompareFBASolutionsParams is a reference to a hash where the following keys are defined:
	fba_id_list has a value which is a reference to a list where each element is a fba_tools.fba_id
	fba_workspace has a value which is a fba_tools.workspace_name
	fbacomparison_output_id has a value which is a fba_tools.fbacomparison_id
	workspace has a value which is a fba_tools.workspace_name
fba_id is a string
workspace_name is a string
fbacomparison_id is a string
CompareFBASolutionsResults is a reference to a hash where the following keys are defined:
	new_fbacomparison_ref has a value which is a fba_tools.ws_fbacomparison_id
ws_fbacomparison_id is a string


=end text



=item Description

Compares multiple FBA solutions and saves comparison as a new object in the workspace

=back

=cut

sub compare_fba_solutions
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to compare_fba_solutions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_fba_solutions');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN compare_fba_solutions
    $self->util_initialize_call($params,$ctx);
	$results = Bio::KBase::ObjectAPI::functions::func_compare_fba_solutions($params);
	$self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $params->{fbacomparison_output_id}.".report",
	});
    #END compare_fba_solutions
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to compare_fba_solutions:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_fba_solutions');
    }
    return($results);
}




=head2 propagate_model_to_new_genome

  $results = $obj->propagate_model_to_new_genome($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.PropagateModelToNewGenomeParams
$results is a fba_tools.PropagateModelToNewGenomeResults
PropagateModelToNewGenomeParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	proteincomparison_id has a value which is a fba_tools.proteincomparison_id
	proteincomparison_workspace has a value which is a fba_tools.workspace_name
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	keep_nogene_rxn has a value which is a fba_tools.bool
	gapfill_model has a value which is a fba_tools.bool
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	thermodynamic_constraints has a value which is a fba_tools.bool
	comprehensive_gapfill has a value which is a fba_tools.bool
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	translation_policy has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	minimum_target_flux has a value which is a float
	number_of_solutions has a value which is an int
fbamodel_id is a string
workspace_name is a string
proteincomparison_id is a string
bool is an int
media_id is a string
compound_id is a string
expseries_id is a string
PropagateModelToNewGenomeResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
	new_fba_ref has a value which is a fba_tools.ws_fba_id
	number_gapfilled_reactions has a value which is an int
	number_removed_biomass_compounds has a value which is an int
ws_fbamodel_id is a string
ws_fba_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.PropagateModelToNewGenomeParams
$results is a fba_tools.PropagateModelToNewGenomeResults
PropagateModelToNewGenomeParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	proteincomparison_id has a value which is a fba_tools.proteincomparison_id
	proteincomparison_workspace has a value which is a fba_tools.workspace_name
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	keep_nogene_rxn has a value which is a fba_tools.bool
	gapfill_model has a value which is a fba_tools.bool
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	thermodynamic_constraints has a value which is a fba_tools.bool
	comprehensive_gapfill has a value which is a fba_tools.bool
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	translation_policy has a value which is a string
	exp_threshold_percentile has a value which is a float
	exp_threshold_margin has a value which is a float
	activation_coefficient has a value which is a float
	omega has a value which is a float
	objective_fraction has a value which is a float
	minimum_target_flux has a value which is a float
	number_of_solutions has a value which is an int
fbamodel_id is a string
workspace_name is a string
proteincomparison_id is a string
bool is an int
media_id is a string
compound_id is a string
expseries_id is a string
PropagateModelToNewGenomeResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
	new_fba_ref has a value which is a fba_tools.ws_fba_id
	number_gapfilled_reactions has a value which is an int
	number_removed_biomass_compounds has a value which is an int
ws_fbamodel_id is a string
ws_fba_id is a string


=end text



=item Description

Translate the metabolic model of one organism to another, using a mapping of similar proteins between their genomes

=back

=cut

sub propagate_model_to_new_genome
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to propagate_model_to_new_genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'propagate_model_to_new_genome');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN propagate_model_to_new_genome
    $self->util_initialize_call($params,$ctx);
	$results = Bio::KBase::ObjectAPI::functions::func_propagate_model_to_new_genome($params);
	$self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $params->{fbamodel_output_id}.".report",
	});
    #END propagate_model_to_new_genome
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to propagate_model_to_new_genome:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'propagate_model_to_new_genome');
    }
    return($results);
}




=head2 simulate_growth_on_phenotype_data

  $results = $obj->simulate_growth_on_phenotype_data($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.SimulateGrowthOnPhenotypeDataParams
$results is a fba_tools.SimulateGrowthOnPhenotypeDataResults
SimulateGrowthOnPhenotypeDataParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	phenotypeset_id has a value which is a fba_tools.phenotypeset_id
	phenotypeset_workspace has a value which is a fba_tools.workspace_name
	phenotypesim_output_id has a value which is a fba_tools.phenotypesim_id
	workspace has a value which is a fba_tools.workspace_name
	all_reversible has a value which is a fba_tools.bool
	gapfill_phenotypes has a value which is a fba_tools.bool
	fit_phenotype_data has a value which is a fba_tools.bool
	save_fluxes has a value which is a fba_tools.bool
	add_all_transporters has a value which is a fba_tools.bool
	add_positive_transporters has a value which is a fba_tools.bool
	target_reaction has a value which is a fba_tools.reaction_id
	feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
	reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
fbamodel_id is a string
workspace_name is a string
phenotypeset_id is a string
phenotypesim_id is a string
bool is an int
reaction_id is a string
feature_id is a string
compound_id is a string
SimulateGrowthOnPhenotypeDataResults is a reference to a hash where the following keys are defined:
	new_phenotypesim_ref has a value which is a fba_tools.ws_phenotypesim_id
ws_phenotypesim_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.SimulateGrowthOnPhenotypeDataParams
$results is a fba_tools.SimulateGrowthOnPhenotypeDataResults
SimulateGrowthOnPhenotypeDataParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	phenotypeset_id has a value which is a fba_tools.phenotypeset_id
	phenotypeset_workspace has a value which is a fba_tools.workspace_name
	phenotypesim_output_id has a value which is a fba_tools.phenotypesim_id
	workspace has a value which is a fba_tools.workspace_name
	all_reversible has a value which is a fba_tools.bool
	gapfill_phenotypes has a value which is a fba_tools.bool
	fit_phenotype_data has a value which is a fba_tools.bool
	save_fluxes has a value which is a fba_tools.bool
	add_all_transporters has a value which is a fba_tools.bool
	add_positive_transporters has a value which is a fba_tools.bool
	target_reaction has a value which is a fba_tools.reaction_id
	feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
	reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
fbamodel_id is a string
workspace_name is a string
phenotypeset_id is a string
phenotypesim_id is a string
bool is an int
reaction_id is a string
feature_id is a string
compound_id is a string
SimulateGrowthOnPhenotypeDataResults is a reference to a hash where the following keys are defined:
	new_phenotypesim_ref has a value which is a fba_tools.ws_phenotypesim_id
ws_phenotypesim_id is a string


=end text



=item Description

Use Flux Balance Analysis (FBA) to simulate multiple growth phenotypes.

=back

=cut

sub simulate_growth_on_phenotype_data
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to simulate_growth_on_phenotype_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'simulate_growth_on_phenotype_data');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN simulate_growth_on_phenotype_data
    $self->util_initialize_call($params,$ctx);
	$results = Bio::KBase::ObjectAPI::functions::func_simulate_growth_on_phenotype_data($params);
	$self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $params->{phenotypesim_output_id}.".report",
	});
    #END simulate_growth_on_phenotype_data
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to simulate_growth_on_phenotype_data:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'simulate_growth_on_phenotype_data');
    }
    return($results);
}




=head2 merge_metabolic_models_into_community_model

  $results = $obj->merge_metabolic_models_into_community_model($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.MergeMetabolicModelsIntoCommunityModelParams
$results is a fba_tools.MergeMetabolicModelsIntoCommunityModelResults
MergeMetabolicModelsIntoCommunityModelParams is a reference to a hash where the following keys are defined:
	fbamodel_id_list has a value which is a reference to a list where each element is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	mixed_bag_model has a value which is a fba_tools.bool
fbamodel_id is a string
workspace_name is a string
bool is an int
MergeMetabolicModelsIntoCommunityModelResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
ws_fbamodel_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.MergeMetabolicModelsIntoCommunityModelParams
$results is a fba_tools.MergeMetabolicModelsIntoCommunityModelResults
MergeMetabolicModelsIntoCommunityModelParams is a reference to a hash where the following keys are defined:
	fbamodel_id_list has a value which is a reference to a list where each element is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	fbamodel_output_id has a value which is a fba_tools.fbamodel_id
	workspace has a value which is a fba_tools.workspace_name
	mixed_bag_model has a value which is a fba_tools.bool
fbamodel_id is a string
workspace_name is a string
bool is an int
MergeMetabolicModelsIntoCommunityModelResults is a reference to a hash where the following keys are defined:
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
ws_fbamodel_id is a string


=end text



=item Description

Merge two or more metabolic models into a compartmentalized community model

=back

=cut

sub merge_metabolic_models_into_community_model
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to merge_metabolic_models_into_community_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'merge_metabolic_models_into_community_model');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN merge_metabolic_models_into_community_model
    $self->util_initialize_call($params,$ctx);
	$results = Bio::KBase::ObjectAPI::functions::func_merge_metabolic_models_into_community_model($params);
	$self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $params->{fbamodel_output_id}.".report",
	});
    #END merge_metabolic_models_into_community_model
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to merge_metabolic_models_into_community_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'merge_metabolic_models_into_community_model');
    }
    return($results);
}




=head2 view_flux_network

  $results = $obj->view_flux_network($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ViewFluxNetworkParams
$results is a fba_tools.ViewFluxNetworkResults
ViewFluxNetworkParams is a reference to a hash where the following keys are defined:
	fba_id has a value which is a fba_tools.fba_id
	fba_workspace has a value which is a fba_tools.workspace_name
	workspace has a value which is a fba_tools.workspace_name
fba_id is a string
workspace_name is a string
ViewFluxNetworkResults is a reference to a hash where the following keys are defined:
	new_report_ref has a value which is a fba_tools.ws_report_id
ws_report_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.ViewFluxNetworkParams
$results is a fba_tools.ViewFluxNetworkResults
ViewFluxNetworkParams is a reference to a hash where the following keys are defined:
	fba_id has a value which is a fba_tools.fba_id
	fba_workspace has a value which is a fba_tools.workspace_name
	workspace has a value which is a fba_tools.workspace_name
fba_id is a string
workspace_name is a string
ViewFluxNetworkResults is a reference to a hash where the following keys are defined:
	new_report_ref has a value which is a fba_tools.ws_report_id
ws_report_id is a string


=end text



=item Description

Merge two or more metabolic models into a compartmentalized community model

=back

=cut

sub view_flux_network
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to view_flux_network:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'view_flux_network');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN view_flux_network
	$self->util_initialize_call($params,$ctx);
	my $output = Bio::KBase::ObjectAPI::functions::func_view_flux_network($params);
	my $path = Bio::KBase::utilities::conf("ModelSEED","fbajobdir")."zippedhtml";
	my $zip = Archive::Zip->new();
	$zip->addTree( $output->{path} );
	File::Path::mkpath([$path], 1);
	$zip->writeToFileNamed($path."/NetworkViewer.zip");
    my $file = $path."/NetworkViewer.zip";
	my $token = Bio::KBase::utilities::token();
	my $url   = Bio::KBase::utilities::conf("fba_tools","shock-url");
	my $attr  = q('{"file":"reporter"}');
	my $cmd   = 'curl --connect-timeout 100 -s -X POST -F attributes=@- -F upload=@'.$file." $url/node ";
	$cmd     .= " -H 'Authorization: OAuth $token'";
	my $out   = `echo $attr | $cmd` or die "Connection timeout uploading file to Shock: $file\n";
	my $json  = Bio::KBase::ObjectAPI::utilities::FROMJSON($out);
	$json->{status} == 200 or die "Error uploading file: $file\n".$json->{status}." ".$json->{error}->[0]."\n";
	my $handle_service = Bio::KBase::HandleService->new(Bio::KBase::utilities::conf("fba_tools","handle-service-url"));
	my $hid = $handle_service->persist_handle({
		url => $url,
		type => 'shock',
		id => $json->{data}->{id}
	});
	my $report_name = $params->{fba_id} =~ s/\//-/gr.".view_flux_network.report";
	my $meta = $self->util_save_object({
		direct_html_link_index => 0,
		html_window_height => undef,
		html_links => [{
			label => "Species interaction view",
			name => "index.html",
			handle => $hid,
			description => "Species interaction view",
			URL => $url."/node/".$json->{data}->{id}
		}],
		file_links => [],
		direct_html => undef,
		text_message => undef,
		summary_window_height => undef,
		objects_created => []
	},Bio::KBase::utilities::buildref($report_name,$params->{workspace}),{hash => 1,type => "KBaseReport.Report", hidden => 1});
    $results = {
    	report_ref => $meta->[6]."/".$meta->[0]."/".$meta->[4],
		report_name => $report_name
    };
    #END view_flux_network
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to view_flux_network:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'view_flux_network');
    }
    return($results);
}




=head2 compare_flux_with_expression

  $results = $obj->compare_flux_with_expression($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.CompareFluxWithExpressionParams
$results is a fba_tools.CompareFluxWithExpressionResults
CompareFluxWithExpressionParams is a reference to a hash where the following keys are defined:
	fba_id has a value which is a fba_tools.fba_id
	fba_workspace has a value which is a fba_tools.workspace_name
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	estimate_threshold has a value which is a fba_tools.bool
	maximize_agreement has a value which is a fba_tools.bool
	fbapathwayanalysis_output_id has a value which is a fba_tools.fbapathwayanalysis_id
	workspace has a value which is a fba_tools.workspace_name
fba_id is a string
workspace_name is a string
expseries_id is a string
bool is an int
fbapathwayanalysis_id is a string
CompareFluxWithExpressionResults is a reference to a hash where the following keys are defined:
	new_fbapathwayanalysis_ref has a value which is a fba_tools.ws_fbapathwayanalysis_id
ws_fbapathwayanalysis_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.CompareFluxWithExpressionParams
$results is a fba_tools.CompareFluxWithExpressionResults
CompareFluxWithExpressionParams is a reference to a hash where the following keys are defined:
	fba_id has a value which is a fba_tools.fba_id
	fba_workspace has a value which is a fba_tools.workspace_name
	expseries_id has a value which is a fba_tools.expseries_id
	expseries_workspace has a value which is a fba_tools.workspace_name
	expression_condition has a value which is a string
	exp_threshold_percentile has a value which is a float
	estimate_threshold has a value which is a fba_tools.bool
	maximize_agreement has a value which is a fba_tools.bool
	fbapathwayanalysis_output_id has a value which is a fba_tools.fbapathwayanalysis_id
	workspace has a value which is a fba_tools.workspace_name
fba_id is a string
workspace_name is a string
expseries_id is a string
bool is an int
fbapathwayanalysis_id is a string
CompareFluxWithExpressionResults is a reference to a hash where the following keys are defined:
	new_fbapathwayanalysis_ref has a value which is a fba_tools.ws_fbapathwayanalysis_id
ws_fbapathwayanalysis_id is a string


=end text



=item Description

Merge two or more metabolic models into a compartmentalized community model

=back

=cut

sub compare_flux_with_expression
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to compare_flux_with_expression:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_flux_with_expression');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN compare_flux_with_expression
    $self->util_initialize_call($params,$ctx);
	$results = Bio::KBase::ObjectAPI::functions::func_compare_flux_with_expression($params);
	$self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $params->{fbapathwayanalysis_output_id}.".report",
	});
    #END compare_flux_with_expression
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to compare_flux_with_expression:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_flux_with_expression');
    }
    return($results);
}




=head2 check_model_mass_balance

  $results = $obj->check_model_mass_balance($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.CheckModelMassBalanceParams
$results is a fba_tools.CheckModelMassBalanceResults
CheckModelMassBalanceParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	workspace has a value which is a fba_tools.workspace_name
fbamodel_id is a string
workspace_name is a string
CheckModelMassBalanceResults is a reference to a hash where the following keys are defined:
	new_report_ref has a value which is a fba_tools.ws_report_id
ws_report_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.CheckModelMassBalanceParams
$results is a fba_tools.CheckModelMassBalanceResults
CheckModelMassBalanceParams is a reference to a hash where the following keys are defined:
	fbamodel_id has a value which is a fba_tools.fbamodel_id
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	workspace has a value which is a fba_tools.workspace_name
fbamodel_id is a string
workspace_name is a string
CheckModelMassBalanceResults is a reference to a hash where the following keys are defined:
	new_report_ref has a value which is a fba_tools.ws_report_id
ws_report_id is a string


=end text



=item Description

Identifies reactions in the model that are not mass balanced

=back

=cut

sub check_model_mass_balance
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to check_model_mass_balance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'check_model_mass_balance');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN check_model_mass_balance
    $self->util_initialize_call($params,$ctx);
	$results = {};
	my $model_name = Bio::KBase::ObjectAPI::functions::func_check_model_mass_balance($params);
	$params->{fbamodel_id} =~ s/\//-/g;
    $self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $model_name.".check_mass_balance.report",
	});
    #END check_model_mass_balance
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to check_model_mass_balance:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'check_model_mass_balance');
    }
    return($results);
}




=head2 predict_auxotrophy

  $results = $obj->predict_auxotrophy($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.PredictAuxotrophyParams
$results is a fba_tools.PredictAuxotrophyResults
PredictAuxotrophyParams is a reference to a hash where the following keys are defined:
	genome_ids has a value which is a reference to a list where each element is a fba_tools.genome_id
	genome_workspace has a value which is a fba_tools.workspace_name
	workspace has a value which is a fba_tools.workspace_name
genome_id is a string
workspace_name is a string
PredictAuxotrophyResults is a reference to a hash where the following keys are defined:
	new_report_ref has a value which is a fba_tools.ws_report_id
ws_report_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.PredictAuxotrophyParams
$results is a fba_tools.PredictAuxotrophyResults
PredictAuxotrophyParams is a reference to a hash where the following keys are defined:
	genome_ids has a value which is a reference to a list where each element is a fba_tools.genome_id
	genome_workspace has a value which is a fba_tools.workspace_name
	workspace has a value which is a fba_tools.workspace_name
genome_id is a string
workspace_name is a string
PredictAuxotrophyResults is a reference to a hash where the following keys are defined:
	new_report_ref has a value which is a fba_tools.ws_report_id
ws_report_id is a string


=end text



=item Description

Identifies reactions in the model that are not mass balanced

=back

=cut

sub predict_auxotrophy
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to predict_auxotrophy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'predict_auxotrophy');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($results);
    #BEGIN predict_auxotrophy
    $self->util_initialize_call($params,$ctx);
	$params = Bio::KBase::utilities::args($params,[],{genome_workspace => $params->{workspace}});
	my $new_genome_list = [split(/[\n;\|]+/,$params->{genome_text})];
	for (my $i=0; $i < @{$new_genome_list}; $i++) {
		push(@{$params->{genome_ids}},Bio::KBase::utilities::buildref($new_genome_list->[$i],$params->{genome_workspace}));
	}
	delete $params->{genome_text};
	$results = {};
	Bio::KBase::ObjectAPI::functions::func_predict_auxotrophy($params);
	$self->util_finalize_call({
		output => $results,
		workspace => $params->{workspace},
		report_name => $params->{media_output_id}.".auxotrophy.report",
	});
    #END predict_auxotrophy
    my @_bad_returns;
    (ref($results) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to predict_auxotrophy:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'predict_auxotrophy');
    }
    return($results);
}




=head2 compare_models

  $return = $obj->compare_models($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ModelComparisonParams
$return is a fba_tools.ModelComparisonResult
ModelComparisonParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a fba_tools.workspace_name
	mc_name has a value which is a string
	model_refs has a value which is a reference to a list where each element is a fba_tools.ws_fbamodel_id
	protcomp_ref has a value which is a fba_tools.ws_proteomecomparison_id
	pangenome_ref has a value which is a fba_tools.ws_pangenome_id
workspace_name is a string
ws_fbamodel_id is a string
ws_proteomecomparison_id is a string
ws_pangenome_id is a string
ModelComparisonResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
	mc_ref has a value which is a string
ws_report_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.ModelComparisonParams
$return is a fba_tools.ModelComparisonResult
ModelComparisonParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a fba_tools.workspace_name
	mc_name has a value which is a string
	model_refs has a value which is a reference to a list where each element is a fba_tools.ws_fbamodel_id
	protcomp_ref has a value which is a fba_tools.ws_proteomecomparison_id
	pangenome_ref has a value which is a fba_tools.ws_pangenome_id
workspace_name is a string
ws_fbamodel_id is a string
ws_proteomecomparison_id is a string
ws_pangenome_id is a string
ModelComparisonResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
	mc_ref has a value which is a string
ws_report_id is a string


=end text



=item Description

Compare models

=back

=cut

sub compare_models
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to compare_models:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_models');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN compare_models
    $self->util_initialize_call($params,$ctx);
	$return = Bio::KBase::ObjectAPI::functions::func_compare_models($params);
	$self->util_finalize_call({
		output => $return,
		workspace => $params->{workspace},
		report_name => $params->{mc_name}.".report",
	});
    #END compare_models
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to compare_models:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_models');
    }
    return($return);
}




=head2 edit_metabolic_model

  $return = $obj->edit_metabolic_model($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.EditMetabolicModelParams
$return is a fba_tools.EditMetabolicModelResult
EditMetabolicModelParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a fba_tools.workspace_name
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	fbamodel_id has a value which is a fba_tools.ws_fbamodel_id
	fbamodel_output_id has a value which is a fba_tools.ws_fbamodel_id
	compounds_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	compounds_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	biomasses_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	biomass_compounds_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	reactions_to_remove has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	reactions_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	reactions_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	edit_compound_stoichiometry has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
workspace_name is a string
ws_fbamodel_id is a string
EditMetabolicModelResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
ws_report_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.EditMetabolicModelParams
$return is a fba_tools.EditMetabolicModelResult
EditMetabolicModelParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a fba_tools.workspace_name
	fbamodel_workspace has a value which is a fba_tools.workspace_name
	fbamodel_id has a value which is a fba_tools.ws_fbamodel_id
	fbamodel_output_id has a value which is a fba_tools.ws_fbamodel_id
	compounds_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	compounds_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	biomasses_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	biomass_compounds_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	reactions_to_remove has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	reactions_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	reactions_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
	edit_compound_stoichiometry has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
workspace_name is a string
ws_fbamodel_id is a string
EditMetabolicModelResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
	new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
ws_report_id is a string


=end text



=item Description

Edit models

=back

=cut

sub edit_metabolic_model
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to edit_metabolic_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'edit_metabolic_model');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN edit_metabolic_model
    $self->util_initialize_call($params,$ctx);
    print Bio::KBase::utilities::to_json($params,1);
	$return = Bio::KBase::ObjectAPI::functions::func_edit_metabolic_model($params);
	$self->util_finalize_call({
		output => $return,
		workspace => $params->{workspace},
		report_name => $params->{fbamodel_output_id}.".report",
	});
    #END edit_metabolic_model
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to edit_metabolic_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'edit_metabolic_model');
    }
    return($return);
}




=head2 edit_media

  $return = $obj->edit_media($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.EditMediaParams
$return is a fba_tools.EditMediaResult
EditMediaParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	compounds_to_remove has a value which is a reference to a list where each element is a fba_tools.compound_id
	compounds_to_change has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a fba_tools.compound_id
		1: (concentration) a float
		2: (min_flux) a float
		3: (max_flux) a float

	compounds_to_add has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a fba_tools.compound_id
		1: (concentration) a float
		2: (min_flux) a float
		3: (max_flux) a float

	pH_data has a value which is a string
	temperature has a value which is a float
	isDefined has a value which is a fba_tools.bool
	type has a value which is a string
	media_output_id has a value which is a fba_tools.media_id
workspace_name is a string
media_id is a string
compound_id is a string
bool is an int
EditMediaResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
	new_media_id has a value which is a fba_tools.media_id
ws_report_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.EditMediaParams
$return is a fba_tools.EditMediaResult
EditMediaParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a fba_tools.workspace_name
	media_id has a value which is a fba_tools.media_id
	media_workspace has a value which is a fba_tools.workspace_name
	compounds_to_remove has a value which is a reference to a list where each element is a fba_tools.compound_id
	compounds_to_change has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a fba_tools.compound_id
		1: (concentration) a float
		2: (min_flux) a float
		3: (max_flux) a float

	compounds_to_add has a value which is a reference to a list where each element is a reference to a list containing 4 items:
		0: a fba_tools.compound_id
		1: (concentration) a float
		2: (min_flux) a float
		3: (max_flux) a float

	pH_data has a value which is a string
	temperature has a value which is a float
	isDefined has a value which is a fba_tools.bool
	type has a value which is a string
	media_output_id has a value which is a fba_tools.media_id
workspace_name is a string
media_id is a string
compound_id is a string
bool is an int
EditMediaResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
	new_media_id has a value which is a fba_tools.media_id
ws_report_id is a string


=end text



=item Description

Edit models

=back

=cut

sub edit_media
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to edit_media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'edit_media');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN edit_media
    $self->util_initialize_call($params,$ctx);
	print Bio::KBase::utilities::to_json($params,1);
	$return = Bio::KBase::ObjectAPI::functions::func_create_or_edit_media($params);
	$self->util_finalize_call({
		output => $return,
		workspace => $params->{workspace},
		report_name => $params->{media_output_id}.".report",
	});
    #END edit_media
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to edit_media:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'edit_media');
    }
    return($return);
}




=head2 excel_file_to_model

  $return = $obj->excel_file_to_model($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a fba_tools.ModelCreationParams
$return is a fba_tools.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a fba_tools.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a fba_tools.ModelCreationParams
$return is a fba_tools.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a fba_tools.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub excel_file_to_model
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to excel_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'excel_file_to_model');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN excel_file_to_model
    $self->util_initialize_call($p,$ctx);
    my $input = {
		model_name => $p->{model_name},
		workspace_name => $p->{workspace_name},
		genome_workspace => $p->{workspace_name},
		genome => $p->{genome},
		reactions => [],
		compounds => [],
		biomass => $p->{biomass},
	};
	my $file_path = $self->util_get_file_path($p->{model_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
    my $sheets = $self->util_parse_excel($file_path);
	my $compounds = (grep { $_ =~ /Compound/i } keys %$sheets)[0];
	my $reactions = (grep { $_ =~ /Reaction/i } keys %$sheets)[0];
    $input->{reactions} = $self->util_parse_input_table($sheets->{$reactions},[
		["id",1],
		["direction",0,"="],
		["compartment",0,"c"],
		["gpr",1],
		["name",0,undef],
		["enzyme",0,undef],
		["pathway",0,undef],
		["reference",0,undef],
		["equation",0,undef],
	]);
	$input->{compounds} = $self->util_parse_input_table($sheets->{$compounds},[
		["id",1],
		["charge",0,undef],
		["formula",0,undef],
		["name",1],
		["aliases",0,undef],
 		['smiles',0,undef],
 		['inchikey',0,undef]
	]);
    $return = Bio::KBase::ObjectAPI::functions::func_importmodel($input);
    #END excel_file_to_model
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to excel_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'excel_file_to_model');
    }
    return($return);
}




=head2 sbml_file_to_model

  $return = $obj->sbml_file_to_model($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a fba_tools.ModelCreationParams
$return is a fba_tools.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a fba_tools.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a fba_tools.ModelCreationParams
$return is a fba_tools.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a fba_tools.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub sbml_file_to_model
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to sbml_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'sbml_file_to_model');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN sbml_file_to_model
    $self->util_initialize_call($p,$ctx);
    my $file_path = $self->util_get_file_path($p->{model_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
    my $input = {
		sbml => "",
		model_name => $p->{model_name},
		workspace_name => $p->{workspace_name},
		genome_workspace => $p->{workspace_name},
		genome => $p->{genome},
		reactions => [],
		compounds => [],
		biomass => $p->{biomass},
	};
	open(my $fh, "<", $file_path);
	while (my $line = <$fh>) {
		$input->{sbml} .= $line;
	}
	close($fh);
	if (defined($p->{compounds_file})) {
		my $cpd_file_path = $self->util_get_file_path($p->{compounds_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
		if (-e $cpd_file_path) {
			$input->{compounds} = $self->util_parse_input_table($cpd_file_path,[
				["id",1],
				["charge",0,undef],
				["formula",0,undef],
				["name",1],
				["aliases",0,undef],
				['smiles',0,undef],
		 		['inchikey',0,undef]
			]);
		}
	}
    $return = Bio::KBase::ObjectAPI::functions::func_importmodel($input);
    #END sbml_file_to_model
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to sbml_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'sbml_file_to_model');
    }
    return($return);
}




=head2 tsv_file_to_model

  $return = $obj->tsv_file_to_model($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a fba_tools.ModelCreationParams
$return is a fba_tools.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a fba_tools.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a fba_tools.ModelCreationParams
$return is a fba_tools.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a fba_tools.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub tsv_file_to_model
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to tsv_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_model');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN tsv_file_to_model
    $self->util_initialize_call($p,$ctx);
    my $input = {
		model_name => $p->{model_name},
		workspace_name => $p->{workspace_name},
		genome_workspace => $p->{workspace_name},
		genome => $p->{genome},
		reactions => [],
		compounds => [],
		biomass => $p->{biomass},
	};
	my $file_path = $self->util_get_file_path($p->{model_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
    my $cpd_file_path = $self->util_get_file_path($p->{compounds_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
	$input->{reactions} = $self->util_parse_input_table($file_path,[
		["id",1],
		["direction",0,"="],
		["compartment",0,"c"],
		["gpr",1],
		["name",0,undef],
		["enzyme",0,undef],
		["pathway",0,undef],
		["reference",0,undef],
		["equation",0,undef],
	]);
	$input->{compounds} = $self->util_parse_input_table($cpd_file_path,[
		["id",1],
		["charge",0,undef],
		["formula",0,undef],
		["name",1],
		["aliases",0,undef],
		["compartment",0,undef],
 		['smiles',0,undef],
 		['inchikey',0,undef]
	]);
    $return = Bio::KBase::ObjectAPI::functions::func_importmodel($input);
    #END tsv_file_to_model
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to tsv_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_model');
    }
    return($return);
}




=head2 model_to_excel_file

  $f = $obj->model_to_excel_file($model)

=over 4

=item Parameter and return types

=begin html

<pre>
$model is a fba_tools.ModelObjectSelectionParams
$f is a fba_tools.File
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
	fulldb has a value which is a fba_tools.bool
boolean is an int
bool is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$model is a fba_tools.ModelObjectSelectionParams
$f is a fba_tools.File
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
	fulldb has a value which is a fba_tools.bool
boolean is an int
bool is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub model_to_excel_file
{
    my $self = shift;
    my($model) = @_;

    my @_bad_arguments;
    (ref($model) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"model\" (value was \"$model\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to model_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_excel_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($f);
    #BEGIN model_to_excel_file
    $self->util_initialize_call($model,$ctx);
    my $input = {
		object => "model",
		format => "excel",
		file_util => 1
	};
    if (defined($model->{fulldb}) && $model->{fulldb} == 1) {
    	$input->{format} = "fullexcel";
    }
    $f = Bio::KBase::ObjectAPI::functions::func_export($model,$input);
    #END model_to_excel_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to model_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_excel_file');
    }
    return($f);
}




=head2 model_to_sbml_file

  $f = $obj->model_to_sbml_file($model)

=over 4

=item Parameter and return types

=begin html

<pre>
$model is a fba_tools.ModelObjectSelectionParams
$f is a fba_tools.File
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
	fulldb has a value which is a fba_tools.bool
boolean is an int
bool is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$model is a fba_tools.ModelObjectSelectionParams
$f is a fba_tools.File
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
	fulldb has a value which is a fba_tools.bool
boolean is an int
bool is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub model_to_sbml_file
{
    my $self = shift;
    my($model) = @_;

    my @_bad_arguments;
    (ref($model) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"model\" (value was \"$model\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to model_to_sbml_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_sbml_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($f);
    #BEGIN model_to_sbml_file
    $self->util_initialize_call($model,$ctx);
    $f = Bio::KBase::ObjectAPI::functions::func_export($model,{
		object => "model",
		format => "sbml",
		file_util => 1
	});
    #END model_to_sbml_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to model_to_sbml_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_sbml_file');
    }
    return($f);
}




=head2 model_to_tsv_file

  $files = $obj->model_to_tsv_file($model)

=over 4

=item Parameter and return types

=begin html

<pre>
$model is a fba_tools.ModelObjectSelectionParams
$files is a fba_tools.ModelTsvFiles
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
	fulldb has a value which is a fba_tools.bool
boolean is an int
bool is an int
ModelTsvFiles is a reference to a hash where the following keys are defined:
	compounds_file has a value which is a fba_tools.File
	reactions_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$model is a fba_tools.ModelObjectSelectionParams
$files is a fba_tools.ModelTsvFiles
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
	fulldb has a value which is a fba_tools.bool
boolean is an int
bool is an int
ModelTsvFiles is a reference to a hash where the following keys are defined:
	compounds_file has a value which is a fba_tools.File
	reactions_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub model_to_tsv_file
{
    my $self = shift;
    my($model) = @_;

    my @_bad_arguments;
    (ref($model) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"model\" (value was \"$model\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to model_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($files);
    #BEGIN model_to_tsv_file
    $self->util_initialize_call($model,$ctx);
    my $input = {
		object => "model",
		format => "tsv",
		file_util => 1
	};
    if (defined($model->{fulldb}) && $model->{fulldb} == 1) {
    	$input->{format} = "fulltsv";
    }
    $files = Bio::KBase::ObjectAPI::functions::func_export($model,$input);
    #END model_to_tsv_file
    my @_bad_returns;
    (ref($files) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"files\" (value was \"$files\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to model_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_tsv_file');
    }
    return($files);
}




=head2 export_model_as_excel_file

  $output = $obj->export_model_as_excel_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_model_as_excel_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_model_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_excel_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_model_as_excel_file
    $self->util_initialize_call($params,$ctx);
    my $input = {
		object => "model",
		format => "excel"
	};
    if (defined($params->{fulldb}) && $params->{fulldb} == 1) {
    	$input->{format} = "fullexcel";
    }
    $output = Bio::KBase::ObjectAPI::functions::func_export($params,$input);
    #END export_model_as_excel_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_model_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_excel_file');
    }
    return($output);
}




=head2 export_model_as_tsv_file

  $output = $obj->export_model_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_model_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_model_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_model_as_tsv_file
    $self->util_initialize_call($params,$ctx);
    my $input = {
		object => "model",
		format => "tsv"
	};
    if (defined($params->{fulldb}) && $params->{fulldb} == 1) {
    	$input->{format} = "fulltsv";
    }
    $output = Bio::KBase::ObjectAPI::functions::func_export($params,$input);
    #END export_model_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_model_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_tsv_file');
    }
    return($output);
}




=head2 export_model_as_sbml_file

  $output = $obj->export_model_as_sbml_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_model_as_sbml_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_model_as_sbml_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_sbml_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_model_as_sbml_file
    $self->util_initialize_call($params,$ctx);
    $output = Bio::KBase::ObjectAPI::functions::func_export($params,{
		object => "model",
		format => "sbml"
	});
    #END export_model_as_sbml_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_model_as_sbml_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_sbml_file');
    }
    return($output);
}




=head2 fba_to_excel_file

  $f = $obj->fba_to_excel_file($fba)

=over 4

=item Parameter and return types

=begin html

<pre>
$fba is a fba_tools.FBAObjectSelectionParams
$f is a fba_tools.File
FBAObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	fba_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$fba is a fba_tools.FBAObjectSelectionParams
$f is a fba_tools.File
FBAObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	fba_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub fba_to_excel_file
{
    my $self = shift;
    my($fba) = @_;

    my @_bad_arguments;
    (ref($fba) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"fba\" (value was \"$fba\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fba_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fba_to_excel_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($f);
    #BEGIN fba_to_excel_file
    $self->util_initialize_call($fba,$ctx);
    $f = Bio::KBase::ObjectAPI::functions::func_export($fba,{
		object => "fba",
		format => "excel",
		file_util => 1
	});
    #END fba_to_excel_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fba_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fba_to_excel_file');
    }
    return($f);
}




=head2 fba_to_tsv_file

  $files = $obj->fba_to_tsv_file($fba)

=over 4

=item Parameter and return types

=begin html

<pre>
$fba is a fba_tools.FBAObjectSelectionParams
$files is a fba_tools.FBATsvFiles
FBAObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	fba_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
FBATsvFiles is a reference to a hash where the following keys are defined:
	compounds_file has a value which is a fba_tools.File
	reactions_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$fba is a fba_tools.FBAObjectSelectionParams
$files is a fba_tools.FBATsvFiles
FBAObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	fba_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
FBATsvFiles is a reference to a hash where the following keys are defined:
	compounds_file has a value which is a fba_tools.File
	reactions_file has a value which is a fba_tools.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub fba_to_tsv_file
{
    my $self = shift;
    my($fba) = @_;

    my @_bad_arguments;
    (ref($fba) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"fba\" (value was \"$fba\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fba_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fba_to_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($files);
    #BEGIN fba_to_tsv_file
    $self->util_initialize_call($fba,$ctx);
    $files = Bio::KBase::ObjectAPI::functions::func_export($fba,{
		object => "fba",
		format => "tsv",
		file_util => 1
	});
    #END fba_to_tsv_file
    my @_bad_returns;
    (ref($files) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"files\" (value was \"$files\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fba_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fba_to_tsv_file');
    }
    return($files);
}




=head2 export_fba_as_excel_file

  $output = $obj->export_fba_as_excel_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_fba_as_excel_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_fba_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_fba_as_excel_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_fba_as_excel_file
    $self->util_initialize_call($params,$ctx);
    $output = Bio::KBase::ObjectAPI::functions::func_export($params,{
		object => "fba",
		format => "excel"
	});
    #END export_fba_as_excel_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_fba_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_fba_as_excel_file');
    }
    return($output);
}




=head2 export_fba_as_tsv_file

  $output = $obj->export_fba_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_fba_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_fba_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_fba_as_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_fba_as_tsv_file
    $self->util_initialize_call($params,$ctx);
    $output = Bio::KBase::ObjectAPI::functions::func_export($params,{
		object => "fba",
		format => "tsv"
	});
    #END export_fba_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_fba_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_fba_as_tsv_file');
    }
    return($output);
}




=head2 tsv_file_to_media

  $return = $obj->tsv_file_to_media($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a fba_tools.MediaCreationParams
$return is a fba_tools.WorkspaceRef
MediaCreationParams is a reference to a hash where the following keys are defined:
	media_file has a value which is a fba_tools.File
	media_name has a value which is a string
	workspace_name has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a fba_tools.MediaCreationParams
$return is a fba_tools.WorkspaceRef
MediaCreationParams is a reference to a hash where the following keys are defined:
	media_file has a value which is a fba_tools.File
	media_name has a value which is a string
	workspace_name has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub tsv_file_to_media
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to tsv_file_to_media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_media');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN tsv_file_to_media
    $self->util_initialize_call($p,$ctx);
    my $file_path = $self->util_get_file_path($p->{media_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
    my $mediadata = $self->util_parse_input_table($file_path,[
		["compounds",1],
		["concentration",0,"0.001"],
		["minflux",0,"-100"],
		["maxflux",0,"100"],
	]);
	my $input = {media_id => $p->{media_name},workspace => $p->{workspace_name}};
	for (my $i=0; $i < @{$mediadata}; $i++) {
		push(@{$input->{compounds}},$mediadata->[$i]->[0]);
		push(@{$input->{maxflux}},$mediadata->[$i]->[3]);
		push(@{$input->{minflux}},$mediadata->[$i]->[2]);
		push(@{$input->{concentrations}},$mediadata->[$i]->[1]);
	}
    $return = Bio::KBase::ObjectAPI::functions::func_import_media($input);
    #END tsv_file_to_media
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to tsv_file_to_media:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_media');
    }
    return($return);
}




=head2 excel_file_to_media

  $return = $obj->excel_file_to_media($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a fba_tools.MediaCreationParams
$return is a fba_tools.WorkspaceRef
MediaCreationParams is a reference to a hash where the following keys are defined:
	media_file has a value which is a fba_tools.File
	media_name has a value which is a string
	workspace_name has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a fba_tools.MediaCreationParams
$return is a fba_tools.WorkspaceRef
MediaCreationParams is a reference to a hash where the following keys are defined:
	media_file has a value which is a fba_tools.File
	media_name has a value which is a string
	workspace_name has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub excel_file_to_media
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to excel_file_to_media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'excel_file_to_media');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN excel_file_to_media
    $self->util_initialize_call($p,$ctx);
    my $file_path = $self->util_get_file_path($p->{media_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
    my $sheets = $self->util_parse_excel($file_path);
	my $Media = (grep { $_ =~ /[Mm]edia/ } keys %$sheets)[0];
    my $mediadata = $self->util_parse_input_table($sheets->{$Media},[
		["compounds",1],
		["concentration",0,"0.001"],
		["minflux",0,"-100"],
		["maxflux",0,"100"],
	]);
	my $input = {media_id => $p->{media_name},workspace => $p->{workspace_name}};
	for (my $i=0; $i < @{$mediadata}; $i++) {
		push(@{$input->{compounds}},$mediadata->[$i]->[0]);
		push(@{$input->{maxflux}},$mediadata->[$i]->[3]);
		push(@{$input->{minflux}},$mediadata->[$i]->[2]);
		push(@{$input->{concentrations}},$mediadata->[$i]->[1]);
	}
    $return = Bio::KBase::ObjectAPI::functions::func_import_media($input);
    #END excel_file_to_media
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to excel_file_to_media:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'excel_file_to_media');
    }
    return($return);
}




=head2 media_to_tsv_file

  $f = $obj->media_to_tsv_file($media)

=over 4

=item Parameter and return types

=begin html

<pre>
$media is a fba_tools.MediaObjectSelectionParams
$f is a fba_tools.File
MediaObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	media_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$media is a fba_tools.MediaObjectSelectionParams
$f is a fba_tools.File
MediaObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	media_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub media_to_tsv_file
{
    my $self = shift;
    my($media) = @_;

    my @_bad_arguments;
    (ref($media) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"media\" (value was \"$media\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to media_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'media_to_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($f);
    #BEGIN media_to_tsv_file
    $self->util_initialize_call($media,$ctx);
    $f = Bio::KBase::ObjectAPI::functions::func_export($media,{
		object => "media",
		format => "tsv",
		file_util => 1
	});
    #END media_to_tsv_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to media_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'media_to_tsv_file');
    }
    return($f);
}




=head2 media_to_excel_file

  $f = $obj->media_to_excel_file($media)

=over 4

=item Parameter and return types

=begin html

<pre>
$media is a fba_tools.MediaObjectSelectionParams
$f is a fba_tools.File
MediaObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	media_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$media is a fba_tools.MediaObjectSelectionParams
$f is a fba_tools.File
MediaObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	media_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub media_to_excel_file
{
    my $self = shift;
    my($media) = @_;

    my @_bad_arguments;
    (ref($media) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"media\" (value was \"$media\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to media_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'media_to_excel_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($f);
    #BEGIN media_to_excel_file
    $self->util_initialize_call($media,$ctx);
    $f = Bio::KBase::ObjectAPI::functions::func_export($media,{
		object => "media",
		format => "excel",
		file_util => 1
	});
    #END media_to_excel_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to media_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'media_to_excel_file');
    }
    return($f);
}




=head2 export_media_as_excel_file

  $output = $obj->export_media_as_excel_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_media_as_excel_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_media_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media_as_excel_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_media_as_excel_file
    $self->util_initialize_call($params,$ctx);
    $output = Bio::KBase::ObjectAPI::functions::func_export($params,{
		object => "media",
		format => "excel"
	});
    #END export_media_as_excel_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_media_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media_as_excel_file');
    }
    return($output);
}




=head2 export_media_as_tsv_file

  $output = $obj->export_media_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_media_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_media_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media_as_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_media_as_tsv_file
    $self->util_initialize_call($params,$ctx);
    $output = Bio::KBase::ObjectAPI::functions::func_export($params,{
		object => "media",
		format => "tsv"
	});
    #END export_media_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_media_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media_as_tsv_file');
    }
    return($output);
}




=head2 tsv_file_to_phenotype_set

  $return = $obj->tsv_file_to_phenotype_set($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a fba_tools.PhenotypeSetCreationParams
$return is a fba_tools.WorkspaceRef
PhenotypeSetCreationParams is a reference to a hash where the following keys are defined:
	phenotype_set_file has a value which is a fba_tools.File
	phenotype_set_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a fba_tools.PhenotypeSetCreationParams
$return is a fba_tools.WorkspaceRef
PhenotypeSetCreationParams is a reference to a hash where the following keys are defined:
	phenotype_set_file has a value which is a fba_tools.File
	phenotype_set_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub tsv_file_to_phenotype_set
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to tsv_file_to_phenotype_set:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_phenotype_set');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($return);
    #BEGIN tsv_file_to_phenotype_set
    $self->util_initialize_call($p,$ctx);
    my $file_path = $self->util_get_file_path($p->{phenotype_set_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
    my $phenodata = $self->util_parse_input_table($file_path,[
		["geneko",0,"",";"],
		["media",1,""],
		["mediaws",1,""],
		["addtlcpd",0,"",";"],
		["growth",1],
		['addtlcpdbounds',0,""],
		['customreactionbounds',0,""],
	]);
	for (my $i=0; $i < @{$phenodata}; $i++) {
		if (defined($phenodata->[$i]->[0]->[0]) && $phenodata->[$i]->[0]->[0] eq "none") {
			$phenodata->[$i]->[0] = [];
		}
		if (defined($phenodata->[$i]->[3]->[0]) && $phenodata->[$i]->[3]->[0] eq "none") {
			$phenodata->[$i]->[3] = [];
		}
	}
    $return = Bio::KBase::ObjectAPI::functions::func_import_phenotype_set({
    	data => $phenodata,
    	phenotypeset_id => $p->{phenotype_set_name},
    	workspace => $p->{workspace_name},
    	genome => $p->{genome},
    	genome_workspace => $p->{genome_workspace}
    });
	print "Phenotype Set Loaded\n";
    #END tsv_file_to_phenotype_set
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to tsv_file_to_phenotype_set:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_phenotype_set');
    }
    return($return);
}




=head2 phenotype_set_to_tsv_file

  $f = $obj->phenotype_set_to_tsv_file($phenotype_set)

=over 4

=item Parameter and return types

=begin html

<pre>
$phenotype_set is a fba_tools.PhenotypeSetObjectSelectionParams
$f is a fba_tools.File
PhenotypeSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_set_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$phenotype_set is a fba_tools.PhenotypeSetObjectSelectionParams
$f is a fba_tools.File
PhenotypeSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_set_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub phenotype_set_to_tsv_file
{
    my $self = shift;
    my($phenotype_set) = @_;

    my @_bad_arguments;
    (ref($phenotype_set) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"phenotype_set\" (value was \"$phenotype_set\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to phenotype_set_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_set_to_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($f);
    #BEGIN phenotype_set_to_tsv_file
    $self->util_initialize_call($phenotype_set,$ctx);
    $f = Bio::KBase::ObjectAPI::functions::func_export($phenotype_set,{
		object => "phenotype",
		format => "tsv",
		file_util => 1
	});
    #END phenotype_set_to_tsv_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to phenotype_set_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_set_to_tsv_file');
    }
    return($f);
}




=head2 export_phenotype_set_as_tsv_file

  $output = $obj->export_phenotype_set_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_phenotype_set_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_phenotype_set_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_set_as_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_phenotype_set_as_tsv_file
    $self->util_initialize_call($params,$ctx);
	$output = Bio::KBase::ObjectAPI::functions::func_export($params,{
		object => "phenotype",
		format => "tsv"
	});
    #END export_phenotype_set_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_phenotype_set_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_set_as_tsv_file');
    }
    return($output);
}




=head2 phenotype_simulation_set_to_excel_file

  $f = $obj->phenotype_simulation_set_to_excel_file($pss)

=over 4

=item Parameter and return types

=begin html

<pre>
$pss is a fba_tools.PhenotypeSimulationSetObjectSelectionParams
$f is a fba_tools.File
PhenotypeSimulationSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_simulation_set_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$pss is a fba_tools.PhenotypeSimulationSetObjectSelectionParams
$f is a fba_tools.File
PhenotypeSimulationSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_simulation_set_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub phenotype_simulation_set_to_excel_file
{
    my $self = shift;
    my($pss) = @_;

    my @_bad_arguments;
    (ref($pss) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"pss\" (value was \"$pss\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to phenotype_simulation_set_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_simulation_set_to_excel_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($f);
    #BEGIN phenotype_simulation_set_to_excel_file
    $self->util_initialize_call($pss,$ctx);
    $f = Bio::KBase::ObjectAPI::functions::func_export($pss,{
		object => "phenosim",
		format => "excel",
		file_util => 1
	});
    #END phenotype_simulation_set_to_excel_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to phenotype_simulation_set_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_simulation_set_to_excel_file');
    }
    return($f);
}




=head2 phenotype_simulation_set_to_tsv_file

  $f = $obj->phenotype_simulation_set_to_tsv_file($pss)

=over 4

=item Parameter and return types

=begin html

<pre>
$pss is a fba_tools.PhenotypeSimulationSetObjectSelectionParams
$f is a fba_tools.File
PhenotypeSimulationSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_simulation_set_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$pss is a fba_tools.PhenotypeSimulationSetObjectSelectionParams
$f is a fba_tools.File
PhenotypeSimulationSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_simulation_set_name has a value which is a string
	save_to_shock has a value which is a fba_tools.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub phenotype_simulation_set_to_tsv_file
{
    my $self = shift;
    my($pss) = @_;

    my @_bad_arguments;
    (ref($pss) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"pss\" (value was \"$pss\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to phenotype_simulation_set_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_simulation_set_to_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($f);
    #BEGIN phenotype_simulation_set_to_tsv_file
    $self->util_initialize_call($pss,$ctx);
    $f = Bio::KBase::ObjectAPI::functions::func_export($pss,{
		object => "phenosim",
		format => "tsv",
		file_util => 1
	});
    #END phenotype_simulation_set_to_tsv_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to phenotype_simulation_set_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_simulation_set_to_tsv_file');
    }
    return($f);
}




=head2 export_phenotype_simulation_set_as_excel_file

  $output = $obj->export_phenotype_simulation_set_as_excel_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_phenotype_simulation_set_as_excel_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_phenotype_simulation_set_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_simulation_set_as_excel_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_phenotype_simulation_set_as_excel_file
    $self->util_initialize_call($params,$ctx);
	$output = Bio::KBase::ObjectAPI::functions::func_export($params,{
		object => "phenosim",
		format => "excel"
	});
    #END export_phenotype_simulation_set_as_excel_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_phenotype_simulation_set_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_simulation_set_as_excel_file');
    }
    return($output);
}




=head2 export_phenotype_simulation_set_as_tsv_file

  $output = $obj->export_phenotype_simulation_set_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a fba_tools.ExportParams
$output is a fba_tools.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_phenotype_simulation_set_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_phenotype_simulation_set_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_simulation_set_as_tsv_file');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN export_phenotype_simulation_set_as_tsv_file
    $self->util_initialize_call($params,$ctx);
	$output = Bio::KBase::ObjectAPI::functions::func_export($params,{
		object => "phenosim",
		format => "tsv"
	});
    #END export_phenotype_simulation_set_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_phenotype_simulation_set_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_simulation_set_as_tsv_file');
    }
    return($output);
}




=head2 bulk_export_objects

  $output = $obj->bulk_export_objects($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a fba_tools.BulkExportObjectsParams
$output is a fba_tools.BulkExportObjectsResult
BulkExportObjectsParams is a reference to a hash where the following keys are defined:
	refs has a value which is a reference to a list where each element is a string
	all_models has a value which is a fba_tools.bool
	all_fba has a value which is a fba_tools.bool
	all_media has a value which is a fba_tools.bool
	all_phenotypes has a value which is a fba_tools.bool
	all_phenosims has a value which is a fba_tools.bool
	model_format has a value which is a string
	fba_format has a value which is a string
	media_format has a value which is a string
	phenotype_format has a value which is a string
	phenosim_format has a value which is a string
	workspace has a value which is a string
bool is an int
BulkExportObjectsResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
	ref has a value which is a string
ws_report_id is a string

</pre>

=end html

=begin text

$params is a fba_tools.BulkExportObjectsParams
$output is a fba_tools.BulkExportObjectsResult
BulkExportObjectsParams is a reference to a hash where the following keys are defined:
	refs has a value which is a reference to a list where each element is a string
	all_models has a value which is a fba_tools.bool
	all_fba has a value which is a fba_tools.bool
	all_media has a value which is a fba_tools.bool
	all_phenotypes has a value which is a fba_tools.bool
	all_phenosims has a value which is a fba_tools.bool
	model_format has a value which is a string
	fba_format has a value which is a string
	media_format has a value which is a string
	phenotype_format has a value which is a string
	phenosim_format has a value which is a string
	workspace has a value which is a string
bool is an int
BulkExportObjectsResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a fba_tools.ws_report_id
	ref has a value which is a string
ws_report_id is a string


=end text



=item Description



=back

=cut

sub bulk_export_objects
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to bulk_export_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'bulk_export_objects');
    }

    my $ctx = $fba_tools::fba_toolsServer::CallContext;
    my($output);
    #BEGIN bulk_export_objects
    $self->util_initialize_call($params,$ctx);
	$output = Bio::KBase::ObjectAPI::functions::func_bulk_export($params,{});
	Bio::KBase::utilities::add_report_file({
		path => $output->{path},
		name => $output->{name},
		description => $output->{description},
	});
	$self->util_finalize_call({
		output => $output,
		workspace => $params->{workspace},
		report_name => Data::UUID->new()->create_str(),
	});
    #END bulk_export_objects
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to bulk_export_objects:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'bulk_export_objects');
    }
    return($output);
}




=head2 status 

  $return = $obj->status()

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

Return the module status. This is a structure including Semantic Versioning number, state and git info.

=back

=cut

sub status {
    my($return);
    #BEGIN_STATUS
    $return = {"state" => "OK", "message" => "", "version" => $VERSION,
               "git_url" => $GIT_URL, "git_commit_hash" => $GIT_COMMIT_HASH};
    #END_STATUS
    return($return);
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

A string representing a Genome id.


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



=head2 media_id

=over 4



=item Description

A string representing a Media id.


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



=head2 template_id

=over 4



=item Description

A string representing a NewModelTemplate id.


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



=head2 fbamodel_id

=over 4



=item Description

A string representing a FBAModel id.


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



=head2 proteincomparison_id

=over 4



=item Description

A string representing a protein comparison id.


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

A string representing a FBA id.


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



=head2 fbapathwayanalysis_id

=over 4



=item Description

A string representing a FBAPathwayAnalysis id.


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



=head2 fbacomparison_id

=over 4



=item Description

A string representing a FBA comparison id.


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



=head2 phenotypeset_id

=over 4



=item Description

A string representing a phenotype set id.


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



=head2 phenotypesim_id

=over 4



=item Description

A string representing a phenotype simulation id.


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



=head2 expseries_id

=over 4



=item Description

A string representing an expression matrix id.


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

A string representing a reaction id.


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

A string representing a feature id.


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

A string representing a compound id.


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



=head2 ws_fbamodel_id

=over 4



=item Description

The workspace ID for a FBAModel data object.
@id ws KBaseFBA.FBAModel


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



=head2 ws_fba_id

=over 4



=item Description

The workspace ID for a FBA data object.
@id ws KBaseFBA.FBA


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



=head2 ws_fbacomparison_id

=over 4



=item Description

The workspace ID for a FBA data object.
@id ws KBaseFBA.FBA


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



=head2 ws_phenotypesim_id

=over 4



=item Description

The workspace ID for a phenotype set simulation object.
@id ws KBasePhenotypes.PhenotypeSimulationSet


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



=head2 ws_fbapathwayanalysis_id

=over 4



=item Description

The workspace ID for a FBA pathway analysis object
@id ws KBaseFBA.FBAPathwayAnalysis


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



=head2 ws_report_id

=over 4



=item Description

The workspace ID for a Report object
@id ws KBaseReport.Report


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



=head2 ws_pangenome_id

=over 4



=item Description

Reference to a Pangenome object in the workspace
@id ws KBaseGenomes.Pangenome


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



=head2 ws_proteomecomparison_id

=over 4



=item Description

Reference to a Proteome Comparison object in the workspace
@id ws GenomeComparison.ProteomeComparison


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



=head2 BuildMetabolicModelParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_id has a value which is a fba_tools.genome_id
genome_workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
template_id has a value which is a fba_tools.template_id
template_workspace has a value which is a fba_tools.workspace_name
coremodel has a value which is a fba_tools.bool
gapfill_model has a value which is a fba_tools.bool
thermodynamic_constraints has a value which is a fba_tools.bool
comprehensive_gapfill has a value which is a fba_tools.bool
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
minimum_target_flux has a value which is a float
number_of_solutions has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_id has a value which is a fba_tools.genome_id
genome_workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
template_id has a value which is a fba_tools.template_id
template_workspace has a value which is a fba_tools.workspace_name
coremodel has a value which is a fba_tools.bool
gapfill_model has a value which is a fba_tools.bool
thermodynamic_constraints has a value which is a fba_tools.bool
comprehensive_gapfill has a value which is a fba_tools.bool
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
minimum_target_flux has a value which is a float
number_of_solutions has a value which is an int


=end text

=back



=head2 BuildMetabolicModelResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
new_fba_ref has a value which is a fba_tools.ws_fba_id
number_gapfilled_reactions has a value which is an int
number_removed_biomass_compounds has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
new_fba_ref has a value which is a fba_tools.ws_fba_id
number_gapfilled_reactions has a value which is an int
number_removed_biomass_compounds has a value which is an int


=end text

=back



=head2 BuildMultipleMetabolicModelsParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_ids has a value which is a reference to a list where each element is a fba_tools.genome_id
genome_text has a value which is a string
genome_workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
template_id has a value which is a fba_tools.template_id
template_workspace has a value which is a fba_tools.workspace_name
coremodel has a value which is a fba_tools.bool
gapfill_model has a value which is a fba_tools.bool
thermodynamic_constraints has a value which is a fba_tools.bool
comprehensive_gapfill has a value which is a fba_tools.bool
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
minimum_target_flux has a value which is a float
number_of_solutions has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_ids has a value which is a reference to a list where each element is a fba_tools.genome_id
genome_text has a value which is a string
genome_workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
template_id has a value which is a fba_tools.template_id
template_workspace has a value which is a fba_tools.workspace_name
coremodel has a value which is a fba_tools.bool
gapfill_model has a value which is a fba_tools.bool
thermodynamic_constraints has a value which is a fba_tools.bool
comprehensive_gapfill has a value which is a fba_tools.bool
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
minimum_target_flux has a value which is a float
number_of_solutions has a value which is an int


=end text

=back



=head2 BuildMultipleMetabolicModelsResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
new_fba_ref has a value which is a fba_tools.ws_fba_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
new_fba_ref has a value which is a fba_tools.ws_fba_id


=end text

=back



=head2 GapfillMetabolicModelParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
target_reaction has a value which is a fba_tools.reaction_id
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
thermodynamic_constraints has a value which is a fba_tools.bool
comprehensive_gapfill has a value which is a fba_tools.bool
source_fbamodel_id has a value which is a fba_tools.fbamodel_id
source_fbamodel_workspace has a value which is a fba_tools.workspace_name
feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
minimum_target_flux has a value which is a float
number_of_solutions has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
target_reaction has a value which is a fba_tools.reaction_id
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
thermodynamic_constraints has a value which is a fba_tools.bool
comprehensive_gapfill has a value which is a fba_tools.bool
source_fbamodel_id has a value which is a fba_tools.fbamodel_id
source_fbamodel_workspace has a value which is a fba_tools.workspace_name
feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
minimum_target_flux has a value which is a float
number_of_solutions has a value which is an int


=end text

=back



=head2 GapfillMetabolicModelResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
new_fba_ref has a value which is a fba_tools.ws_fba_id
number_gapfilled_reactions has a value which is an int
number_removed_biomass_compounds has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
new_fba_ref has a value which is a fba_tools.ws_fba_id
number_gapfilled_reactions has a value which is an int
number_removed_biomass_compounds has a value which is an int


=end text

=back



=head2 RunFluxBalanceAnalysisParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
target_reaction has a value which is a fba_tools.reaction_id
fba_output_id has a value which is a fba_tools.fba_id
workspace has a value which is a fba_tools.workspace_name
thermodynamic_constraints has a value which is a fba_tools.bool
fva has a value which is a fba_tools.bool
minimize_flux has a value which is a fba_tools.bool
simulate_ko has a value which is a fba_tools.bool
find_min_media has a value which is a fba_tools.bool
all_reversible has a value which is a fba_tools.bool
feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
max_c_uptake has a value which is a float
max_n_uptake has a value which is a float
max_p_uptake has a value which is a float
max_s_uptake has a value which is a float
max_o_uptake has a value which is a float
default_max_uptake has a value which is a float
notes has a value which is a string
massbalance has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
target_reaction has a value which is a fba_tools.reaction_id
fba_output_id has a value which is a fba_tools.fba_id
workspace has a value which is a fba_tools.workspace_name
thermodynamic_constraints has a value which is a fba_tools.bool
fva has a value which is a fba_tools.bool
minimize_flux has a value which is a fba_tools.bool
simulate_ko has a value which is a fba_tools.bool
find_min_media has a value which is a fba_tools.bool
all_reversible has a value which is a fba_tools.bool
feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
max_c_uptake has a value which is a float
max_n_uptake has a value which is a float
max_p_uptake has a value which is a float
max_s_uptake has a value which is a float
max_o_uptake has a value which is a float
default_max_uptake has a value which is a float
notes has a value which is a string
massbalance has a value which is a string


=end text

=back



=head2 RunFluxBalanceAnalysisResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_fba_ref has a value which is a fba_tools.ws_fba_id
objective has a value which is an int
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fba_ref has a value which is a fba_tools.ws_fba_id
objective has a value which is an int
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id


=end text

=back



=head2 CompareFBASolutionsParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fba_id_list has a value which is a reference to a list where each element is a fba_tools.fba_id
fba_workspace has a value which is a fba_tools.workspace_name
fbacomparison_output_id has a value which is a fba_tools.fbacomparison_id
workspace has a value which is a fba_tools.workspace_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fba_id_list has a value which is a reference to a list where each element is a fba_tools.fba_id
fba_workspace has a value which is a fba_tools.workspace_name
fbacomparison_output_id has a value which is a fba_tools.fbacomparison_id
workspace has a value which is a fba_tools.workspace_name


=end text

=back



=head2 CompareFBASolutionsResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_fbacomparison_ref has a value which is a fba_tools.ws_fbacomparison_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fbacomparison_ref has a value which is a fba_tools.ws_fbacomparison_id


=end text

=back



=head2 PropagateModelToNewGenomeParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
proteincomparison_id has a value which is a fba_tools.proteincomparison_id
proteincomparison_workspace has a value which is a fba_tools.workspace_name
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
keep_nogene_rxn has a value which is a fba_tools.bool
gapfill_model has a value which is a fba_tools.bool
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
thermodynamic_constraints has a value which is a fba_tools.bool
comprehensive_gapfill has a value which is a fba_tools.bool
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
translation_policy has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
minimum_target_flux has a value which is a float
number_of_solutions has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
proteincomparison_id has a value which is a fba_tools.proteincomparison_id
proteincomparison_workspace has a value which is a fba_tools.workspace_name
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
keep_nogene_rxn has a value which is a fba_tools.bool
gapfill_model has a value which is a fba_tools.bool
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
thermodynamic_constraints has a value which is a fba_tools.bool
comprehensive_gapfill has a value which is a fba_tools.bool
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
translation_policy has a value which is a string
exp_threshold_percentile has a value which is a float
exp_threshold_margin has a value which is a float
activation_coefficient has a value which is a float
omega has a value which is a float
objective_fraction has a value which is a float
minimum_target_flux has a value which is a float
number_of_solutions has a value which is an int


=end text

=back



=head2 PropagateModelToNewGenomeResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
new_fba_ref has a value which is a fba_tools.ws_fba_id
number_gapfilled_reactions has a value which is an int
number_removed_biomass_compounds has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id
new_fba_ref has a value which is a fba_tools.ws_fba_id
number_gapfilled_reactions has a value which is an int
number_removed_biomass_compounds has a value which is an int


=end text

=back



=head2 SimulateGrowthOnPhenotypeDataParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
phenotypeset_id has a value which is a fba_tools.phenotypeset_id
phenotypeset_workspace has a value which is a fba_tools.workspace_name
phenotypesim_output_id has a value which is a fba_tools.phenotypesim_id
workspace has a value which is a fba_tools.workspace_name
all_reversible has a value which is a fba_tools.bool
gapfill_phenotypes has a value which is a fba_tools.bool
fit_phenotype_data has a value which is a fba_tools.bool
save_fluxes has a value which is a fba_tools.bool
add_all_transporters has a value which is a fba_tools.bool
add_positive_transporters has a value which is a fba_tools.bool
target_reaction has a value which is a fba_tools.reaction_id
feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
phenotypeset_id has a value which is a fba_tools.phenotypeset_id
phenotypeset_workspace has a value which is a fba_tools.workspace_name
phenotypesim_output_id has a value which is a fba_tools.phenotypesim_id
workspace has a value which is a fba_tools.workspace_name
all_reversible has a value which is a fba_tools.bool
gapfill_phenotypes has a value which is a fba_tools.bool
fit_phenotype_data has a value which is a fba_tools.bool
save_fluxes has a value which is a fba_tools.bool
add_all_transporters has a value which is a fba_tools.bool
add_positive_transporters has a value which is a fba_tools.bool
target_reaction has a value which is a fba_tools.reaction_id
feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
custom_bound_list has a value which is a reference to a list where each element is a string
media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id


=end text

=back



=head2 SimulateGrowthOnPhenotypeDataResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_phenotypesim_ref has a value which is a fba_tools.ws_phenotypesim_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_phenotypesim_ref has a value which is a fba_tools.ws_phenotypesim_id


=end text

=back



=head2 MergeMetabolicModelsIntoCommunityModelParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fbamodel_id_list has a value which is a reference to a list where each element is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
mixed_bag_model has a value which is a fba_tools.bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fbamodel_id_list has a value which is a reference to a list where each element is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
fbamodel_output_id has a value which is a fba_tools.fbamodel_id
workspace has a value which is a fba_tools.workspace_name
mixed_bag_model has a value which is a fba_tools.bool


=end text

=back



=head2 MergeMetabolicModelsIntoCommunityModelResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id


=end text

=back



=head2 ViewFluxNetworkParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fba_id has a value which is a fba_tools.fba_id
fba_workspace has a value which is a fba_tools.workspace_name
workspace has a value which is a fba_tools.workspace_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fba_id has a value which is a fba_tools.fba_id
fba_workspace has a value which is a fba_tools.workspace_name
workspace has a value which is a fba_tools.workspace_name


=end text

=back



=head2 ViewFluxNetworkResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_report_ref has a value which is a fba_tools.ws_report_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_report_ref has a value which is a fba_tools.ws_report_id


=end text

=back



=head2 CompareFluxWithExpressionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fba_id has a value which is a fba_tools.fba_id
fba_workspace has a value which is a fba_tools.workspace_name
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
estimate_threshold has a value which is a fba_tools.bool
maximize_agreement has a value which is a fba_tools.bool
fbapathwayanalysis_output_id has a value which is a fba_tools.fbapathwayanalysis_id
workspace has a value which is a fba_tools.workspace_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fba_id has a value which is a fba_tools.fba_id
fba_workspace has a value which is a fba_tools.workspace_name
expseries_id has a value which is a fba_tools.expseries_id
expseries_workspace has a value which is a fba_tools.workspace_name
expression_condition has a value which is a string
exp_threshold_percentile has a value which is a float
estimate_threshold has a value which is a fba_tools.bool
maximize_agreement has a value which is a fba_tools.bool
fbapathwayanalysis_output_id has a value which is a fba_tools.fbapathwayanalysis_id
workspace has a value which is a fba_tools.workspace_name


=end text

=back



=head2 CompareFluxWithExpressionResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_fbapathwayanalysis_ref has a value which is a fba_tools.ws_fbapathwayanalysis_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fbapathwayanalysis_ref has a value which is a fba_tools.ws_fbapathwayanalysis_id


=end text

=back



=head2 CheckModelMassBalanceParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
workspace has a value which is a fba_tools.workspace_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
fbamodel_id has a value which is a fba_tools.fbamodel_id
fbamodel_workspace has a value which is a fba_tools.workspace_name
workspace has a value which is a fba_tools.workspace_name


=end text

=back



=head2 CheckModelMassBalanceResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_report_ref has a value which is a fba_tools.ws_report_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_report_ref has a value which is a fba_tools.ws_report_id


=end text

=back



=head2 PredictAuxotrophyParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_ids has a value which is a reference to a list where each element is a fba_tools.genome_id
genome_workspace has a value which is a fba_tools.workspace_name
workspace has a value which is a fba_tools.workspace_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_ids has a value which is a reference to a list where each element is a fba_tools.genome_id
genome_workspace has a value which is a fba_tools.workspace_name
workspace has a value which is a fba_tools.workspace_name


=end text

=back



=head2 PredictAuxotrophyResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
new_report_ref has a value which is a fba_tools.ws_report_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_report_ref has a value which is a fba_tools.ws_report_id


=end text

=back



=head2 ModelComparisonParams

=over 4



=item Description

ModelComparisonParams object: a list of models and optional pangenome and protein comparison; mc_name is the name for the new object.

@optional protcomp_ref pangenome_ref


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a fba_tools.workspace_name
mc_name has a value which is a string
model_refs has a value which is a reference to a list where each element is a fba_tools.ws_fbamodel_id
protcomp_ref has a value which is a fba_tools.ws_proteomecomparison_id
pangenome_ref has a value which is a fba_tools.ws_pangenome_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a fba_tools.workspace_name
mc_name has a value which is a string
model_refs has a value which is a reference to a list where each element is a fba_tools.ws_fbamodel_id
protcomp_ref has a value which is a fba_tools.ws_proteomecomparison_id
pangenome_ref has a value which is a fba_tools.ws_pangenome_id


=end text

=back



=head2 ModelComparisonResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id
mc_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id
mc_ref has a value which is a string


=end text

=back



=head2 EditMetabolicModelParams

=over 4



=item Description

EditMetabolicModelParams object: arguments for the edit model function


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a fba_tools.workspace_name
fbamodel_workspace has a value which is a fba_tools.workspace_name
fbamodel_id has a value which is a fba_tools.ws_fbamodel_id
fbamodel_output_id has a value which is a fba_tools.ws_fbamodel_id
compounds_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
compounds_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
biomasses_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
biomass_compounds_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
reactions_to_remove has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
reactions_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
reactions_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
edit_compound_stoichiometry has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a fba_tools.workspace_name
fbamodel_workspace has a value which is a fba_tools.workspace_name
fbamodel_id has a value which is a fba_tools.ws_fbamodel_id
fbamodel_output_id has a value which is a fba_tools.ws_fbamodel_id
compounds_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
compounds_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
biomasses_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
biomass_compounds_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
reactions_to_remove has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
reactions_to_change has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
reactions_to_add has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string
edit_compound_stoichiometry has a value which is a reference to a list where each element is a reference to a hash where the key is a string and the value is a string


=end text

=back



=head2 EditMetabolicModelResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id
new_fbamodel_ref has a value which is a fba_tools.ws_fbamodel_id


=end text

=back



=head2 EditMediaParams

=over 4



=item Description

EditMediaParams object: arguments for the edit model function


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
compounds_to_remove has a value which is a reference to a list where each element is a fba_tools.compound_id
compounds_to_change has a value which is a reference to a list where each element is a reference to a list containing 4 items:
	0: a fba_tools.compound_id
	1: (concentration) a float
	2: (min_flux) a float
	3: (max_flux) a float

compounds_to_add has a value which is a reference to a list where each element is a reference to a list containing 4 items:
	0: a fba_tools.compound_id
	1: (concentration) a float
	2: (min_flux) a float
	3: (max_flux) a float

pH_data has a value which is a string
temperature has a value which is a float
isDefined has a value which is a fba_tools.bool
type has a value which is a string
media_output_id has a value which is a fba_tools.media_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a fba_tools.workspace_name
media_id has a value which is a fba_tools.media_id
media_workspace has a value which is a fba_tools.workspace_name
compounds_to_remove has a value which is a reference to a list where each element is a fba_tools.compound_id
compounds_to_change has a value which is a reference to a list where each element is a reference to a list containing 4 items:
	0: a fba_tools.compound_id
	1: (concentration) a float
	2: (min_flux) a float
	3: (max_flux) a float

compounds_to_add has a value which is a reference to a list where each element is a reference to a list containing 4 items:
	0: a fba_tools.compound_id
	1: (concentration) a float
	2: (min_flux) a float
	3: (max_flux) a float

pH_data has a value which is a string
temperature has a value which is a float
isDefined has a value which is a fba_tools.bool
type has a value which is a string
media_output_id has a value which is a fba_tools.media_id


=end text

=back



=head2 EditMediaResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id
new_media_id has a value which is a fba_tools.media_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id
new_media_id has a value which is a fba_tools.media_id


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



=head2 File

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string


=end text

=back



=head2 WorkspaceRef

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a string


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



=head2 ModelCreationParams

=over 4



=item Description

compounds_file is not used for excel file creations


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model_file has a value which is a fba_tools.File
model_name has a value which is a string
workspace_name has a value which is a string
genome has a value which is a string
biomass has a value which is a reference to a list where each element is a string
compounds_file has a value which is a fba_tools.File

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model_file has a value which is a fba_tools.File
model_name has a value which is a string
workspace_name has a value which is a string
genome has a value which is a string
biomass has a value which is a reference to a list where each element is a string
compounds_file has a value which is a fba_tools.File


=end text

=back



=head2 ModelObjectSelectionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
model_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean
fulldb has a value which is a fba_tools.bool

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
model_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean
fulldb has a value which is a fba_tools.bool


=end text

=back



=head2 ModelTsvFiles

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
compounds_file has a value which is a fba_tools.File
reactions_file has a value which is a fba_tools.File

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
compounds_file has a value which is a fba_tools.File
reactions_file has a value which is a fba_tools.File


=end text

=back



=head2 FBAObjectSelectionParams

=over 4



=item Description

****** FBA Result Converters ******


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
fba_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
fba_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean


=end text

=back



=head2 FBATsvFiles

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
compounds_file has a value which is a fba_tools.File
reactions_file has a value which is a fba_tools.File

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
compounds_file has a value which is a fba_tools.File
reactions_file has a value which is a fba_tools.File


=end text

=back



=head2 MediaCreationParams

=over 4



=item Description

****** Media Converters *********


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
media_file has a value which is a fba_tools.File
media_name has a value which is a string
workspace_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
media_file has a value which is a fba_tools.File
media_name has a value which is a string
workspace_name has a value which is a string


=end text

=back



=head2 MediaObjectSelectionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
media_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
media_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean


=end text

=back



=head2 PhenotypeSetCreationParams

=over 4



=item Description

****** Phenotype Data Converters *******


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
phenotype_set_file has a value which is a fba_tools.File
phenotype_set_name has a value which is a string
workspace_name has a value which is a string
genome has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
phenotype_set_file has a value which is a fba_tools.File
phenotype_set_name has a value which is a string
workspace_name has a value which is a string
genome has a value which is a string


=end text

=back



=head2 PhenotypeSetObjectSelectionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
phenotype_set_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
phenotype_set_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean


=end text

=back



=head2 PhenotypeSimulationSetObjectSelectionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
phenotype_simulation_set_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
phenotype_simulation_set_name has a value which is a string
save_to_shock has a value which is a fba_tools.boolean


=end text

=back



=head2 BulkExportObjectsParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
refs has a value which is a reference to a list where each element is a string
all_models has a value which is a fba_tools.bool
all_fba has a value which is a fba_tools.bool
all_media has a value which is a fba_tools.bool
all_phenotypes has a value which is a fba_tools.bool
all_phenosims has a value which is a fba_tools.bool
model_format has a value which is a string
fba_format has a value which is a string
media_format has a value which is a string
phenotype_format has a value which is a string
phenosim_format has a value which is a string
workspace has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
refs has a value which is a reference to a list where each element is a string
all_models has a value which is a fba_tools.bool
all_fba has a value which is a fba_tools.bool
all_media has a value which is a fba_tools.bool
all_phenotypes has a value which is a fba_tools.bool
all_phenosims has a value which is a fba_tools.bool
model_format has a value which is a string
fba_format has a value which is a string
media_format has a value which is a string
phenotype_format has a value which is a string
phenosim_format has a value which is a string
workspace has a value which is a string


=end text

=back



=head2 BulkExportObjectsResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id
ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a fba_tools.ws_report_id
ref has a value which is a string


=end text

=back



=cut

1;
