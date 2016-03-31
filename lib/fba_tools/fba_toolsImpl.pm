package fba_tools::fba_toolsImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

fba_tools

=head1 DESCRIPTION

A KBase module: fba_tools
This module contains the implementation for the primary methods in KBase for metabolic model reconstruction, gapfilling, and analysis

=cut

#BEGIN_HEADER
use Bio::KBase::AuthToken;
use Bio::KBase::workspace::Client;
use Config::IniFiles;
use Data::Dumper;
use POSIX;
use Bio::KBase::ObjectAPI::config;
use Bio::KBase::ObjectAPI::utilities;
use Bio::KBase::ObjectAPI::KBaseStore;
use Bio::KBase::ObjectAPI::logging;

#Initialization function for call
sub util_initialize_call {
	my ($self,$params,$ctx) = @_;
	print("Starting ".$ctx->method()." method.\n");
	delete($self->{_kbase_store});
	Bio::KBase::ObjectAPI::utilities::elaspedtime();
	Bio::KBase::ObjectAPI::config::username($ctx->user_id());
	Bio::KBase::ObjectAPI::config::token($ctx->token());
	Bio::KBase::ObjectAPI::config::provenance($ctx->provenance());
	return $params;
}

sub util_validate_args {
	my ($self,$params,$mandatoryArguments,$optionalArguments) = @_;
	print "Retrieving input parameters.\n";
	return Bio::KBase::ObjectAPI::utilities::ARGS($params,$mandatoryArguments,$optionalArguments);
}

sub util_kbase_store {
	my ($self) = @_;
    if (!defined($self->{_kbase_store})) {
    	my $wsClient=Bio::KBase::workspace::Client->new($self->{'workspace-url'},token => Bio::KBase::ObjectAPI::config::token());
    	$self->{_kbase_store} = Bio::KBase::ObjectAPI::KBaseStore->new({
			workspace => $wsClient
		});
    }
	return $self->{_kbase_store};
}

sub util_build_expression_hash {
	my ($self,$exp_matrix,$exp_condition) = @_;
	my $exphash = {};	
    my $float_matrix = $exp_matrix->{data};
	my $exp_sample_col = -1;
	for (my $i=0; $i < @{$float_matrix->{"col_ids"}}; $i++) {
		if ($float_matrix->{col_ids}->[$i] eq $exp_condition) {
		    $exp_sample_col = $i;
		    last;
		}
	}
	if ($exp_sample_col < 0) {
		Bio::KBase::ObjectAPI::utilities::error("No column named ".$exp_condition." in expression matrix.");
	}
	for (my $i=0; $i < @{$float_matrix->{row_ids}}; $i++) {
		$exphash->{$float_matrix->{row_ids}->[$i]} = $float_matrix->{values}->[$i]->[$exp_sample_col];
	}
    return $exphash;
}

sub util_build_fba {
	my ($self,$params,$model,$media,$id,$add_external_reactions,$make_model_reactions_reversible,$source_model,$gapfilling) = @_;
	my $uptakelimits = {};
    if (defined($params->{max_c_uptake})) {
    	$uptakelimits->{C} = $params->{max_c_uptake}
    }
    if (defined($params->{max_n_uptake})) {
    	$uptakelimits->{N} = $params->{max_n_uptake}
    }
    if (defined($params->{max_p_uptake})) {
    	$uptakelimits->{P} = $params->{max_p_uptake}
    }
    if (defined($params->{max_s_uptake})) {
    	$uptakelimits->{S} = $params->{max_s_uptake}
    }
    if (defined($params->{max_o_uptake})) {
    	$uptakelimits->{O} = $params->{max_o_uptake}
    }
    my $exp_matrix;
	my $exphash = {};
    if (defined($params->{expseries_id})) {
    	print "Retrieving expression matrix.\n";
    	$exp_matrix = $self->util_kbase_store()->get_object($params->{expseries_workspace}."/".$params->{expseries_id});
    	if (!defined($params->{expression_condition})) {
			Bio::KBase::ObjectAPI::utilities::error("Input must specify the column to select from the expression matrix");
		}
		$exphash = $self->util_build_expression_hash($exp_matrix,$params->{expression_condition});
    }
    my $fbaobj = Bio::KBase::ObjectAPI::KBaseFBA::FBA->new({
		id => $id,
		fva => defined $params->{fva} ? $params->{fva} : 0,
		fluxMinimization => defined $params->{minimize_flux} ? $params->{minimize_flux} : 0,
		findMinimalMedia => defined $params->{find_min_media} ? $params->{find_min_media} : 0,
		allReversible => defined $params->{all_reversible} ? $params->{all_reversible} : 0,
		simpleThermoConstraints => defined $params->{thermodynamic_constraints} ? $params->{thermodynamic_constraints} : 0,
		thermodynamicConstraints => defined $params->{thermodynamic_constraints} ? $params->{thermodynamic_constraints} : 0,
		noErrorThermodynamicConstraints => 0,
		minimizeErrorThermodynamicConstraints => 0,
		maximizeObjective => 1,
		compoundflux_objterms => {},
    	reactionflux_objterms => {},
		biomassflux_objterms => {},
		comboDeletions => defined $params->{simulate_ko} ? $params->{simulate_ko} : 0,
		numberOfSolutions => defined $params->{number_of_solutions} ? $params->{number_of_solutions} : 1,
		objectiveConstraintFraction => defined $params->{objective_fraction} ? $params->{objective_fraction} : 0.1,
		defaultMaxFlux => 1000,
		defaultMaxDrainFlux => defined $params->{default_max_uptake} ? $params->{default_max_uptake} : 0,
		defaultMinDrainFlux => -1000,
		decomposeReversibleFlux => 0,
		decomposeReversibleDrainFlux => 0,
		fluxUseVariables => 0,
		drainfluxUseVariables => 0,
		fbamodel => $model,
		fbamodel_ref => $model->_reference(),
		media => $media,
		media_ref => $media->_reference(),
		geneKO_refs => [],
		reactionKO_refs => [],
		additionalCpd_refs => [],
		uptakeLimits => $uptakelimits,
		parameters => {},
		inputfiles => {},
		FBAConstraints => [],
		FBAReactionBounds => [],
		FBACompoundBounds => [],
		outputfiles => {},
		FBACompoundVariables => [],
		FBAReactionVariables => [],
		FBABiomassVariables => [],
		FBAPromResults => [],
		FBADeletionResults => [],
		FBAMinimalMediaResults => [],
		FBAMetaboliteProductionResults => [],
		ExpressionAlpha => defined $params->{activation_coefficient} ? $params->{activation_coefficient} : 0.5,
		ExpressionOmega => defined $params->{omega} ? $params->{omega} : 0,
		ExpressionKappa => defined $params->{exp_threshold_margin} ? $params->{exp_threshold_margin} : 0.1
	});
	$fbaobj->parent($self->util_kbase_store());
	$fbaobj->parameters()->{minimum_target_flux} = defined $params->{minimum_target_flux} ? $params->{minimum_target_flux} : 0.01;
	if (!defined($params->{target_reaction})) {
		$params->{target_reaction} = "bio1";
	}
    my $bio = $model->getObject("biomasses",$params->{target_reaction});
	if (defined($bio)) {
		$fbaobj->biomassflux_objterms()->{$bio->id()} = 1;
	} else {
		my $rxn = $model->getObject("modelreactions",$params->{target_reaction});
		if (defined($rxn)) {
			$fbaobj->reactionflux_objterms()->{$rxn->id()} = 1;
		} else {
			my $cpd = $model->getObject("modelcompounds",$params->{target_reaction});
			if (defined($cpd)) {
				$fbaobj->compoundflux_objterms()->{$cpd->id()} = 1;
			} else {
				Bio::KBase::ObjectAPI::utilities::error("Could not find biomass objective object:".$params->{target_reaction});
			}
		}
	}
	if (defined($model->genome_ref()) && defined($params->{feature_ko_list})) {
		my $genome = $model->genome();
		foreach my $gene (@{$params->{feature_ko_list}}) {
			my $geneObj = $genome->searchForFeature($gene);
			if (defined($geneObj)) {
				$fbaobj->addLinkArrayItem("geneKOs",$geneObj);
			}
		}
	}
	if (defined($params->{reaction_ko_list})) {
		foreach my $reaction (@{$params->{reaction_ko_list}}) {
			my $rxnObj = $model->searchForReaction($reaction);
			if (defined($rxnObj)) {
				$fbaobj->addLinkArrayItem("reactionKOs",$rxnObj);
			}
		}
	}
	if (defined($params->{media_supplement_list})) {
		foreach my $compound (@{$params->{media_supplement_list}}) {
			my $cpdObj = $model->searchForCompound($compound);
			if (defined($cpdObj)) {
				$fbaobj->addLinkArrayItem("additionalCpds",$cpdObj);
			}
		}
	}
	if (!defined($params->{custom_bound_list})) {
		$params->{custom_bound_list} = [];
	}
	for (my $i=0; $i < @{$params->{custom_bound_list}}; $i++) {
		my $array = [split(/[\<;]/,$params->{custom_bound_list}->[$i])];
		my $rxn = $model->searchForReaction($array->[1]);
		if (defined($rxn)) {
			$fbaobj->add("FBAReactionBounds",{
				modelreaction_ref => $rxn->_reference(),
				variableType => "flux",
				upperBound => $array->[2]+0,
				lowerBound => $array->[0]+0
			});
		} else {
			my $cpd = $model->searchForCompound($array->[1]);
			if (defined($cpd)) {
				$fbaobj->add("FBACompoundBounds",{
					modelcompound_ref => $cpd->_reference(),
					variableType => "drainflux",
					upperBound => $array->[2]+0,
					lowerBound => $array->[0]+0
				});
			}
		}
	}
    if (defined($exp_matrix) || (defined($gapfilling) && $gapfilling == 1)) {
		if ($params->{minimum_target_flux} < 0.1) {
			$params->{minimum_target_flux} = 0.1;
		}
		if (!defined($exp_matrix) && $params->{comprehensive_gapfill} == 0) {
			$params->{activation_coefficient} = 0;
		}
		my $input = {
			gapfill_id => $params->{gapfill_id},
			integrate_gapfilling_solution => 1,
			minimum_target_flux => $params->{minimum_target_flux},
			target_reactions => [],#?
			completeGapfill => 0,#?
			fastgapfill => 1,
			alpha => $params->{activation_coefficient},
			omega => $params->{omega},
			num_solutions => $params->{number_of_solutions},
			add_external_rxns => $add_external_reactions,
			make_model_rxns_reversible => $make_model_reactions_reversible,
			activate_all_model_reactions => 0,
		};
		if (defined($exp_matrix)) {
			$input->{expsample} = $exphash;
			$input->{expression_threshold_percentile} = $params->{exp_threshold_percentile};
			$input->{kappa} = $params->{exp_threshold_margin};
			$fbaobj->expression_matrix_ref($params->{expseries_workspace}."/".$params->{expseries_id});
			$fbaobj->expression_matrix_column($params->{expression_condition});	
		}
		if (defined($source_model)) {
    		$input->{source_model} = $source_model;
    	}
		$fbaobj->PrepareForGapfilling($input);
    }
    return $fbaobj;
}

sub func_build_metabolic_model {
	my ($self,$params) = @_;
	$params = $self->util_validate_args($params,["workspace","genome_id"],{
    	media_id => undef,
    	template_id => "auto",
    	genome_workspace => $params->{workspace},
    	template_workspace => $params->{workspace},
    	media_workspace => $params->{workspace},
    	fbamodel_output_id => $params->{genome_id}.".model",
    	coremodel => 0,
    	gapfill_model => 1,
    	thermodynamic_constraints => 0,
    	comprehensive_gapfill => 0,
    	custom_bound_list => [],
		media_supplement_list => [],
		expseries_id => undef,
		expseries_workspace => $params->{workspace},
		expression_condition => undef,
		exp_threshold_percentile => 0.5,
		exp_threshold_margin => 0.1,
		activation_coefficient => 0.5,
		omega => 0,
		objective_fraction => 0.1,
		minimum_target_flux => 0.1,
		number_of_solutions => 1
    });
	#Getting genome
	print "Retrieving genome.\n";
	my $genome = $self->util_kbase_store()->get_object($params->{genome_workspace}."/".$params->{genome_id});
	#Classifying genome
	$params->{template_workspace} = "NewKBaseModelTemplates";
	if ($params->{template_id} eq "auto") {
    	print "Classifying genome in order to select template.\n";
    	if ($genome->template_classification() eq "plant") {
    		$params->{template_id} = "PlantModelTemplate";
    	} elsif ($genome->template_classification() eq "Gram negative") {
    		$params->{template_id} = "GramNegModelTemplate";
    	} elsif ($genome->template_classification() eq "Gram positive") {
    		$params->{template_id} = "GramPosModelTemplate";
    	}
	} elsif ($params->{template_id} eq "grampos") {		
		$params->{template_id} = "GramPosModelTemplate";
	} elsif ($params->{template_id} eq "gramneg") {
		$params->{template_id} = "GramNegModelTemplate";
	} elsif ($params->{template_id} eq "plant") {
		$params->{template_id} = "PlantModelTemplate";
	}
    #Retrieving template
    print "Retrieving model template ".$params->{template_id}.".\n";
    my $template = $self->util_kbase_store()->get_object($params->{template_workspace}."/".$params->{template_id});
    #Building the model
    my $model = $template->buildModel({
	    genome => $genome,
	    modelid => $params->{fbamodel_output_id},
	    fulldb => 0
	});
	#Gapfilling model if requested
	my $output;
	if ($params->{gapfill_model} == 1) {
		$output = $self->func_gapfill_metabolic_model({
			thermodynamic_constraints => $params->{thermodynamic_constraints},
	    	comprehensive_gapfill => $params->{comprehensive_gapfill},
	    	custom_bound_list => $params->{custom_bound_list},
			media_supplement_list => $params->{media_supplement_list},
			expseries_id => $params->{expseries_id},
			expseries_workspace => $params->{expseries_workspace},
			expression_condition => $params->{expression_condition},
			exp_threshold_percentile => $params->{exp_threshold_percentile},
			exp_threshold_margin => $params->{exp_threshold_margin},
			activation_coefficient => $params->{activation_coefficient},
			omega => $params->{omega},
			objective_fraction => $params->{objective_fraction},
			minimum_target_flux => $params->{minimum_target_flux},
			number_of_solutions => $params->{number_of_solutions},
			workspace => $params->{workspace},
			fbamodel_id => $params->{fbamodel_output_id},
			fbamodel_output_id => $params->{fbamodel_output_id},
			media_workspace => $params->{media_workspace},
			media_id => $params->{media_id}
		},$model);
	} else {
		#If not gapfilling, then we just save the model directly
		$output->{number_gapfilled_reactions} = 0;
		$output->{number_removed_biomass_compounds} = 0;
		my $wsmeta = $self->util_kbase_store()->save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id});
		$output->{new_fbamodel_ref} = $params->{workspace}."/".$params->{fbamodel_output_id};
	}
	return $output;
}

sub func_gapfill_metabolic_model {
	my ($self,$params,$model,$source_model) = @_;
	$params = $self->util_validate_args($params,["workspace","fbamodel_id"],{
    	fbamodel_workspace => $params->{workspace},
    	media_id => undef,
    	media_workspace => $params->{workspace},
    	target_reaction => "bio1",
    	fbamodel_output_id => $params->{fbamodel_id},
    	thermodynamic_constraints => 0,
    	comprehensive_gapfill => 0,
    	source_fbamodel_id => undef,
    	source_fbamodel_workspace => $params->{workspace},
    	feature_ko_list => [],
		reaction_ko_list => [],
		custom_bound_list => [],
		media_supplement_list => [],
		expseries_id => undef,
    	expseries_workspace => $params->{workspace},
    	expression_condition => undef,
    	exp_threshold_percentile => 0.5,
    	exp_threshold_margin => 0.1,
    	activation_coefficient => 0.5,
    	omega => 0,
    	objective_fraction => 0,
    	minimum_target_flux => 0.1,
		number_of_solutions => 1
    });
    if (!defined($model)) {
    	print "Retrieving model.\n";
		$model = $self->util_kbase_store()->get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    }
    if (!defined($params->{media_id})) {
    	$params->{default_max_uptake} = 100;
    	$params->{media_id} = "Complete";
    	$params->{media_workspace} = "KBaseMedia";
    }
    print "Retrieving ".$params->{media_id}." media.\n";
    my $media = $self->util_kbase_store()->get_object($params->{media_workspace}."/".$params->{media_id});
    print "Preparing flux balance analysis problem.\n";
    if (defined($params->{source_fbamodel_id}) && !defined($source_model)) {
		$source_model = $self->util_kbase_store()->get_object($params->{source_fbamodel_workspace}."/".$params->{source_fbamodel_id});
	}
	my $gfs = $model->gapfillings();
	my $currentid = 0;
	for (my $i=0; $i < @{$gfs}; $i++) {
		if ($gfs->[$i]->id() =~ m/gf\.(\d+)$/) {
			if ($1 >= $currentid) {
				$currentid = $1+1;
			}
		}
	}
	my $gfid = "gf.".$currentid;
	$params->{gapfill_id} = $gfid;
    my $fba = $self->util_build_fba($params,$model,$media,$params->{fbamodel_output_id}.".".$gfid,1,1,$source_model,1);
    print "Running flux balance analysis problem.\n";
	$fba->runFBA();
	#Error checking the FBA and gapfilling solution
	if (!defined($fba->gapfillingSolutions()->[0])) {
		Bio::KBase::ObjectAPI::utilities::error("Analysis completed, but no valid solutions found!");
	}
    print "Saving gapfilled model.\n";
    my $wsmeta = $self->util_kbase_store()->save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id});
    print "Saving FBA object with gapfilling sensitivity analysis and flux.\n";
    $fba->fbamodel_ref($model->_reference());
    $wsmeta = $self->util_kbase_store()->save_object($fba,$params->{workspace}."/".$params->{fbamodel_output_id}.".".$gfid);
	return {
		new_fba_ref => $params->{workspace}."/".$params->{fbamodel_output_id}.".".$gfid,
		new_fbamodel_ref => $params->{workspace}."/".$params->{fbamodel_output_id},
		number_gapfilled_reactions => 0,
		number_removed_biomass_compounds => 0
	};
}

sub func_run_flux_balance_analysis {
	my ($self,$params,$model) = @_;
	$params = $self->util_validate_args($params,["workspace","fbamodel_id","fba_output_id"],{
		fbamodel_workspace => $params->{workspace},
		media_id => undef,
		media_workspace => $params->{workspace},
		target_reaction => "bio1",
		thermodynamic_constraints => 0,
		fva => 0,
		minimize_flux => 0,
		simulate_ko => 0,
		find_min_media => 0,
		all_reversible => 0,
		feature_ko_list => [],
		reaction_ko_list => [],
		custom_bound_list => [],
		media_supplement_list => [],
		expseries_id => undef,
		expseries_workspace => $params->{workspace},
		expression_condition => undef,
		exp_threshold_percentile => 0.5,
		exp_threshold_margin => 0.1,
		activation_coefficient => 0.5,
		omega => 0,
		objective_fraction => 0.1,
		max_c_uptake => undef,
		max_n_uptake => undef,
		max_p_uptake => undef,
		max_s_uptake => undef,
		max_o_uptake => undef,
		default_max_uptake => 0,
		notes => undef,
		massbalance => undef
    });
    if (!defined($model)) {
    	print "Retrieving model.\n";
		$model = $self->util_kbase_store()->get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    }
    my $expseries;
    if (defined($params->{expseries_id})) {
    	print "Retrieving expression matrix.\n";
    	$expseries = $self->util_kbase_store()->get_object($params->{expseries_workspace}."/".$params->{expseries_id});
    }
    if (!defined($params->{media_id})) {
    	$params->{default_max_uptake} = 100;
    	$params->{media_id} = "Complete";
    	$params->{media_workspace} = "KBaseMedia";
    }
    print "Retrieving ".$params->{media_id}." media.\n";
    my $media = $self->util_kbase_store()->get_object($params->{media_workspace}."/".$params->{media_id});
    print "Preparing flux balance analysis problem.\n";
    my $fba = $self->util_build_fba($params,$model,$media,$params->{fba_output_id},0,0,undef);
    #Running FBA
    print "Running flux balance analysis problem.\n";
    my $objective;
    #eval {
		local $SIG{ALRM} = sub { die "FBA timed out! Model likely contains numerical instability!" };
		alarm 86400;
		$objective = $fba->runFBA();
		alarm 0;
	#};
    if (!defined($objective)) {
    	Bio::KBase::ObjectAPI::utilities::error("FBA failed with no solution returned!");
    }    
    print "Saving FBA results.\n";
    my $wsmeta = $self->util_kbase_store()->save_object($fba,$params->{workspace}."/".$params->{fba_output_id});
	return {
		new_fba_ref => $params->{workspace}."/".$params->{fba_output_id}
	};
}

sub func_compare_fba_solutions {
	my ($self,$params) = @_;
	$params = $self->util_validate_args($params,["workspace","fba_id_list","fbacomparison_output_id"],{
		fba_workspace => $params->{workspace},
    });
    my $fbacomp = Bio::KBase::ObjectAPI::KBaseFBA::FBAComparison->new({
    	id => $params->{fbacomparison_output_id},
    	common_reactions => 0,
    	common_compounds => 0,
    	fbas => [],
    	reactions => [],
    	compounds => []
    });
    $fbacomp->parent($self->util_kbase_store());
    my $commoncompounds = 0;
    my $commonreactions = 0;
    my $fbahash = {};
    my $fbaids = [];
    my $fbarxns = {};
    my $rxnhash = {};
    my $cpdhash = {};
    my $fbacpds = {};
    my $fbacount = @{$params->{fba_id_list}};
    for (my $i=0; $i < @{$params->{fba_id_list}}; $i++) {
    	$fbaids->[$i] = $params->{fba_workspace}."/".$params->{fba_id_list}->[$i];
    	print "Retrieving FBA ".$fbaids->[$i].".\n";
    	my $fba = $self->util_kbase_store()->get_object($fbaids->[$i]);
   		my $rxns = $fba->FBAReactionVariables();
		my $cpds = $fba->FBACompoundVariables();
		my $cpdcount = @{$cpds};
		my $rxncount = @{$rxns};
		$fbahash->{$fbaids->[$i]} = $fbacomp->add("fbas",{
			id => $fbaids->[$i],
			fba_ref => $fba->_reference(),
			fbamodel_ref => $fba->fbamodel_ref(),
			fba_similarity => {},
			objective => $fba->objectiveValue(),
			media_ref => $fba->media_ref(),
			reactions => $rxncount,
			compounds => $cpdcount,
			forward_reactions => 0,
			reverse_reactions => 0,
			uptake_compounds => 0,
			excretion_compounds => 0
		});
		my $forwardrxn = 0;
		my $reverserxn = 0;
		my $uptakecpd = 0;
		my $excretecpd = 0;
		for (my $j=0; $j < @{$rxns}; $j++) {
			my $id = $rxns->[$j]->modelreaction()->reaction()->id();
			my $name = $rxns->[$j]->modelreaction()->reaction()->name();
			if ($id eq "rxn00000") {
				$id = $rxns->[$j]->modelreaction()->id();
				$name = $rxns->[$j]->modelreaction()->id();
			} elsif ($rxns->[$j]->modelreaction()->id() =~ m/_([a-z]+\d+)$/) {
				$id .= "_".$1;
			}
			if (!defined($rxnhash->{$id})) {
				$rxnhash->{$id} = $fbacomp->add("reactions",{
					id => $id,
					name => $name,
					stoichiometry => $rxns->[$j]->modelreaction()->stoichiometry(),
					direction => $rxns->[$j]->modelreaction()->direction(),
					state_conservation => {},
					most_common_state => "unknown",
					reaction_fluxes => {}
				});
			}
			my $state = "IA";
			if ($rxns->[$j]->value() > 0.000000001) {
				$state = "FOR";
				$forwardrxn++;
			} elsif ($rxns->[$j]->value() < -0.000000001) {
				$state = "REV";
				$reverserxn++;
			}
			if (!defined($rxnhash->{$id}->state_conservation()->{$state})) {
				$rxnhash->{$id}->state_conservation()->{$state} = [0,0,0,0];
			}
			$rxnhash->{$id}->state_conservation()->{$state}->[0]++;
			$rxnhash->{$id}->state_conservation()->{$state}->[2] += $rxns->[$j]->value();
			$rxnhash->{$id}->reaction_fluxes()->{$fbaids->[$i]} = [$state,$rxns->[$j]->upperBound(),$rxns->[$j]->lowerBound(),$rxns->[$j]->max(),$rxns->[$j]->min(),$rxns->[$j]->value(),$rxns->[$j]->scaled_exp(),$rxns->[$j]->exp_state(),$rxns->[$j]->modelreaction()->id()];
			$fbarxns->{$fbaids->[$i]}->{$id} = $state;
		}
		for (my $j=0; $j < @{$cpds}; $j++) {
			my $id = $cpds->[$j]->modelcompound()->id();
			if (!defined($cpdhash->{$id})) {
				$cpdhash->{$id} = $fbacomp->add("compounds",{
					id => $id,
					name => $cpds->[$j]->modelcompound()->name(),
					charge => $cpds->[$j]->modelcompound()->charge(),
					formula => $cpds->[$j]->modelcompound()->formula(),
					state_conservation => {},
					most_common_state => "unknown",
					exchanges => {}
				});
			}
			my $state = "IA";
			if ($cpds->[$j]->value() > 0.000000001) {
				$state = "UP";
				$uptakecpd++;
			} elsif ($cpds->[$j]->value() < -0.000000001) {
				$state = "EX";
				$excretecpd++;
			}
			if (!defined($cpdhash->{$id}->state_conservation()->{$state})) {
				$cpdhash->{$id}->state_conservation()->{$state} = [0,0,0,0];
			}
			$cpdhash->{$id}->state_conservation()->{$state}->[0]++;
			$cpdhash->{$id}->state_conservation()->{$state}->[2] += $cpds->[$j]->value();
			$cpdhash->{$id}->exchanges()->{$fbaids->[$i]} = [$state,$cpds->[$j]->upperBound(),$cpds->[$j]->lowerBound(),$cpds->[$j]->max(),$cpds->[$j]->min(),$cpds->[$j]->value(),$cpds->[$j]->class()];
			$fbacpds->{$fbaids->[$i]}->{$id} = $state;
		}
		foreach my $comprxn (keys(%{$rxnhash})) {
			if (!defined($rxnhash->{$comprxn}->reaction_fluxes()->{$fbaids->[$i]})) {
				if (!defined($rxnhash->{$comprxn}->state_conservation()->{NA})) {
					$rxnhash->{$comprxn}->state_conservation()->{NA} = [0,0,0,0];
				}
				$rxnhash->{$comprxn}->state_conservation()->{NA}->[0]++;
			}
		}
		foreach my $compcpd (keys(%{$cpdhash})) {
			if (!defined($cpdhash->{$compcpd}->exchanges()->{$fbaids->[$i]})) {
				if (!defined($cpdhash->{$compcpd}->state_conservation()->{NA})) {
					$cpdhash->{$compcpd}->state_conservation()->{NA} = [0,0,0,0];
				}
				$cpdhash->{$compcpd}->state_conservation()->{NA}->[0]++;
			}
		}
		$fbahash->{$fbaids->[$i]}->forward_reactions($forwardrxn);
		$fbahash->{$fbaids->[$i]}->reverse_reactions($reverserxn);
		$fbahash->{$fbaids->[$i]}->uptake_compounds($uptakecpd);
		$fbahash->{$fbaids->[$i]}->excretion_compounds($excretecpd);
    }
    print "Computing similarities.\n";
    for (my $i=0; $i < @{$fbaids}; $i++) {
    	for (my $j=0; $j < @{$fbaids}; $j++) {
    		if ($j != $i) {
    			$fbahash->{$fbaids->[$i]}->fba_similarity()->{$fbaids->[$j]} = [0,0,0,0,0,0,0,0];
    		}
    	}
    }
    print "Comparing reaction states.\n";
    foreach my $rxn (keys(%{$rxnhash})) {
    	my $fbalist = [keys(%{$rxnhash->{$rxn}->reaction_fluxes()})];
    	my $rxnfbacount = @{$fbalist};
    	foreach my $state (keys(%{$rxnhash->{$rxn}->state_conservation()})) {
    		$rxnhash->{$rxn}->state_conservation()->{$state}->[1] = $rxnhash->{$rxn}->state_conservation()->{$state}->[0]/$fbacount;
			$rxnhash->{$rxn}->state_conservation()->{$state}->[2] = $rxnhash->{$rxn}->state_conservation()->{$state}->[2]/$rxnhash->{$rxn}->state_conservation()->{$state}->[0];
    	}
    	for (my $i=0; $i < @{$fbalist}; $i++) {
    		my $item = $rxnhash->{$rxn}->reaction_fluxes()->{$fbalist->[$i]};
    		my $diff = $item->[5]-$rxnhash->{$rxn}->state_conservation()->{$item->[0]}->[2];
    		$rxnhash->{$rxn}->state_conservation()->{$item->[0]}->[3] += ($diff*$diff);
    		for (my $j=0; $j < @{$fbalist}; $j++) {
    			if ($j != $i) {
    				$fbahash->{$fbalist->[$i]}->fba_similarity()->{$fbalist->[$j]}->[0]++;
    				if ($rxnhash->{$rxn}->reaction_fluxes()->{$fbalist->[$i]}->[5] < -0.00000001 && $rxnhash->{$rxn}->reaction_fluxes()->{$fbalist->[$j]}->[5] < -0.00000001) {
    					$fbahash->{$fbalist->[$i]}->fba_similarity()->{$fbalist->[$j]}->[2]++;
    				}
    				if ($rxnhash->{$rxn}->reaction_fluxes()->{$fbalist->[$i]}->[5] > 0.00000001 && $rxnhash->{$rxn}->reaction_fluxes()->{$fbalist->[$j]}->[5] > 0.00000001) {
    					$fbahash->{$fbalist->[$i]}->fba_similarity()->{$fbalist->[$j]}->[1]++;
    				}
    				if ($rxnhash->{$rxn}->reaction_fluxes()->{$fbalist->[$i]}->[5] == 0 && $rxnhash->{$rxn}->reaction_fluxes()->{$fbalist->[$j]}->[5] == 0) {
    					$fbahash->{$fbalist->[$i]}->fba_similarity()->{$fbalist->[$j]}->[3]++;
    				}
    			}	
    		}
    	}
    	my $bestcount = 0;
    	my $beststate;
    	foreach my $state (keys(%{$rxnhash->{$rxn}->state_conservation()})) {
    		$rxnhash->{$rxn}->state_conservation()->{$state}->[3] = $rxnhash->{$rxn}->state_conservation()->{$state}->[3]/$rxnhash->{$rxn}->state_conservation()->{$state}->[0];
    		$rxnhash->{$rxn}->state_conservation()->{$state}->[3] = sqrt($rxnhash->{$rxn}->state_conservation()->{$state}->[3]);
    		if ($rxnhash->{$rxn}->state_conservation()->{$state}->[0] > $bestcount) {
    			$bestcount = $rxnhash->{$rxn}->state_conservation()->{$state}->[0];
    			$beststate = $state;
    		}
    	}
    	$rxnhash->{$rxn}->most_common_state($beststate);
    	if ($rxnfbacount == $fbacount) {
    		$commonreactions++;
    	}
    }
    print "Comparing compound states.\n";
    foreach my $cpd (keys(%{$cpdhash})) {
    	my $fbalist = [keys(%{$cpdhash->{$cpd}->exchanges()})];
    	my $cpdfbacount = @{$fbalist};
    	foreach my $state (keys(%{$cpdhash->{$cpd}->state_conservation()})) {
    		$cpdhash->{$cpd}->state_conservation()->{$state}->[1] = $cpdhash->{$cpd}->state_conservation()->{$state}->[0]/$fbacount;
			$cpdhash->{$cpd}->state_conservation()->{$state}->[2] = $cpdhash->{$cpd}->state_conservation()->{$state}->[2]/$cpdhash->{$cpd}->state_conservation()->{$state}->[0];
    	}
    	for (my $i=0; $i < @{$fbalist}; $i++) {
    		my $item = $cpdhash->{$cpd}->exchanges()->{$fbalist->[$i]};
    		my $diff = $item->[5]-$cpdhash->{$cpd}->state_conservation()->{$item->[0]}->[2];
    		$cpdhash->{$cpd}->state_conservation()->{$item->[0]}->[3] += ($diff*$diff);
    		for (my $j=0; $j < @{$fbalist}; $j++) {
    			if ($j != $i) {
    				$fbahash->{$fbalist->[$i]}->fba_similarity()->{$fbalist->[$j]}->[4]++;
    				if ($cpdhash->{$cpd}->exchanges()->{$fbalist->[$i]}->[5] < -0.00000001 && $cpdhash->{$cpd}->exchanges()->{$fbalist->[$j]}->[5] < -0.00000001) {
    					$fbahash->{$fbalist->[$i]}->fba_similarity()->{$fbalist->[$j]}->[6]++;
    				}
    				if ($cpdhash->{$cpd}->exchanges()->{$fbalist->[$i]}->[5] > 0.00000001 && $cpdhash->{$cpd}->exchanges()->{$fbalist->[$j]}->[5] > 0.00000001) {
    					$fbahash->{$fbalist->[$i]}->fba_similarity()->{$fbalist->[$j]}->[5]++;
    				}
    				if ($cpdhash->{$cpd}->exchanges()->{$fbalist->[$i]}->[5] == 0 && $cpdhash->{$cpd}->exchanges()->{$fbalist->[$j]}->[5] == 0) {
    					$fbahash->{$fbalist->[$i]}->fba_similarity()->{$fbalist->[$j]}->[7]++;
    				}
    			}	
    		}
    	}
    	my $bestcount = 0;
    	my $beststate;
    	foreach my $state (keys(%{$cpdhash->{$cpd}->state_conservation()})) {
    		$cpdhash->{$cpd}->state_conservation()->{$state}->[3] = $cpdhash->{$cpd}->state_conservation()->{$state}->[3]/$cpdhash->{$cpd}->state_conservation()->{$state}->[0];
    		$cpdhash->{$cpd}->state_conservation()->{$state}->[3] = sqrt($cpdhash->{$cpd}->state_conservation()->{$state}->[3]);
    		if ($cpdhash->{$cpd}->state_conservation()->{$state}->[0] > $bestcount) {
    			$bestcount = $cpdhash->{$cpd}->state_conservation()->{$state}->[0];
    			$beststate = $state;
    		}
    	}
    	$cpdhash->{$cpd}->most_common_state($beststate);
    	if ($cpdfbacount == $fbacount) {
    		$commoncompounds++;
    	}
    }
    $fbacomp->common_compounds($commoncompounds);
    $fbacomp->common_reactions($commonreactions);
    print "Saving FBA comparison object.\n";
    my $wsmeta = $self->util_kbase_store()->save_object($fbacomp,$params->{workspace}."/".$params->{fbacomparison_output_id});
	return {
		new_fbacomparison_ref => $params->{workspace}."/".$params->{fbacomparison_output_id}
	};
}

sub func_propagate_model_to_new_genome {
	my ($self,$params) = @_;
    $params = $self->util_validate_args($params,["workspace","fbamodel_id","proteincomparison_id","fbamodel_output_id"],{
    	fbamodel_workspace => $params->{workspace},
    	proteincomparison_workspace => $params->{workspace},
    	keep_nogene_rxn => 0,
    	gapfill_model => 0,
    	media_id => undef,
    	media_workspace => $params->{workspace},
    	thermodynamic_constraints => 0,
    	comprehensive_gapfill => 0,
    	custom_bound_list => [],
		media_supplement_list => [],
		expseries_id => undef,
		expseries_workspace => $params->{workspace},
		expression_condition => undef,
		exp_threshold_percentile => 0.5,
		exp_threshold_margin => 0.1,
		activation_coefficient => 0.5,
		omega => 0,
		objective_fraction => 0.1,
		minimum_target_flux => 0.1,
		number_of_solutions => 1,
		translation_policy => "translate_only"
    });
	#Getting genome
	my $source_model = $self->util_kbase_store()->get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
	my $rxns = $source_model->modelreactions();
	my $model = $source_model->cloneObject();
	$model->parent($source_model->parent());
	print "Retrieving proteome comparison.\n";
	my $protcomp = $self->util_kbase_store()->get_object($params->{proteincomparison_workspace}."/".$params->{proteincomparison_id});
	print "Translating model.\n";
	my $report = $model->translate_model({
		proteome_comparison => $protcomp,
		keep_nogene_rxn => $params->{keep_nogene_rxn},
		translation_policy => $params->{translation_policy},
	});
	#Gapfilling model if requested
	my $output;
	if ($params->{gapfill_model} == 1) {
		$output = $self->func_gapfill_metabolic_model({
			thermodynamic_constraints => $params->{thermodynamic_constraints},
	    	comprehensive_gapfill => $params->{comprehensive_gapfill},
	    	custom_bound_list => $params->{custom_bound_list},
			media_supplement_list => $params->{media_supplement_list},
			expseries_id => $params->{expseries_id},
			expseries_workspace => $params->{expseries_workspace},
			expression_condition => $params->{expression_condition},
			exp_threshold_percentile => $params->{exp_threshold_percentile},
			exp_threshold_margin => $params->{exp_threshold_margin},
			activation_coefficient => $params->{activation_coefficient},
			omega => $params->{omega},
			objective_fraction => $params->{objective_fraction},
			minimum_target_flux => $params->{minimum_target_flux},
			number_of_solutions => $params->{number_of_solutions},
			workspace => $params->{workspace},
			fbamodel_id => $params->{fbamodel_output_id},
			fbamodel_output_id => $params->{fbamodel_output_id},
			media_workspace => $params->{media_workspace},
			media_id => $params->{media_id},
			source_fbamodel_id => $params->{fbamodel_id},
    		source_fbamodel_workspace => $params->{fbamodel_workspace}
		},$model,$source_model);
	} else {
		#If not gapfilling, then we just save the model directly
		$output->{number_gapfilled_reactions} = 0;
		$output->{number_removed_biomass_compounds} = 0;
		my $wsmeta = $self->util_kbase_store()->save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id});
		$output->{new_fbamodel_ref} = $params->{workspace}."/".$params->{fbamodel_output_id};
	}
	return $output;
}

sub func_simulate_growth_on_phenotype_data {
	my ($self,$params,$model) = @_;
	$params = $self->util_validate_args($params,["workspace","fbamodel_id","phenotypeset_id","phenotypesim_output_id"],{
		fbamodel_workspace => $params->{workspace},
		phenotypeset_workspace => $params->{workspace},
		thermodynamic_constraints => 0,
		all_reversible => 0,
		feature_ko_list => [],
		reaction_ko_list => [],
		custom_bound_list => [],
		media_supplement_list => [],
		all_transporters => 0,
		positive_transporters => 0,
		gapfill_phenotypes => 0
    });
    if (!defined($model)) {
    	print "Retrieving model.\n";
		$model = $self->util_kbase_store()->get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    }
    print "Retrieving phenotype set.\n";
    my $pheno = $self->util_kbase_store()->get_object($params->{phenotypeset_workspace}."/".$params->{phenotypeset_id});
    if ( $params->{all_transporters} ) {
		$model->addPhenotypeTransporters({phenotypes => $pheno,positiveonly => 0});
	} elsif ( $params->{positive_transporters} ) {
		$model->addPhenotypeTransporters({phenotypes => $pheno,positiveonly => 1});
	}
    print "Retrieving ".$params->{media_id}." media.\n";
    $params->{default_max_uptake} = 100;
    my $media = $self->util_kbase_store()->get_object("KBaseMedia/Complete");
    print "Preparing flux balance analysis problem.\n";
    my $fba;
    if ($params->{gapfill_phenotypes} == 0) {
    	$fba = $self->util_build_fba($params,$model,$media,$params->{phenotypesim_output_id}.".fba",0,0,undef);
    } else {
    	$fba = $self->util_build_fba($params,$model,$media,$params->{phenotypesim_output_id}.".fba",1,1,undef,1);
    }
    $fba->{_phenosimid} = $params->{phenotypesim_output_id};
    $fba->phenotypeset_ref($pheno->_reference());
    $fba->phenotypeset($pheno);
    print "Running flux balance analysis problem.\n";
    $fba->runFBA();
	if (!defined($fba->{_tempphenosim})) {
    	Bio::KBase::ObjectAPI::utilities::error("Simulation of phenotypes failed to return results from FBA! The model probably failed to grow on Complete media. Try running gapfiling first on Complete media.");
	}
    print "Saving FBA object with gapfilling sensitivity analysis and flux.\n";
    my $wsmeta = $self->util_kbase_store()->save_object($fba->phenotypesimulationset(),$params->{workspace}."/".$params->{phenotypesim_output_id});
    $fba->phenotypesimulationset_ref($fba->phenotypesimulationset()->_reference());
    $wsmeta = $self->util_kbase_store()->save_object($fba,$params->{workspace}."/".$params->{phenotypesim_output_id}.".fba",{hidden => 1});
    return {
		new_phenotypesim_ref => $params->{workspace}."/".$params->{phenotypesim_output_id}
	};
}

sub func_merge_metabolic_models_into_community_model {
	my ($self,$params) = @_;
    $params = $self->util_validate_args($params,["workspace","fbamodel_id_list","fbamodel_output_id"],{
    	fbamodel_workspace => $params->{workspace},
    	mixed_bag_model => 0
    });
    #Getting genome
	print "Retrieving first model.\n";
	my $model = $self->util_kbase_store()->get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id_list}->[0]);
	#Creating new community model
	my $commdl = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new({
		source_id => $params->{fbamodel_output_id},
		source => "KBase",
		id => $params->{fbamodel_output_id},
		type => "CommunityModel",
		name => $params->{fbamodel_output_id},
		template_ref => $model->template_ref(),
		template_refs => [$model->template_ref()],
		genome_ref => $params->{workspace}."/".$params->{fbamodel_output_id}.".genome",
		modelreactions => [],
		modelcompounds => [],
		modelcompartments => [],
		biomasses => [],
		gapgens => [],
		gapfillings => [],
	});
	$commdl->parent($self->util_kbase_store());
	for (my $i=0; $i < @{$params->{fbamodel_id_list}}; $i++) {
		$params->{fbamodel_id_list}->[$i] = $params->{fbamodel_workspace}."/".$params->{fbamodel_id_list}->[$i];
	}
	print "Merging models.\n";
	my $genomeObj = $commdl->merge_models({
		models => $params->{fbamodel_id_list},
		mixed_bag_model => $params->{mixed_bag_model},
		fbamodel_output_id => $params->{fbamodel_output_id}
	});
	print "Saving model and combined genome.\n";
	my $wsmeta = $self->util_kbase_store()->save_object($genomeObj,$params->{workspace}."/".$params->{fbamodel_output_id}.".genome");
	$wsmeta = $self->util_kbase_store()->save_object($commdl,$params->{workspace}."/".$params->{fbamodel_output_id});
	return {
		new_fbamodel_ref => $params->{workspace}."/".$params->{fbamodel_output_id}
	};
}

sub func_compare_flux_with_expression {
	my ($self,$params) = @_;
    $params = $self->util_validate_args($params,["workspace","fba_id","expseries_id","expression_condition","fbapathwayanalysis_output_id"],{
    	fba_workspace => $params->{workspace},
    	expseries_workspace => $params->{workspace},
    	exp_threshold_percentile => 0.5,
    	estimate_threshold => 0,
    	maximize_agreement => 0
    });
	print "Retrieving FBA solution.\n";
	my $fb = $self->util_kbase_store()->get_object($params->{fba_workspace}."/".$params->{fba_id});
   	print "Retrieving expression matrix.\n";
   	my $em = $self->util_kbase_store()->get_object($params->{expseries_workspace}."/".$params->{expseries_id});
	print "Retrieving FBA model.\n";
	my $fm = $fb->fbamodel();
	print "Retriveing genome.\n";
	my $genome = $fm->genome();
	print "Computing threshold based on always active genes (but will not be used unless requested).\n";
	my $exphash = $self->util_build_expression_hash($em,$params->{expression_condition});
	my $output = $genome->compute_gene_activity_threshold_using_faria_method($exphash);
	if ($output->[2] < 30) {
		print "Too few always-on genes recognized with nonzero expression for the reliable estimation of threshold.\n";
		if ($params->{estimate_threshold} == 1) {
			Bio::KBase::ObjectAPI::utilities::error("Threshold estimation selected, but too few always-active genes recognized to permit estimation.\n");
		} else {
			print "This is not a problem because threshold estimation was not explicitly requested in analysis.\n";
		}
	}
	if ($params->{estimate_threshold} == 1) {
		print "Expression threshold percentile for calling active genes set to:".100*$output->[1]."\n";
		$params->{exp_threshold_percentile} = $output->[1];	
	}
	print "Computing the cutoff expression value to use to call genes active.\n";
	my $sortedgenes = [sort { $exphash->{$a} <=> $exphash->{$b} } keys(%{$exphash})];
	my $threshold_gene = @{$sortedgenes};
	$threshold_gene = floor($params->{exp_threshold_percentile}*$threshold_gene);
	$threshold_gene =  $sortedgenes->[$threshold_gene];
	my $threshold_value = $exphash->{$threshold_gene};
	print "Computing expression values for each reaction.\n";
	my $modelrxns = $fm->modelreactions();
	my $rxn_exp_hash = {};
	my $rxn_flux_hash = {};
	my $gapfill_hash = {};
	my $fluxcount = 0;
	my $gapfillcount = 0;
	for (my $i=0; $i < @{$modelrxns}; $i++) {
		$rxn_exp_hash->{$modelrxns->[$i]->id()} = $modelrxns->[$i]->reaction_expression($exphash);
		if (@{$modelrxns->[$i]->modelReactionProteins()} == 0) {
			$gapfill_hash->{$modelrxns->[$i]->id()} = 1;
			$gapfillcount++;
		}
	}
	my $rxnvar = $fb->FBAReactionVariables();
	for (my $i=0; $i < @{$rxnvar}; $i++) {
		if ($rxnvar->[$i]->variableType() eq "flux" && abs($rxnvar->[$i]->value()) > 0.000000001) {
			if ($rxnvar->[$i]->modelreaction_ref() =~ m/\/([^\/]+)$/) {
				$fluxcount++;
				$rxn_flux_hash->{$1} = $rxnvar->[$i]->value();
			}
		}
	}
	my $noflux = @{$modelrxns} - $fluxcount - $gapfillcount;
	print "Computing the ideal cutoff to maximize agreement with predicted flux.\n";
	my $sortedrxns = [sort { $rxn_exp_hash->{$a} <=> $rxn_exp_hash->{$b} } keys(%{$rxn_exp_hash})]; 
	my $bestindex = 0;
	my $currentscore = 1.5*$fluxcount-$noflux;
	my $idealcutoff = $currentscore;
	my $bestpercentile;
	my $unrealizedscore = $currentscore;
	for (my $i=0; $i < @{$sortedrxns}; $i++) {
		if ($currentscore > $idealcutoff) {
			$bestindex = $i;
			$idealcutoff = $currentscore;
		}
		if (defined($rxn_flux_hash->{$sortedrxns->[$i]})) {
			$unrealizedscore = $unrealizedscore-1.5;
		} else {
			$unrealizedscore++;
		}
		if ($i >= 1 && $rxn_exp_hash->{$sortedrxns->[$i]} > $rxn_exp_hash->{$sortedrxns->[$i-1]}) {
			$currentscore = $unrealizedscore;
		}
	}
	$idealcutoff = $rxn_exp_hash->{$sortedrxns->[$bestindex]};
	for (my $i=0; $i < @{$sortedgenes}; $i++) {
		if ($exphash->{$sortedgenes->[$i]} == $idealcutoff) {
			$bestpercentile = $i/@{$sortedgenes};
			last;
		}
	}
	$bestpercentile = floor(100*$bestpercentile)/100;
	print "The threshold that maximizes model agreement is ".$idealcutoff." or ".100*$bestpercentile." percentile.\n";
	if ($params->{maximize_agreement} == 1) {
		print "Expression threshold percentile for calling active genes set to:".100*$bestpercentile."\n";
		$threshold_value = $idealcutoff;
		$params->{exp_threshold_percentile} = $bestpercentile;	
	}
	print "Retrieving biochemistry data.\n";
	my $bc = $self->util_kbase_store()->get_object("kbase/plantdefault_obs");
	print "Building expression FBA comparison object.\n";
	my $all_analyses = [{
		pathwayType => "KEGG",
		expression_matrix_ref => $em->{_reference},
		expression_condition => $params->{expression_condition},
		fbamodel_ref => $fm->_reference(),
		fba_ref => $fb->_reference(),
    	pathways => []
	}];
    my $globalpathways = ["Entire model","Best possible"];
    my $globalids = ["all","ideal"];
    my $rxnhash = {};
    my $baserxnhash = {};
    for (my $i=0; $i < @{$globalpathways}; $i++) {
    	my $currentpathway = {
    		pathwayName => $globalpathways->[$i],
	    	pathwayId => $globalids->[$i],
	    	totalModelReactions => 0,
	    	totalKEGGRxns => 0,
		    totalRxnFlux => 0,
		    gsrFluxPExpP => 0,
		    gsrFluxPExpN => 0,
		    gsrFluxMExpP => 0,
		    gsrFluxMExpM => 0,
		    gpRxnsFluxP => 0,
	    	reaction_list => []
    	};
    	push(@{$all_analyses->[0]->{pathways}},$currentpathway);
    	for (my $j=0; $j < @{$modelrxns}; $j++) {
    		$currentpathway->{totalModelReactions}++;
    		if (!defined($rxnhash->{$modelrxns->[$j]->id()})) {
	    		$rxnhash->{$modelrxns->[$j]->id()} = {
	    			id => $modelrxns->[$j]->id(),
	    			name => $modelrxns->[$j]->name(),
	    			flux => 0,
	    			gapfill => 0,
	    			expressed => 0,
					pegs => []
	    		};
	    		my $ftrs = $modelrxns->[$j]->featureIDs();
	    		for (my $k=0; $k < @{$ftrs}; $k++) {
	    			push(@{$rxnhash->{$modelrxns->[$j]->id()}->{pegs}},{
	    				pegId => $ftrs->[$k],
		    			expression => $exphash->{$ftrs->[$k]}
	    			});
	    		}
    		}
    		push(@{$currentpathway->{reaction_list}},$rxnhash->{$modelrxns->[$j]->id()});
    		if ($modelrxns->[$j]->id() =~ m/(.+)_[a-z](\d+)$/) {
    			my $baseid = $1;
    			my $cmpindex = $2;
    			if ($modelrxns->[$j]->reaction_ref() =~ m/(rxn\d+)/) {
    				if ($1 ne "rxn00000") {
    					$baseid = $1;
    				}
    			}
    			$baserxnhash->{$baseid}->{$modelrxns->[$j]->id()} = $rxnhash->{$modelrxns->[$j]->id()};
    			if ($cmpindex != 0) {
    				if (!defined($all_analyses->[$cmpindex])) {
	    				$all_analyses->[$cmpindex] = {
							pathwayType => "KEGG",
							expression_matrix_ref => $em->{_reference},
							expression_condition => $params->{expression_condition},
							fbamodel_ref => $fm->_reference(),
							fba_ref => $fb->_reference(),
					    	pathways => []
						};
    				}
    				if (!defined($all_analyses->[$cmpindex]->{pathways}->[$i])) {
    					$all_analyses->[$cmpindex]->{pathways}->[$i] = {
				    		pathwayName => $globalpathways->[$i],
					    	pathwayId => $globalids->[$i],
					    	totalModelReactions => 0,
					    	totalKEGGRxns => 0,
						    totalRxnFlux => 0,
						    gsrFluxPExpP => 0,
						    gsrFluxPExpN => 0,
						    gsrFluxMExpP => 0,
						    gsrFluxMExpM => 0,
						    gpRxnsFluxP => 0,
					    	reaction_list => []
				    	};
    				}
    				push(@{$all_analyses->[$cmpindex]->{pathways}->[$i]->{reaction_list}},$rxnhash->{$modelrxns->[$j]->id()});
    				$all_analyses->[$cmpindex]->{pathways}->[$i]->{totalModelReactions}++;
    				$all_analyses->[$cmpindex]->{pathways}->[$i]->{totalKEGGRxns}++;
    			}
    		}
    	}
    }
    my $pathwayhash = {};
    my $rxnDB = $bc->reactionSets();
	for (my $i =0; $i < @{$rxnDB}; $i++){
		 if ($rxnDB->[$i]->type() =~ /KEGG/) {
    		$pathwayhash->{$rxnDB->[$i]->name()} = $rxnDB->[$i];
		 }
	}
	my $target_pathways = [
	    "Glycolysis / Gluconeogenesis",
		"Pentose phosphate pathway",
		"Citrate cycle (TCA cycle)",
		"Pentose and glucuronate interconversions",
		"Lysine biosynthesis",
		"Valine, leucine and isoleucine biosynthesis",
		"Phenylalanine, tyrosine and tryptophan biosynthesis",
		"Cysteine and methionine metabolism",
		"Glycine, serine and threonine metabolism",
		"Alanine, aspartate and glutamate metabolism",
		"Arginine and proline metabolism",
		"Histidine metabolism",
		"Purine metabolism",
		"Pyrimidine metabolism",
		"Thiamine metabolism",
		"Nicotinate and nicotinamide metabolism",
		"Pantothenate and CoA biosynthesis",
		"Folate biosynthesis",
		"Riboflavin metabolism",
		"Vitamin B6 metabolism",
		"Ubiquinone and other terpenoid-quinone biosynthesis",
		"Terpenoid backbone biosynthesis",
		"Biotin metabolism",
		"Fatty acid biosynthesis",
		"Fatty acid elongation",
		"Peptidoglycan biosynthesis",
		"Lipopolysaccharide biosynthesis",
		"Methane metabolism",
		"Sulfur metabolism",
		"Nitrogen metabolism",
		"Glutathione metabolism",
		"Fatty acid metabolism",
		"Propanoate metabolism",
		"Butanoate metabolism",
		"Pyruvate metabolism",
		"One carbon pool by folate",
		"Carbon fixation pathways in prokaryotes",
		"Carbon fixation in photosynthetic organisms",
		"Tryptophan metabolism",
		"Valine, leucine and isoleucine degradation",
		"Lysine degradation",
		"Phenylalanine metabolism",
		"Tyrosine metabolism",
		"D-Glutamine and D-glutamate metabolism"
    ];
    for (my $i=0; $i < @{$target_pathways}; $i++) {
    	if (defined($pathwayhash->{$target_pathways->[$i]})) {
	    	my $rxns = $pathwayhash->{$target_pathways->[$i]}->reaction_refs();
	    	my $currentpathway = {
		 		pathwayName => $target_pathways->[$i],
		    	pathwayId => $pathwayhash->{$target_pathways->[$i]}->id(),
		    	totalModelReactions => 0,
		    	totalKEGGRxns => @{$rxns},
			    totalRxnFlux => 0,
			    gsrFluxPExpP => 0,
			    gsrFluxPExpN => 0,
			    gsrFluxMExpP => 0,
			    gsrFluxMExpM => 0,
			    gpRxnsFluxP => 0,
		    	reaction_list => []
		 	};
		 	my $allpathhash = {};
		 	push(@{$all_analyses->[0]->{pathways}},$currentpathway);
    		for (my $j =0; $j < @{$rxns}; $j++){
    			if ($rxns->[$j] =~ m/\/([^\/]+)$/) {
    				my $id = $1;
    				if (defined($baserxnhash->{$id})) {
    					foreach my $mdlrxn (keys(%{$baserxnhash->{$id}})) {
    						$currentpathway->{totalModelReactions}++;
    						push(@{$currentpathway->{reaction_list}},$baserxnhash->{$id}->{$mdlrxn});
    						if ($mdlrxn =~ m/(.+)_[a-z](\d+)$/) {
				    			my $cmpindex = $2;
				    			if ($cmpindex != 0) {
				    				if (!defined($allpathhash->{$cmpindex}->{$target_pathways->[$i]})) {
				    					$allpathhash->{$cmpindex}->{$target_pathways->[$i]} = {
								    		pathwayName => $target_pathways->[$i],
		    								pathwayId => $pathwayhash->{$target_pathways->[$i]}->id(),
									    	totalModelReactions => 0,
									    	totalKEGGRxns => @{$rxns},
										    totalRxnFlux => 0,
										    gsrFluxPExpP => 0,
										    gsrFluxPExpN => 0,
										    gsrFluxMExpP => 0,
										    gsrFluxMExpM => 0,
										    gpRxnsFluxP => 0,
									    	reaction_list => []
								    	};
								    	push(@{$all_analyses->[$cmpindex]->{pathways}},$allpathhash->{$cmpindex}->{$target_pathways->[$i]});
				    				}
				    				push(@{$allpathhash->{$cmpindex}->{$target_pathways->[$i]}->{reaction_list}},$rxnhash->{$modelrxns->[$j]->id()});
				    				$allpathhash->{$cmpindex}->{$target_pathways->[$i]}->{totalModelReactions}++;
				    			}
				    		}
    					}
    				}	
    			}
    		}
    	}
    }
	for (my $m=0; $m < @{$all_analyses}; $m++) {
		my $expAnalysis = $all_analyses->[$m];
		for (my $i=0; $i < @{$expAnalysis->{pathways}}; $i++) {
			if (!defined($expAnalysis->{pathways}->[$i]->{reaction_list})) {
				$expAnalysis->{pathways}->[$i]->{reaction_list} = [];
			}
			my $currentcutoff = $threshold_value;;
			if ($expAnalysis->{pathways}->[$i]->{pathwayId} eq "ideal") {
				$currentcutoff = $idealcutoff;
			}
			for (my $j=0; $j < @{$expAnalysis->{pathways}->[$i]->{reaction_list}}; $j++) {
				my $id = $expAnalysis->{pathways}->[$i]->{reaction_list}->[$j]->{id};
				if (defined($rxn_flux_hash->{$id})) {
					$expAnalysis->{pathways}->[$i]->{reaction_list}->[$j]->{flux} = $rxn_flux_hash->{$id};
					$expAnalysis->{pathways}->[$i]->{totalRxnFlux}++;
					if (defined($gapfill_hash->{$id})) {
						$expAnalysis->{pathways}->[$i]->{reaction_list}->[$j]->{gapfill} = 1;
						$expAnalysis->{pathways}->[$i]->{gpRxnsFluxP}++;
					} elsif (defined($rxn_exp_hash->{$id}) && $rxn_exp_hash->{$id} >= $currentcutoff) {
						$expAnalysis->{pathways}->[$i]->{reaction_list}->[$j]->{expressed} = 1;
						$expAnalysis->{pathways}->[$i]->{gsrFluxPExpP}++;
					} else {
						$expAnalysis->{pathways}->[$i]->{gsrFluxPExpN}++;
					}
				} else {
					$expAnalysis->{pathways}->[$i]->{reaction_list}->[$j]->{flux} = 0;
					if (defined($rxn_exp_hash->{$id}) && $rxn_exp_hash->{$id} >= $currentcutoff) {
						$expAnalysis->{pathways}->[$i]->{gsrFluxMExpP}++;
						$expAnalysis->{pathways}->[$i]->{reaction_list}->[$j]->{expressed} = 1;
					} else {
						$expAnalysis->{pathways}->[$i]->{gsrFluxMExpM}++;
					}
					if (defined($gapfill_hash->{$id})) {
						$expAnalysis->{pathways}->[$i]->{reaction_list}->[$j]->{gapfill} = 1;
					}
				}
			}
			my $intlist = ["totalModelReactions","totalKEGGRxns","totalRxnFlux","gsrFluxPExpP","gsrFluxPExpN","gsrFluxMExpP","gsrFluxMExpM","gpRxnsFluxP"];
			for (my $j=0; $j < @{$intlist}; $j++) {
				if (!defined($expAnalysis->{pathways}->[$i]->{$intlist->[$j]})) {
					$expAnalysis->{pathways}->[$i]->{$intlist->[$j]} = 0;
				}
				$expAnalysis->{pathways}->[$i]->{$intlist->[$j]} = $expAnalysis->{pathways}->[$i]->{$intlist->[$j]}+0;
			}
		}
	}
	print "Saving FBAPathwayAnalysis object.\n";
    my $meta = $self->util_kbase_store->workspace()->save_objects({
    	workspace => $params->{workspace},
    	objects => [{
    		type => "KBaseFBA.FBAPathwayAnalysis",
    		data => $all_analyses->[0],
    		name => $params->{fbapathwayanalysis_output_id}
    	}]
    });
    my $outputobj = {
		new_fbapathwayanalysis_ref => $params->{workspace}."/".$params->{fbapathwayanalysis_output_id}
	};
    if (@{$all_analyses} > 1) {
    	for (my $m=1; $m < @{$all_analyses}; $m++) {
	    	$meta = $self->util_kbase_store->workspace()->save_objects({
		    	workspace => $params->{workspace},
		    	objects => [{
		    		type => "KBaseFBA.FBAPathwayAnalysis",
		    		data => $all_analyses->[$m],
		    		name => $params->{fbapathwayanalysis_output_id}.".".$m
		    	}]
		    });
		    push(@{$outputobj->{additional_fbapathwayanalysis_ref}},$params->{workspace}."/".$params->{fbapathwayanalysis_output_id}.".".$m);
    	}
    }
	return $outputobj;
}

sub func_check_model_mass_balance {
	my ($self,$params) = @_;
	$params = $self->util_validate_args($params,["workspace","fbamodel_id"],{
		fbamodel_workspace => $params->{workspace},
    });
    print "Retrieving model.\n";
	my $model = $self->util_kbase_store()->get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    my $media = $self->util_kbase_store()->get_object("KBaseMedia/Complete");
    my $fba = $self->util_build_fba($params,$model,$media,"tempfba",0,0,undef);
    $fba->parameters()->{"Mass balance atoms"} = "C;S;P;O;N";
    print "Checking model mass balance.\n";
   	my $objective = $fba->runFBA();
	my $message = "No mass imbalance found";
    if (length($fba->MFALog) > 0) {
    	$message = $fba->MFALog();
    }
    my $reportObj = {
		'objects_created' => [],
		'text_message' => $message
	};
    my $meta = $self->util_kbase_store->workspace()->save_objects({
    	workspace => $params->{workspace},
    	objects => [{
    		type => "KBaseReport.Report",
    		data => $reportObj,
    		name => $params->{fbamodel_id}.".massbalancereport",
    		hidden => 1,
    		provenance => Bio::KBase::ObjectAPI::config::provenance(),
    		meta => {}
    	}]
    });
   	return {
		report_name => $params->{fbamodel_id}.".massbalancereport",
		ws_report_id => $params->{workspace}.'/'.$params->{fbamodel_id}.".massbalancereport"
	};
}

sub func_create_or_edit_media {
	my ($self,$params) = @_;
    $params = $self->util_validate_args($params,["workspace","media_id","data"],{
    	media_workspace => $params->{workspace},
    	media_output_id => $params->{media_id}
    });
	#Getting genome
	my $media = $self->util_kbase_store()->get_object($params->{media_workspace}."/".$params->{media_id});
	my $newmedia = Bio::KBase::ObjectAPI::Biochem::Media->new($params->{data});
	my $wsmeta = $self->util_kbase_store()->save_object($newmedia,$params->{workspace}."/".$params->{media_output_id});
	my $oldmediacpd = $media->mediacompounds();
	my $newmediacpd = $newmedia->mediacompounds();
	my $added = [];
	my $removed = [];
	my $changed = [];
	for (my $i=0; $i < @{$oldmediacpd}; $i++) {
		my $qcpd = $newmedia->queryObject("mediacompounds",{compound_ref => $oldmediacpd->[$i]->compound_ref()});
		if (!defined($qcpd)) {
			push(@{$removed},$oldmediacpd->[$i]->compound()->name()." (".$oldmediacpd->[$i]->compound()->id().")");
		} else {
			if ($oldmediacpd->[$i]->concentration() != $qcpd->concentration()) {
				push(@{$changed},$oldmediacpd->[$i]->compound()->name()." (".$oldmediacpd->[$i]->compound()->id().") concentration changed: ".$oldmediacpd->[$i]->concentration()." => ".$qcpd->concentration())
			}
			if ($oldmediacpd->[$i]->maxFlux() != $qcpd->maxFlux()) {
				push(@{$changed},$oldmediacpd->[$i]->compound()->name()." (".$oldmediacpd->[$i]->compound()->id().") max flux changed: ".$oldmediacpd->[$i]->maxFlux()." => ".$qcpd->maxFlux())
			}
			if ($oldmediacpd->[$i]->minFlux() != $qcpd->minFlux()) {
				push(@{$changed},$oldmediacpd->[$i]->compound()->name()." (".$oldmediacpd->[$i]->compound()->id().") min flux changed: ".$oldmediacpd->[$i]->minFlux()." => ".$qcpd->minFlux())
			}
		}
	}
	for (my $i=0; $i < @{$newmediacpd}; $i++) {
		my $qcpd = $media->queryObject("mediacompounds",{compound_ref => $newmediacpd->[$i]->compound_ref()});
		if (!defined($qcpd)) {
			push(@{$added},$newmediacpd->[$i]->compound()->name()." (".$newmediacpd->[$i]->compound()->id().")");
		}
	}
	my $message = "New media created: ".$params->{media_output_id}."\nStarting from: ".$params->{media_id}."\n\nAdded:\n".join("\n",@{$added})."\n\nRemoved:\n".join("\n",@{$removed})."\n\nChanges:\n".join("\n",@{$changed})."\n";
	print $message;
	my $reportObj = {
		'objects_created' => [$wsmeta->[6]."/".$wsmeta->[0]."/".$wsmeta->[4]],
		'text_message' => $message
	};
    my $meta = $self->util_kbase_store->workspace()->save_objects({
    	workspace => $params->{workspace},
    	objects => [{
    		type => "KBaseReport.Report",
    		data => $reportObj,
    		name => $params->{media_output_id}.".create_or_edit_media.report",
    		hidden => 1,
    		provenance => Bio::KBase::ObjectAPI::config::provenance(),
    		meta => {}
    	}]
    });
   	return {
		new_media_ref => $params->{workspace}."/".$params->{media_output_id},
		report_name => $params->{media_output_id}.".create_or_edit_media.report",
		ws_report_id => $params->{workspace}.'/'.$params->{media_output_id}.".create_or_edit_media.report"
	};
}

sub func_edit_metabolic_model {
	my ($self,$params) = @_;
    $params = $self->util_validate_args($params,["workspace","fbamodel_id","data"],{
    	fbamodel_workspace => $params->{workspace},
    	fbamodel_output_id => $params->{fbamodel_id}
    });
	#Getting genome
	print "Loading model from workspace\n";
	my $model = $self->util_kbase_store()->get_object($params->{media_workspace}."/".$params->{fbamodel_id});
	my $added = [];
	my $removed = [];
	my $changed = [];
	#Removing reactions specified for removal
	print "Removing specified reactions\n";
	if (defined($params->{data}->{reactions_to_remove})) {
		for (my $i=0; $i < @{$params->{data}->{reactions_to_remove}}; $i++) {
	    	my $rxn = $model->getObject("modelreactions",$params->{data}->{reactions_to_remove}->[$i]);
	    	if (defined($rxn)) {
	    		push(@{$removed},$params->{data}->{reactions_to_remove}->[$i]);
	    		$model->remove("modelreactions",$rxn);
	    	}
	    }
	}
	#Adding reactions specified for addition
	print "Adding specified reactions\n";
	($params->{reactions},my $compoundhash) = $self->_process_reactions_list($params->{reactions},$params->{compounds});
	if (defined($params->{data}->{reactions_to_add})) {
		for (my $i=0; $i < @{$params->{data}->{reactions_to_add}}; $i++) {
	    	my $rxn = $params->{data}->{reactions_to_add}->[$i];
	    	push(@{$added},$rxn->[0]);
		    $rxn->[0] =~ s/[^\w]/_/g;
	    	if (defined($rxn->[8])) {
	    		if ($rxn->[8] =~ m/^\[([A-Za-z])\]\s*:\s*(.+)/) {
	    			$rxn->[2] = lc($1);
	    			$rxn->[8] = $2;
	    		}
	    		my $eqn = "| ".$rxn->[8]." |";
	    		my $species_array = [split(/[\s\+<>=]+/,$rxn->[8])];
	    		my $translation = {};
	    		for (my $j=0; $j < @{$species_array}; $j++) {
	    			$species_array->[$j] =~ s/\[.+\]$//g;
	    			my $id = $species_array->[$j];
			    	if ($id =~ m/[^\w]/) {
			    		$species_array->[$j] =~ s/[^\w]/_/g;
			    	}
			    	if ($id =~ m/-/) {
			    		$species_array->[$j] =~ s/-/_/g;
			    	}
			    	$translation->{$id} = $species_array->[$j];
	    		}
	    		foreach my $cpd (keys(%{$translation})) {
	    			if (index($eqn,$cpd) >= 0 && $cpd ne $translation->{$cpd}) {
	    				my $origcpd = $cpd;
	    				$cpd =~ s/\+/\\+/g;
	    				$cpd =~ s/\(/\\(/g;
	    				$cpd =~ s/\)/\\)/g;
	    				my $array = [split(/\s$cpd\s/,$eqn)];
	    				$eqn = join(" ".$translation->{$origcpd}." ",@{$array});
	    				$array = [split(/\s$cpd\[/,$eqn)];
	    				$eqn = join(" ".$translation->{$origcpd}."[",@{$array});
	    			}
	    		}
	    		$eqn =~ s/^\|\s//;
	    		$eqn =~ s/\s\|$//;
	    		while ($eqn =~ m/\[([A-Z])\]/) {
	    			my $reqplace = "[".lc($1)."]";
	    			$eqn =~ s/\[[A-Z]\]/$reqplace/;
	    		}
	    		if ($eqn =~ m/<[-=]+>/) {
	    			if (!defined($rxn->[1])) {
	    				$rxn->[1] = "=";
	    			}
	    		} elsif ($eqn =~ m/[-=]+>/) {
	    			if (!defined($rxn->[1])) {
	    				$rxn->[1] = ">";
	    			}
	    		} elsif ($eqn =~ m/<[-=]+/) {
	    			if (!defined($rxn->[1])) {
	    				$rxn->[1] = "<";
	    			}
	    		}
	    		$rxn->[8] = $eqn;
	    	}
	    	$model->addModelReaction({
			    reaction => $rxn->[0],
			    direction => $rxn->[2],
			    compartment => $rxn->[1],
			    gpr => $rxn->[3],
			    compounds => {},
			    equation => $rxn->[8],
			    pathway => $rxn->[4],
			    name => $rxn->[5],
			    reference => $rxn->[6],
			    enzyme => $rxn->[7]
			});
	    }
	}
	#Modifying reactions specified for modification
	print "Modifying specified reactions\n";
	if (defined($params->{data}->{reactions_to_modify})) {
		for (my $i=0; $i < @{$params->{data}->{reactions_to_modify}}; $i++) {
			push(@{$changed},$params->{data}->{reactions_to_modify}->[$i]->[0]);
	    	$model->adjustModelReaction({
			    reaction => $params->{data}->{reactions_to_modify}->[$i]->[0],
			    direction => $params->{data}->{reactions_to_modify}->[$i]->[1],
			    gpr => $params->{data}->{reactions_to_modify}->[$i]->[2],
			    pathway => $params->{data}->{reactions_to_modify}->[$i]->[3],
			    name => $params->{data}->{reactions_to_modify}->[$i]->[4],
			    reference => $params->{data}->{reactions_to_modify}->[$i]->[5],
			    enzyme => $params->{data}->{reactions_to_modify}->[$i]->[6]
			});
	    }
	}
	#Creating message to report all modifications made
	print "Saving edited model to workspace\n";
	my $wsmeta = $self->util_kbase_store()->save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id});
	my $message = "Name of edited model: ".$params->{fbamodel_output_id}."\nStarting from: ".$params->{fbamodel_id}."\n\nAdded:\n".join("\n",@{$added})."\n\nRemoved:\n".join("\n",@{$removed})."\n\nChanged:\n".join("\n",@{$changed})."\n";
	print $message;
	my $reportObj = {
		'objects_created' => [$wsmeta->[6]."/".$wsmeta->[0]."/".$wsmeta->[4]],
		'text_message' => $message
	};
    my $meta = $self->util_kbase_store->workspace()->save_objects({
    	workspace => $params->{workspace},
    	objects => [{
    		type => "KBaseReport.Report",
    		data => $reportObj,
    		name => $params->{fbamodel_output_id}.".edit_metabolic_model.report",
    		hidden => 1,
    		provenance => Bio::KBase::ObjectAPI::config::provenance(),
    		meta => {}
    	}]
    });
   	return {
		new_fbamodel_ref => $params->{workspace}."/".$params->{fbamodel_output_id},
		report_name => $params->{fbamodel_output_id}.".edit_metabolic_model.report",
		ws_report_id => $params->{workspace}.'/'.$params->{fbamodel_output_id}.".edit_metabolic_model.report"
	};
}

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    
    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg = Config::IniFiles->new(-file=>$config_file);
    my $wsInstance = $cfg->val('fba_tools','workspace-url');
    die "no workspace-url defined" unless $wsInstance;
    
    $self->{'workspace-url'} = $wsInstance;
    my $confighash = {};
    my $params = [$cfg->Parameters('fba_tools')];
    my $paramhash = {};
    foreach my $param (@{$params}) {
    	$paramhash->{$param} = $cfg->val('fba_tools',$param);
    }
    Bio::KBase::ObjectAPI::config::all_params($paramhash);
    
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
	$return = $self->func_build_metabolic_model($params);
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
	$results = $self->func_gapfill_metabolic_model($params);
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
ws_fba_id is a string

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
ws_fba_id is a string


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
	$results = $self->func_run_flux_balance_analysis($params);
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
	$results = $self->func_compare_fba_solutions($params);
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
	$results = $self->func_propagate_model_to_new_genome($params);
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
	feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
	reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
fbamodel_id is a string
workspace_name is a string
phenotypeset_id is a string
phenotypesim_id is a string
bool is an int
feature_id is a string
reaction_id is a string
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
	feature_ko_list has a value which is a reference to a list where each element is a fba_tools.feature_id
	reaction_ko_list has a value which is a reference to a list where each element is a fba_tools.reaction_id
	custom_bound_list has a value which is a reference to a list where each element is a string
	media_supplement_list has a value which is a reference to a list where each element is a fba_tools.compound_id
fbamodel_id is a string
workspace_name is a string
phenotypeset_id is a string
phenotypesim_id is a string
bool is an int
feature_id is a string
reaction_id is a string
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
	$results = $self->func_simulate_growth_on_phenotype_data($params);
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
	$results = $self->func_merge_metabolic_models_into_community_model($params);
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
	$results = $self->func_compare_flux_with_expression($params);
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
	$results = $self->func_check_model_mass_balance($params);
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

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
new_fba_ref has a value which is a fba_tools.ws_fba_id
objective has a value which is an int


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



=cut

1;
