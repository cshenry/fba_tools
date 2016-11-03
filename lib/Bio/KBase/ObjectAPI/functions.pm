package Bio::KBase::ObjectAPI::functions;
use strict;
use warnings;
use Data::Dumper;
use Bio::KBase::ObjectAPI::utilities;

our $handler;#Needs: log(string),save_object,get_object

sub set_handler {
	my ($input_handler) = @_;
	$handler = $input_handler;
}

sub util_get_object {
	my($ref,$parameters) = @_;
	return $handler->util_get_object($ref,$parameters);
}

sub util_save_object {
	my($object,$ref,$parameters) = @_;
	return $handler->util_save_object($ref,$parameters);
}

sub util_build_expression_hash {
	my ($exp_matrix,$exp_condition) = @_;
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
	my ($params,$model,$media,$id,$add_external_reactions,$make_model_reactions_reversible,$source_model,$gapfilling) = @_;
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
    	$handler->util_log("Retrieving expression matrix.");
    	$exp_matrix = $handler->util_get_object($params->{expseries_workspace}."/".$params->{expseries_id});
    	if (!defined($params->{expression_condition})) {
			Bio::KBase::ObjectAPI::utilities::error("Input must specify the column to select from the expression matrix");
		}
		$exphash = Bio::KBase::ObjectAPI::functions::util_build_expression_hash($exp_matrix,$params->{expression_condition});
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
		parameters => {
			minimum_target_flux => defined $params->{minimum_target_flux} ? $params->{minimum_target_flux} : 0.01,
		},
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
		ExpressionKappa => defined $params->{exp_threshold_margin} ? $params->{exp_threshold_margin} : 0.1,
		calculateReactionKnockoutSensitivity => defined($params->{sensitivity_analysis}) ? $params->{sensitivity_analysis} : 0
    });
	$fbaobj->parent($handler->util_store());
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
	if (defined($model->genome_ref()) && defined($params->{feature_ko_list})  && $params->{feature_ko_list} ne "") {
		my $genome = $model->genome();
		foreach my $gene (@{$params->{feature_ko_list}}) {
			my $geneObj = $genome->searchForFeature($gene);
			if (defined($geneObj)) {
				$fbaobj->addLinkArrayItem("geneKOs",$geneObj);
			}
		}
	}
	if (defined($params->{reaction_ko_list}) && $params->{reaction_ko_list} ne "") {
		foreach my $reaction (@{$params->{reaction_ko_list}}) {
			my $rxnObj = $model->searchForReaction($reaction);
			if (defined($rxnObj)) {
				$fbaobj->addLinkArrayItem("reactionKOs",$rxnObj);
			}
		}
	}
	if (defined($params->{media_supplement_list}) && $params->{media_supplement_list} ne "") {
		foreach my $compound (@{$params->{media_supplement_list}}) {
			my $cpdObj = $model->searchForCompound($compound);
			if (defined($cpdObj)) {
				$fbaobj->addLinkArrayItem("additionalCpds",$cpdObj);
			}
		}
	}
	if (!defined($params->{custom_bound_list}) || $params->{custom_bound_list} eq "") {
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
			activate_all_model_reactions => $params->{comprehensive_gapfill},
		};
		print "activate_all_model_reactions:".$params->{comprehensive_gapfill}."\n";
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

sub util_process_reactions_list {
	my ($reactions,$compounds) = @_;
	my $translation = {};
    for (my $i=0; $i < @{$compounds}; $i++) {
    	my $cpd = $compounds->[$i];
    	my $id = $cpd->[0];
    	if ($id =~ m/[^\w]/) {
    		$cpd->[0] =~ s/[^\w]/_/g;
    	}
    	if ($id =~ m/-/) {
    		$cpd->[0] =~ s/-/_/g;
    	}
    	$translation->{$id} = $cpd->[0];
    }
    for (my $i=0; $i < @{$reactions}; $i++) {
    	my $rxn = $reactions->[$i];
    	$rxn->[0] =~ s/[^\w]/_/g;
    	if (defined($rxn->[8])) {
    		if ($rxn->[8] =~ m/^\[([A-Za-z])\]\s*:\s*(.+)/) {
    			$rxn->[2] = lc($1);
    			$rxn->[8] = $2;
    		}
    		my $eqn = "| ".$rxn->[8]." |";
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
    }
	my $compoundhash = {};
	for (my $i=0; $i < @{$compounds}; $i++) {
		$compoundhash->{$compounds->[$i]->[0]} = $compounds->[$i];
	}
	return ($reactions,$compoundhash);
}

sub func_build_metabolic_model {
	my ($params,$datachannel) = @_;
	$params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","genome_id","fbamodel_output_id"],{
    	media_id => undef,
    	template_id => "auto",
    	genome_workspace => $params->{workspace},
    	template_workspace => $params->{workspace},
    	media_workspace => $params->{workspace},
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
	$handler->util_log("Retrieving genome.");
	my $genome = $handler->util_get_object($params->{genome_workspace}."/".$params->{genome_id});
	#Classifying genome
	if ($params->{template_id} eq "auto") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
    	$handler->util_log("Classifying genome in order to select template.");
    	if ($genome->template_classification() eq "plant") {
    		$params->{template_id} = "PlantModelTemplate";
    	} elsif ($genome->template_classification() eq "Gram negative") {
    		$params->{template_id} = "GramNegModelTemplate";
    	} elsif ($genome->template_classification() eq "Gram positive") {
    		$params->{template_id} = "GramPosModelTemplate";
    	}
	} elsif ($params->{template_id} eq "grampos") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "GramPosModelTemplate";
	} elsif ($params->{template_id} eq "gramneg") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "GramNegModelTemplate";
	} elsif ($params->{template_id} eq "plant") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "PlantModelTemplate";
	} elsif ($params->{template_id} eq "core") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "CoreModelTemplate";
	}
    #Retrieving template
    $handler->util_log("Retrieving model template ".$params->{template_id}.".");
    my $template = $handler->util_get_object($params->{template_workspace}."/".$params->{template_id});
    #Building the model
    my $model = $template->buildModel({
	    genome => $genome,
	    modelid => $params->{fbamodel_output_id},
	    fulldb => 0
	});
	$datachannel->{fbamodel} = $model;
	#Gapfilling model if requested
	my $output;
	if ($params->{gapfill_model} == 1) {
		$output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
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
		my $wsmeta = $handler->util_save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
		$output->{new_fbamodel_ref} = $params->{workspace}."/".$params->{fbamodel_output_id};
	}
	return $output;
}

sub func_gapfill_metabolic_model {
	my ($params,$model,$source_model) = @_;
	$params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fbamodel_id"],{
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
		number_of_solutions => 1,
		gapfill_output_id => undef
    });
    if (!defined($model)) {
    	$handler->util_log("Retrieving model.");
		$model = $handler->util_get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    }
    if (!defined($params->{media_id})) {
    	if ($model->genome()->domain() eq "Plant" || $model->genome()->taxonomy() =~ /viridiplantae/i) {
			$params->{media_id} = Bio::KBase::ObjectAPI::config::default_plant_media();
    	} else {
			$params->{default_max_uptake} = 100;
			$params->{media_id} = Bio::KBase::ObjectAPI::config::default_microbial_media();
		}
    	$params->{media_workspace} = Bio::KBase::ObjectAPI::config::default_media_workspace();
    }
    $handler->util_log("Retrieving ".$params->{media_id}." media.");
    my $media = $handler->util_get_object($params->{media_workspace}."/".$params->{media_id});
    $handler->util_log("Preparing flux balance analysis problem.");
    if (defined($params->{source_fbamodel_id}) && !defined($source_model)) {
		$source_model = $handler->util_get_object($params->{source_fbamodel_workspace}."/".$params->{source_fbamodel_id});
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
    my $fba = Bio::KBase::ObjectAPI::functions::util_build_fba($params,$model,$media,$params->{fbamodel_output_id}.".".$gfid,1,1,$source_model,1);
    $handler->util_log("Running flux balance analysis problem.");
	$fba->runFBA();
	#Error checking the FBA and gapfilling solution
	if (!defined($fba->gapfillingSolutions()->[0])) {
		Bio::KBase::ObjectAPI::utilities::error("Analysis completed, but no valid solutions found!");
	}
    $handler->util_log("Saving gapfilled model.");
    my $wsmeta = $handler->util_save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
    $handler->util_log("Saving FBA object with gapfilling sensitivity analysis and flux.");
    $fba->fbamodel_ref($model->_reference());
    if (!defined($params->{gapfill_output_id})) {
    	$params->{gapfill_output_id} = $params->{fbamodel_output_id}.".".$gfid;
    }
    $fba->id($params->{gapfill_output_id});
    $wsmeta = $handler->util_save_object($fba,$params->{workspace}."/".$params->{gapfill_output_id},{type => "KBaseFBA.FBA"});
	return {
		new_fba_ref => $params->{workspace}."/".$params->{fbamodel_output_id}.".".$gfid,
		new_fbamodel_ref => $params->{workspace}."/".$params->{fbamodel_output_id},
		number_gapfilled_reactions => 0,
		number_removed_biomass_compounds => 0
	};
}

sub func_run_flux_balance_analysis {
	my ($params,$model) = @_;
	$params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fbamodel_id","fba_output_id"],{
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
		massbalance => undef,
		sensitivity_analysis => 0
    });
    if (!defined($model)) {
    	$handler->util_log("Retrieving model.");
		$model = $handler->util_get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    }
    if (!defined($params->{media_id})) {
    	if ($model->genome()->domain() eq "Plant" || $model->genome()->taxonomy() =~ /viridiplantae/i) {
			$params->{media_id} = Bio::KBase::ObjectAPI::config::default_plant_media();
    	} else {
			$params->{default_max_uptake} = 100;
			$params->{media_id} = Bio::KBase::ObjectAPI::config::default_microbial_media();
		}
    	$params->{media_workspace} = Bio::KBase::ObjectAPI::config::default_media_workspace();
    }
    $handler->util_log("Retrieving ".$params->{media_id}." media.");
    my $media = $handler->util_get_object($params->{media_workspace}."/".$params->{media_id});
    $handler->util_log("Preparing flux balance analysis problem.");
    my $fba = Bio::KBase::ObjectAPI::functions::util_build_fba($params,$model,$media,$params->{fba_output_id},0,0,undef);
    #Running FBA
    $handler->util_log("Running flux balance analysis problem.");
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
    $handler->util_log("Saving FBA results.");
    $fba->id($params->{fba_output_id});
    my $wsmeta = $handler->util_save_object($fba,$params->{workspace}."/".$params->{fba_output_id},{type => "KBaseFBA.FBA"});
	return {
		new_fba_ref => $params->{workspace}."/".$params->{fba_output_id}
	};
}

sub func_compare_fba_solutions {
	my ($params) = @_;
	$params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fba_id_list","fbacomparison_output_id"],{
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
    $fbacomp->parent($handler->util_store());
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
    	$handler->util_log("Retrieving FBA ".$fbaids->[$i].".");
    	my $fba = $handler->util_get_object($fbaids->[$i]);
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
    $handler->util_log("Computing similarities.");
    for (my $i=0; $i < @{$fbaids}; $i++) {
    	for (my $j=0; $j < @{$fbaids}; $j++) {
    		if ($j != $i) {
    			$fbahash->{$fbaids->[$i]}->fba_similarity()->{$fbaids->[$j]} = [0,0,0,0,0,0,0,0];
    		}
    	}
    }
    $handler->util_log("Comparing reaction states.");
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
    $handler->util_log("Comparing compound states.");
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
    $handler->util_log("Saving FBA comparison object.");
    my $wsmeta = $handler->util_save_object($fbacomp,$params->{workspace}."/".$params->{fbacomparison_output_id},{type => "KBaseFBA.FBAComparison"});
	return {
		new_fbacomparison_ref => $params->{workspace}."/".$params->{fbacomparison_output_id}
	};
}

sub func_propagate_model_to_new_genome {
	my ($params) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fbamodel_id","proteincomparison_id","fbamodel_output_id"],{
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
	my $source_model = $handler->util_get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
	my $rxns = $source_model->modelreactions();
	my $model = $source_model->cloneObject();
	$model->parent($source_model->parent());
	$handler->util_log("Retrieving proteome comparison.");
	my $protcomp = $handler->util_get_object($params->{proteincomparison_workspace}."/".$params->{proteincomparison_id});
	$handler->util_log("Translating model.");
	my $report = $model->translate_model({
		proteome_comparison => $protcomp,
		keep_nogene_rxn => $params->{keep_nogene_rxn},
		translation_policy => $params->{translation_policy},
	});
	#Gapfilling model if requested
	my $output;
	if ($params->{gapfill_model} == 1) {
		$output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
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
		my $wsmeta = $handler->util_save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
		$output->{new_fbamodel_ref} = $params->{workspace}."/".$params->{fbamodel_output_id};
	}
	return $output;
}

sub func_simulate_growth_on_phenotype_data {
	my ($params,$model) = @_;
	$params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fbamodel_id","phenotypeset_id","phenotypesim_output_id"],{
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
		gapfill_phenotypes => 0,
		fit_phenotype_data => 0,
		fbamodel_output_id => $params->{fbamodel_id}.".phenogf"
    });
    if (!defined($model)) {
    	$handler->util_log("Retrieving model.");
		$model = $handler->util_get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    }
    $handler->util_log("Retrieving phenotype set.");
    my $pheno = $handler->util_get_object($params->{phenotypeset_workspace}."/".$params->{phenotypeset_id});
    if ( $params->{all_transporters} ) {
		$model->addPhenotypeTransporters({phenotypes => $pheno,positiveonly => 0});
	} elsif ( $params->{positive_transporters} ) {
		$model->addPhenotypeTransporters({phenotypes => $pheno,positiveonly => 1});
	}
    $handler->util_log("Retrieving ".$params->{media_id}." media.");
    $params->{default_max_uptake} = 100;
    my $media = $handler->util_get_object("KBaseMedia/Complete");
    $handler->util_log("Preparing flux balance analysis problem.");
    my $fba;
    if ($params->{gapfill_phenotypes} == 0 && $params->{fit_phenotype_data} == 0) {
    	$fba = Bio::KBase::ObjectAPI::functions::util_build_fba($params,$model,$media,$params->{phenotypesim_output_id}.".fba",0,0,undef);
    } else {
    	$fba = Bio::KBase::ObjectAPI::functions::util_build_fba($params,$model,$media,$params->{phenotypesim_output_id}.".fba",1,1,undef,1);
    }
    $fba->{_phenosimid} = $params->{phenotypesim_output_id};
    $fba->phenotypeset_ref($pheno->_reference());
    $fba->phenotypeset($pheno);
    $handler->util_log("Running flux balance analysis problem.");
   	$fba->{"fit phenotype data"} = $params->{fit_phenotype_data};
    $fba->runFBA();
	if (!defined($fba->{_tempphenosim})) {
    	Bio::KBase::ObjectAPI::utilities::error("Simulation of phenotypes failed to return results from FBA! The model probably failed to grow on Complete media. Try running gapfiling first on Complete media.");
	}
	my $phenoset = $fba->phenotypesimulationset();
	if ($params->{gapfill_phenotypes} == 1 || $params->{fit_phenotype_data} == 1) {
		$handler->util_log("Phenotype gapfilling results:");
		$handler->util_log("Media\tKO\tSupplements\tGrowth\tSim growth\tGapfilling count\tGapfilled reactions");
		my $phenos = $phenoset->phenotypeSimulations();
		for (my $i=0; $i < @{$phenos}; $i++) {
			if ($phenos->[$i]->numGapfilledReactions() > 0) {
				$handler->util_log($phenos->[$i]->phenotype()->media()->_wsname()."\t".$phenos->[$i]->phenotype()->geneKOString()."\t".$phenos->[$i]->phenotype()->additionalCpdString()."\t".$phenos->[$i]->phenotype()->normalizedGrowth()."\t".$phenos->[$i]->simulatedGrowth()."\t".$phenos->[$i]->numGapfilledReactions()."\t".join(";",@{$phenos->[$i]->gapfilledReactions()})."");
			}
		}
		if ($params->{fit_phenotype_data} == 1) {
			$handler->util_log("Saving gapfilled model.");
			my $wsmeta = $handler->util_save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
    		$fba->fbamodel_ref($model->_reference());
		}
	}
    $handler->util_log("Saving FBA object with phenotype simulation results.");
    my $wsmeta = $handler->util_save_object($phenoset,$params->{workspace}."/".$params->{phenotypesim_output_id},{type => "KBasePhenotypes.PhenotypeSimulationSet"});
    $fba->phenotypesimulationset_ref($phenoset->_reference());
    $wsmeta = $handler->util_save_object($fba,$params->{workspace}."/".$params->{phenotypesim_output_id}.".fba",{hidden => 1,type => "KBaseFBA.FBA"});
    return {
		new_phenotypesim_ref => $params->{workspace}."/".$params->{phenotypesim_output_id}
	};
}

sub func_merge_metabolic_models_into_community_model {
	my ($params) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fbamodel_id_list","fbamodel_output_id"],{
    	fbamodel_workspace => $params->{workspace},
    	mixed_bag_model => 0
    });
    #Getting genome
	$handler->util_log("Retrieving first model.");
	my $model = $handler->util_get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id_list}->[0]);
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
	$commdl->parent($handler->util_store());
	for (my $i=0; $i < @{$params->{fbamodel_id_list}}; $i++) {
		$params->{fbamodel_id_list}->[$i] = $params->{fbamodel_workspace}."/".$params->{fbamodel_id_list}->[$i];
	}
	$handler->util_log("Merging models.");
	my $genomeObj = $commdl->merge_models({
		models => $params->{fbamodel_id_list},
		mixed_bag_model => $params->{mixed_bag_model},
		fbamodel_output_id => $params->{fbamodel_output_id}
	});
	$handler->util_log("Saving model and combined genome.");
	my $wsmeta = $handler->util_save_object($genomeObj,$params->{workspace}."/".$params->{fbamodel_output_id}.".genome",,{type => "KBaseGenomes.Genome"});
	$wsmeta = $handler->util_save_object($commdl,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
	return {
		new_fbamodel_ref => $params->{workspace}."/".$params->{fbamodel_output_id}
	};
}

sub func_compare_flux_with_expression {
	my ($params) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fba_id","expseries_id","expression_condition","fbapathwayanalysis_output_id"],{
    	fba_workspace => $params->{workspace},
    	expseries_workspace => $params->{workspace},
    	exp_threshold_percentile => 0.5,
    	estimate_threshold => 0,
    	maximize_agreement => 0
    });
	$handler->util_log("Retrieving FBA solution.");
	my $fb = $handler->util_get_object($params->{fba_workspace}."/".$params->{fba_id});
   	$handler->util_log("Retrieving expression matrix.");
   	my $em = $handler->util_get_object($params->{expseries_workspace}."/".$params->{expseries_id});
	$handler->util_log("Retrieving FBA model.");
	my $fm = $fb->fbamodel();
	$handler->util_log("Retriveing genome.");
	my $genome = $fm->genome();
	$handler->util_log("Computing threshold based on always active genes (but will not be used unless requested).");
	my $exphash = Bio::KBase::ObjectAPI::functions::util_build_expression_hash($em,$params->{expression_condition});
	my $output = $genome->compute_gene_activity_threshold_using_faria_method($exphash);
	if ($output->[2] < 30) {
		$handler->util_log("Too few always-on genes recognized with nonzero expression for the reliable estimation of threshold.");
		if ($params->{estimate_threshold} == 1) {
			Bio::KBase::ObjectAPI::utilities::error("Threshold estimation selected, but too few always-active genes recognized to permit estimation.\n");
		} else {
			$handler->util_log("This is not a problem because threshold estimation was not explicitly requested in analysis.");
		}
	}
	if ($params->{estimate_threshold} == 1) {
		$handler->util_log("Expression threshold percentile for calling active genes set to:".100*$output->[1]."");
		$params->{exp_threshold_percentile} = $output->[1];	
	}
	$handler->util_log("Computing the cutoff expression value to use to call genes active.");
	my $sortedgenes = [sort { $exphash->{$a} <=> $exphash->{$b} } keys(%{$exphash})];
	my $threshold_gene = @{$sortedgenes};
	$threshold_gene = floor($params->{exp_threshold_percentile}*$threshold_gene);
	$threshold_gene =  $sortedgenes->[$threshold_gene];
	my $threshold_value = $exphash->{$threshold_gene};
	$handler->util_log("Computing expression values for each reaction.");
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
	$handler->util_log("Computing the ideal cutoff to maximize agreement with predicted flux.");
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
	$handler->util_log("The threshold that maximizes model agreement is ".$idealcutoff." or ".100*$bestpercentile." percentile.");
	if ($params->{maximize_agreement} == 1) {
		$handler->util_log("Expression threshold percentile for calling active genes set to:".100*$bestpercentile."");
		$threshold_value = $idealcutoff;
		$params->{exp_threshold_percentile} = $bestpercentile;	
	}
	$handler->util_log("Retrieving biochemistry data.");
	my $bc = $handler->util_get_object("kbase/plantdefault_obs");
	$handler->util_log("Building expression FBA comparison object.");
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
	$handler->util_log("Saving FBAPathwayAnalysis object.");
    my $meta = $handler->util_save_object($all_analyses->[0],$params->{workspace}."/".$params->{fbapathwayanalysis_output_id},{hash => 1,type => "KBaseFBA.FBAPathwayAnalysis"});
    my $outputobj = {
		new_fbapathwayanalysis_ref => $params->{workspace}."/".$params->{fbapathwayanalysis_output_id}
	};
    if (@{$all_analyses} > 1) {
    	for (my $m=1; $m < @{$all_analyses}; $m++) {
	    	$meta = $handler->util_save_object($all_analyses->[$m],$params->{workspace}."/".$params->{fbapathwayanalysis_output_id}.".".$m,{hash => 1,type => "KBaseFBA.FBAPathwayAnalysis"});
		    push(@{$outputobj->{additional_fbapathwayanalysis_ref}},$params->{workspace}."/".$params->{fbapathwayanalysis_output_id}.".".$m);
    	}
    }
	return $outputobj;
}

sub func_check_model_mass_balance {
	my ($params) = @_;
	$params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fbamodel_id"],{
		fbamodel_workspace => $params->{workspace},
    });
    $handler->util_log("Retrieving model.");
	my $model = $handler->util_get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    my $media = $handler->util_get_object("KBaseMedia/Complete");
    my $fba = Bio::KBase::ObjectAPI::functions::util_build_fba($params,$model,$media,"tempfba",0,0,undef);
    $fba->parameters()->{"Mass balance atoms"} = "C;S;P;O;N";
    $handler->util_log("Checking model mass balance.");
   	my $objective = $fba->runFBA();
   	my $htmlreport = "<p>No mass imbalance found</p>";
	my $message = "No mass imbalance found";
    if (length($fba->MFALog) > 0) {
    	$message = $fba->MFALog();
    	$htmlreport = "<table><row><td>Reaction</td><td>Reactants</td><td>Products</td><td>Extra atoms in reactants</td><td>Extra atoms in products</td></row>";
    	my $array = [split(/\n/,$message)];
    	my ($id,$reactants,$products,$rimbal,$pimbal);
    	for (my $i=0; $i < @{$array}; $i++) {
    		if ($array->[$i] =~ m/Reaction\s(.+)\simbalanced/) {
    			if (defined($id)) {
    				$htmlreport .= "<row><td>".$id."</td><td>".$reactants."<td>".$products."</td><td>".$rimbal."</td><td>".$pimbal."</td></row>";	
    			}
    			$reactants = "";
				$products = "";
				$rimbal = "";
				$pimbal = "";
    			$id = $1;
    		} elsif ($array->[$i] =~ m/Extra\s(.+)\s(.+)\sin\sproducts/) {
    			if (length($reactants) > 0) {
    				$rimbal .= "<br>";
    			}
    			$rimbal = $1." ".$2;
    		} elsif ($array->[$i] =~ m/Extra\s(.+)\s(.+)\sin\sreactants/) {
    			if (length($reactants) > 0) {
    				$pimbal .= "<br>";
    			}
    			$pimbal = $1." ".$2;
    		} elsif ($array->[$i] =~ m/Reactants:/) {
    			$i++;
    			while ($array->[$i] ne "Products:") {
    				if (length($reactants) > 0) {
    					$reactants .= "<br>";
    				}
    				$reactants = $array->[$i];
    				$i++;
    			}
    			$i++;
    			while (length($array->[$i]) > 0) {
    				if (length($products) > 0) {
    					$products .= "<br>";
    				}
    				$products = $array->[$i];
    				$i++;
    			}
    		}
    	}
    	if (defined($id)) {
			$htmlreport .= "<row><td>".$id."</td><td>".$reactants."<td>".$products."</td><td>".$rimbal."</td><td>".$pimbal."</td></row>";
		}
    	$htmlreport .= "</table>";
    }
   	return {
		direct_html => $htmlreport,
		message => $message
	};
}

sub func_create_or_edit_media {
	my ($params) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","media_id","data"],{
    	media_workspace => $params->{workspace},
    	media_output_id => $params->{media_id}
    });
	#Getting genome
	my $media = $handler->util_get_object($params->{media_workspace}."/".$params->{media_id});
	my $newmedia = Bio::KBase::ObjectAPI::Biochem::Media->new($params->{data});
	my $wsmeta = $handler->util_save_object($newmedia,$params->{workspace}."/".$params->{media_output_id},{type => "KBaseBiochem.Meda"});
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
	$handler->util_log($message);
	$handler->util_report({
    	'ref' => $params->{workspace}."/".$params->{media_output_id}.".create_or_edit_media.report",
    	message => $message,
    	objects => [$wsmeta->[6]."/".$wsmeta->[0]."/".$wsmeta->[4],"Edited media"]
    });
   	return {
		new_media_ref => $params->{workspace}."/".$params->{media_output_id},
		report_name => $params->{media_output_id}.".create_or_edit_media.report",
		ws_report_id => $params->{workspace}.'/'.$params->{media_output_id}.".create_or_edit_media.report"
	};
}

sub func_edit_metabolic_model {
	my ($params) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","fbamodel_id","data"],{
    	fbamodel_workspace => $params->{workspace},
    	fbamodel_output_id => $params->{fbamodel_id}
    });
	#Getting genome
	$handler->util_log("Loading model from workspace");
	my $model = $handler->util_get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
	(my $editresults,my $detaileditresults) = $model->edit_metabolic_model($params->{data});
	#Creating message to report all modifications made
	$handler->util_log("Saving edited model to workspace");
	my $wsmeta = $handler->util_save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
	my $message = "Name of edited model: ".$params->{fbamodel_output_id}."\n";
	$message .= "Starting from: ".$params->{fbamodel_id}."\n";	
	$message .= "Added:".join("\n",@{$editresults->{reactions_added}})."\n";
	$message .= "Removed:".join("\n",@{$editresults->{reactions_removed}})."\n";
	$message .= "Changed:".join("\n",@{$editresults->{reactions_modified}})."\n";
	$message .= "Added biomass:";
	for (my $i=0; $i < @{$editresults->{biomass_added}}; $i++) {
		$message .= $editresults->{biomass_added}->[$i]->[0].":".$editresults->{biomass_added}->[$i]->[1].";";
	}
	$message .= "\nRemoved biomass:";
	for (my $i=0; $i < @{$editresults->{biomass_removed}}; $i++) {
		$message .= $editresults->{biomass_removed}->[$i]->[0].":".$editresults->{biomass_removed}->[$i]->[1].";";
	}
	$message .= "\nChanged biomass:";
	for (my $i=0; $i < @{$editresults->{biomass_changed}}; $i++) {
		$message .= $editresults->{biomass_changed}->[$i]->[0].":".$editresults->{biomass_changed}->[$i]->[1].";";
	}
	$message .= "\n";
	$handler->util_log($message);
	my $reportObj = {
		'objects_created' => [],
		'text_message' => $message
	};
    my $metadata = $handler->util_report({
    	'ref' => $params->{workspace}.'/'.$params->{fbamodel_output_id}.".edit_metabolic_model.report",
    	message => $message,
    	objects => [[$params->{workspace}."/".$params->{fbamodel_output_id},"Edited model"]]
    });
   	return {
		new_fbamodel_ref => $params->{workspace}."/".$params->{fbamodel_output_id},
		report_name => $params->{fbamodel_output_id}.".edit_metabolic_model.report",
		ws_report_id => $params->{workspace}.'/'.$params->{fbamodel_output_id}.".edit_metabolic_model.report",
		detailed_edit_results => $detaileditresults
   	};
}

sub func_quantitative_optimization {
	my ($params,$model) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["fbamodel_id","constraints","workspace"],{
    	fbamodel_workspace => $params->{workspace},
    	fbamodel_output_id => $params->{fbamodel_id},
    	MaxBoundMult => 2,
		MinFluxCoef => 0.000001,
		ReactionCoef => 100,
		DrainCoef => 10,
		BiomassCoef => 0.1,
		ATPSynthCoef => 1,
		ATPMaintCoef => 1,
		MinVariables => 3,
		Resolution => 0.01,
		media_id => undef,
		media_workspace => $params->{workspace},
		target_reaction => "bio1",
		feature_ko_list => [],
		reaction_ko_list => [],
		custom_bound_list => [],
		media_supplement_list => [],
		objective_fraction => 0.1,
		default_max_uptake => 0
    });
	$handler->util_log("Loading model from workspace");
	if (!defined($model)) {
    	$handler->util_log("Retrieving model.");
		$model = $handler->util_get_object($params->{fbamodel_workspace}."/".$params->{fbamodel_id});
    }
	if (!defined($params->{media_id})) {
    	$params->{default_max_uptake} = 100;
    	$params->{media_id} = "Complete";
    	$params->{media_workspace} = "KBaseMedia";
    }
	$handler->util_log("Retrieving ".$params->{media_id}." media.");
	my $media = $handler->util_get_object($params->{media_workspace}."/".$params->{media_id});
	$handler->util_log("Preparing flux balance analysis problem.");
    my $fba = Bio::KBase::ObjectAPI::functions::util_build_fba($params,$model,$media,$params->{fba_output_id},0,0,undef); 
    $fba->RunQuantitativeOptimization({
		ReactionCoef => $params->{ReactionCoef},
		DrainCoef => $params->{DrainCoef},
		BiomassCoef => $params->{BiomassCoef},
		ATPSynthCoef => $params->{ATPSynthCoef},
		ATPMaintCoef => $params->{ATPMaintCoef},
		TimePerSolution => $params->{timePerSolution},
		TotalTimeLimit => $params->{totalTimeLimit},
		Num_solutions => $params->{num_solutions},
		MaxBoundMult => $params->{MaxBoundMult},
		MinFluxCoef => $params->{MinFluxCoef},
		Constraints => $params->{constraints},
		Resolution => $params->{Resolution},
		MinVariables => $params->{MinVariables}
	});
    $handler->util_log("Saving FBA results.");
    my $wsmeta = $handler->util_save_object($fba,$params->{workspace}."/".$params->{fbamodel_output_id}.".fba",{type => "KBaseFBA.FBA"});
    $model->AddQuantitativeOptimization($fba,1);
    $handler->util_save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
	return {
		new_fbamodel_ref => $params->{workspace}."/".$params->{fbamodel_output_id}
	};
}

sub func_compare_models {
	my ($params,$model) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["workspace","model_refs"],{
    	protcomp_ref => undef,
    	pangenome_ref => undef,
    	mc_name => "ModelComparison"
    });
	if (@{$params->{model_refs}} < 2) {
		Bio::KBase::ObjectAPI::utilities::error("Must select at least two models to compare");
    }
	if (!defined($params->{protcomp_ref}) || !defined($params->{pangenome_ref})) {
    	Bio::KBase::ObjectAPI::utilities::error("Must provide either a pangenome or proteome comparison");
    }
    my $wsClient = Bio::KBase::ObjectAPI::utilities::util_kbase_store->workspace();

    my $provenance = [{}];
    my @models;
    foreach my $model_ref (@{$params->{model_refs}}) {
		my $model=undef;
		eval {
		    $model=$handler->util_get_object($model_ref,{raw => 1});
		    $model->{model_ref} = $model_ref;
		    push @models, $model;
		    push @{$provenance->[0]->{'input_ws_objects'}}, $model_ref;
		};
		if ($@) {
		    die "Error loading model from workspace:\n".$@;
		}
    }

    my $protcomp;
    if (defined $params->{protcomp_ref}) {
		eval {
		    $protcomp=$handler->util_get_object($params->{protcomp_ref},{raw => 1});
		    push @{$provenance->[0]->{'input_ws_objects'}}, $params->{protcomp_ref};
		};
		if ($@) {
		    die "Error loading protein comparison from workspace:\n".$@;
		}
    }

    my $pangenome;
    if (defined $params->{pangenome_ref}) {
		eval {
		    $pangenome=$handler->util_get_object($params->{pangenome_ref},{raw => 1});
		    push @{$provenance->[0]->{'input_ws_objects'}}, $params->{pangenome_ref};
		};
		if ($@) {
		    die "Error loading pangenome from workspace:\n".$@;
		}
    }

    $handler->util_log("All data loaded from workspace");

    # PREPARE MODEL INFO
    my %mcpd_refs; # hash from modelcompound_refs to their data
    my %ftr2model; # hash from gene feature ids to the models they are in
    my %ftr2reactions;

    foreach my $model (@models) {
	$handler->util_log("Processing model ", $model->{id}, "");
	foreach my $cmp (@{$model->{modelcompartments}}) {
	    $model->{cmphash}->{$cmp->{id}} = $cmp;
	}
	foreach my $cpd (@{$model->{modelcompounds}}) {
	    $cpd->{cmpkbid} = pop @{[split "/", $cpd->{modelcompartment_ref}]};
	    $cpd->{cpdkbid} = pop @{[split "/", $cpd->{compound_ref}]};
	    if (! defined $cpd->{name}) {
		$cpd->{name} = $cpd->{id};
	    }
	    $cpd->{name} =~ s/_[a-zA-z]\d+$//g;
	    
	    $model->{cpdhash}->{$cpd->{id}} = $cpd;
	    if ($cpd->{cpdkbid} ne "cpd00000") {
		$model->{cpdhash}->{$cpd->{$cpd->{cpdkbid}."_".$cpd->{cmpkbid}}} = $cpd;
	    }
	}
	foreach my $rxn (@{$model->{modelreactions}}) {
	    $rxn->{rxnkbid} = pop @{[split "/", $rxn->{reaction_ref}]};
	    $rxn->{cmpkbid} = pop @{[split "/", $rxn->{modelcompartment_ref}]};
	    $rxn->{dispid} = $rxn->{id};
	    $rxn->{dispid} =~ s/_[a-zA-z]\d+$//g;
	    $rxn->{dispid} .= "[".$rxn->{cmpkbid}."]";
	    if ($rxn->{name} eq "CustomReaction") {
		$rxn->{name} = $rxn->{id};
	    }
	    $rxn->{name} =~ s/_[a-zA-z]\d+$//g;
	    $model->{rxnhash}->{$rxn->{id}} = $rxn;
	    if ($rxn->{rxnkbid} ne "rxn00000") {
		$model->{rxnhash}->{$rxn->{rxnkbid}."_".$rxn->{cmpkbid}} = $rxn;
		if ($rxn->{rxnkbid}."_".$rxn->{cmpkbid} ne $rxn->{id}) {
		    $rxn->{dispid} .= "<br>(".$rxn->{rxnkbid}.")";
		}
	    }
	    my $reactants = "";
	    my $products = "";
	    my $sign = "<=>";
	    if ($rxn->{direction} eq ">") {
		$sign = "=>";
	    } elsif ($rxn->{direction} eq "<") {
		$sign = "<=";
	    }
	    foreach my $rgt (@{$rxn->{modelReactionReagents}}) {
		$rgt->{cpdkbid} = pop @{[split "/", $rgt->{modelcompound_ref}]};
		$mcpd_refs{$rgt->{modelcompound_ref}} = $model->{cpdhash}->{$rgt->{cpdkbid}}; # keep track of model compound refs
		if ($rgt->{coefficient} < 0) {
		    if ($reactants ne "") {
			$reactants .= " + ";
		    }
		    if ($rgt->{coefficient} != -1) {
			my $abscoef = int(-1*100*$rgt->{coefficient})/100;
			$reactants .= "(".$abscoef.") ";
		    }
		    $reactants .= $model->{cpdhash}->{$rgt->{cpdkbid}}->{name}."[".$model->{cpdhash}->{$rgt->{cpdkbid}}->{cmpkbid}."]";
		} else {
		    if ($products ne "") {
			$products .= " + ";
		    }
		    if ($rgt->{coefficient} != 1) {
			my $abscoef = int(100*$rgt->{coefficient})/100;
			$products .= "(".$abscoef.") ";
		    }
		    $products .= $model->{cpdhash}->{$rgt->{cpdkbid}}->{name}."[".$model->{cpdhash}->{$rgt->{cpdkbid}}->{cmpkbid}."]";
		}
	    }
	    $rxn->{ftrhash} = {};
	    foreach my $prot (@{$rxn->{modelReactionProteins}}) {
		foreach my $subunit (@{$prot->{modelReactionProteinSubunits}}) {
		    foreach my $feature (@{$subunit->{feature_refs}}) {
			my $ef = pop @{[split "/", $feature]};
			$rxn->{ftrhash}->{$ef} = 1;
			$ftr2model{$ef}->{$model->{id}} = 1;
			$ftr2reactions{$ef}->{$rxn->{id}} = 1;
		    }
		}
	    }
	    $rxn->{dispfeatures} = "";
	    foreach my $gene (keys %{$rxn->{ftrhash}}) {
		if ($rxn->{dispfeatures} ne "") {
		    $rxn->{dispfeatures} .= "<br>";
		}
		$rxn->{dispfeatures} .= $gene;
	    }
	    $rxn->{equation} = $reactants." ".$sign." ".$products;
	}
    }
    
    # PREPARE FEATURE COMPARISONS
    my $gene_translation;
    my %model2family;
    my %ftr2family;
    my $mc_families = {};
    my $core_families = 0;

    if (defined $protcomp) {
	my $i = 0;
	foreach my $ftr (@{$protcomp->{proteome1names}}) {
	    foreach my $hit (@{$protcomp->{data1}->[$i]}) {
		$gene_translation->{$ftr}->{$protcomp->{proteome2names}->[$hit->[0]]} = 1;
	    }
	    $i++;
	}
        $i = 0;
	foreach my $ftr (@{$protcomp->{proteome2names}}) {
	    foreach my $hit (@{$protcomp->{data2}->[$i]}) {
		$gene_translation->{$ftr}->{$protcomp->{proteome1names}->[$hit->[0]]} = 1;
	    }
	    $i++;
	}
    }
    if (defined $pangenome) {
	foreach my $family (@{$pangenome->{orthologs}}) {
	    my $in_models = {};
	    my $family_model_data = {};
	    foreach my $ortholog (@{$family->{orthologs}}) {
		$ftr2family{$ortholog->[0]} = $family;
		map { $gene_translation->{$ortholog->[0]}->{$_->[0]} = 1 } @{$family->{orthologs}};
		foreach my $model (@models) {
		    if (exists $ftr2model{$ortholog->[0]}->{$model->{id}}) {
			map { $in_models->{$model->{id}}->{$_} = 1 } keys $ftr2reactions{$ortholog->[0]};
			push @{$model2family{$model->{id}}->{$family->{id}}}, $ortholog->[0];
		    }
		}
	    }
	    my $num_models = scalar keys %$in_models;
	    if ($num_models > 0) {
		foreach my $model (@models) {
		    if (exists $in_models->{$model->{id}}) {
			my @reactions = sort keys %{$in_models->{$model->{id}}};
			$family_model_data->{$model->{id}} =  [1, \@reactions];
		    }
		    else {
			$family_model_data->{$model->{id}} = [0, []];
		    }
		}
		my $mc_family = {
		    id => $family->{id},
		    family_id => $family->{id},
		    function => $family->{function},
		    number_models => $num_models,
		    fraction_models => $num_models*1.0/@models,
		    core => ($num_models == @models ? 1 : 0),
		    family_model_data => $family_model_data
		};
		$mc_families->{$family->{id}} = $mc_family;
		$core_families++ if ($num_models == @models);
	    }
	}
    }

    # ACCUMULATE REACTIONS AND FAMILIES
    my %rxn2families;

    foreach my $model (@models) {
	foreach my $rxnid (keys %{$model->{rxnhash}}) {
	    foreach my $ftr (keys %{$model->{$rxnid}->{ftrhash}}) {
		$rxn2families{$rxnid}->{$ftr2family{$ftr}->{id}} = $ftr2family{$ftr};
	    }
	}
    }

    # READY TO COMPARE

    my $mc_models;
    my $mc_reactions;
    my $mc_compounds;
    my $mc_bcpds;

    foreach my $model1 (@models) {
	my $mc_model = {};
	push @{$mc_models}, $mc_model;
	$mc_model->{id} = $model1->{id};
	$mc_model->{model_ref} = $model1->{model_ref};
	$mc_model->{genome_ref} = $model1->{genome_ref};
	$mc_model->{families} = exists $model2family{$model1->{id}} ? scalar keys %{$model2family{$model1->{id}}} : 0;

	eval {
		my $genome=$handler->util_get_object($model1->{genome_ref},{raw => 1});
	    $mc_model->{name} = $genome->{scientific_name};
	    $mc_model->{taxonomy} = $genome->{taxonomy};
	};
	if ($@) {
	    warn "Error loading genome from workspace:\n".$@;
	}

	$mc_model->{reactions} = scalar @{$model1->{modelreactions}};
	$mc_model->{compounds} = scalar @{$model1->{modelcompounds}};
	$mc_model->{biomasses} = scalar @{$model1->{biomasses}};

	foreach my $model2 (@models) {
	    next if $model1->{id} eq $model2->{id};		    
	    $mc_model->{model_similarity}->{$model2->{id}} = [0,0,0,0,0];
	}

	foreach my $rxn (@{$model1->{modelreactions}}) {
	    my $ftrs = [];
	    if (defined $pangenome) {
		foreach my $ftr (keys %{$rxn->{ftrhash}}) {
		    my $family = $ftr2family{$ftr};
		    next if ! defined $family;
		    my $conservation = 0;
		    foreach my $m (keys %model2family) {
			$conservation++ if exists $model2family{$m}->{$family->{id}};
		    }
		    push @$ftrs, [$ftr, $family->{id}, $conservation*1.0/@models, 0];
		}
		# maybe families associated with reaction aren't in model
		foreach my $familyid (keys %{$rxn2families{$rxn->{id}}}) {
		    if (! exists $model2family{$model1->{id}}->{$familyid}) {
			my $conservation = 0;
			foreach my $m (keys %model2family) {
			    $conservation++ if exists $model2family{$m}->{$familyid};
			}
			push @$ftrs, ["", $familyid, $conservation*1.0/@models, 1];
		    }
		}
	    }
	    my $mc_reaction = $mc_reactions->{$rxn->{id}};
	    if (! defined $mc_reaction) {
		$mc_reaction = {
		    id => $rxn->{id},
		    reaction_ref => $rxn->{reaction_ref},
		    name => $rxn->{name},
		    equation => $rxn->{equation},
		    number_models => 1,
		    core => 0
		};
		$mc_reactions->{$mc_reaction->{id}} = $mc_reaction;
	    } else {
		$mc_reaction->{number_models}++;
	    }
	    $mc_reaction->{reaction_model_data}->{$model1->{id}} = [1,$rxn->{direction},$ftrs,$rxn->{dispfeatures}];
	    foreach my $model2 (@models) {
		next if $model1->{id} eq $model2->{id};

		my $model2_ftrs;
		if ($rxn->{rxnkbid} =~ "rxn00000" && defined $model2->{rxnhash}->{$rxn->{id}}) {
		    $mc_model->{model_similarity}->{$model2->{id}}->[0]++;
		    $model2_ftrs = $model2->{rxnhash}->{$rxn->{id}}->{ftrhash};
		}
		elsif (defined $model2->{rxnhash}->{$rxn->{rxnkbid}."_".$rxn->{cmpkbid}}) {
		    $mc_model->{model_similarity}->{$model2->{id}}->[0]++;
		    $model2_ftrs = $model2->{rxnhash}->{$rxn->{rxnkbid}."_".$rxn->{cmpkbid}}->{ftrhash};
		}

		my $gpr_matched = 0;
		if (scalar keys %{$rxn->{ftrhash}} > 0) {
		    $gpr_matched = 1;
		    foreach my $ftr (keys %{$rxn->{ftrhash}}) {
			my $found_a_match = 0;
			foreach my $gene (keys %{$gene_translation->{$ftr}}) {
			    if (exists $ftr2model{$gene}->{$model2->{id}}) {
				$found_a_match = 1;
				last;
			    }
			}
			$gpr_matched = 0 if ($found_a_match == 0);
		    }
		    if ($gpr_matched == 1) {
			foreach my $ftr (keys %{$model2_ftrs}) {
			    my $found_a_match = 0;
			    foreach my $gene (keys %{$gene_translation->{$ftr}}) {
				if (exists $ftr2model{$gene}->{$model1->{id}}) {
				    $found_a_match = 1;
				    last;
				}
			    }
			    $gpr_matched = 0 if ($found_a_match == 0);
			}
		    }
		}
		if ($gpr_matched == 1) {
		    $mc_model->{model_similarity}->{$model2->{id}}->[4]++;
		}
	    }
	}
	# fill in info for reactions not in model
	foreach my $rxnid (keys %rxn2families) {
	    if (! exists $model1->{rxnhash}->{$rxnid}) {
		my $ftrs = [];
		if (defined $pangenome) {
		    foreach my $familyid (keys %{$rxn2families{$rxnid}}) {
			my $conservation = 0;
			foreach my $m (keys %model2family) {
			    $conservation++ if exists $model2family{$m}->{$familyid};
			}
			if (exists $model2family{$model1->{id}}->{$familyid}) {
			    foreach my $ftr (@{$model2family{$model1->{id}}->{$familyid}}) {
				push @$ftrs, [$ftr, $familyid, $conservation*1.0/@models, 0];
			    }
			}
			else {
			    push @$ftrs, ["", $familyid, $conservation*1.0/@models, 1];
			}
		    }
		}
		$mc_reactions->{$rxnid}->{reaction_model_data}->{$model1->{id}} = [1,"",$ftrs,""];
	    }
	}
	# process compounds
	my %cpds_registered; # keep track of which compounds are accounted for since they might appear in multiple compartments
	foreach my $cpd (@{$model1->{modelcompounds}}) {
	    my $match_id = $cpd->{cpdkbid};
	    if ($match_id =~ "cpd00000") {
		$match_id = $cpd->{id};
		$match_id =~ s/_[a-zA-z]\d+$//g;
	    }
	    my $mc_compound = $mc_compounds->{$match_id};
	    if (! defined $mc_compound) {
		$mc_compound = {
		    id => $match_id,
		    compound_ref => $cpd->{compound_ref},
		    name => $cpd->{name},
		    number_models => 0,
		    core => 0,
		    model_compound_compartments => { $model1->{id} => [[$cpd->{modelcompartment_ref},$cpd->{charge}]] }
		};
		$mc_compounds->{$mc_compound->{id}} = $mc_compound;
	    } else {
		push @{$mc_compound->{model_compound_compartments}->{$model1->{id}}}, [$cpd->{modelcompartment_ref},$cpd->{charge}];
	    }
	    if (! exists $cpds_registered{$match_id}) {
		$mc_compound->{number_models}++;
		$cpds_registered{$match_id} = 1;
	    }
	    foreach my $model2 (@models) {
		next if $model1->{id} eq $model2->{id};

		if (($cpd->{cpdkbid} =~ "cpd00000" && defined $model2->{cpdhash}->{$cpd->{id}}) ||
		    (defined $model2->{cpdhash}->{$cpd->{cpdkbid}."_".$cpd->{cmpkbid}})) {
		    $mc_model->{model_similarity}->{$model2->{id}}->[1]++;
		}
	    }
	}
	my %model1bcpds;
	foreach my $biomass (@{$model1->{biomasses}}) {
	    foreach my $bcpd (@{$biomass->{biomasscompounds}}) {
		my $cpdkbid = pop @{[split "/", $bcpd->{modelcompound_ref}]};
		my $cpd = $model1->{cpdhash}->{$cpdkbid};
		my $match_id = $cpd->{cpdkbid};
		if (! defined $match_id || $match_id =~ "cpd00000") {
		    $match_id = $cpd->{id};
		    $match_id =~ s/_[a-zA-z]\d+$//g;
		}
		if (! defined $match_id) {
		    Bio::KBase::ObjectAPI::utilities::error("no match possible for biomass compound:");
		    Bio::KBase::ObjectAPI::utilities::error(Dumper($bcpd));
		    next;
		}
		$model1bcpds{$match_id} = 0;
		my $mc_bcpd = $mc_bcpds->{$match_id};
		my $cref = defined $cpd->{modelcompartment_ref} ? $cpd->{modelcompartment_ref} : "";
		if (! defined $mc_bcpd) {
		    $mc_bcpd = {
			id => $match_id,
			compound_ref => defined $cpd->{compound_ref} ? $cpd->{compound_ref} : "",
			name => $cpd->{name},
			number_models => 1,
			core => 0,
			model_biomass_compounds => { $model1->{id} => [[$cref,$bcpd->{coefficient}]] }
		    };
		    $mc_bcpds->{$mc_bcpd->{id}} = $mc_bcpd;
		} else {
		    $mc_bcpd->{number_models}++;
		    push @{$mc_bcpd->{model_biomass_compounds}->{$model1->{id}}}, [$cref,$bcpd->{coefficient}];
		}
		foreach my $model2 (@models) {
		    next if $model1->{id} eq $model2->{id};

		    if (($cpd->{cpdkbid} =~ "cpd00000" && defined $model2->{cpdhash}->{$cpd->{id}}) ||
			(defined $model2->{cpdhash}->{$cpd->{cpdkbid}."_".$cpd->{cmpkbid}})) {
			$mc_model->{model_similarity}->{$model2->{id}}->[2]++;
		    }
		}
	    }
	}
	$mc_model->{biomasscpds} = scalar keys %model1bcpds;

	foreach my $family (keys %{$model2family{$model1->{id}}}) {
	    foreach my $model2 (@models) {
		next if $model1->{id} eq $model2->{id};

		if (exists $model2family{$model2->{id}}->{$family}) {
		    $mc_model->{model_similarity}->{$model2->{id}}->[3]++;
		}
	    }
	}
    }

    # need to set 'core' and 'fraction_models'
    my $core_reactions = 0;
    foreach my $mc_reaction (values %$mc_reactions) {
	if ($mc_reaction->{number_models} == @models) {
	    $core_reactions++;
	    $mc_reaction->{core} = 1;
	}
	$mc_reaction->{fraction_models} = 1.0*$mc_reaction->{number_models}/@models;
    }

    my $core_compounds = 0;
    foreach my $mc_compound (values %$mc_compounds) {
	if ($mc_compound->{number_models} == @models) {
	    $core_compounds++;
	    $mc_compound->{core} = 1;
	}
	$mc_compound->{fraction_models} = 1.0*$mc_compound->{number_models}/@models;
    }

    my $core_bcpds = 0;
    foreach my $mc_bcpd (values %$mc_bcpds) {
	if ($mc_bcpd->{number_models} == @models) {
	    $core_bcpds++;
	    $mc_bcpd->{core} = 1;
	}
	$mc_bcpd->{fraction_models} = 1.0*$mc_bcpd->{number_models}/@models;
    }

    my $mc = {};
    $mc->{id} = $params->{mc_name};
    $mc->{name} = $params->{mc_name};
    $mc->{models} = $mc_models;
    $mc->{reactions} = [values %$mc_reactions];
    $mc->{core_reactions} = $core_reactions;
    $mc->{compounds} = [values %$mc_compounds];
    $mc->{core_compounds} = $core_compounds;
    $mc->{biomasscpds} = [values %$mc_bcpds];
    $mc->{core_biomass_compounds} = $core_bcpds;
    $mc->{core_families} = $core_families;
    $mc->{families} = [values %$mc_families];
    $mc->{protcomp_ref} = $params->{protcomp_ref} if (defined $params->{protcomp_ref});
    $mc->{pangenome_ref} = $params->{pangenome_ref} if (defined $params->{pangenome_ref});
    
    my $mc_metadata = $handler->util_save_object($mc,$params->{workspace}."/".$params->{mc_name},{hash => 1,type => "KBaseFBA.ModelComparison"});   
    my $metadata = $handler->util_report({
    	'ref' => $params->{workspace}."/model_comparison_report_".$params->{mc_name},
    	message => "ModelComparison saved to ".$params->{workspace}."/".$params->{mc_name}."\n",
    	objects => [[$params->{workspace}."/".$params->{mc_name},"Model Comparison"]]
    });
    return { 
    	'report_name'=>'model_comparison_report_'.$params->{mc_name},
    	'report_ref' => $metadata->[6]."/".$metadata->[0]."/".$metadata->[4], 
    	'mc_ref' => $params->{workspace}."/".$params->{mc_name}
    };
}

sub func_importmodel {
	my ($params) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::ARGS($params,["biomass","model_name","workspace_name"],{
    	sbml => undef,
    	model_file => undef,
    	genome => undef,
    	genome_workspace => $params->{workspace_name},
    	compounds_file => undef,
    	source => "External",
    	type => "SingleOrganism",
    	template => undef,
    	template_workspace => $params->{workspace_name},
    	compounds => [],
    	reactions => []
    });
    #RETRIEVING THE GENOME FOR THE MODEL
    if (!defined($params->{genome})) {
    	$params->{genome} = "Empty";
    	$params->{genome_workspace} = "PlantSEED";
    }
    my $genomeobj = $handler->util_get_object($params->{genome_workspace}."/".$params->{genome},{});
    #RETRIEVING THE TEMPLATE FOR THE MODEL
    if ($params->{template_id} eq "auto") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
    	$handler->util_log("Classifying genome in order to select template.");
    	if ($genomeobj->template_classification() eq "plant") {
    		$params->{template_id} = "PlantModelTemplate";
    	} elsif ($genomeobj->template_classification() eq "Gram negative") {
    		$params->{template_id} = "GramNegModelTemplate";
    	} elsif ($genomeobj->template_classification() eq "Gram positive") {
    		$params->{template_id} = "GramPosModelTemplate";
    	}
	} elsif ($params->{template_id} eq "grampos") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "GramPosModelTemplate";
	} elsif ($params->{template_id} eq "gramneg") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "GramNegModelTemplate";
	} elsif ($params->{template_id} eq "plant") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "PlantModelTemplate";
	} elsif ($params->{template_id} eq "core") {
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "CoreModelTemplate";
	}
	my $templateobj = $handler->util_get_object($params->{template_workspace}."/".$params->{template_id},{});
    #HANDLING SBML FILENAMES IF PROVIDED
    if (defined($params->{model_file})) {
    	$params->{model_file} = $handler->util_get_file_path($params->{model_file});
    	if (!-e $params->{model_file}) {
	    	Bio::KBase::ObjectAPI::utilities::error("SBML file ".$params->{model_file}." doesn't exist!");
	    }
	    $params->{sbml} = "";
	    open(my $fh, "<", $params->{model_file}) || return;
		while (my $line = <$fh>) {
			$params->{sbml} .= $line;
		}
		close($fh);
    }
    #HANDLING COMPOUND FILENAMES IF PROVIDED
    if (defined($params->{compounds_file})) {
   		$params->{compounds_file} = $handler->util_get_file_path($params->{compounds_file});
    	if (!-e $params->{compounds_file}) {
	    	Bio::KBase::ObjectAPI::utilities::error("Compound file ".$params->{compounds_file}." doesn't exist!");
	    }
	    $params->{compound_data} = Bio::KBase::ObjectAPI::utilities::parse_input_table($params->{compounds_file},[
			["id",1],
			["charge",0,undef],
			["formula",0,undef],
			["name",1],
			["aliases",0,undef]
		]);
    }
    #PARSING SBML IF PROVIDED
    if (defined($params->{sbml})) {
    	$params->{compounds} = [];
		$params->{reactions} = [];
	    require "XML/DOM.pm";
		my $parser = new XML::DOM::Parser;
		my $doc = $parser->parse($params->{sbml});
		#Parsing compartments
	    my $cmpts = [$doc->getElementsByTagName("compartment")];
	    my $cmptrans;
	    my $compdata = {};
	    my $custom_comp_index = 0;
	    my $custom_comp_letters = [qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)];
	    my $nonexactcmptrans = {
	    	xtra => "e",
	    	wall => "w",
	    	peri => "p",
	    	cyto => "c",
	    	retic => "r",
	    	lys => "l",
	    	nucl => "n",
	    	chlor => "d",
	    	mito => "m",
	    	perox => "x",
	    	vacu => "v",
	    	plast => "d",
			golg => "g"
	    };
	    foreach my $cmpt (@$cmpts){
	    	my $cmp_SEED_id;
	    	my $cmpid;
	    	my $cmproot;
	    	my $cmpind = 0;
	    	my $cmpname;
	    	foreach my $attr ($cmpt->getAttributes()->getValues()) {
	    		my $name = $attr->getName();
	    		my $value = $attr->getValue();
	    		if ($name eq "id") {
	    			$cmpid = $value;
	    		} elsif ($name eq "name") {
	    			$cmpname = $value;
	    		}
	    	}
	    	if (!defined($cmpname)) {
	    		$cmpname = $cmpid;
	    	}
	    	$cmproot = $cmpid;
	    	if ($cmpid =~ m/^([a-zA-Z]+)(\d+)$/) {
	    		$cmproot = $1;
	    		$cmpind = $2;
	    	}
	    	my $cmp = $templateobj->searchForCompartment($cmproot);
	    	if (defined($cmp)) {
	    		$cmp_SEED_id = $cmp->id();
	    	} else {
	    		foreach my $term (keys(%{$nonexactcmptrans})) {
	    			if ($cmproot =~ m/$term/i) {
	    				$cmp_SEED_id = $nonexactcmptrans->{$term};
	    			} elsif ($cmpname =~ m/$term/i) {
	    				$cmp_SEED_id = $nonexactcmptrans->{$term};
	    			}
	    		} 
	    	}
	    	if (!defined($cmp_SEED_id)) {
				$cmp_SEED_id = $custom_comp_letters->[$custom_comp_index];
				$custom_comp_index++;
	    	}
	    	$compdata->{$cmpid} = {
	    		id => $cmpid,
	    		root => $cmproot,
	    		ind => $cmpind,
	    		seed => $cmp_SEED_id,
	    		name => $cmpname
	    	};
	    }
		#Parsing compounds
	    my $cpds = [$doc->getElementsByTagName("species")];
	    my $cpdhash = {};
	    my $cpdidhash = {};
	    foreach my $cpd (@$cpds){
	    	my $formula = "Unknown";
	    	my $charge = "0";
	    	my $sbmlid;
	    	my $compartment = "c";
	    	my $name;
	    	my $id;
	    	my $aliases;
	    	my $boundary = 0;
	    	foreach my $attr ($cpd->getAttributes()->getValues()) {
	    		my $nm = $attr->getName();
	    		my $value = $attr->getValue();
	    		if ($nm eq "id") {
	    			$sbmlid = $value;
	    			$id = $value;
	    			if ($id =~ m/^M_(.+)/) {
	    				$id = $1;
	    			}
	    		} elsif ($nm eq "name") {
	    			$name = $value;
	    			if ($name =~ m/^M_(.+)/) {
	    				$name = $1;
	    			}
	    			if ($name =~ m/(.+)_((?:[A-Z][a-z]?\d*)+)$/) {
	    				$name = $1;
	    				$formula = $2;
	    			}
	    		} elsif ($nm eq "compartment") {
	    			$compartment = $value;
	    			if (defined($cmptrans->{$compartment})) {
	    				$compartment = $cmptrans->{$compartment};
	    			}
	    		} elsif ($nm eq "charge") {
	    			$charge = $value;
	    		} elsif ($nm eq "formula") {
	    			$formula = $value;
	    		} elsif ($nm eq "boundaryCondition" && $value =~ m/true/i) {
	    			$boundary = 1;
	    		}
	    	}
	    	foreach my $cmpid (keys(%{$compdata})) {
    			my $size = length($cmpid)+1;
    			if (length($id) > $size && "_".$cmpid eq substr($id,length($id)-$size,$size)) {
    				$id = substr($id,0,length($id)-$size);
    				if (length($name) > $size && "_".$cmpid eq substr($name,length($name)-$size,$size)) {
    					$name = substr($name,0,length($name)-$size);
    				}
    				last;
    			}
    		}
	        foreach my $node ($cpd->getElementsByTagName("*",0)) {
			    foreach my $html ($node->getElementsByTagName("*",0)){
					my $nodes = $html->getChildNodes();
					foreach my $node (@{$nodes}) {
					    my $text = $node->toString();
					    if ($text =~ m/FORMULA:\s*([^<]+)/) {
							if (length($1) > 0) {
							    $formula = $1;
							}
					    } elsif ($text =~ m/CHARGE:\s*([^<]+)/) {
							if (length($1) > 0) {
							    $charge = $1;
							}
						} elsif ($text =~ m/BIOCYC:\s*([^<]+)/) {
							if (length($1) > 0) {
							    if (length($aliases) > 0) {
							    	$aliases .= "|";
							    }
							    $aliases .= "BIOCYC:".$1;
							}
						} elsif ($text =~ m/INCHI:\s*([^<]+)/) {
							if (length($1) > 0) {
							    if (length($aliases) > 0) {
							    	$aliases .= "|";
							    }
							    $aliases .= "INCHI:".$1;
							}
						} elsif ($text =~ m/CHEBI:\s*([^<]+)/) {
							if (length($1) > 0) {
							    if (length($aliases) > 0) {
							    	$aliases .= "|";
							    }
							    $aliases .= "CHEBI:".$1;
							}
						} elsif ($text =~ m/CHEMSPIDER:\s*([^<]+)/) {
							if (length($1) > 0) {
							    if (length($aliases) > 0) {
							    	$aliases .= "|";
							    }
							    $aliases .= "CHEMSPIDER:".$1;
							}
						} elsif ($text =~ m/PUBCHEM:\s*([^<]+)/) {
							if (length($1) > 0) {
							    if (length($aliases) > 0) {
							    	$aliases .= "|";
							    }
							    $aliases .= "PUBCHEM:".$1;
							}
						} elsif ($text =~ m/KEGG:\s*([^<]+)/) {
							if (length($1) > 0) {
							    if (length($aliases) > 0) {
							    	$aliases .= "|";
							    }
							    $aliases .= "KEGG:".$1;
							}
					    }
					}
			    }
			}	
	    	if (!defined($name)) {
	    		$name = $id;
	    	}
	    	if (!defined($cpdidhash->{$id})) {
	    		$cpdidhash->{$id} = [$id,$charge,$formula,$name,$aliases];
	    		push(@{$params->{compounds}},$cpdidhash->{$id});
	    	}
	    	$cpdhash->{$sbmlid} = {
	    		id => $sbmlid,
	    		rootid => $id,
	    		name => $name,
	    		formula => $formula,
	    		charge => $charge,
	    		aliases => $aliases
	    	};
	    }
	    #Parsing reactions
	    my $rxns = [$doc->getElementsByTagName("reaction")];
	    my $rxnhash = {};
	    foreach my $rxn (@$rxns){
	    	my $id = undef;
	    	my $sbmlid = undef;
	    	my $name = undef;
	    	my $direction = "=";
	    	my $reactants;
	    	my $products;
	    	my $compartment = "c";
	    	my $gpr;
	    	my $pathway;
	    	my $enzyme;
	    	my $aliases;
	    	my $protein = "Unknown";
	    	foreach my $attr ($rxn->getAttributes()->getValues()) {
	    		my $nm = $attr->getName();
	    		my $value = $attr->getValue();
	    		if ($nm eq "id") {
	    			$sbmlid = $value;
	    			if ($value =~ m/^R_(.+)/) {
	    				$value = $1;
	    			}
	    			$id = $value;
	    		} elsif ($nm eq "name") {
	    			if ($value =~ m/^R_(.+)/) {
	    				$value = $1;
	    			}
	    			$value =~ s/_/-/g;
	    			$name = $value;
	    		} elsif ($nm eq "reversible") {
	    			if ($value ne "true") {
	    				$direction = ">";
	    			}
	    		} else {
	    			#print $nm.":".$value."\n";
	    		}
	    	}
			my %cpd_compartments;
	    	foreach my $node ($rxn->getElementsByTagName("*",0)){
	    		if ($node->getNodeName() eq "listOfReactants" || $node->getNodeName() eq "listOfProducts") {
	    			foreach my $species ($node->getElementsByTagName("speciesReference",0)){
	    				my $spec;
	    				my $stoich = 1;
	    				my $boundary = 0;
	    				foreach my $attr ($species->getAttributes()->getValues()) {
	    					if ($attr->getName() eq "species") {
	    						$spec = $attr->getValue();
	    						if (defined($cpdhash->{$spec})) {
	    							$boundary = $cpdhash->{$spec}->[2];
								my $cpt = $cpdhash->{$spec}->[1];
	    							$spec = $cpdhash->{$spec}->[0]."[".$cpt."]";
								$cpd_compartments{$cpt} = 1;
	    						}
	    					} elsif ($attr->getName() eq "stoichiometry") {
	    						$stoich = $attr->getValue();
	    					}
	    				}
	    				if ($boundary == 0) {
		    				if ($node->getNodeName() eq "listOfReactants") {
		    					if (length($reactants) > 0) {
		    						$reactants .= " + ";
		    					}
		    					$reactants .= "(".$stoich.") ".$spec;
		    				} else {
		    					if (length($products) > 0) {
		    						$products .= " + ";
		    					}
		    					$products .= "(".$stoich.") ".$spec;
		    				}
	    				}
	    			}	
	    		} elsif ($node->getNodeName() eq "notes") {
	    			foreach my $html ($node->getElementsByTagName("*",0)){
	    				my $nodes = $html->getChildNodes();
	    				foreach my $node (@{$nodes}) {
		    				my $text = $node->toString();
							if ($text =~ m/GENE_ASSOCIATION:\s*([^<]+)/) {
								if (length($1) > 0) {
									$gpr = $1;
								}
							} elsif ($text =~ m/PROTEIN_ASSOCIATION:\s*([^<]+)/) {
								if (length($1) > 0) {
									$protein = $1;
								}
							} elsif ($text =~ m/PROTEIN_CLASS:\s*([^<]+)/ || $text =~ m/EC\sNumber:\s*([^<]+)/) {
								if (length($1) > 0) {
									my $array = [split(/\s/,$1)];
									$enzyme = $array->[0];
								}
							} elsif ($text =~ m/SUBSYSTEM:\s*([^<]+)/) {
								if (length($1) > 0) {
									$pathway = $1;
									$pathway =~ s/^S_//;
								}
							} elsif ($text =~ m/BIOCYC:\s*([^<]+)/) {
								if (length($1) > 0) {
									if (length($aliases) > 0) {
								    	$aliases .= "|";
								    }
								    $aliases .= "BIOCYC".$1;
								}
							}
	    				}
	    			}
	    		}
	    	}
	    	if (!defined($name)) {
	    		$name = $id;
	    	}
	    	$rxnhash->{$sbmlid} = {
	    		id => $sbmlid,
	    		rootid => $id,
	    		direction => $direction,
	    		compartment => $compartment,
	    		gpr => $gpr,
	    		name => $name,
	    		enzyme => $enzyme,
	    		pathway => $pathway,
	    		equation => $reactants." => ".$products,
	    		aliases => $aliases
	    	};
	    	push(@{$params->{reactions}},[$id,$direction,$compartment,$gpr,$name,$enzyme,$pathway,undef,$reactants." => ".$products,$aliases]);
	    }
    }
    #ENSURING THAT THERE ARE REACTIONS AND COMPOUNDS FOR THE MODEL AT THIS STAGE
    if (!defined($params->{compounds}) || @{$params->{compounds}} == 0) {
    	Bio::KBase::ObjectAPI::utilities::ERROR("Must have compounds for model!");
    }
    if (!defined($params->{reactions}) || @{$params->{reactions}} == 0) {
    	Bio::KBase::ObjectAPI::utilities::ERROR("Must have reactions for model!");
    }
    #PARSING BIOMASS ARRAY IF ITS NOT ALREADY AN ARRAY
    if (ref($params->{biomass}) ne 'ARRAY') {
    	$params->{biomass} = [split(/;/,$params->{biomass})];
    }
    #CREATING EMPTY MODEL OBJECT
    my $model = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new({
		id => $params->{model_name},
		source => $params->{source},
		source_id => $params->{model_name},
		name => $params->{model_name},
		type => $params->{type},
		genome_ref => $genomeobj->_reference(),
		template_ref => $templateobj->_reference(),
		gapfillings => [],
		gapgens => [],
		biomasses => [],
		modelcompartments => [],
		modelcompounds => [],
		modelreactions => []
	});
	$model->parent($handler->util_data_store());
	#REPROCESSING IDS
    my $translation = {};
    for (my $i=0; $i < @{$params->{compounds}}; $i++) {
    	my $cpd = $params->{compounds}->[$i];
    	my $id = $cpd->[0];
    	if ($id =~ m/[^\w]/) {
    		$cpd->[0] =~ s/[^\w]/_/g;
    	}
    	if ($id =~ m/-/) {
    		$cpd->[0] =~ s/-/_/g;
    	}
    	$translation->{$id} = $cpd->[0];
    }
    for (my $i=0; $i < @{$params->{reactions}}; $i++) {
    	my $rxn = $params->{reactions}->[$i];
    	if ($rxn->[0] =~ m/(.+)_[a-z]\d+$/) {
    		$rxn->[0] = $1;
    	}
    	$rxn->[0] =~ s/[^\w]/_/g;
    	$rxn->[0] =~ s/_/-/g;
    	if (defined($rxn->[8])) {
    		if ($rxn->[8] =~ m/^\[([A-Za-z])\]\s*:\s*(.+)/) {
    			$rxn->[2] = lc($1);
    			$rxn->[8] = $2;
    		}
    		my $eqn = "| ".$rxn->[8]." |";
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
    		for (my $j=0; $j < @{$params->{biomass}}; $j++) {
	    		my $biomass = $params->{biomass}->[$j];
	    		$biomass =~ s/[^\w]/_/g;
    			$biomass =~ s/_/-/g;
	    		if ($rxn->[0] eq $biomass) {
	    			$params->{biomass}->[$j] = $eqn;
	    			splice(@{$params->{reactions}},$i,1);
	    			$i--;
	    			last;
	    		}
    		}
    	}
    }
    for (my $i=0; $i < @{$params->{biomass}}; $i++) {
	    my $eqn = "| ".$params->{biomass}->[$i]." |";
	    foreach my $cpd (keys(%{$translation})) {
	    	if (index($params->{biomass}->[$i],$cpd) >= 0 && $cpd ne $translation->{$cpd}) {
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
	    $params->{biomass}->[$i] = $eqn;
    }
    #Loading reactions to model
	my $missingGenes = {};
	my $missingCompounds = {};
	my $missingReactions = {};
	my $compoundhash = {};
	for (my $i=0; $i < @{$params->{compounds}}; $i++) {
		$compoundhash->{$params->{compounds}->[$i]->[0]} = $params->{compounds}->[$i];
	}
	for (my  $i=0; $i < @{$params->{reactions}}; $i++) {
		my $rxnrow = $params->{reactions}->[$i];
		my $compartment = $rxnrow->[2];
		my $compartmentIndex = 0;
		# check to see if the compartment already specifies an index
		if ($compartment =~/^(\w)(\d+)$/) {
		    $compartment = $1;
		    $compartmentIndex = $2;
		}		
		my $input = {
		    reaction => $rxnrow->[0],
		    direction => $rxnrow->[1],
		    compartment => $compartment,
		    compartmentIndex => $compartmentIndex,
		    gpr => $rxnrow->[3],
		    removeReaction => 0,
		    addReaction => 1,
		    compounds => $compoundhash
		};
		if (defined($rxnrow->[4])) {
			$input->{name} = $rxnrow->[4];
		}
		if (defined($rxnrow->[5])) {
			$input->{enzyme} = $rxnrow->[5];
		}
		if (defined($rxnrow->[6])) {
			$input->{pathway} = $rxnrow->[6];
		}
		if (defined($rxnrow->[7])) {
			$input->{reference} = $rxnrow->[7];
		}
		if (defined($rxnrow->[8])) {
			$input->{equation} = $rxnrow->[8];
		}
		#print $input->{equation}."\n";
		$model->addModelReaction($input);
		#if (defined($report->{missing_genes})) {
		#	for (my $i=0; $i < @{$report->{missing_genes}}; $i++) {
		#		$missingGenes->{$report->{missing_genes}->[$i]} = 1;
		#	}
		#}
		#if (defined($report->{missing_compounds})) {
		#	for (my $i=0; $i < @{$report->{missing_compounds}}; $i++) {
		#		$missingCompounds->{$report->{missing_compounds}->[$i]} = 1;
		#	}
		#}
		#if (defined($report->{missing_reactions})) {
		#	for (my $i=0; $i < @{$report->{missing_reactions}}; $i++) {
		#		$missingReactions->{$report->{missing_reactions}->[$i]} = 1;
		#	}
		#}
	}
	my $rxns = $model->modelreactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		my $rgts = $rxn->modelReactionReagents();
		if (@{$rgts} == 1 && $rgts->[0]->modelcompound()->id() =~ m/_e\d+$/) {
			$handler->util_log("Removing reaction:".$rxn->definition()."\n");
			$model->remove("modelreactions",$rxn);
		}	
	}
	for (my $i=0; $i < @{$params->{biomass}}; $i++) {
		$handler->util_log("Biomass:".$params->{biomass}->[$i]."\n");
		my $report = $model->adjustBiomassReaction({
			biomass => "bio".($i+1),
			equation => $params->{biomass}->[$i],
			compartment => "c",
			compartmentIndex => 0,
		    compounds => $compoundhash
		});
	}
	my $msg = "";
	if (defined($model->{missinggenes})) {
		$handler->util_log("Missing genes:\n".join("\n",keys(%{$model->{missinggenes}}))."\n");
	}
	my $wsmeta = $handler->util_save_object($model,$params->{workspace_name}."/".$params->{model_name},{type => "KBaseFBA.FBAModel"});
    $handler->util_log("Saved new FBA Model to: ".$params->{workspace_name}."/".$params->{model_name}."\n");
    return { ref => $wsmeta->[6]."/".$wsmeta->[0]."/".$wsmeta->[4] };
}

1;
