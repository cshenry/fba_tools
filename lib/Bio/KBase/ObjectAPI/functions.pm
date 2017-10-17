package Bio::KBase::ObjectAPI::functions;
use strict;
use warnings;
use POSIX;
use Data::Dumper;
use Data::UUID;
use Bio::KBase::utilities;
use Bio::KBase::constants;

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

sub util_get_ref{
	my $metadata = shift;
	return $metadata->[6]."/".$metadata->[0]."/".$metadata->[4]
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
		Bio::KBase::utilities::error("No column named ".$exp_condition." in expression matrix.");
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
		$exp_matrix = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{expseries_id},$params->{expseries_workspace}));
		if (!defined($params->{expression_condition})) {
			Bio::KBase::utilities::error("Input must specify the column to select from the expression matrix");
		}
		$exphash = util_build_expression_hash($exp_matrix,$params->{expression_condition});
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
				Bio::KBase::utilities::error("Could not find biomass objective object:".$params->{target_reaction});
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
	if (defined($params->{probanno_id})) {
		$handler->util_log("Getting reaction likelihoods from ".$params->{probanno_id});
		my $rxnprobs = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{probanno_id},$params->{probanno_workspace}));
		$fbaobj->{parameters}->{"Objective coefficient file"} = "ProbModelReactionCoefficients.txt";
		$fbaobj->{inputfiles}->{"ProbModelReactionCoefficients.txt"} = [];
		my $rxncosts = {};
		foreach my $rxn (@{$rxnprobs->{reaction_probabilities}}) {
			$rxncosts->{$rxn->[0]} = (1-$rxn->[1]); # ID is first element, likelihood is second element
		}
		foreach my $rxn (keys(%{$rxncosts})) {
			push(@{$fbaobj->{inputfiles}->{"ProbModelReactionCoefficients.txt"}},"forward\t".$rxn."\t".$rxncosts->{$rxn});
			push(@{$fbaobj->{inputfiles}->{"ProbModelReactionCoefficients.txt"}},"reverse\t".$rxn."\t".$rxncosts->{$rxn});
		}
		$handler->util_log("Added reaction coefficients from reaction likelihoods");
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
		#print "activate_all_model_reactions:".$params->{comprehensive_gapfill}."\n";
		if (defined($exp_matrix)) {
			$input->{expsample} = $exphash;
			$input->{expression_threshold_percentile} = $params->{exp_threshold_percentile};
			$input->{kappa} = $params->{exp_threshold_margin};
			$fbaobj->expression_matrix_ref(Bio::KBase::utilities::buildref($params->{expseries_id},$params->{expseries_workspace}));
			$fbaobj->expression_matrix_column($params->{expression_condition});
		}
		if (defined($source_model)) {
			$input->{source_model} = $source_model;
		}
		$fbaobj->PrepareForGapfilling($input);
	}
	if (defined($params->{save_fluxes})) {
		$fbaobj->parameters()->{"save phenotype simulation fluxes"} = 1;
	}
	if(defined($params->{MFASolver})){
		$fbaobj->parameters()->{"MFASolver"}=$params->{MFASolver};
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
	$params = Bio::KBase::utilities::args($params,["workspace","genome_id"],{
		fbamodel_output_id => undef,
		media_id => undef,
		template_id => "auto",
		genome_workspace => $params->{workspace},
		template_workspace => undef,
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
	my $genome = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{genome_id},$params->{genome_workspace}));
	if (!defined($params->{fbamodel_output_id})) {
		$params->{fbamodel_output_id} = $genome->id().".fbamodel";
	}
	#Retrieving template
	my $template_trans = Bio::KBase::constants::template_trans();
	if (defined($template_trans->{$params->{template_id}})) {
		if ($template_trans->{$params->{template_id}} eq "auto") {
			$handler->util_log("Classifying genome in order to select template.");
			if (defined($template_trans->{$genome->template_classification()})) {
				$params->{template_id} = Bio::KBase::utilities::conf("ModelSEED","default_template_workspace")."/".$template_trans->{$genome->template_classification()};
			} else {
				Bio::KBase::utilities::error("Genome classification ".$genome->template_classification()." not recognized!");
			}
		} else {
			$params->{template_id} = Bio::KBase::utilities::conf("ModelSEED","default_template_workspace")."/".$template_trans->{$params->{template_id}};
		}
	} elsif (!defined($params->{template_workspace})) {
		$params->{template_workspace} = $params->{workspace};
	}
	$handler->util_log("Retrieving model template ".$params->{template_id}.".");
	my $template = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{template_id},$params->{template_workspace}));
	#Building the model
	my $model = $template->buildModel({
		genome => $genome,
		modelid => $params->{fbamodel_output_id},
		fulldb => 0
	});
	$datachannel->{fbamodel} = $model;
	#Gapfilling model if requested
	my $output;
	my $htmlreport = Bio::KBase::utilities::style()."<div style=\"height: 200px; overflow-y: scroll;\"><p>A new draft genome-scale metabolic model was constructed based on the annotations in the genome ".$params->{genome_id}.".";
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
		$htmlreport .= $output->{html_report}." Model was saved with the name ".$params->{fbamodel_output_id}.". The final model includes ".@{$model->modelreactions()}." reactions, ".@{$model->modelcompounds()}." compounds, and ".$model->gene_count()." genes.</p>".Bio::KBase::utilities::gapfilling_html_table()."</div>";
	} else {
		#If not gapfilling, then we just save the model directly
		$output->{number_gapfilled_reactions} = 0;
		$output->{number_removed_biomass_compounds} = 0;
		$output->{new_fbamodel_ref} = Bio::KBase::utilities::buildref($params->{fbamodel_output_id},$params->{workspace});
		my $wsmeta = $handler->util_save_object($model,$output->{new_fbamodel_ref},{type => "KBaseFBA.FBAModel"});
		$htmlreport .= " No gapfilling was performed on the model. It is expected that the model will not be capable of producing biomass on any growth condition until gapfilling is run. Model was saved with the name ".$params->{fbamodel_output_id}.". The final model includes ".@{$model->modelreactions()}." reactions, ".@{$model->modelcompounds()}." compounds, and ".$model->gene_count()." genes.</p></div>"
	}
	$output->{new_fbamodel} = $model;
	Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	return $output;
}

sub func_gapfill_metabolic_model {
	my ($params,$model,$source_model) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id"],{
		fbamodel_workspace => $params->{workspace},
		media_id => undef,
		media_workspace => $params->{workspace},
		probanno_id => undef,
		probanno_workspace => $params->{workspace},
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
	my $printreport = 1;
	my $htmlreport = "";
	if (defined($params->{reaction_ko_list}) && ref($params->{reaction_ko_list}) ne "ARRAY") {
		if (length($params->{reaction_ko_list}) > 0) {
			$params->{reaction_ko_list} = [split(/,/,$params->{reaction_ko_list})];
		} else {
			 $params->{reaction_ko_list} = [];
		}
	}
	if (!defined($model)) {
		$handler->util_log("Retrieving model.");
		$model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
		$htmlreport .= Bio::KBase::utilities::style()."<div style=\"height: 200px; overflow-y: scroll;\"><p>The genome-scale metabolic model ".$params->{fbamodel_id}." was gapfilled";
	} else {
		$printreport = 0;
		$htmlreport .= "<p>The model ".$params->{fbamodel_id}." was gapfilled";
	}
	if (!defined($params->{media_id})) {
		if ($model->genome()->domain() eq "Plant" || $model->genome()->taxonomy() =~ /viridiplantae/i) {
			$params->{media_id} = Bio::KBase::utilities::conf("ModelSEED","default_plant_media");
		} else {
			$params->{default_max_uptake} = 100;
			$params->{media_id} = Bio::KBase::utilities::conf("ModelSEED","default_microbial_media");
		}
		$params->{media_workspace} = Bio::KBase::utilities::conf("ModelSEED","default_media_workspace");
	}
	$htmlreport .= " in ".$params->{media_id}." media to force a minimum flux of ".$params->{minimum_target_flux}." through the ".$params->{target_reaction}." reaction.";
	$handler->util_log("Retrieving ".$params->{media_id}." media.");
	my $media = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{media_id},$params->{media_workspace}));
	$handler->util_log("Preparing flux balance analysis problem.");
	if (defined($params->{source_fbamodel_id}) && !defined($source_model)) {
		$htmlreport .= " During the gapfilling, the source biochemistry database was augmented with all the reactions contained in the existing ".$params->{source_fbamodel_id}." model.";
		$source_model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{source_fbamodel_id},$params->{source_fbamodel_workspace}));	
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
		Bio::KBase::utilities::error("Analysis completed, but no valid solutions found!");
	}
	$handler->util_log("Saving gapfilled model.");
	$model->genome_ref($model->_reference().";".$model->genome_ref());
	my $wsmeta = $handler->util_save_object($model,Bio::KBase::utilities::buildref($params->{fbamodel_output_id},$params->{workspace}),{type => "KBaseFBA.FBAModel"});
	$handler->util_log("Saving FBA object with gapfilling sensitivity analysis and flux.");
	$fba->fbamodel_ref($model->_reference());
	if (!defined($params->{gapfill_output_id})) {
		$params->{gapfill_output_id} = $params->{fbamodel_output_id}.".".$gfid;
	}
	$fba->id($params->{gapfill_output_id});
	my $wsmeta2 = $handler->util_save_object($fba,Bio::KBase::utilities::buildref($params->{gapfill_output_id},$params->{workspace}),{type => "KBaseFBA.FBA"});
	$htmlreport .= "</p>";
	if ($printreport == 1) {
		$htmlreport .= Bio::KBase::utilities::gapfilling_html_table()."</div>";
		Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	}
	return {
		new_fbamodel => $model,
		html_report => $htmlreport,
		new_fba_ref => util_get_ref($wsmeta2),
		new_fbamodel_ref => util_get_ref($wsmeta),
		number_gapfilled_reactions => 0,
		number_removed_biomass_compounds => 0
	};
}

sub func_run_flux_balance_analysis {
	my ($params,$model) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id","fba_output_id"],{
		fbamodel_workspace => $params->{workspace},
		mediaset_id => undef,
		mediaset_workspace => $params->{workspace},
		media_id_list => undef,
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
	if (defined($params->{reaction_ko_list}) && ref($params->{reaction_ko_list}) ne "ARRAY") {
		if (length($params->{reaction_ko_list}) > 0) {
			$params->{reaction_ko_list} = [split(/,/,$params->{reaction_ko_list})];
		} else {
			 $params->{reaction_ko_list} = [];
		}
	}
	if (!defined($model)) {
		$handler->util_log("Retrieving model.");
		$model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
		Bio::KBase::utilities::print_report_message({message => "A flux balance analysis (FBA) was performed on the metabolic model ".$params->{fbamodel_id}." growing in ",append => 0,html => 0});
	}
	if (!defined($params->{media_id})) {
		if ($model->genome()->domain() eq "Plant" || $model->genome()->taxonomy() =~ /viridiplantae/i) {
			$params->{media_id} = Bio::KBase::utilities::conf("ModelSEED","default_plant_media");
		} else {
			$params->{default_max_uptake} = 100;
			$params->{media_id} = Bio::KBase::utilities::conf("ModelSEED","default_microbial_media");
		}
		$params->{media_workspace} = Bio::KBase::utilities::conf("ModelSEED","default_media_workspace");
	}

	$handler->util_log("Retrieving ".$params->{media_id}." media or mediaset.");
	my $media = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{media_id},$params->{media_workspace}));
	if ($media->_wstype() eq "KBaseBiochem.MediaSet") {
		$params->{mediaset_id} = $params->{media_id};
		$params->{mediaset_workspace} = $params->{media_workspace};
		my $firstmedia = $media->{elements}->[0]->{"ref"};
		shift(@{$media->{elements}});
		my $array = [split(/\//,$firstmedia)];
		$params->{media_id} = pop(@{$array});
		$media = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{media_id},$params->{media_workspace}));
	}
	Bio::KBase::utilities::print_report_message({message => $params->{media_id}." media.",append => 1,html => 0});
	$handler->util_log("Preparing flux balance analysis problem.");
	my $fba = util_build_fba($params,$model,$media,$params->{fba_output_id},0,0,undef);
	if (defined($params->{mediaset_id})) {
		$fba->mediaset_ref($params->{mediaset_workspace}."/".$params->{mediaset_id});
	}
	if (defined($params->{media_id_list})) {
		if (ref($params->{media_id_list}) ne 'ARRAY') {
			$params->{media_id_list} = [split(/[\n;\|]+/,$params->{media_id_list})];
		}
		for (my $i=0; $i < @{$params->{media_id_list}}; $i++) {
			my $currref = $params->{media_id_list}->[$i];
			if ($currref !~ m/\//) {
				$currref = $params->{media_workspace}."/".$currref;
			}
			push(@{$fba->media_list_refs()},$currref);
		}
	}
	#Running FBA
	$handler->util_log("Running flux balance analysis problem.");
	my $objective;
	#eval {
		local $SIG{ALRM} = sub { die "FBA timed out! Model likely contains numerical instability!" };
		alarm 86400;
		$objective = $fba->runFBA();
		$fba->toJSON({pp => 1});
		alarm 0;
	#};
	if (!defined($objective)) {
		Bio::KBase::utilities::error("FBA failed with no solution returned!");
	}
	$handler->util_log("Saving FBA results.");
	$fba->id($params->{fba_output_id});
	my $wsmeta = $handler->util_save_object($fba,Bio::KBase::utilities::buildref($params->{fba_output_id},$params->{workspace}),{type => "KBaseFBA.FBA"});
	return {
		new_fba_ref => util_get_ref($wsmeta),
		objective => $objective
	};
}

sub func_compare_fba_solutions {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fba_id_list","fbacomparison_output_id"],{
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
		$fbaids->[$i] = $params->{fba_id_list}->[$i];
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
	my $wsmeta = $handler->util_save_object($fbacomp,Bio::KBase::utilities::buildref($params->{fbacomparison_output_id},$params->{workspace}),{type => "KBaseFBA.FBAComparison"});
	return {
		new_fbacomparison_ref => util_get_ref($wsmeta)
	};
}

sub func_propagate_model_to_new_genome {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id","proteincomparison_id","fbamodel_output_id"],{
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
	Bio::KBase::utilities::print_report_message({message => "A new genome-scale metabolic model was constructed by propagating the existing model ".$params->{fbamodel_id}." to the genome ".$params->{genome_id}.".",append => 0,html => 0});
	my $source_model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	my $rxns = $source_model->modelreactions();
	my $model = $source_model->cloneObject();
	$model->parent($source_model->parent());
	$model->id($params->{fbamodel_output_id});
	$handler->util_log("Retrieving proteome comparison.");
	my $protcomp = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{proteincomparison_id},$params->{proteincomparison_workspace}));
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
		my $wsmeta = $handler->util_save_object($model,Bio::KBase::utilities::buildref($params->{fbamodel_output_id},$params->{workspace}),{type => "KBaseFBA.FBAModel"});
		$output->{new_fbamodel_ref} = util_get_ref($wsmeta);
	}
	return $output;
}

sub func_view_flux_network {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fba_id"],{
		fba_workspace => $params->{workspace}
	});
	$handler->util_log("Retrieving FBA.");
	my $fba = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fba_id},$params->{fba_workspace}));
	my $network = {
		nodes => []
	};
	my $nodelist;
	my $extcpdhash = {};
	my $comphash = {};
	my $rxns = $fba->FBAReactionVariables();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		if (abs($rxn->value()) > 0.0000001) {
			my $mdlrxn = $rxn->modelreaction();
			my $genome;
			my $prots = $mdlrxn->modelReactionProteins();
			for (my $j=0; $j < @{$prots}; $j++) {
				my $sus = $prots->[$j]->modelReactionProteinSubunits();
				for (my $k=0; $k < @{$sus}; $k++) {
					my $ftrs = $sus->[$k]->features();
					for (my $m=0; $m < @{$ftrs}; $m++) {
						$genome = $ftrs->[$m]->parent();
						last;
					}
					if (defined($genome)) {
						last;
					}
				}
				if (defined($genome)) {
					last;
				}
			}
			my $label;
			if ($mdlrxn->id() =~ m/_([a-zA-Z]\d+)$/) {
				$label = $1;
			}
			if (!defined($comphash->{$label})) {
				$comphash->{$label} = {
					media => 0,
					node_type => "compound",
					compound => $label,
					id => $label,
					compartment => "e0"
				};
				push(@{$nodelist},$comphash->{$label});
			}
			if (!defined($comphash->{$label}->{name}) && defined($genome)) {
				$comphash->{$label}->{name} = "Species_".$label;
			}
			my $rgts = $mdlrxn->modelReactionReagents();
			for (my $j=0; $j < @{$rgts}; $j++) {
				if ($rgts->[$j]->modelcompound()->id() =~ m/_e0$/ && $rgts->[$j]->modelcompound()->id() !~ m/cpd00067/ && $rgts->[$j]->modelcompound()->id() !~ m/cpd00001/) {
					if (!defined($extcpdhash->{$rgts->[$j]->modelcompound()->id()})) {
						my $name = $rgts->[$j]->modelcompound()->name();
						$name =~ s/_e0$//;
						my $id = $rgts->[$j]->modelcompound()->id();
						$id =~ s/_e0$//;
						if (length($name) > 10) {
							$name = $id;
						}
						$extcpdhash->{$rgts->[$j]->modelcompound()->id()} = {
							flux => 0,
							node => {
								name => $name,
								media => 0,
								node_type => "compound",
								compound => $id,
								id => $id,
								compartment => "e0"
							},
							species_flux => {}
						};
						push(@{$nodelist},$extcpdhash->{$rgts->[$j]->modelcompound()->id()}->{node});
					}
					$extcpdhash->{$rgts->[$j]->modelcompound()->id()}->{flux} += $rgts->[$j]->coefficient()*$rxn->value();
					if (!defined($extcpdhash->{$rgts->[$j]->modelcompound()->id()}->{species_flux}->{$label})) {
						$extcpdhash->{$rgts->[$j]->modelcompound()->id()}->{species_flux}->{$label} = 0;
					}
					$extcpdhash->{$rgts->[$j]->modelcompound()->id()}->{species_flux}->{$label} += $rgts->[$j]->coefficient()*$rxn->value();
				}
			}
		}
	}
	for (my $i=0; $i < @{$nodelist}; $i++) {
		push(@{$network->{nodes}},{
			data => $nodelist->[$i]
		});
	}
	foreach my $mdlcpd (keys(%{$extcpdhash})) {
		foreach my $species (keys(%{$extcpdhash->{$mdlcpd}->{species_flux}})) {
			if ($extcpdhash->{$mdlcpd}->{species_flux}->{$species} > 0.0000001) {
				push(@{$network->{nodes}},{
					data => {
						reaction =>  $mdlcpd."_".$species, 
		                direction => "=", 
		                features => [], 
		                definition => "(1) ".$extcpdhash->{$mdlcpd}->{node}->{name}."[".$species."] <=> (1) ".$extcpdhash->{$mdlcpd}->{node}->{name}."[e0]",
		                products => [{
							compartment => "e0", 
							id => $extcpdhash->{$mdlcpd}->{node}->{id}, 
							stoich => "1", 
							compound => $extcpdhash->{$mdlcpd}->{node}->{id}
						}], 
		                flux => $extcpdhash->{$mdlcpd}->{species_flux}->{$species}, 
		                node_type => "reaction", 
		                reactants => [{
							compartment => $species, 
							id => $species, 
							stoich => "1", 
							compound => $species
		                }], 
		                gapfilled => 0, 
		                compartment => $species, 
		                id => $mdlcpd."_".$species, 
		                name => $mdlcpd."_".$species
					}
				});
			} elsif ($extcpdhash->{$mdlcpd}->{species_flux}->{$species} < -0.0000001) {
				push(@{$network->{nodes}},{
					data => {
						reaction =>  $mdlcpd."_".$species, 
		                direction => "=", 
		                features => [], 
		                definition => "(1) ".$extcpdhash->{$mdlcpd}->{node}->{name}."[e0] <=> (1) ".$extcpdhash->{$mdlcpd}->{node}->{name}."[".$species."]",
		                reactants => [{
							compartment => "e0", 
							id => $extcpdhash->{$mdlcpd}->{node}->{id}, 
							stoich => "1", 
							compound => $extcpdhash->{$mdlcpd}->{node}->{id}
						}], 
		                flux => abs($extcpdhash->{$mdlcpd}->{species_flux}->{$species}), 
		                node_type => "reaction", 
		                products => [{
							compartment => $species, 
							id => $species, 
							stoich => "1", 
							compound => $species
		                }], 
		                gapfilled => 0, 
		                compartment => $species, 
		                id => $mdlcpd."_".$species, 
		                name => $mdlcpd."_".$species
					}
				});
			}
		}
	}
	my $path = Bio::KBase::utilities::conf("ModelSEED","fbajobdir");
	if (!-d $path) {
		File::Path::mkpath ($path);
	}
	system("cd ".$path.";tar -xzf ".Bio::KBase::utilities::conf("ModelSEED","network_viewer"));
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($path."/NetworkViewer/data/Network.json",[Bio::KBase::ObjectAPI::utilities::TOJSON($network)]);
	return {path => $path."/NetworkViewer"};
}

sub func_simulate_growth_on_phenotype_data {
	my ($params,$model) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id","phenotypeset_id","phenotypesim_output_id"],{
		fbamodel_workspace => $params->{workspace},
		phenotypeset_workspace => $params->{workspace},
		thermodynamic_constraints => 0,
		save_fluxes => 0,
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
		$model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	$handler->util_log("Retrieving phenotype set.");
	my $pheno = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{phenotypeset_id},$params->{phenotypeset_workspace}));
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
		Bio::KBase::utilities::error("Simulation of phenotypes failed to return results from FBA! The model probably failed to grow on Complete media. Try running gapfiling first on Complete media.");
	}
	my $phenoset = $fba->phenotypesimulationset();
	my $phenos = $phenoset->phenotypeSimulations();
	my $total = @{$phenos};
	my $htmlreport =Bio::KBase::utilities::style()."<div style=\"height: 400px; overflow-y: scroll;\"><p>Correct positives: ".$phenoset->cp()." (".POSIX::floor(100*$phenoset->cp()/$total)."%)<br>".
					"Correct negatives: ".$phenoset->cn()." (".POSIX::floor(100*$phenoset->cn()/$total)."%)<br>".
					"False positives : ".$phenoset->fp()." (".POSIX::floor(100*$phenoset->fp()/$total)."%)<br>".
					"False negatives : ".$phenoset->fn()." (".POSIX::floor(100*$phenoset->fn()/$total)."%)<br>".
					"Overall accuracy : ".POSIX::floor(100*($phenoset->cp()+$phenoset->cn())/$total)."%<p>";
	if ($params->{gapfill_phenotypes} == 1 || $params->{fit_phenotype_data} == 1) {
		my $htmltable = "<br><table class=\"reporttbl\">".
			"<row><th>Media</th><th>KO</th><th>Supplements</th><th>Growth</th><th>Gapfilled reactions</th></row>";
		my $found = 0;
		for (my $i=0; $i < @{$phenos}; $i++) {
			if ($phenos->[$i]->numGapfilledReactions() > 0) {
				$found = 1;
				$htmltable .= "<tr><td>".$phenos->[$i]->phenotype()->media()->_wsname()."</td><td>".
					$phenos->[$i]->phenotype()->geneKOString()."</td><td>".
					$phenos->[$i]->phenotype()->additionalCpdString()."</td><td>".
					$phenos->[$i]->phenotype()->normalizedGrowth()."</td><td>".
					$phenos->[$i]->gapfilledReactionString()."</td></tr>";
			}
		}
		$htmltable .= "</table>";
		if ($found == 1) {
			$htmlreport .= $htmltable;
		}
		if ($params->{fit_phenotype_data} == 1) {
			$handler->util_log("Saving gapfilled model.");
			$model->genome_ref($model->_reference().";".$model->genome_ref());
			my $wsmeta = $handler->util_save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
			$fba->fbamodel_ref($model->_reference());
		}
	}
	$htmlreport .= "</div>";
	Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	$handler->util_log("Saving FBA object with phenotype simulation results.");
	my $wsmeta = $handler->util_save_object($phenoset,$params->{workspace}."/".$params->{phenotypesim_output_id},{type => "KBasePhenotypes.PhenotypeSimulationSet"});
	$fba->phenotypesimulationset_ref($phenoset->_reference());
	$wsmeta = $handler->util_save_object($fba,$params->{workspace}."/".$params->{phenotypesim_output_id}.".fba",{hidden => 1,type => "KBaseFBA.FBA"});
	return {
		new_phenotypesim_ref => util_get_ref($wsmeta)
	};
}

sub func_merge_metabolic_models_into_community_model {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id_list","fbamodel_output_id"],{
		fbamodel_workspace => $params->{workspace},
		mixed_bag_model => 0
	});
	#Getting genome
	$handler->util_log("Retrieving first model.");
	my $model = $handler->util_get_object($params->{fbamodel_id_list}->[0]);
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
		new_fbamodel_ref => util_get_ref($wsmeta)
	};
}

sub func_compare_flux_with_expression {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fba_id","expseries_id","expression_condition","fbapathwayanalysis_output_id"],{
		fba_workspace => $params->{workspace},
		expseries_workspace => $params->{workspace},
		exp_threshold_percentile => 0.5,
		estimate_threshold => 0,
		maximize_agreement => 0
	});
	$handler->util_log("Retrieving FBA solution.");
	my $fb = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fba_id},$params->{fba_workspace}));
   	$handler->util_log("Retrieving expression matrix.");
   	my $em = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{expseries_id},$params->{expseries_workspace}));
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
			Bio::KBase::utilities::error("Threshold estimation selected, but too few always-active genes recognized to permit estimation.\n");
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
	$threshold_gene = POSIX::floor($params->{exp_threshold_percentile}*$threshold_gene);
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
		new_fbapathwayanalysis_ref => util_get_ref($meta)
	};
	if (@{$all_analyses} > 1) {
		for (my $m=1; $m < @{$all_analyses}; $m++) {
			$meta = $handler->util_save_object($all_analyses->[$m],$params->{workspace}."/".$params->{fbapathwayanalysis_output_id}.".".$m,{hash => 1,type => "KBaseFBA.FBAPathwayAnalysis"});
			push(@{$outputobj->{additional_fbapathwayanalysis_ref}},util_get_ref($meta));
		}
	}
	return $outputobj;
}

sub func_check_model_mass_balance {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id"],{
		fbamodel_workspace => $params->{workspace},
	});
	$handler->util_log("Retrieving model.");
	my $model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	my $media = $handler->util_get_object("KBaseMedia/Complete");
	my $fba = util_build_fba($params,$model,$media,"tempfba",0,0,undef);
	$fba->parameters()->{"Mass balance atoms"} = "C;S;P;O;N";
	$handler->util_log("Checking model mass balance.");
   	my $objective = $fba->runFBA();
   	my $htmlreport = "<p>No mass imbalance found</p>";
	my $message = "No mass imbalance found";
	if (length($fba->MFALog) > 0) {
		$message = $fba->MFALog();
		$htmlreport = Bio::KBase::utilities::style()."<div style=\"height: 400px; overflow-y: scroll;\"><table class=\"reporttbl\"><row><td>Reaction</td><td>Reactants</td><td>Products</td><td>Extra atoms in reactants</td><td>Extra atoms in products</td></row>";
		my $array = [split(/\n/,$message)];
		my ($id,$reactants,$products,$rimbal,$pimbal);
		for (my $i=0; $i < @{$array}; $i++) {
			if ($array->[$i] =~ m/Reaction\s(.+)\simbalanced/) {
				if (defined($id)) {
					$htmlreport .= "<tr><td>".$id."</td><td>".$reactants."<td>".$products."</td><td>".$rimbal."</td><td>".$pimbal."</td></tr>";
				}
				$reactants = "";
				$products = "";
				$rimbal = "";
				$pimbal = "";
				$id = $1;
			} elsif ($array->[$i] =~ m/Extra\s(.+)\s(.+)\sin\sproducts/) {
				if (length($rimbal) > 0) {
					$rimbal .= "<br>";
				}
				$rimbal .= $1." ".$2;
			} elsif ($array->[$i] =~ m/Extra\s(.+)\s(.+)\sin\sreactants/) {
				if (length($pimbal) > 0) {
					$pimbal .= "<br>";
				}
				$pimbal .= $1." ".$2;
			} elsif ($array->[$i] =~ m/Reactants:/) {
				$i++;
				while ($array->[$i] ne "Products:") {
					if (length($reactants) > 0) {
						$reactants .= "<br>";
					}
					$reactants .= $array->[$i];
					$i++;
				}
				$i++;
				while (length($array->[$i]) > 0) {
					if (length($products) > 0) {
						$products .= "<br>";
					}
					$products .= $array->[$i];
					$i++;
				}
			}
		}
		if (defined($id)) {
			$htmlreport .= "<tr><td>".$id."</td><td>".$reactants."<td>".$products."</td><td>".$rimbal."</td><td>".$pimbal."</td></tr>";
		}
		$htmlreport .= "</table></div>";
	}
	Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
}

sub func_create_or_edit_media {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","media_output_id"],{
		media_id => undef,
		compounds_to_remove => "",
		compounds_to_change => [],
		compounds_to_add => [],
		protocol_link => undef,
		atmosphere => undef,
		atmosphere_addition => undef,
		media_workspace => $params->{workspace},
		pH_data => undef,
		temperature => undef,
		source_id => undef,
		source => undef,
		name => undef,
		type => undef,
		isDefined => undef
	});
	my $media = {
		mediacompounds => [],
	};
	if (defined($params->{media_id})) {
		$media = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{media_id},$params->{media_workspace}),{raw => 1});
	}
	$media->{id} = $params->{media_output_id};
	$media->{name} = $params->{media_output_id};
	my $list = ["name","source","source_id","type","isDefined","temperature","pH_data","atmosphere","atmosphere_addition","protocol_link"];
	for (my $i=0; $i < @{$list}; $i++) {
		if (defined($params->{$list->[$i]})) {
			$media->{$list->[$i]} = $params->{$list->[$i]};
		}
	}
	my $mediacpds = $media->{mediacompounds};
	my $count = @{$mediacpds};
	my $removed_list = [];
	if (defined($params->{compounds_to_remove}) && length($params->{compounds_to_remove}) > 0) {
		$params->{compounds_to_remove} = [split(/,/,$params->{compounds_to_remove})];
	} else {
		$params->{compounds_to_remove} = [];
	}
	for (my $i=0; $i < @{$params->{compounds_to_remove}}; $i++) {
		$params->{compounds_to_remove}->[$i] =~ s/.+\///;
		for (my $j=0; $j < @{$mediacpds}; $j++) {
			if ($mediacpds->[$j]->{compound_ref} =~ m/(cpd\d+)/) {
				if ($1 eq $params->{compounds_to_remove}->[$i]) {
					push(@{$removed_list},$params->{compounds_to_remove}->[$i]);
					splice(@{$mediacpds}, $j, 1);
					last;
				}
			}
		}
	}
	if (@{$removed_list} == 0) {
		Bio::KBase::utilities::print_report_message({message => "No compounds removed from the media.",append => 0,html => 0});
	} else {
		my $count = @{$removed_list};
		Bio::KBase::utilities::print_report_message({message => $count." compounds removed from the media: ".join("; ",@{$removed_list}).".",append => 0,html => 0});
	}
	my $change_list = [];
	for (my $i=0; $i < @{$params->{compounds_to_change}}; $i++) {
		if (defined($params->{compounds_to_change}->[$i]->{change_id})) {
			if (ref($params->{compounds_to_change}->[$i]->{change_id}) eq "ARRAY") {
				$params->{compounds_to_change}->[$i]->{change_id} = $params->{compounds_to_change}->[$i]->{change_id}->[0];
			}
		}
		$params->{compounds_to_change}->[$i]->{change_id} =~ s/.+\///;
		for (my $j=0; $j < @{$mediacpds}; $j++) {
			if ($mediacpds->[$j]->{compound_ref} =~ m/(cpd\d+)/) {
				if ($1 eq $params->{compounds_to_change}->[$i]->{change_id}) {
					push(@{$change_list},$params->{compounds_to_change}->[$i]->{change_id});
					$mediacpds->[$j]->{concentration} = $params->{compounds_to_change}->[$i]->{change_concentration};
					$mediacpds->[$j]->{minFlux} = $params->{compounds_to_change}->[$i]->{change_minflux};
					$mediacpds->[$j]->{maxFlux} = $params->{compounds_to_change}->[$i]->{change_maxflux};
				}
			}
		}
	}
	if (@{$change_list} == 0) {
		Bio::KBase::utilities::print_report_message({message => " No compounds changed in the media.",append => 1,html => 0});
	} else {
		my $count = @{$change_list};
		Bio::KBase::utilities::print_report_message({message => " ".$count." compounds changed in the media: ".join("; ",@{$change_list}).".",append => 1,html => 0});
	}
	my $add_list = [];
	my $bio = $handler->util_get_object("kbase/default",{});
	for (my $i=0; $i < @{$params->{compounds_to_add}}; $i++) {
		my $found = 0;
		my $cpd;
		if ($params->{compounds_to_add}->[$i]->{add_id} =~ m/^cpd\d+$/) {
			$cpd = $bio->getObject("compounds",$params->{compounds_to_add}->[$i]->{add_id});
		} else {
			$cpd = $bio->searchForCompound($params->{compounds_to_add}->[$i]->{add_id});
		}
		if (defined($cpd)) {
			for (my $j=0; $j < @{$mediacpds}; $j++) {
				if ($mediacpds->[$j]->{compound_ref} =~ m/(cpd\d+)/) {
					if ($1 eq $cpd->id()) {
						$mediacpds->[$j]->{concentration} = $params->{compounds_to_add}->[$i]->{add_concentration};
						$mediacpds->[$j]->{minFlux} = $params->{compounds_to_add}->[$i]->{add_minflux};
						$mediacpds->[$j]->{maxFlux} = $params->{compounds_to_add}->[$i]->{add_maxflux};
						$found = 1;
					}
				}
			}
		} else {
			for (my $j=0; $j < @{$mediacpds}; $j++) {
				if (defined($mediacpds->[$j]->{id}) && $mediacpds->[$j]->{id} eq $params->{compounds_to_add}->[$i]->{add_id}) {
					$found = 1;
				} elsif (defined($mediacpds->[$j]->{name}) && $mediacpds->[$j]->{name} eq $params->{compounds_to_add}->[$i]->{add_id}) {
					$found = 1;
				}
			}
		}
		if ($found == 0) {
			my $newmediacpd = {
				concentration => $params->{compounds_to_add}->[$i]->{add_concentration},
				maxFlux => $params->{compounds_to_add}->[$i]->{add_minflux},
				minFlux => $params->{compounds_to_add}->[$i]->{add_maxflux}
			};
			if (defined($cpd)) {
				$newmediacpd->{id} = $cpd->id();
				$newmediacpd->{name} = $cpd->name();
				$newmediacpd->{compound_ref} = "kbase/default/compounds/id/".$cpd->id();
			} else {
				$newmediacpd->{id} = $params->{compounds_to_add}->[$i]->{add_id};
				$newmediacpd->{name} = $params->{compounds_to_add}->[$i]->{add_id};
				$newmediacpd->{compound_ref} = "kbase/default/compounds/id/cpd00000";
			}
			if (defined($params->{compounds_to_add}->[$i]->{smiles})) {
				$newmediacpd->{smiles} = $params->{compounds_to_add}->[$i]->{smiles};
			}
			if (defined($params->{compounds_to_add}->[$i]->{inchikey})) {
				$newmediacpd->{inchikey} = $params->{compounds_to_add}->[$i]->{inchikey};
			}
			push(@{$mediacpds},$newmediacpd);
			push(@{$add_list},$params->{compounds_to_add}->[$i]->{add_id});
		}
	}
	if (@{$add_list} == 0) {
		Bio::KBase::utilities::print_report_message({message => " No compounds added to the media.",append => 1,html => 0});
	} else {
		my $count = @{$add_list};
		Bio::KBase::utilities::print_report_message({message => " ".$count." compounds added to the media: ".join("; ",@{$add_list}).".",append => 1,html => 0});
	}
	for (my $i=0; $i < @{$mediacpds}; $i++) {
		if ($mediacpds->[$i]->{compound_ref} =~ m/(cpd\d+)/) {
			my $cpdid = $1;
			if ($cpdid ne "cpd00000") {
				my $cpdobj = $bio->getObject("compounds",$cpdid);
				if (!defined($mediacpds->[$i]->{name})) {
					$mediacpds->[$i]->{name} = $cpdobj->name();
				}
				if (!defined($mediacpds->[$i]->{id})) {
					$mediacpds->[$i]->{id} = $cpdobj->id();
				}
			}
		}
	}
	my $mediaobj = Bio::KBase::ObjectAPI::KBaseBiochem::Media->new($media);
	$mediaobj->parent($handler->util_store());
	my $mediaobjcpds = $mediaobj->mediacompounds();
	my $wsmeta = $handler->util_save_object($mediaobj,$params->{workspace}."/".$params->{media_output_id});
   	return {
		new_media_ref => util_get_ref($wsmeta),
		report_name => $params->{media_output_id}.".create_or_edit_media.report",
		ws_report_id => $params->{workspace}.'/'.$params->{media_output_id}.".create_or_edit_media.report"
	};
}

sub func_edit_metabolic_model {
	my ($params,$model) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id"],{
		compounds_to_add => [],
		compounds_to_change => [],
		biomasses_to_add => [],
		biomass_compounds_to_change => [],
		reactions_to_remove => "",
		reactions_to_change => [],
		reactions_to_add => [],
		edit_compound_stoichiometry => [],
		fbamodel_workspace => $params->{workspace},
		fbamodel_output_id => $params->{fbamodel_id}
	});
	if (defined($params->{reactions_to_remove}) && length($params->{reactions_to_remove}) > 0) {
		$params->{reactions_to_remove} = [split(/,/,$params->{reactions_to_remove})];
	} else {
		$params->{reactions_to_remove} = [];
	}
	#Getting genome
	$handler->util_log("Loading model from workspace");
	if (!defined($model)) {
		$model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	(my $editresults,my $detaileditresults) = $model->edit_metabolic_model({
		compounds_to_add => $params->{compounds_to_add},
		compounds_to_change => $params->{compounds_to_change},
		biomasses_to_add => $params->{biomasses_to_add},
		biomass_compounds_to_change => $params->{biomass_compounds_to_change},
		reactions_to_remove => $params->{reactions_to_remove},
		reactions_to_change => $params->{reactions_to_change},
		reactions_to_add => $params->{reactions_to_add},
		edit_compound_stoichiometry => $params->{edit_compound_stoichiometry}
	});
	#Creating message to report all modifications made
	$handler->util_log("Saving edited model to workspace");
	$model->genome_ref($model->_reference().";".$model->genome_ref());
	my $wsmeta = $handler->util_save_object($model,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
	my $message = "Name of edited model: ".$params->{fbamodel_output_id}."\n";
	$message .= "Starting from: ".$params->{fbamodel_id}."\n";
	$message .= "Compounds added:".join("\n",@{$editresults->{compounds_added}})."\n";
	$message .= "Compounds changed:".join("\n",@{$editresults->{compounds_changed}})."\n";
	$message .= "Biomass added:".join("\n",@{$editresults->{biomass_added}})."\n";
	$message .= "Biomass compounds removed:".join("\n",@{$editresults->{biomass_compounds_removed}})."\n";
	$message .= "Biomass compounds added:".join("\n",@{$editresults->{biomass_compounds_added}})."\n";
	$message .= "Biomass compounds changed:".join("\n",@{$editresults->{biomass_compounds_changed}})."\n";
	$message .= "Reactions added:".join("\n",@{$editresults->{reactions_added}})."\n";
	$message .= "Reactions changed:".join("\n",@{$editresults->{reactions_changed}})."\n";
	$message .= "Reactions removed:".join("\n",@{$editresults->{reactions_removed}})."\n";
	Bio::KBase::utilities::print_report_message({message => $message,append => 0,html => 0});
   	return {
		new_fbamodel_ref => util_get_ref($wsmeta),
		detailed_edit_results => $detaileditresults
   	};
}

sub func_quantitative_optimization {
	my ($params,$model) = @_;
	$params = Bio::KBase::utilities::args($params,["fbamodel_id","constraints","workspace"],{
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
		$model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	if (!defined($params->{media_id})) {
		$params->{default_max_uptake} = 100;
		$params->{media_id} = "Complete";
		$params->{media_workspace} = "KBaseMedia";
	}
	$handler->util_log("Retrieving ".$params->{media_id}." media.");
	my $media = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{media_id},$params->{media_workspace}));
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
		new_fbamodel_ref => util_get_ref($wsmeta)
	};
}

sub func_compare_models {
	my ($params,$model) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","model_refs"],{
		protcomp_ref => undef,
		pangenome_ref => undef,
		mc_name => "ModelComparison"
	});
	if (@{$params->{model_refs}} < 2) {
		Bio::KBase::utilities::error("Must select at least two models to compare");
	}

	my $provenance = [{}];
	my $models;
	my $modelnames = ();
	my $modelnamehash = {};
	foreach my $model_ref (@{$params->{model_refs}}) {
		my $model=undef;
		eval {
			$model = $handler->util_get_object($model_ref,{raw => 1});
			print("Downloaded model: $model->{id}\n");
			if (defined($modelnamehash->{$model->{id}})) {
				die "Duplicate model names are not permitted\n";
			}
			$modelnamehash->{$model->{id}} = 1;
			push(@{$modelnames},$model->{id});
			$model->{model_ref} = $model_ref;
			push @{$models}, $model;
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

	foreach my $model (@{$models}) {
		$handler->util_log("Processing model ", $model->{id}, "");
		foreach my $cmp (@{$model->{modelcompartments}}) {
			$model->{cmphash}->{$cmp->{id}} = $cmp;
		}
		foreach my $cpd (@{$model->{modelcompounds}}) {
			$cpd->{cmpkbid} = pop @{[split /\//, $cpd->{modelcompartment_ref}]};
			$cpd->{cpdkbid} = pop @{[split /\//, $cpd->{compound_ref}]};
			if (! defined $cpd->{name}) {
				$cpd->{name} = $cpd->{id};
			}
			$cpd->{name} =~ s/_[a-zA-z]\d+$//g;

			$model->{cpdhash}->{$cpd->{id}} = $cpd;
			if ($cpd->{cpdkbid} ne "cpd00000") {
				local $SIG{__WARN__} = sub { };
				# The follow line works but throws a shit-ton of warnings.
				# Rather than fix the implementation like I probably should,
				# I'm silencing them with the preceding line
				$model->{cpdhash}->{$cpd->{$cpd->{cpdkbid}."_".$cpd->{cmpkbid}}} = $cpd;
			}
		}
		foreach my $rxn (@{$model->{modelreactions}}) {
			$rxn->{rxnkbid} = pop @{[split /\//, $rxn->{reaction_ref}]};
			$rxn->{cmpkbid} = pop @{[split /\//, $rxn->{modelcompartment_ref}]};
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
			$rgt->{cpdkbid} = pop @{[split /\//, $rgt->{modelcompound_ref}]};
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
				my $ef = pop @{[split /\//, $feature]};
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
	my $genomehash;
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
				foreach my $model (@{$models}) {
					$genomehash->{$model->{genome_ref}} = $handler->util_get_object($model->{genome_ref},{raw => 1,parent => $model});
					if (exists $ftr2model{$ortholog->[0]}->{$model->{id}}) {
						map { $in_models->{$model->{id}}->{$_} = 1 } keys %{$ftr2reactions{$ortholog->[0]}};
						push @{$model2family{$model->{id}}->{$family->{id}}}, $ortholog->[0];
					}
				}
			}
			my $num_models = scalar keys %$in_models;
			if ($num_models > 0) {
				foreach my $model (@{$models}) {
					if (exists $in_models->{$model->{id}}) {
						my @reactions = sort keys %{$in_models->{$model->{id}}};
						$family_model_data->{$model->{id}} =  [1, \@reactions];
					} else {
						$family_model_data->{$model->{id}} = [0, []];
					}
				}
				my $mc_family = {
					id => $family->{id},
					family_id => $family->{id},
					function => $family->{function},
					number_models => $num_models,
					fraction_models => $num_models*1.0/@{$models},
					core => ($num_models == @{$models} ? 1 : 0),
					family_model_data => $family_model_data
				};
				$mc_families->{$family->{id}} = $mc_family;
				$core_families++ if ($num_models == @{$models});
			}
		}
	}
	if (!defined($gene_translation)) {
		foreach my $model1 (@{$models}) {
			$genomehash->{$model1->{genome_ref}} = $handler->util_get_object($model1->{genome_ref},{raw => 1,parent => $model1});
			my $ftrs = $genomehash->{$model1->{genome_ref}}->{features};
			for (my $i=0; $i < @{$ftrs}; $i++) {
				$gene_translation->{$ftrs->[$i]->{id}}->{$ftrs->[$i]->{id}} = 1;
			}
		}
	}

	# ACCUMULATE REACTIONS AND FAMILIES
	my %rxn2families;
	foreach my $model (@{$models}) {
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

	foreach my $model1 (@{$models}) {
		my $mc_model = {model_similarity => {}};
		push @{$mc_models}, $mc_model;
		$mc_model->{id} = $model1->{id};
		$mc_model->{model_ref} = $model1->{model_ref};
		$mc_model->{genome_ref} = $model1->{model_ref}.";".$model1->{genome_ref};
		$mc_model->{families} = exists $model2family{$model1->{id}} ? scalar keys %{$model2family{$model1->{id}}} : 0;
		eval {
			$mc_model->{name} = $genomehash->{$model1->{genome_ref}}->{scientific_name};
			$mc_model->{taxonomy} = $genomehash->{$model1->{genome_ref}}->{taxonomy};
		};
		if ($@) {
			warn "Error loading genome from workspace:\n".$@;
		}

		$mc_model->{reactions} = scalar @{$model1->{modelreactions}};
		$mc_model->{compounds} = scalar @{$model1->{modelcompounds}};
		$mc_model->{biomasses} = scalar @{$model1->{biomasses}};

		foreach my $model2 (@{$models}) {
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
				push @$ftrs, [$ftr, $family->{id}, $conservation*1.0/@{$models}, 0];
			}
			# maybe families associated with reaction aren't in model
			foreach my $familyid (keys %{$rxn2families{$rxn->{id}}}) {
				if (! exists $model2family{$model1->{id}}->{$familyid}) {
				my $conservation = 0;
				foreach my $m (keys %model2family) {
					$conservation++ if exists $model2family{$m}->{$familyid};
				}
				push @$ftrs, ["", $familyid, $conservation*1.0/@{$models}, 1];
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
			foreach my $model2 (@{$models}) {
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
								push @$ftrs, [$ftr, $familyid, $conservation*1.0/@{$models}, 0];
							}
						} else {
							push @$ftrs, ["", $familyid, $conservation*1.0/@{$models}, 1];
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
			foreach my $model2 (@{$models}) {
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
			my $cpdkbid = pop @{[split /\//, $bcpd->{modelcompound_ref}]};
			my $cpd = $model1->{cpdhash}->{$cpdkbid};
			my $match_id = $cpd->{cpdkbid};
			if (! defined $match_id || $match_id =~ "cpd00000") {
				$match_id = $cpd->{id};
				$match_id =~ s/_[a-zA-z]\d+$//g;
			}
			if (! defined $match_id) {
				Bio::KBase::utilities::error("no match possible for biomass compound:");
				Bio::KBase::utilities::error(Dumper($bcpd));
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
			foreach my $model2 (@{$models}) {
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
			foreach my $model2 (@{$models}) {
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
	if ($mc_reaction->{number_models} == @{$models}) {
		$core_reactions++;
		$mc_reaction->{core} = 1;
	}
	$mc_reaction->{fraction_models} = 1.0*$mc_reaction->{number_models}/@{$models};
	}

	my $core_compounds = 0;
	foreach my $mc_compound (values %$mc_compounds) {
	if ($mc_compound->{number_models} == @{$models}) {
		$core_compounds++;
		$mc_compound->{core} = 1;
	}
	$mc_compound->{fraction_models} = 1.0*$mc_compound->{number_models}/@{$models};
	}

	my $core_bcpds = 0;
	foreach my $mc_bcpd (values %$mc_bcpds) {
	if ($mc_bcpd->{number_models} == @{$models}) {
		$core_bcpds++;
		$mc_bcpd->{core} = 1;
	}
	$mc_bcpd->{fraction_models} = 1.0*$mc_bcpd->{number_models}/@{$models};
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
	my $wsmeta = $handler->util_save_object($mc,$params->{workspace}."/".$params->{mc_name},{hash => 1,type => "KBaseFBA.ModelComparison"});
	Bio::KBase::utilities::print_report_message({message => "The compounds, reactions, genes, and biomass compositions in the following ".@{$models}." models were compared:".join("; ",@{$modelnames}).".",append => 0,html => 0});
	Bio::KBase::utilities::print_report_message({message => " All models shared a common set of ".$core_compounds." compounds, ".$core_reactions." reactions, and ".$core_bcpds." biomass compounds.",append => 1,html => 0});
	return {
		'mc_ref' => util_get_ref($wsmeta)
	};
}

sub func_import_media {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["compounds","media_id","workspace"],{
		name => $params->{media_id},
		source => undef,
		source_id => undef,
		protocol_link => undef,
		pH_data => undef,
		temperature => undef,
		atmosphere => undef,
		atmosphere_addition => undef,
		isDefined => 0,
		isMinimal => 0,
		type => "custom",
		concentrations => [],
		smiles => {},
		inchikey => {},
		compound_names => {},
		maxflux => [],
		minflux => []
	});
	#Creating the media object from the specifications
	my $bio = $handler->util_get_object("kbase/default",{});
	my $media = {
		id => $params->{media_id},
		name => $params->{name},
		isDefined => $params->{isDefined},
		isMinimal => $params->{isMinimal},
		type => $params->{type},
		source_id => $params->{media_id},
		mediacompounds => []
	};
	my $attributelist = [
		"source",
		"source_id",
		"protocol_link",
		"pH_data",
		"temperature",
		"atmosphere",
		"atmosphere_addition"
	];
	for (my $i=0; $i < @{$attributelist}; $i++) {
		if (defined($params->{$attributelist->[$i]})) {
			$media->{$attributelist->[$i]} = $params->{$attributelist->[$i]};
		}
	}
	for (my $i=0; $i < @{$params->{compounds}}; $i++) {
		my $newcpd = {
			id => $params->{compounds}->[$i],
			name => $params->{compounds}->[$i],
			concentration => 0.001,
			maxFlux => 1000,
			minFlux => -1000,
			compound_ref => "/kbase/default/compounds/id/cpd00000"
		};
		if (defined($params->{compound_names}->{$params->{compounds}->[$i]})) {
			$newcpd->{name} = $params->{compound_names}->{$params->{compounds}->[$i]};
		}
		if (defined($params->{smiles}->{$params->{compounds}->[$i]})) {
			$newcpd->{smiles} = $params->{smiles}->{$params->{compounds}->[$i]};
		}
		if (defined($params->{inchikey}->{$params->{compounds}->[$i]})) {
			$newcpd->{inchikey} = $params->{inchikey}->{$params->{compounds}->[$i]};
		}
		if (defined($params->{concentrations}->[$i])) {
			$newcpd->{concentration} = 0+$params->{concentrations}->[$i];
		}
		if (defined($params->{maxflux}->[$i])) {
			$newcpd->{maxFlux} = 0+$params->{maxflux}->[$i];
		}
		if (defined($params->{minflux}->[$i])) {
			$newcpd->{minFlux} = 0+$params->{minflux}->[$i];
		}
		my $cpdobj = $bio->searchForCompound($newcpd->{id});
		if (defined($cpdobj)) {
			$newcpd->{id} = $cpdobj->id();
			$newcpd->{compound_ref} = $bio->_reference()."/compounds/id/".$cpdobj->id();
		}
		push(@{$media->{mediacompounds}},$newcpd);
	}
	#Saving media in database
	my $wsmeta = $handler->util_save_object($media,$params->{workspace}."/".$params->{media_id},{type => "KBaseBiochem.Media",hash => 1});
	return { ref => util_get_ref($wsmeta) };
}

sub func_import_phenotype_set {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["data","phenotypeset_id","workspace","genome",],{
		genome_workspace => $params->{workspace},
		source => "KBase",
		name => $params->{phenotypeset_id},
		type => "unspecified",
		ignore_errors => 0
	});
	my $genomeobj = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{genome},$params->{genome_workspace}));
	my $phenoset = Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSet->new({
		id => $params->{phenotypeset_id},
		source_id => $params->{phenotypeset_id},
		source => $params->{source},
		name => $params->{name},
		genome_ref => $genomeobj->_reference(),
		phenotypes => [],
		importErrors => "",
		type => $params->{type}
	});
	$phenoset->parent($handler->util_store());
	my $bio = $handler->util_get_object("kbase/default",{});
	$phenoset->import_phenotype_table({
		data => $params->{data},
		biochem => $bio
	});
	if (!scalar(@{$phenoset->phenotypes()})){
		Bio::KBase::utilities::error("No phenotypes imported. File may be empty or file parseing failed.\n")
	}
	my $wsmeta = $handler->util_save_object($phenoset,$params->{workspace}."/".$params->{phenotypeset_id},{type => "KBasePhenotypes.PhenotypeSet"});
	return { ref => util_get_ref($wsmeta) };
}

sub func_importmodel {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["biomass","model_name","workspace_name"],{
		sbml => undef,
		model_file => undef,
		genome => undef,
		genome_workspace => $params->{workspace_name},
		source => "External",
		type => "SingleOrganism",
		template_id => "auto",
		template_workspace => $params->{workspace_name},
		compounds => [],
		reactions => []
	});
	my $original_rxn_ids;
	#RETRIEVING THE GENOME FOR THE MODEL
	if (!defined($params->{genome})) {
		$params->{genome} = "Empty";
		$params->{genome_workspace} = "PlantSEED";
		$params->{template_workspace} = "NewKBaseModelTemplates";
		$params->{template_id} = "GramNegModelTemplate";
	}
	my $genomeobj = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{genome},$params->{genome_workspace}),{});
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
	my $templateobj = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{template_id},$params->{template_workspace}),{});
	#HANDLING SBML FILENAMES IF PROVIDED
	if (defined($params->{model_file})) {
		$params->{model_file} = $handler->util_get_file_path($params->{model_file});
		if (!-e $params->{model_file}) {
			Bio::KBase::utilities::error("SBML file ".$params->{model_file}." doesn't exist!");
		}
		$params->{sbml} = "";
		open(my $fh, "<", $params->{model_file}) || return;
		while (my $line = <$fh>) {
			$params->{sbml} .= $line;
		}
		close($fh);
	}
	#PARSING SBML IF PROVIDED
	my $comptrans = Bio::KBase::constants::compartment_trans();
	my $genetranslation;
	# Parse SBML file if provided
	if (defined($params->{sbml})) {
		print("Parseing SBML text\n");
		$params->{compounds} = [];
		$params->{reactions} = [];
		require "XML/DOM.pm";
		my $parser = new XML::DOM::Parser;
		my $doc = $parser->parse($params->{sbml});
		#Parsing compartments
		my $cmpts = [$doc->getElementsByTagName("compartment")];
		my $compdata = {};
		my $custom_comp_index = 0;
		my $custom_comp_letters = [qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)];
		my $nonexactcmptrans = {
			xtra => "e0",
			wall => "w0",
			peri => "p0",
			cyto => "c0",
			retic => "r0",
			lys => "l0",
			nucl => "n0",
			chlor => "d0",
			mito => "m0",
			perox => "x0",
			vacu => "v0",
			plast => "d0",
			golg => "g0"
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
			$cmpid =~ s/__/!/g;
			while ($cmpid =~ m/^([^\!]+)\!(\d+)\!(.*)/) {
				$cmpid = $1.chr($2).$3;
			}
			$cmpid =~ s/\!/__/g;
			if (defined($comptrans->{$cmproot})) {
				$cmproot = $comptrans->{$cmproot};
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
				print("not_defined\n");
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
			my $compartment = "c0";
			my $name;
			my $id;
			my $striped_id;
			my $aliases;
			my $smiles = "";
			my $inchikey = "";
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
					$id =~ s/__/!/g;
					while ($id =~ m/^([^\!]+)\!(\d+)\!(.*)/) {
						$id = $1.chr($2).$3;
					}
					$id =~ s/\!/__/g;
					#strip the compartment in ID if present
					$striped_id = $id =~ s/_[a-z]\d*$//r;
				} elsif ($nm eq "name") {
					$name = $value;
					$name =~ s/_plus_/+/g;
					if ($name =~ m/^M_(.+)/) {
						$name = $1;
					}
					if ($name =~ m/(.+)_((?:[A-Z][a-z]?\d*)+)$/) {
						$name = $1;
						$formula = $2;
					}
					$name =~ s/_/ /g;
				} elsif ($nm eq "compartment") {
					$compartment = $value;
					$compartment =~ s/__/!/g;
					while ($compartment =~ m/^([^\!]+)\!(\d+)\!(.*)/) {
						$compartment = $1.chr($2).$3;
					}
					$compartment =~ s/\!/__/g;
					if (defined($comptrans->{$compartment})) {
						$compartment = $comptrans->{$compartment}
					}
					if (length $compartment == 1){
						$compartment .= "0"
					}
				} elsif ($nm eq "charge" || $nm eq "fbc:charge") {
					$charge = $value;
				} elsif ($nm eq "formula" || $nm eq "fbc:chemicalFormula") {
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
				if ($node->getNodeName() eq "notes") {
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
									if (defined($aliases) && length($aliases) > 0) {
										$aliases .= "|";
									}
									$aliases .= "BIOCYC:".$1;
								}
							} elsif ($text =~ m/INCHI:\s*([^<]+)/) {
								if (length($1) > 0) {
									if (defined($aliases) && length($aliases) > 0) {
										$aliases .= "|";
									}
									$aliases .= "INCHI:".$1;
								}
							} elsif ($text =~ m/CHEBI:\s*([^<]+)/) {
								if (length($1) > 0) {
									if (defined($aliases) && length($aliases) > 0) {
										$aliases .= "|";
									}
									$aliases .= "CHEBI:".$1;
								}
							} elsif ($text =~ m/CHEMSPIDER:\s*([^<]+)/) {
								if (length($1) > 0) {
									if (defined($aliases) && length($aliases) > 0) {
										$aliases .= "|";
									}
									$aliases .= "CHEMSPIDER:".$1;
								}
							} elsif ($text =~ m/PUBCHEM:\s*([^<]+)/) {
								if (length($1) > 0) {
									if (defined($aliases) && length($aliases) > 0) {
										$aliases .= "|";
									}
									$aliases .= "PUBCHEM:".$1;
								}
							} elsif ($text =~ m/KEGG:\s*([^<]+)/) {
								if (length($1) > 0) {
									if (defined($aliases) && length($aliases) > 0) {
										$aliases .= "|";
									}
									$aliases .= "KEGG:".$1;
								}
							}
						}
					}
				}
			}
			if (!defined($name)) {
				$name = $id;
			}
			if (!defined($aliases)) {
				$aliases = [];
			}
			# not going to try to deduplicate here(confuseing for users)
			push(@{$params->{compounds}},[$striped_id."_".$compartment,$charge,$formula,$name,$aliases,$smiles,$inchikey]);
			$cpdhash->{$sbmlid} = {
				id => $sbmlid,
				rootid => $id,
				name => $name,
				formula => $formula,
				charge => $charge,
				aliases => $aliases,
				compartment => $compartment,
				boundary => $boundary
			};
		}
		#Parsing reactions
		my $rxns = [$doc->getElementsByTagName("reaction")];
		my $rxnhash = {};
		my $rxncount = 0;
		foreach my $rxn (@$rxns){
			my $id = undef;
			my $sbmlid = undef;
			my $name = undef;
			my $direction = "=";
			my $reactants = "";
			my $products = "";
			my $compartment = "c0";
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
					$id =~ s/__/!/g;
					while ($id =~ m/^([^\!]+)\!(\d+)\!(.*)/) {
						$id = $1.chr($2).$3;
					}
					$id =~ s/\!/__/g;
					# look for compartment suffix in reaction ID
					if ($id =~ m/_([a-z])(\d?)$/){
						$compartment = (length $2) ? $1.$2 : $1."0";
					}
					$original_rxn_ids->{$sbmlid} = $rxncount;
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
								#$spec =~ s/__/!/g;
								#while ($spec =~ m/^([^\!]+)\!(\d+)\!(.*)/) {
								#	$spec = $1.chr($2).$3;
								#}
								#$spec =~ s/\!/__/g;
								if (defined($cpdhash->{$spec})) {
									$boundary = $cpdhash->{$spec}->{boundary};
									my $cpt = $cpdhash->{$spec}->{compartment};
									$spec = $cpdhash->{$spec}->{rootid}."[".$cpdhash->{$spec}->{compartment}."]";
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
				} elsif ($node->getNodeName() eq "fbc:geneProductAssociation") {
					my $data = {
						gpr => "",
						current => undef
					};
					&process_nodes($node,$data);
					$gpr = $data->{gpr};
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
									if (defined($aliases) && length($aliases) > 0) {
										$aliases .= "|";
									}
									$aliases .= "BIOCYC:".$1;
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
			$rxncount++;
			push(@{$params->{reactions}},[$id,$direction,$compartment,$gpr,$name,$enzyme,$pathway,undef,$reactants." => ".$products,$aliases]);
		}
		my $geneproducts = [$doc->getElementsByTagName("fbc:geneProduct")];
		for (my $i=0; $i < @{$geneproducts}; $i++) {
			my $id;
			my $gid;
			foreach my $attr ($geneproducts->[$i]->getAttributes()->getValues()) {
				if ($attr->getName() eq "fbc:id") {
					$id = $attr->getValue();
				} elsif ($attr->getName() eq "fbc:label") {
					$gid = $attr->getValue();
				}
			}
			if (defined($id) && defined($gid)) {
				push(@{$genetranslation->{$id}},$gid);
			}
		}
	} else {
		for (my $i=0; $i < @{$params->{reactions}}; $i++) {
			$original_rxn_ids->{$params->{reactions}->[$i]->[0]} = $i;
		}
	}
	#print(Dumper($params->{compounds}));
	#print(Dumper($params->{reactions}));
	#ENSURING THAT THERE ARE REACTIONS AND COMPOUNDS FOR THE MODEL AT THIS STAGE
	if (!defined($params->{compounds}) || @{$params->{compounds}} == 0) {
		Bio::KBase::utilities::error("Must have compounds for model!");
	}
	if (!defined($params->{reactions}) || @{$params->{reactions}} == 0) {
		Bio::KBase::utilities::error("Must have reactions for model!");
	}
	#PARSING BIOMASS ARRAY IF ITS NOT ALREADY AN ARRAY
	if (ref($params->{biomass}) ne 'ARRAY') {
		$params->{biomass} = [split(/;/,$params->{biomass})];
	}
	my %reaction_ids=map{$_->[0] =>1} @{$params->{reactions}};
	# Strip "R_" if present in the biomass id
	my @missing=grep(!defined($reaction_ids{$_ =~ s/R_//r}), @{$params->{biomass}});
	if (@missing) {
		print "Specified biomass reaction not in reaction list:\t$_\n" foreach (@missing);
		Bio::KBase::utilities::error("Could not resolve one or more biomass reactions");
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
	$model->parent($handler->util_store());
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
		if ($rxn->[0] =~ m/(.+)_[abcdefghijklmnopqrstuvwxyz]\d+$/) {
			$rxn->[0] = $1;
		}
		$rxn->[0] =~ s/[^\w]/_/g;
		$rxn->[0] =~ s/_/-/g;
		if (defined($rxn->[8])) {
			if ($rxn->[8] =~ m/^\[([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz])\]\s*:\s*(.+)/) {
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
					my $search = " ".$cpd." ";
					my $array = [split(/\Q$search/,$eqn)];
					$eqn = join(" ".$translation->{$origcpd}." ",@{$array});
					$search = " ".$cpd."[";
					$array = [split(/\Q$search/,$eqn)];
					$eqn = join(" ".$translation->{$origcpd}."[",@{$array});
				}
			}
			$eqn =~ s/^\|\s//;
			$eqn =~ s/\s\|$//;
			while ($eqn =~ m/\[([ABCDEFGHIJKLMNOPQRSTUVWXYZ])\]/) {
				my $reqplace = "[".lc($1)."]";
				$eqn =~ s/\[[ABCDEFGHIJKLMNOPQRSTUVWXYZ]\]/$reqplace/;
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
	print("Processing Biomass equations\n");
	my $excludehash = {};
	for (my $i=0; $i < @{$params->{biomass}}; $i++) {
		if (defined($original_rxn_ids->{$params->{biomass}->[$i]})) {
			$params->{biomass}->[$i] = $params->{reactions}->[$original_rxn_ids->{$params->{biomass}->[$i]}]->[8];
			$excludehash->{$original_rxn_ids->{$params->{biomass}->[$i]}} = 1;
		} elsif (defined($original_rxn_ids->{"R_".$params->{biomass}->[$i]})) {
			$params->{biomass}->[$i] = $params->{reactions}->[$original_rxn_ids->{"R_".$params->{biomass}->[$i]}]->[8];
			$excludehash->{$original_rxn_ids->{"R_".$params->{biomass}->[$i]}} = 1;
		}
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
	print("Adding Reactions");
	for (my  $i=0; $i < @{$params->{reactions}}; $i++) {
		if (defined($excludehash->{$i})) {
			next;
		}
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
		if (defined($genetranslation)) {
			$input->{genetranslation} = $genetranslation;
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
		if (@{$rgts} == 1 && ($rgts->[0]->modelcompound()->id() =~ m/_e\d+$/ || $rgts->[0]->modelcompound()->id() =~ m/cpd08636_c0/ || $rgts->[0]->modelcompound()->id() =~ m/cpd15302_c0/ || $rgts->[0]->modelcompound()->id() =~ m/cpd11416_c0/)) {
			Bio::KBase::utilities::log("Removing reaction:".$rxn->definition(),"debugging");
			$model->remove("modelreactions",$rxn);
		}	
	}
	for (my $i=0; $i < @{$params->{biomass}}; $i++) {
		Bio::KBase::utilities::log("Biomass:".$params->{biomass}->[$i],"debugging");
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
		Bio::KBase::utilities::log("Missing genes:\n".join("\n",keys(%{$model->{missinggenes}}))."\n");
	}
	my $wsmeta = $handler->util_save_object($model,$params->{workspace_name}."/".$params->{model_name},{type => "KBaseFBA.FBAModel"});
	Bio::KBase::utilities::log("Saved new FBA Model to: ".$params->{workspace_name}."/".$params->{model_name}."\n");
	return { ref => util_get_ref($wsmeta) };
}

sub func_export {
	my ($params,$args) = @_;
	$params = Bio::KBase::utilities::args($params,[],{
		save_to_shock => 0
	});
	$args = Bio::KBase::utilities::args($args,["format","object"],{
		file_util => 0,
		path => Bio::KBase::utilities::conf("fba_tools","scratch")
	});
	my $ref;
	if ($args->{file_util} == 1 && !defined $params->{input_ref}) {
		$ref = $params->{workspace_name}."/";
		if ($args->{object} eq "phenosim") {
			$ref .= $params->{phenotype_simulation_set_name};
		} elsif ($args->{object} eq "phenotype") {
			$ref .= $params->{phenotype_set_name};
		} else {
			$ref .= $params->{$args->{object}."_name"};
		}
	} else {
		$ref = $params->{input_ref};
	}
	my $export_dir = $args->{path};
	my $object = $handler->util_get_object($ref,{});
	if ($args->{file_util} == 0) {
		$export_dir .= "/".$object->_wsname();
		File::Path::mkpath ($export_dir);
	}
	my $files = $object->export({format => $args->{format},file => 1,path => $export_dir});
	if ($args->{file_util} == 1) {
		if ($params->{save_to_shock} == 1) {
			if ($args->{format} eq "tsv" && ($args->{object} eq "model" || $args->{object} eq "fba")) {
				my $output;
				$output->[0] = $handler->util_file_to_shock({
					file_path=>$files->[0],
					gzip=>0,
					make_handle=>0
				});
				$output->[1] = $handler->util_file_to_shock({
					file_path=>$files->[1],
					gzip=>0,
					make_handle=>0
				});
				return {
					compounds_file => {shock_id => $output->[0]->{shock_id}},
					reactions_file => {shock_id => $output->[1]->{shock_id}}
				};
			} else {
				my $output = $handler->util_file_to_shock({
					file_path=>$files->[0],
					gzip=>0,
					make_handle=>0
				});
				return {
					shock_id => $output->{shock_id}
				};
			}
		} else {
			if ($args->{format} eq "tsv" && ($args->{object} eq "model" || $args->{object} eq "fba")) {
				return {
					compounds_file => {path => $files->[0]},
					reactions_file => {path => $files->[1]}
				};
			} else {
				return {
					path => $files->[0]
				};
			}
		}
	} else {
		return $handler->util_package_for_download({ 
			file_path => $export_dir,
			ws_refs   => [ $params->{input_ref} ]
		});	
	}
}

sub func_bulk_export {
	my ($params,$args) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace"],{
		refs => [],
		all_models => 0,
		all_fba => 0,
		all_media => 0,
		all_phenotypes => 0,
		all_phenosims => 0,
		model_format => "sbml",
		fba_format => "tsv",
		media_format => "tsv",
		phenotype_format => "tsv",
		phenosim_format => "tsv",
	});
	my $translation = {
		"KBaseFBA.FBA" => "fba",
		"KBaseBiochem.Media" => "media",
		"KBasePhenotypes.PhenotypeSet" => "phenotype",
		"KBasePhenotypes.PhenotypeSimulationSet" => "phenosim",
		"KBaseFBA.FBAModel" => "model"
	};
	my $hash = {};
	for (my $i=0; $i < @{$params->{refs}}; $i++) {
		$hash->{$params->{refs}->[$i]} = 1;
	}
	my $input;
	if ($params->{workspace} =~ m/^\d+$/) {
		$input->{ids} = [$params->{workspace}];
	} else {
		$input->{workspaces} = [$params->{workspace}];
	}
	my $typehash = {
		all_models => "KBaseFBA.FBAModel",
		all_fba => "KBaseFBA.FBA",
		all_media => "KBaseBiochem.Media",
		all_phenotypes => "KBasePhenotypes.PhenotypeSet",
		all_phenosims => "KBasePhenotypes.PhenotypeSimulationSet"
	};
	foreach my $field (keys(%{$typehash})) {
		if ($params->{$field} == 1) {
			$input->{type} = $typehash->{$field};
			my $objects = $handler->util_list_objects($input);
			for (my $i=0; $i < @{$objects}; $i++) {
				$hash->{$objects->[$i]->[6]."/".$objects->[$i]->[0]."/".$objects->[$i]->[4]} = 1;
			}
		}
	}
	
	my $export_dir = Bio::KBase::utilities::conf("fba_tools","scratch")."/model_objects";
	if (-d $export_dir) {
		File::Path::rmtree ($export_dir);
	}
	File::Path::mkpath ($export_dir);
	my $count = keys(%{$hash});
	foreach my $item (keys(%{$hash})) {
		my $object = $handler->util_get_object($item,{});
		my $input = {workspace_name => $params->{workspace}};
		if ($translation->{$object->_type()} eq "phenosim") {
			$input->{phenotype_simulation_set_name} = $object->_wsname();
		} elsif ($translation->{$object->_type()} eq "phenotype") {
			$input->{phenotype_set_name} = $object->_wsname();
		} else {
			$input->{$translation->{$object->_type()}."_name"} = $object->_wsname();
		}
		func_export($input,{
			file_util => 1,
			format => $params->{$translation->{$object->_type()}."_format"},
			object => $translation->{$object->_type()},
			path => $export_dir
		});
	}
	chdir(Bio::KBase::utilities::conf("fba_tools","scratch"));
	system("tar -czf model_objects.tgz model_objects");
	return {
		name => "model_objects.tgz",
		description => "Zip archive of ".$count." model objects.",
		path => Bio::KBase::utilities::conf("fba_tools","scratch")."/model_objects.tgz"
	};
}

sub process_nodes {
	my ($node,$data) = @_;
	my $current = $data->{current};
	if (!defined($current)) {
		$current = "or";
	}
	my $first = 0;
	my @newnode = $node->getElementsByTagName("fbc:and",0);
	if (defined($newnode[0])) {
		for (my $j=0; $j < @newnode; $j++) {
			my $newdata = {
				gpr => "",
				current => "and"
			};
			&process_nodes($newnode[$j],$newdata);
			if ($first == 0) {
				$first = 1;
			} else {
				$data->{gpr} .= " ".$current." ";
			}
			$data->{gpr} .= "(".$newdata->{gpr}.")";
		}
	}
	@newnode = $node->getElementsByTagName("fbc:or",0);
	if (defined($newnode[0])) {
		for (my $j=0; $j < @newnode; $j++) {
			my $newdata = {
				gpr => "",
				current => "or"
			};
			&process_nodes($newnode[$j],$newdata);
			if ($first == 0) {
				$first = 1;
			} else {
				$data->{gpr} .= " ".$current." ";
			}
			$data->{gpr} .= "(".$newdata->{gpr}.")";
		}
	}
	@newnode = $node->getElementsByTagName("fbc:geneProductRef",0);
	if (defined($newnode[0])) {
		my $genes = [];
		for (my $j=0; $j < @newnode; $j++) {
			foreach my $attr ($newnode[$j]->getAttributes()->getValues()) {
				if ($attr->getName() eq "fbc:geneProduct") {
					push(@{$genes},$attr->getValue());
				}	
			}
		}
		if ($first == 1) {
			$data->{gpr} .= " ".$current." ";
		}
		$data->{gpr} .= join(" ".$current." ",@{$genes});
	}
}

1;
