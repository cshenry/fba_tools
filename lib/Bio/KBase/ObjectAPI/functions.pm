package Bio::KBase::ObjectAPI::functions;
use strict;
use warnings;
use POSIX;
use Data::Dumper::Concise;
use Data::UUID;
use Bio::KBase::utilities;
use Bio::KBase::constants;
use XML::DOM;
use Bio::KBase::Templater qw( render_template );

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
	return $handler->util_store()->get_ref_from_metadata($metadata);
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
	my ($params) = @_;
	$params = Bio::KBase::ObjectAPI::utilities::args(["model","media","fba_output_id"],{
		mediaset => undef,
		metabolite_matrix => undef,
		exometabolite_matrix => undef,
		expression_matrix => undef,
		probanno => undef,
		source_model => undef,

		target_reaction => "bio1",
		thermodynamic_constraints => 0,
		fva => 0,
		minimize_flux => 0,
		simulate_ko => 0,
		find_min_media => 0,
		all_reversible => 0,
		add_external_reactions => 0,
		gapfilling => 0,
		reaction_addition_study => 0,
		sensitivity_analysis => 0,
		metabolite_production_analysis => 0,
		metabolite_consumption_analysis => 0,
		predict_community_composition => 0,
		compute_characteristic_flux => 0,
		steady_state_protein_fba => 0,
		dynamic_fba => 0,
		atp_production_check => 1,

		media_id_list => [],
		feature_ko_list => [],
		reaction_ko_list => [],
		custom_bound_list => [],
		media_supplement_list => [],
		source_metabolite_list => [],
		target_metabolite_list => [],
		reaction_list => [],#For reaction addition analysis
		kcat_hash => undef,
		proteomics_hash => undef,
		concentrations => undef,
		turnovers => undef,
		kprimes => undef,
		kmvalues => undef,

		expression_condition => undef,
		metabolite_condition => undef,
		exometabolite_condition => undef,
		characteristic_flux_file => undef,
		input_gene_parameter_file => undef,
		input_reaction_parameter_file => undef,

		omega => 0,
		activation_coefficient => 0,
		exp_threshold_margin => 0.5,
		number_of_solutions => 1,
		objective_fraction => 0.1,
		default_max_uptake => 0,
		reduce_objective => 0,
		max_objective => 0,
		min_objective => 0,
		max_objective_limit => 1.2,
		max_c_uptake => undef,
		max_n_uptake => undef,
		max_p_uptake => undef,
		max_s_uptake => undef,
		max_o_uptake => undef,
		minimum_target_flux => 0.1,
		protein_limit => 500,
		protein_prod_limit => 500,
		time_step => 1,
		stop_time => 86400,
		initial_biomass => 0.001,
		volume => 1,
		protein_formulation => 0,
		fraction_metabolism => 0.5,
		default_turnover => 0.034537,
		default_kprime => 5,
		default_km => 0.0001,
		default_protein_sequence => "MSSMTTTDNKAFLNELARLVGSSHLLTDPAKTARYRKGFRSGQGDALAVVFPGSLLELWRVLKACVTADKIILMQAANTGLTEGSTPNGNDYDRDVVIISTLRLDKLHVLGKGEQVLAYPGTTLYSLEKALKPLGREPHSVIGSSCIGASVIGGICNNSGGSLVQRGPAYTEMSLFARINEDGKLTLVNHLGIDLGETPEQILSKLDDDRIKDDDVRHDGRHAHDYDYVHRVRDIEADTPARYNADPDRLFESSGCAGKLAVFAVRLDTFEAEKNQQVFYIGTNQPEVLTEIRRHILANFENLPVAGEYMHRDIYDIAEKYGKDTFLMIDKLGTDKMPFFFNLKGRTDAMLEKVKFFRPHFTDRAMQKFGHLFPSHLPPRMKNWRDKYEHHLLLKMAGDGVGEAKSWLVDYFKQAEGDFFVCTPEEGSKAFLHRFAAAGAAIRYQAVHSDEVEDILALDIALRRNDTEWYEHLPPEIDSQLVHKLYYGHFMCYVFHQDYIVKKGVDVHALKEQMLELLQQRGAQYPAEHNVGHLYKAPETLQKFYRENDPTNSMNPGIGKTSKRKNWQEVE",

		notes => undef,
	}, $params);

	#Making sure reaction KO list is an array
	if (defined($params->{reaction_ko_list}) && ref($params->{reaction_ko_list}) ne "ARRAY") {
		if (length($params->{reaction_ko_list}) > 0) {
			$params->{reaction_ko_list} = [split(/,/,$params->{reaction_ko_list})];
		} else {
			 $params->{reaction_ko_list} = [];
		}
	}
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
	my $genenum = $params->{model}->gene_count();
	if ($genenum == 0) {
		$genenum = 1;
	}
	my $fbaobj = Bio::KBase::ObjectAPI::KBaseFBA::FBA->new({
		id => $params->{fba_output_id},
		fva => $params->{fva},
		fluxMinimization => $params->{minimize_flux},
		findMinimalMedia => $params->{find_min_media},
		allReversible => $params->{all_reversible},
		simpleThermoConstraints => $params->{thermodynamic_constraints},
		thermodynamicConstraints => $params->{thermodynamic_constraints},
		noErrorThermodynamicConstraints => 0,
		minimizeErrorThermodynamicConstraints => 0,
		maximizeObjective => 1,
		compoundflux_objterms => {},reactionflux_objterms => {},biomassflux_objterms => {},
		comboDeletions => $params->{simulate_ko},
		numberOfSolutions => $params->{number_of_solutions},
		objectiveConstraintFraction => $params->{objective_fraction},
		defaultMaxFlux => 1000,
		defaultMaxDrainFlux => $params->{default_max_uptake},
		defaultMinDrainFlux => -1000,
		decomposeReversibleFlux => 0,
		decomposeReversibleDrainFlux => 0,
		fluxUseVariables => 0,
		drainfluxUseVariables => 0,
		fbamodel => $params->{model},
		fbamodel_ref => $params->{model}->_reference(),
		media => $params->{media},
		media_ref => $params->{media}->_reference(),
		geneKO_refs => [],
		reactionKO_refs => [],
		additionalCpd_refs => [],
		uptakeLimits => $uptakelimits,
		parameters => {
			minimum_target_flux => $params->{minimum_target_flux},
			custom_bound_list => $params->{custom_bound_list},
			target_reaction => $params->{target_reaction},
			"run dynamic FBA" => $params->{dynamic_fba},
			"Protein limit" => $params->{protein_limit},
			"Protein prod limit" => $params->{protein_prod_limit},
			"Time step" => $params->{time_step},
			"Stop time" => $params->{stop_time},
			"Initial biomass" => $params->{initial_biomass},
			"Volume" => $params->{volume},
			"protein formulation" => $params->{protein_formulation},
			"save phenotype simulation fluxes" => $params->{save_fluxes},
			"MFASolver" => $params->{MFASolver},
			"Perform auxotrophy analysis" => $params->{predict_auxotrophy},
			"steady state community modeling" => $params->{predict_community_composition},
			"Compute characteristic fluxes" => $params->{compute_characteristic_flux},
			"characteristic flux file" => $params->{characteristic_flux_file},
			"steady state protein fba" => $params->{steady_state_protein_fba},
			"reduce objective" => $params->{reduce_objective},
			"max objective" => $params->{max_objective},
			"min objective" => $params->{min_objective},
			"reaction addition study" => $params->{reaction_addition_study},
			"max objective limit" => $params->{max_objective_limit},
			"adding reaction list" => join(";",@{$params->{reaction_list}}),
			"Source metabolite list" => join(";",@{$params->{source_metabolite_list}}),
			"Target metabolite list" => join(";",@{$params->{target_metabolite_list}}),
			"Metabolite production analysis" => $params->{metabolite_production_analysis},
			"Metabolite consumption analysis" => $params->{metabolite_consumption_analysis},
			default_kprime => $params->{default_kprime},
			default_turnover => $params->{default_turnover},
			default_km => $params->{default_km},
			default_protein_sequence => $params->{default_protein_sequence},
			default_concentration => $params->{fraction_metabolism}*$params->{protein_limit}/$genenum,
			"ATP check gapfilling solutions" => $params->{atp_production_check}
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
		ExpressionAlpha => $params->{activation_coefficient},
		ExpressionOmega => $params->{omega},
		ExpressionKappa => $params->{exp_threshold_margin},
		calculateReactionKnockoutSensitivity => $params->{sensitivity_analysis}
	});
	if (defined($params->{media_id_list})) {
		if (ref($params->{media_id_list}) ne 'ARRAY') {
			$params->{media_id_list} = [split(/[\n;\|]+/,$params->{media_id_list})];
		}
		for (my $i=0; $i < @{$params->{media_id_list}}; $i++) {
			my $currref = $params->{media_id_list}->[$i];
			if ($currref !~ m/\//) {
				$currref = $params->{media_workspace}."/".$currref;
			}
			push(@{$fbaobj->media_list_refs()},$currref);
		}
	}
	if (defined($params->{kcat_hash})) {
		$fbaobj->parameters()->{kcat_hash} = "";
		foreach my $id (keys(%{$params->{kcat_hash}})) {
			if (length($fbaobj->parameters()->{kcat_hash}) > 0) {
				$fbaobj->parameters()->{kcat_hash} .= ";";
			}
			$fbaobj->parameters()->{kcat_hash} .= $id.":".$params->{kcat_hash}->{$id};
		}
	}
	if (defined($params->{proteomics_hash})) {
		$fbaobj->parameters()->{proteomics_hash} = "";
		foreach my $id (keys(%{$params->{proteomics_hash}})) {
			if (length($fbaobj->parameters()->{proteomics_hash}) > 0) {
				$fbaobj->parameters()->{proteomics_hash} .= ";";
			}
			$fbaobj->parameters()->{proteomics_hash} .= $id.":".$params->{proteomics_hash}->{$id};
		}
	}
	$fbaobj->parent($handler->util_store());

	my $bio = $params->{model}->getObject("biomasses",$params->{target_reaction});
	if (defined($bio)) {
		$fbaobj->biomassflux_objterms()->{$bio->id()} = 1;
	} else {
		my $rxn = $params->{model}->getObject("modelreactions",$params->{target_reaction});
		if (defined($rxn)) {
			$fbaobj->reactionflux_objterms()->{$rxn->id()} = 1;
		} else {
			my $cpd = $params->{model}->getObject("modelcompounds",$params->{target_reaction});
			if (defined($cpd)) {
				$fbaobj->compoundflux_objterms()->{$cpd->id()} = 1;
			} else {
				Bio::KBase::utilities::error("Could not find biomass objective object:".$params->{target_reaction});
			}
		}
	}
	if (defined($params->{model}->genome_ref())) {
		my $genome = $params->{model}->genome();
		foreach my $gene (@{$params->{feature_ko_list}}) {
			my $geneObj = $genome->searchForFeature($gene);
			if (defined($geneObj)) {
				$fbaobj->addLinkArrayItem("geneKOs",$geneObj);
			}
		}
	}
	foreach my $reaction (@{$params->{reaction_ko_list}}) {
		my $rxnObj = $params->{model}->searchForReaction($reaction);
		if (defined($rxnObj)) {
			$fbaobj->addLinkArrayItem("reactionKOs",$rxnObj);
		}
	}
	foreach my $compound (@{$params->{media_supplement_list}}) {
		my $cpdObj = $params->{model}->searchForCompound($compound);
		if (defined($cpdObj)) {
			$fbaobj->addLinkArrayItem("additionalCpds",$cpdObj);
		}
	}
	for (my $i=0; $i < @{$params->{custom_bound_list}}; $i++) {
		my $array = [split(/[\<;]/,$params->{custom_bound_list}->[$i])];
		my $rxn = $params->{model}->searchForReaction($array->[1]);
		if (defined($rxn)) {
			$fbaobj->add("FBAReactionBounds",{
				modelreaction_ref => $rxn->_reference(),
				variableType => "flux",
				upperBound => $array->[2]+0,
				lowerBound => $array->[0]+0
			});
		} else {
			my $cpd = $params->{model}->searchForCompound($array->[1]);
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
	if (defined($params->{probanno})) {
		$fbaobj->{parameters}->{"Objective coefficient file"} = "ProbModelReactionCoefficients.txt";
		$fbaobj->{inputfiles}->{"ProbModelReactionCoefficients.txt"} = [];
		my $rxncosts = {};
		foreach my $rxn (@{$params->{probanno}->{reaction_probabilities}}) {
			$rxncosts->{$rxn->[0]} = (1-$rxn->[1]); # ID is first element, likelihood is second element
		}
		foreach my $rxn (keys(%{$rxncosts})) {
			push(@{$fbaobj->{inputfiles}->{"ProbModelReactionCoefficients.txt"}},"forward\t".$rxn."\t".$rxncosts->{$rxn});
			push(@{$fbaobj->{inputfiles}->{"ProbModelReactionCoefficients.txt"}},"reverse\t".$rxn."\t".$rxncosts->{$rxn});
		}
		$handler->util_log("Added reaction coefficients from reaction likelihoods");
 	}
	if ($params->{gapfilling} == 1) {
		my $input = {
			integrate_gapfilling_solution => 1,
			minimum_target_flux => $params->{minimum_target_flux},
			target_reactions => [],#?
			completeGapfill => 0,#?
			fastgapfill => 1,
			alpha => $params->{activation_coefficient},
			omega => $params->{omega},
			num_solutions => $params->{number_of_solutions},
			add_external_rxns => $params->{add_external_rxns},
			make_model_rxns_reversible => $params->{all_reversible},
			activate_all_model_reactions => $params->{comprehensive_gapfill},
		};
		if (defined($params->{blacklist})) {
			$input->{blacklistedrxns} = $params->{blacklist};
		}
		if (defined($params->{source_model})) {
			$input->{source_model} = $params->{source_model};
		}
		$fbaobj->PrepareForGapfilling($input);
	}

	if (defined($params->{expression_matrix})) {
		#$exphash = util_build_expression_hash($exp_matrix,$params->{expression_condition});
		$fbaobj->process_expression_data({
			object => $params->{expression_matrix},
			condition => $params->{expression_condition}
		});
	}
	if (defined($params->{metabolite_matrix})) {
		$fbaobj->process_metabolomic_data({
			matrix => Bio::KBase::ObjectAPI::functions::process_matrix($params->{metabolite_matrix}),
			condition => $params->{metabolite_condition},
			type => "logp"
		});
	} elsif (defined($params->{metabolite_ref}) && -e $params->{metabolite_ref}) {
		$fbaobj->process_metabolomic_data({
			matrix => Bio::KBase::ObjectAPI::functions::load_matrix($params->{metabolite_ref}),
			condition => $params->{metabolite_condition},
			type => "logp"
		});
	} elsif (defined($params->{metabolite_peak_string})) {
		$fbaobj->parameters()->{"Intrametabolite peak data"} = $params->{metabolite_peak_string};
	}
	if (defined($params->{exometabolite_matrix})) {
		$fbaobj->process_metabolomic_data({
			matrix => Bio::KBase::ObjectAPI::functions::process_matrix($params->{exometabolite_matrix}),
			condition => $params->{exometabolite_condition},
			type => "exo"
		});
	} elsif (defined($params->{exometabolite_ref}) && -e $params->{exometabolite_ref}) {
		$fbaobj->process_metabolomic_data({
			matrix => Bio::KBase::ObjectAPI::functions::load_matrix($params->{exometabolite_ref}),
			condition => $params->{exometabolite_condition},
			type => "exo"
		});
	} elsif (defined($params->{exometabolite_peak_string})) {
		$fbaobj->parameters()->{"Exometabolite peak data"} = $params->{exometabolite_peak_string};
	}

	if (defined($params->{input_gene_parameter_file})) {
		my $file = Bio::KBase::ObjectAPI::utilities::LOADFILE($params->{input_gene_parameter_file});
		my $headers = [split(/\t/,$file->[0])];
		$fbaobj->parameters()->{genes_kprime} = "";
		$fbaobj->parameters()->{genes_kmcpd} = "";
		$fbaobj->parameters()->{genes_concentration} = "";
		$fbaobj->parameters()->{genes_turnover} = "";
		$fbaobj->parameters()->{genes_target_fraction} = "";
		for (my $i=1; $i < @{$file}; $i++) {
			my $array = [split(/\t/,$file->[$i])];
			for (my $j=1; $j < @{$headers}; $j++) {
				if ($headers->[$j] eq "kprime") {
					$fbaobj->parameters()->{genes_kprime} .= $array->[0].":".$array->[$j].";";
				} elsif ($headers->[$j] eq "kmcpd") {
					$fbaobj->parameters()->{genes_kmcpd} .= $array->[0].":".$array->[$j].";";
				} elsif ($headers->[$j] eq "concentration") {
					$fbaobj->parameters()->{genes_concentration} .= $array->[0].":".$array->[$j].";";
				} elsif ($headers->[$j] eq "turnover") {
					$fbaobj->parameters()->{genes_turnover} .= $array->[0].":".$array->[$j].";";
				} elsif ($headers->[$j] eq "target_fraction") {
					$fbaobj->parameters()->{genes_target_fraction} .= $array->[0].":".$array->[$j].";";
				}
			}
		}
	}
	if (defined($params->{input_reaction_parameter_file})) {
		my $file = Bio::KBase::ObjectAPI::utilities::LOADFILE($params->{input_reaction_parameter_file});
		my $headers = [split(/\t/,$file->[0])];
		$fbaobj->parameters()->{reactions_kprime} = "";
		$fbaobj->parameters()->{reactions_kmcpd} = "";
		$fbaobj->parameters()->{reactions_concentration} = "";
		$fbaobj->parameters()->{reactions_turnover} = "";
		$fbaobj->parameters()->{reactions_target_kprime} = "";
		for (my $i=1; $i < @{$file}; $i++) {
			my $array = [split(/\t/,$file->[$i])];
			for (my $j=1; $j < @{$headers}; $j++) {
				if ($headers->[$j] eq "kprime") {
					$fbaobj->parameters()->{reactions_kprime} .= $array->[0].":".$array->[$j].";";
				} elsif ($headers->[$j] eq "kmcpd") {
					$fbaobj->parameters()->{reactions_kmcpd} .= $array->[0].":".$array->[$j].";";
				} elsif ($headers->[$j] eq "concentration") {
					$fbaobj->parameters()->{reactions_concentration} .= $array->[0].":".$array->[$j].";";
				} elsif ($headers->[$j] eq "turnover") {
					$fbaobj->parameters()->{reactions_turnover} .= $array->[0].":".$array->[$j].";";
				} elsif ($headers->[$j] eq "target_kprime") {
					$fbaobj->parameters()->{reactions_target_kprime} .= $array->[0].":".$array->[$j].";";
				}
			}
		}
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

sub add_auxotrophy_transporters {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["fbamodel"],{
		compartment_index => 0
	});
	my $transporthash = Bio::KBase::constants::auxotrophy_transports();
	foreach my $rxn (keys(%{$transporthash})) {
		if (!defined($params->{fbamodel}->queryObject("modelreactions",{id => $rxn."_c".$params->{compartment_index}}))) {
			$params->{fbamodel}->addModelReaction({
				reaction => $rxn,
				direction => "=",
				addReaction => 1
			});
		}
	}
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
		number_of_solutions => 1,
		max_objective_limit => 1.2,
		predict_auxotrophy => 0,
		mode => "new",
		anaerobe => 0,
		use_annotated_functions => 1,
		merge_all_annotations => 0,
		source_ontology_list => [],
		add_auxotrophy_transporters => 1
	});
	#Making sure reaction KO list is an array
	if (defined($params->{source_ontology_list}) && ref($params->{source_ontology_list}) ne "ARRAY") {
		if (length($params->{source_ontology_list}) > 0) {
			$params->{source_ontology_list} = [split(/,/,$params->{source_ontology_list})];
		} else {
			 $params->{source_ontology_list} = [];
		}
	}
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
	#Organizing annotation source array
	if ($params->{source_ontology_list} eq "") {
		$params->{source_ontology_list} = [];
	}
	my $anno_sources = [];
	if ($params->{use_annotated_functions} == 1) {
		$anno_sources = ["_FUNCTION_"];
	}
	if (@{$params->{source_ontology_list}} == 0) {
		push(@{$anno_sources},"_SEED_");
	}
	for (my $i=0; $i < @{$params->{source_ontology_list}};$i++) {
		push(@{$anno_sources},$params->{source_ontology_list}->[$i]);
	}
	#Pulling annotation hashes from genome
	my $annotation_hash = $genome->build_annotation_hashes({
		template => $template,
		annotation_sources => $anno_sources,
		merge => $params->{merge_all_annotations}
	});
	#Building model with classic template
	my $mdl = $template->NewBuildModel({
		modelid => $params->{fbamodel_output_id},
		function_hash => $annotation_hash->{function_hash},
		reaction_hash => $annotation_hash->{reaction_hash},
		no_features => 0,
		genome => $genome
	});
	#Adding transport reactions
	if ($params->{add_auxotrophy_transporters} == 1) {
		Bio::KBase::ObjectAPI::functions::add_auxotrophy_transporters({fbamodel => $mdl});
	}
	#Creating HTML report
	my $htmlreport = Bio::KBase::utilities::style()."<div style=\"height: 200px; overflow-y: scroll;\"><p>A new draft genome-scale metabolic model was constructed based on the annotations in the genome ".$params->{genome_id}.".";
	if ($params->{mode} eq "new") {
		my $output = $mdl->EnsureProperATPProduction({
			anaerobe => $params->{anaerobe},
			max_objective_limit => $params->{max_objective_limit}
		});
		#Predicting auxotrophy
		if ($params->{predict_auxotrophy} == 1) {
			$datachannel->{fbamodel} = $mdl->cloneObject();
			Bio::KBase::ObjectAPI::functions::func_predict_auxotrophy_from_model({
				workspace => "NULL",
				fbamodel_id => $params->{fbamodel_output_id}
			},$datachannel);
			my $wsmeta = $handler->util_save_object($datachannel->{media},$params->{workspace}."/".$params->{fbamodel_output_id}.".auxo_media");
			$params->{media_id} = $params->{fbamodel_output_id}.".auxo_media";
			$params->{media_workspace} = $params->{workspace}
		}
	}
	#Gapfilling model if requested
	my $output = {};
	if ($params->{gapfill_model} == 1) {
		$output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
			target_reaction => "bio1",
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
			atp_production_check => 1
		},{fbamodel => $mdl});
		$htmlreport .= $output->{html_report}." Model was saved with the name ".$params->{fbamodel_output_id}.". The final model includes ".@{$mdl->modelreactions()}." reactions, ".@{$mdl->modelcompounds()}." compounds, and ".$mdl->gene_count()." genes.</p>".Bio::KBase::utilities::gapfilling_html_table()."</div>";
	} else {
		#If not gapfilling, then we just save the model directly
		$output->{number_gapfilled_reactions} = 0;
		$output->{number_removed_biomass_compounds} = 0;
		$output->{new_fbamodel_ref} = Bio::KBase::utilities::buildref($params->{fbamodel_output_id},$params->{workspace});
		#print "\n\n".$fullmodel->toJSON()."\n\n";
		my $wsmeta = $handler->util_save_object($mdl,$output->{new_fbamodel_ref},{type => "KBaseFBA.FBAModel"});
		$htmlreport .= " No gapfilling was performed on the model. It is expected that the model will not be capable of producing biomass on any growth condition until gapfilling is run. Model was saved with the name ".$params->{fbamodel_output_id}.". The final model includes ".@{$mdl->modelreactions()}." reactions, ".@{$mdl->modelcompounds()}." compounds, and ".$mdl->gene_count()." genes.</p></div>"
	}
	$datachannel->{fbamodel} = $mdl;
	Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	return $output;
}

sub func_gapfill_metabolic_model {
	my ($params,$datachannel) = @_;
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
		blacklist => [],
		custom_bound_list => [],
		media_supplement_list => [],
		expseries_id => undef,
		expseries_workspace => $params->{workspace},
		expression_condition => undef,
		exometabolite_ref => undef,
		exometabolite_workspace => $params->{workspace},
		metabolite_ref => undef,
		metabolite_workspace => $params->{workspace},
		metabolite_condition => undef,
		exometabolite_condition => undef,
		exomedia_output_id => $params->{fbamodel_id}.".exomedia",
		exp_threshold_percentile => 0.5,
		exp_threshold_margin => 0.1,
		activation_coefficient => 0.5,
		omega => 0,
		objective_fraction => 0,
		minimum_target_flux => 0.1,
		number_of_solutions => 1,
		gapfill_output_id => undef,
		atp_production_check => 1,
		add_external_reactions => 1,
		metabolite_peak_string => undef
	});
	my $printreport = 1;
	my $htmlreport = "<html>";
	if (!defined($datachannel->{fbamodel})) {
		$handler->util_log("Retrieving model.");
		$datachannel->{fbamodel} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
		$htmlreport .= Bio::KBase::utilities::style()."<body><div style=\"height: 200px; overflow-y: scroll;\"><p>The genome-scale metabolic model ".$params->{fbamodel_id}." was gapfilled";
	} else {
		$printreport = 0;
		$htmlreport .= "<p>The model ".$params->{fbamodel_id}." was gapfilled";
	}
	if (defined($params->{probanno_id})) {
		$handler->util_log("Getting reaction likelihoods from ".$params->{probanno_id});
		$params->{probanno} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{probanno_id},$params->{probanno_workspace}));
	}
	if (defined($params->{exometabolite_ref}) && !-e $params->{exometabolite_ref}) {
		$params->{exometabolite_matrix} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{exometabolite_ref},$params->{exometabolite_workspace}));
	}
	if (defined($params->{metabolite_ref}) && !-e $params->{metabolite_ref}) {
		$params->{metabolite_matrix} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{metabolite_ref},$params->{metabolite_workspace}));
	}
	if (!defined($params->{media_id})) {
		if (defined($datachannel->{fbamodel}->genome_ref()) && length($datachannel->{fbamodel}->genome_ref()) > 0 && ($datachannel->{fbamodel}->genome()->domain() eq "Plant" || $datachannel->{fbamodel}->genome()->taxonomy() =~ /viridiplantae/i)) {
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
	if (defined($params->{source_fbamodel_id}) && !defined($datachannel->{source_model})) {
		$htmlreport .= " During the gapfilling, the source biochemistry database was augmented with all the reactions contained in the existing ".$params->{source_fbamodel_id}." model.";
		$datachannel->{source_model} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{source_fbamodel_id},$params->{source_fbamodel_workspace}));
	}
	my $gfs = $datachannel->{fbamodel}->gapfillings();
	my $currentid = 0;
	for (my $i=0; $i < @{$gfs}; $i++) {
		if ($gfs->[$i]->id() =~ m/gf\.(\d+)$/) {
			if ($1 >= $currentid) {
				$currentid = $1+1;
			}
		}
	}
	my $gfid = "gf.".$currentid;
	$params->{media} = $media;
	$params->{model} = $datachannel->{fbamodel};
	$params->{source_model} = $datachannel->{source_model};
	$params->{fba_output_id} = $params->{fbamodel_output_id}.".".$gfid;
	$params->{gapfilling} = 1;
	my $fba = Bio::KBase::ObjectAPI::functions::util_build_fba($params);
	$handler->util_log("Running flux balance analysis problem.");
	$fba->runFBA();
	#Error checking the FBA and gapfilling solution
	if (!defined($fba->gapfillingSolutions()->[0])) {
		$htmlreport .= "Analysis completed, but no valid solutions found. Check that you have a valid media formulation!</p>";
		if ($printreport == 1) {
			Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
		}
		return {
			html_report => $htmlreport
		};
	}
	my $gapfillnum = 0;
	if (defined($fba->gapfillingSolutions()->[0]->{gapfillingSolutionReactions})) {
		$gapfillnum = @{$fba->gapfillingSolutions()->[0]->{gapfillingSolutionReactions}};
	}
	$handler->util_log("Saving gapfilled model.");
	# If the model is saved in the workspace, add it to the genome reference path
	if ($datachannel->{fbamodel}->_reference() =~ m/^(\w+\/\w+\/\w+)/ && defined($datachannel->{fbamodel}->genome_ref()) && length($datachannel->{fbamodel}->genome_ref()) > 0) {
		$datachannel->{fbamodel}->genome_ref($datachannel->{fbamodel}->_reference() . ";" . $datachannel->{fbamodel}->genome_ref());
	}
	my $modelmeta = $handler->util_save_object($datachannel->{fbamodel},Bio::KBase::utilities::buildref($params->{fbamodel_output_id},$params->{workspace}),{type => "KBaseFBA.FBAModel"});
	$handler->util_log("Saving FBA object with gapfilling sensitivity analysis and flux.");
	$fba->fbamodel_ref($datachannel->{fbamodel}->_reference());
	if (defined($fba->outputfiles()->{MetabolomicsFittingResults})) {
		my $output = Bio::KBase::ObjectAPI::utilities::FROMJSON($fba->outputfiles()->{MetabolomicsFittingResults}->[0]);
		my $template_hash = {
			title=>"Metabolomics analysis results",gapfilltable => Bio::KBase::utilities::gapfilling_html_table(), tabone => "",tabtwo => "",divone => "",divtwo => "",exodata => "[]",intradata => "[]"
		};
		if (defined($output->{exo})) {
			$media = $handler->util_get_object(Bio::KBase::utilities::conf("ModelSEED","default_media_workspace")."/Carbon-D-Glucose");
			$media->id($params->{exomedia_output_id});
			$media->name($params->{exomedia_output_id});
			$media->source_id($params->{exomedia_output_id});
			my $mediacpds = $media->mediacompounds();
			my $mediahash = {};
			for (my $i=0; $i < @{$mediacpds}; $i++) {
				$mediahash->{$mediacpds->[$i]->compound()->id()} = $mediacpds->[$i];
			}
			my $exodata = [];
			my $peaklist = [sort(keys(%{$output->{exo}}))];
			for (my $i=0; $i < @{$peaklist}; $i++) {
				my $peakdata = $output->{exo}->{$peaklist->[$i]};
				push(@{$exodata},[$peaklist->[$i],$peakdata->{mass},$peakdata->{formula},join("<br>",@{$peakdata->{metabolite}}),$peakdata->{score},join(", ",@{$peakdata->{gapfillrxn}}),join(", ",@{$peakdata->{rxn}})]);
				for (my $j=0; $j < @{$peakdata->{metabolite}}; $j++) {
					my $baseid = $peakdata->{metabolite}->[$j];
					$baseid =~ s/_([a-z])\d+//;
					if ($1 ne "e") {
						my $equation = $baseid."_e0 => ".$baseid."_c0";
						if ($peakdata->{score} > 0) {
							$equation = $baseid."_c0 => ".$baseid."_e0";
						}
						$datachannel->{fbamodel}->addModelReaction({
							reaction => $baseid."-transport",
							equation => $equation,
							direction => ">",
							compartment => "c",
							compartmentIndex => 0,
							addReaction => 1,
							name => $baseid." transport"
						});
					}
					if (defined($mediahash->{$baseid})) {
						if ($peakdata->{score} > 0) {
							$mediahash->{$baseid}->maxFlux(-0.01);
							$mediahash->{$baseid}->minFlux(-100);
						} elsif ($peakdata->{score} < 0) {
							$mediahash->{$baseid}->maxFlux(100);
							$mediahash->{$baseid}->minFlux(0.01);
						}
					} else {
						if ($peakdata->{score} > 0) {
							$media->add("mediacompounds",{
								compound_ref => "kbase/default/compounds/id/".$baseid,
								concentration => 0.001,
								maxFlux => -0.01,
								minFlux => -100
							});
						} elsif ($peakdata->{score} < 0) {
							$media->add("mediacompounds",{
								compound_ref => "kbase/default/compounds/id/".$baseid,
								concentration => 0.001,
								maxFlux => 100,
								minFlux => 0.01
							});
						}
					}
				}
			}
			my $mediameta = $handler->util_save_object($media,Bio::KBase::utilities::buildref($params->{exomedia_output_id},$params->{workspace}));
			$template_hash->{exodata} = Bio::KBase::ObjectAPI::utilities::TOJSON($exodata);
			$template_hash->{tabone} = '<li class="active"><a href="#tab-table1" data-toggle="tab">Exometabolite results</a></li>';
			$template_hash->{divone} = '<div class="tab-pane active" id="tab-table1"><table id="example" class="display" width="100%"></table></div>';
		}
		if (defined($output->{met})) {
			my $metadata = [];
			$template_hash->{intradata} = Bio::KBase::ObjectAPI::utilities::TOJSON($metadata);
			$template_hash->{tabtwo} = '<li class="active"><a href="#tab-table2" data-toggle="tab">Intrametabolite results</a></li>';
			$template_hash->{divtwo} = '<div class="tab-pane active" id="tab-table2"><table id="example2" class="display" width="100%"></table></div>';
		}
		$htmlreport = Bio::KBase::utilities::build_report_from_template("ExometaboliteTemplate",$template_hash);
	} else {
		$htmlreport .= "</p>";
		if ($printreport == 1) {
			$htmlreport .= Bio::KBase::utilities::gapfilling_html_table()."</div></body></html>";
		}
	}
	$fba->fbamodel_ref($datachannel->{fbamodel}->_reference());
	if (!defined($params->{gapfill_output_id})) {
		$params->{gapfill_output_id} = $params->{fbamodel_output_id}.".".$gfid;
	}
	$fba->id($params->{gapfill_output_id});
	my $fbameta = $handler->util_save_object(
		$fba,
		Bio::KBase::utilities::buildref($params->{gapfill_output_id},
		$params->{workspace}),
		{type => "KBaseFBA.FBA", hidden => 1}
	);
	if ($printreport == 1) {
		Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	}
	my $output = {
		html_report => $htmlreport,
		new_fba_ref => util_get_ref($fbameta),
		new_fbamodel_ref => util_get_ref($modelmeta),
		number_gapfilled_reactions => $gapfillnum,
		number_removed_biomass_compounds => 0
	};
	if (defined($fba->parameters()->{growth})) {
		$output->{growth} = $fba->parameters()->{growth};
	}
	if (defined($fba->parameters()->{atpproduction})) {
		$output->{atpproduction} = $fba->parameters()->{atpproduction};
	}
	return $output;
}

sub func_catalogue_all_loops_in_model {
	my ($params,$model) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id"],{
		fbamodel_workspace => $params->{workspace},
		fbamodel_output_id => $params->{fbamodel_id},
		save_model => 1,
		print_report => 1,
		fba_output_id => $params->{fbamodel_id}.".loopfba"
	});
	if (!defined($model)) {
		$model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	my $media = $handler->util_get_object(Bio::KBase::utilities::buildref("Complete","KBaseMedia"));
	my $fba = util_build_fba($params,$model,$media,$params->{fba_output_id},0,0,undef);
	$fba->parameters()->{"catalogue flux loops"} = 1;
	$fba->runFBA();
	my $htmlreport = "";
	if (defined($fba->outputfiles()->{ExometaboliteOutput})) {
		my $output_rows = $fba->outputfiles()->{ExometaboliteOutput};
		my $loops = [];
		for (my $i=0; $i < @{$output_rows}; $i++) {
			$loops->[$i] = [split(/;/,$output_rows->[$i])];
		}
		$model->loops($loops);
	}
	if ($params->{save_model} == 1) {
		$handler->util_save_object($model,Bio::KBase::utilities::buildref($params->{fbamodel_output_id},$params->{workspace}),{type => "KBaseFBA.FBAModel"});
	}
	if ($params->{print_report} == 1) {
		Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	}
	my $output = {
		new_fbamodel => $model
	};
	return $output;
}

sub func_run_flux_balance_analysis {
	my ($params,$datachannel) = @_;
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
		sensitivity_analysis => 0,
		metabolite_production_analysis => 0,
		metabolite_consumption_analysis => 0,
		source_metabolite_list => [],
		target_metabolite_list => [],
		reduce_objective => 0,
		max_objective => 0,
		min_objective => 0,
		reaction_addition_study => 0,
		max_objective_limit => 1.2,
		reaction_list => [],
		predict_community_composition => 0,
		compute_characteristic_flux => 0,
		steady_state_protein_fba => 0,
		characteristic_flux_file => undef,
		kcat_hash => undef,
		proteomics_hash => undef,
		dynamic_fba => 0,
		protein_limit => 500,
		protein_prod_limit => 500,
		time_step => 1,
		stop_time => 86400,
		initial_biomass => 0.001,
		volume => 1,
		protein_formulation => 1,
		concentrations => {},
		turnovers => {},
		kprimes => {},
		kmvalues => {},
		fraction_metabolism => 0.5,
		default_turnover => 0.034537,
		default_kprime => 5,
		default_km => 0.0001,
		default_protein_sequence => "MSSMTTTDNKAFLNELARLVGSSHLLTDPAKTARYRKGFRSGQGDALAVVFPGSLLELWRVLKACVTADKIILMQAANTGLTEGSTPNGNDYDRDVVIISTLRLDKLHVLGKGEQVLAYPGTTLYSLEKALKPLGREPHSVIGSSCIGASVIGGICNNSGGSLVQRGPAYTEMSLFARINEDGKLTLVNHLGIDLGETPEQILSKLDDDRIKDDDVRHDGRHAHDYDYVHRVRDIEADTPARYNADPDRLFESSGCAGKLAVFAVRLDTFEAEKNQQVFYIGTNQPEVLTEIRRHILANFENLPVAGEYMHRDIYDIAEKYGKDTFLMIDKLGTDKMPFFFNLKGRTDAMLEKVKFFRPHFTDRAMQKFGHLFPSHLPPRMKNWRDKYEHHLLLKMAGDGVGEAKSWLVDYFKQAEGDFFVCTPEEGSKAFLHRFAAAGAAIRYQAVHSDEVEDILALDIALRRNDTEWYEHLPPEIDSQLVHKLYYGHFMCYVFHQDYIVKKGVDVHALKEQMLELLQQRGAQYPAEHNVGHLYKAPETLQKFYRENDPTNSMNPGIGKTSKRKNWQEVE",
		input_gene_parameter_file => undef,
		input_reaction_parameter_file => undef
	});
	my $model;
	if (defined($datachannel->{fbamodel})) {
		$model = $datachannel->{fbamodel};
	} else {
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
		$params->{mediaset} = $media;
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
	$params->{media} = $media;
	$params->{model} = $model;
	if (defined($params->{expseries_id})) {
		$params->{expression_matrix} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{expseries_id},$params->{expseries_workspace}));
	}
	my $fba = util_build_fba($params);
	if (defined($params->{mediaset_id})) {
		$fba->mediaset_ref($params->{mediaset_workspace}."/".$params->{mediaset_id});
	}
	#Running FBA
	$handler->util_log("Running flux balance analysis problem.");
	my $objective;
	#eval {
		local $SIG{ALRM} = sub { die "FBA timed out! Model likely contains numerical instability!" };
		alarm 86400;
		$objective = $fba->runFBA();
	#$fba->toJSON({pp => 1});
		alarm 0;
	#};
	if (!defined($objective)) {
		Bio::KBase::utilities::error("FBA failed with no solution returned!");
	}
	if ($params->{predict_community_composition} == 1) {
		Bio::KBase::utilities::print_report_message({message => "<p>Predict community compositions with varied flux coefficient</p><p>".join("<br>",@{$fba->outputfiles()->{SSCommunityFluxAnalysis}})."</p>",append => 1,html => 1});
	}
	$handler->util_log("Saving FBA results.");
	$fba->id($params->{fba_output_id});
	my $wsmeta = $handler->util_save_object($fba,Bio::KBase::utilities::buildref($params->{fba_output_id},$params->{workspace}),{type => "KBaseFBA.FBA"});
	$datachannel->{fba} = $fba;
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
		},{fbamodel => $model, source_model => $source_model});
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
	});
	if (!defined($model)) {
		$handler->util_log("Retrieving model.");
		$model = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	$params->{fbamodel_output_id} = $model->id().".phenogf";
	$handler->util_log("Retrieving phenotype set.");
	my $pheno = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{phenotypeset_id},$params->{phenotypeset_workspace}));
	if ( $params->{all_transporters} ) {
		$model->addPhenotypeTransporters({phenotypes => $pheno,positiveonly => 0});
	} elsif ( $params->{positive_transporters} ) {
		$model->addPhenotypeTransporters({phenotypes => $pheno,positiveonly => 1});
	}
	$handler->util_log("Retrieving ".$params->{media_id}." media.");
	$params->{default_max_uptake} = 100;
	my $media = $handler->util_get_object(Bio::KBase::utilities::conf("ModelSEED","default_media_workspace")."/Complete");
	$handler->util_log("Preparing flux balance analysis problem.");
	my $fba;
	$params->{model} = $model;
	$params->{media} = $media;
	$params->{fba_output_id} = $params->{phenotypesim_output_id}.".fba";
	if ($params->{gapfill_phenotypes} != 0 || $params->{fit_phenotype_data} != 0) {
		$params->{add_external_reactions} = 1,
		$params->{gapfilling} = 1,
	}
	$fba = Bio::KBase::ObjectAPI::functions::util_build_fba($params);
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
	my ($params,$datachannel) = @_;
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
		genome_ref => $model->genome_ref(),
		modelreactions => [],
		modelcompounds => [],
		modelcompartments => [],
		biomasses => [],
		gapgens => [],
		gapfillings => [],
	});
	$commdl->parent($handler->util_store());
	$datachannel->{fbamodel} = $commdl;
	$handler->util_log("Merging models.");
	$commdl->merge_models({
		models => $params->{fbamodel_id_list},
		mixed_bag_model => $params->{mixed_bag_model},
		fbamodel_output_id => $params->{fbamodel_output_id}
	});
	$handler->util_log("Saving model and combined genome.");
	my $wsmeta = $handler->util_save_object($commdl,$params->{workspace}."/".$params->{fbamodel_output_id},{type => "KBaseFBA.FBAModel"});
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
	my $media = $handler->util_get_object(Bio::KBase::utilities::conf("ModelSEED","default_media_workspace")."/Complete");
	$params->{fba_output_id} = $params->{fbamodel_id}.".cmb";
	$params->{media} = $media;
	$params->{model} = $model;
	my $fba = util_build_fba($params);
	$fba->parameters()->{"Mass balance atoms"} = "C;S;P;O;N";
	$handler->util_log("Checking model mass balance.");
   	my $objective = $fba->runFBA();
   	my $htmlreport = "<p>No mass imbalance found</p>";
	my $message = "No mass imbalance found";
	if ($fba->MFALog =~ /Couldn't open MFALog.txt/){
		die("Model triggered fatal solver error. Check logs.");
	}
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
	return $model->id()
}

sub func_baseline_gapfilling {
	my ($params,$datachannel) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id"],{
		media_id => undef,
		media_workspace => $params->{workspace},
		target_reaction => "bio1",
		fbamodel_workspace => $params->{workspace}
	});
	#Retreiving model
	if (!defined($datachannel->{fbamodel})) {
		$handler->util_log("Retrieving model.");
		$datachannel->{fbamodel} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	#Retrieving base media
	if (!defined($datachannel->{media})) {
		$handler->util_log("Retrieving media.");
		if (!defined($params->{media_id})) {
			$params->{media_id} = "Carbon-D-Glucose";
			$params->{media_workspace} = "KBaseMedia"
		}
		$datachannel->{media} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{media_id},$params->{media_workspace}));
	}
	#Adding all compounds to base media in order to gain a base-line gapfilling analysis
	my $auxotrophy_threshold_hash = Bio::KBase::constants::auxotrophy_thresholds();
	my $cpddatahash = Bio::KBase::utilities::compound_hash();
	my $mediacpds = $datachannel->{media}->mediacompounds();
	foreach my $cpd (keys(%{$auxotrophy_threshold_hash})) {
		my $found = 0;
		for (my $i=0; $i < @{$mediacpds}; $i++) {
			if ($mediacpds->[$i]->compound()->id() eq $cpd) {
				$mediacpds->[$i]->maxFlux(100);
				$found = 1;
			}
		}
		if ($found == 0) {
			$datachannel->{media}->add("mediacompounds",{
				compound_ref => "kbase/default/compounds/id/".$cpd,
				id => $cpd,
				name => $cpddatahash->{$cpd}->{name},
				concentration => 0.001,
				maxFlux => 100,
				minFlux => -100
			});
		}
	}
	#Adding auxotrophy transporters
	Bio::KBase::ObjectAPI::functions::add_auxotrophy_transporters({fbamodel => $datachannel->{fbamodel}});
	#Conducting base-line gapfilling analysis with rich media (ignoring previous gapfilling)
	my $fba = Bio::KBase::ObjectAPI::functions::util_build_fba({
		model => $datachannel->{fbamodel},
		media => $datachannel->{media},
		fba_output_id => $params->{fbamodel_id}."-AuxoFBA",
		gapfilling => 1,
		add_external_reactions => 1,
		add_gapfilling_solution_to_model => 0,
		target_reaction => $params->{target_reaction},
	});
	$fba->runFBA();
	#Error checking the FBA and gapfilling solution
	if (!defined($fba->gapfillingSolutions()->[0])) {
		Bio::KBase::utilities::error("Initial base-line gapfilling failed! Check that model and media formulations are valid.");
	}
	#Determine how many reactions were gapfilled and what reactions were gapfilled
	$datachannel->{fbamodel}->attributes()->{baseline_gapfilling} = 0;
	if (defined($fba->gapfillingSolutions()->[0]->{gapfillingSolutionReactions})) {
		$datachannel->{fbamodel}->attributes()->{baseline_gapfilling} = @{$fba->gapfillingSolutions()->[0]->{gapfillingSolutionReactions}};
	}
	return $fba->gapfillingSolutions()->[0];
}

sub func_predict_auxotrophy_from_model {
	my ($params,$datachannel) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id"],{
		media_id => undef,
		media_workspace => $params->{workspace},
		target_reaction => "bio1",
		fbamodel_workspace => $params->{workspace}
	});
	#Retreiving model
	if (!defined($datachannel->{fbamodel})) {
		$handler->util_log("Retrieving model.");
		$datachannel->{fbamodel} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	#Retrieving base media
	if (!defined($datachannel->{media})) {
		$handler->util_log("Retrieving media.");
		if (!defined($params->{media_id})) {
			$params->{media_id} = "Carbon-D-Glucose";
			$params->{media_workspace} = Bio::KBase::utilities::conf("ModelSEED","default_media_workspace")
		}
		$datachannel->{media} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{media_id},$params->{media_workspace}));
	}
	my $current_media = $datachannel->{media};
	$datachannel->{media} = $current_media->cloneObject();
	$datachannel->{media}->parent($current_media->parent());
	my $baseline_solution = Bio::KBase::ObjectAPI::functions::func_baseline_gapfilling({
		workspace => "NULL",
		fbamodel_id => $params->{fbamodel_id},
		media_id => $params->{media_id},
		media_workspace => $params->{media_workspace},
		target_reaction => $params->{target_reaction},
		fbamodel_workspace => $params->{fbamodel_workspace}
	},$datachannel);
	#Now gapfilling model in minimal media
	my $output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
		workspace => "NULL",
		fbamodel_id => $params->{fbamodel_id},
		fbamodel_output_id => $params->{fbamodel_id}.".gf",
		target_reaction => $params->{target_reaction},
		media_workspace => $params->{media_workspace},
		media_id => $params->{media_id}
	},$datachannel);
	$datachannel->{media} = $current_media;
	my $cpddatahash = Bio::KBase::utilities::compound_hash();
	my $auxotrophy_threshold_hash = Bio::KBase::constants::auxotrophy_thresholds();
	my $cofarray = Bio::KBase::constants::cofactors();
	my $cofactors = {};
	foreach my $id (@{$cofarray}) {
		$cofactors->{$id."_c0"} = 1;
	}
	#Populating reaction and compound hashes
	my $rxns = $datachannel->{fbamodel}->modelreactions();
	my $rxnhash;
	for (my $j=0; $j < @{$rxns}; $j++) {
		$rxnhash->{$rxns->[$j]->id()} = $rxns->[$j];
	}
	my $cpds = $datachannel->{fbamodel}->modelcompounds();
	my $cpdhash;
	for (my $j=0; $j < @{$cpds}; $j++) {
		$cpdhash->{$cpds->[$j]->id()} = $cpds->[$j];
	}
	#Running auxotrophy prediction flux balance analysis
	my $filelist = [];
	Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis({
		workspace => "NULL",
		fbamodel_id => $params->{fbamodel_id}.".gf",
		fba_output_id => $params->{fbamodel_id}.".fba_auxo1",
		media_id => $params->{media_id},
		media_workspace => $params->{media_workspace},
		target_reaction => $params->{target_reaction},
		metabolite_production_analysis => 1,
		source_metabolite_list => ["cpd00103_c0","cpd00171_c0","cpd00146_c0","cpd00020_c0","cpd00024_c0","cpd00169_c0","cpd00102_c0","cpd00072_c0","cpd00032_c0",
			"cpd00079_c0","cpd00022_c0","cpd00236_c0","cpd00101_c0","cpd00061_c0","cpd00041_c0","cpd00002_c0","cpd00038_c0","cpd00023_c0","cpd00053_c0"],
		target_metabolite_list => ["cpd00017_c0","cpd00033_c0","cpd00054_c0","cpd00161_c0","cpd00084_c0","cpd00119_c0","cpd00060_c0","cpd00051_c0","cpd00129_c0",
			"cpd00118_c0","cpd00132_c0","cpd00016_c0","cpd00056_c0","cpd00220_c0","cpd00028_c0","cpd00166_c0","cpd00557_c0","cpd00039_c0","cpd00069_c0",
			"cpd00066_c0","cpd00065_c0","cpd00393_c0","cpd00156_c0","cpd00107_c0"],
	},$datachannel);
	$filelist->[0] = Bio::KBase::ObjectAPI::utilities::FROMJSON($datachannel->{fba}->outputfiles()->{MetaboliteProductionResults}->[0]);
	Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis({
		workspace => "NULL",
		fbamodel_id => $params->{fbamodel_id}.".gf",
		fba_output_id => $params->{fbamodel_id}.".fba_auxo1",
		media_id => "Carbon-D-Glucose",
		media_workspace => Bio::KBase::utilities::conf("ModelSEED","default_media_workspace"),
		target_reaction => "bio1",
		metabolite_production_analysis => 1,
		source_metabolite_list => ["cpd00103_c0","cpd00171_c0","cpd00146_c0","cpd00020_c0","cpd00024_c0","cpd00169_c0","cpd00102_c0","cpd00072_c0","cpd00032_c0",
			"cpd00079_c0","cpd00022_c0","cpd00236_c0","cpd00101_c0","cpd00061_c0","cpd00041_c0","cpd00002_c0","cpd00038_c0","cpd00023_c0","cpd00053_c0","cpd00054_c0"],
		target_metabolite_list => ["cpd00065"],
	},$datachannel);
	$filelist->[1] = Bio::KBase::ObjectAPI::utilities::FROMJSON($datachannel->{fba}->outputfiles()->{MetaboliteProductionResults}->[0]);
	Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis({
		workspace => "NULL",
		fbamodel_id => $params->{fbamodel_id}.".gf",
		fba_output_id => $params->{fbamodel_id}.".fba_auxo2",
		media_id => "Carbon-D-Glucose",
		media_workspace => Bio::KBase::utilities::conf("ModelSEED","default_media_workspace"),
		target_reaction => "bio1",
		metabolite_production_analysis => 1,
		source_metabolite_list => ["cpd00800_c0","cpd00103_c0","cpd00171_c0","cpd00146_c0","cpd00020_c0","cpd00024_c0","cpd00169_c0","cpd00102_c0","cpd00072_c0","cpd00032_c0",
		"cpd00079_c0","cpd00022_c0","cpd00236_c0","cpd00101_c0","cpd00061_c0","cpd00041_c0","cpd00002_c0","cpd00038_c0","cpd00023_c0","cpd00053_c0",
		"cpd00017_c0","cpd00051_c0","cpd00084_c0","cpd00065_c0","cpd00161_c0","cpd00156_c0","cpd00800_c0","cpd00054_c0"],
		target_metabolite_list => ["cpd00065","cpd00644_c0","cpd00264_c0","cpd00042_c0","cpd00003_c0","cpd00104_c0","cpd00322_c0"],
	},$datachannel);
	$filelist->[2] = Bio::KBase::ObjectAPI::utilities::FROMJSON($datachannel->{fba}->outputfiles()->{MetaboliteProductionResults}->[0]);
	my $auxotrophy_results = {};
	my $translation = {
		cpd00016 => "cpd00215"
	};
	for (my $j=0; $j < @{$filelist}; $j++) {
		foreach my $cpd (keys(%{$filelist->[$j]})) {
			$auxotrophy_results->{$cpd} = $filelist->[$j]->{$cpd};
			if ($auxotrophy_results->{$cpd}->{auxotrophic} == 1) {
				$current_media->add("mediacompounds",{
					compound_ref => "kbase/default/compounds/id/".$cpd,
					id => $cpd,
					name => $cpddatahash->{$cpd}->{name},
					concentration => 0.001,
					maxFlux => 100,
					minFlux => -100
				});
			}
		}
	}
	$datachannel->{media} = $current_media;
	my $wsmeta = $handler->util_save_object($current_media,$params->{workspace}."/".$params->{fbamodel_id}.".auxo_media");
	return {auxotrophy_data =>  $auxotrophy_results,baseline => $baseline_solution};
}

sub func_predict_auxotrophy {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","genome_ids"],{
		genome_workspace => $params->{workspace}
	});
	my $genomedata = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{Bio::KBase::ObjectAPI::utilities::LOADFILE(Bio::KBase::utilities::conf("ModelSEED","genome auxotrophy data filename"))}));
	my $rxndata = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{Bio::KBase::ObjectAPI::utilities::LOADFILE(Bio::KBase::utilities::conf("ModelSEED","reaction auxotrophy data filename"))}));
	my $cpddata = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{Bio::KBase::ObjectAPI::utilities::LOADFILE(Bio::KBase::utilities::conf("ModelSEED","biomass compound data filename"))}));
	my $media = $handler->util_get_object(Bio::KBase::utilities::conf("ModelSEED","default_media_workspace")."/Carbon-D-Glucose");
	my $genomes = $params->{genome_ids};
	my $transporthash = {};
	my $cpddatahash = {};
	my $auxotrophy_threshold_hash = Bio::KBase::constants::auxotrophy_thresholds();
	for (my $i=0; $i < @{$cpddata}; $i++) {
		if (defined($cpddata->[$i]->{transporter})) {
			$transporthash->{$cpddata->[$i]->{transporter}} = 1;
		}
		$cpddatahash->{$cpddata->[$i]->{id}} = $cpddata->[$i];
	}
	my $auxotrophy_hash;
	my $template_trans = Bio::KBase::constants::template_trans();
	for (my $i=0; $i < @{$genomes}; $i++) {
		my $datachannel = {};
		my $genomeobj = $handler->util_get_object(Bio::KBase::utilities::buildref($genomes->[$i],$params->{genome_workspace}));
		my $genomeid = $genomeobj->_wsname();
		$genomes->[$i] = $genomeid;
		print "Processing ".$genomeid."\n";
		my $current_media = $media->cloneObject();
		my $tid = $template_trans->{$genomeobj->template_classification()};
		Bio::KBase::ObjectAPI::functions::func_build_metabolic_model({
			template_id => $tid,
			template_workspace => Bio::KBase::utilities::conf("ModelSEED","default_template_workspace"),
			workspace => "NULL",
			fbamodel_output_id => $genomeid.".fbamodel",
			genome_id => $genomeid,
			genome_workspace => $params->{genome_workspace},
			media_id => "Carbon-D-Glucose",
			media_workspace => Bio::KBase::utilities::conf("ModelSEED","default_media_workspace"),
			gapfill_model => 1
		},$datachannel);
		foreach my $rxn (keys(%{$transporthash})) {
			if (!defined($datachannel->{fbamodel}->queryObject("modelreactions",{id => $rxn."_c0"}))) {
				$datachannel->{fbamodel}->addModelReaction({
					reaction => $rxn,
					direction => "=",
					addReaction => 1
				});
			}
		}
		Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis({
			workspace => "NULL",
			fbamodel_id => $genomeid.".fbamodel",
			fba_output_id => $genomeid.".fba_min",
			media_id => "Carbon-D-Glucose",
			media_workspace => Bio::KBase::utilities::conf("ModelSEED","default_media_workspace"),
			target_reaction => "bio1",
			fva => 1,
			minimize_flux => 1,
		},$datachannel->{fbamodel});
		Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis({
			workspace => "NULL",
			fbamodel_id => $genomeid.".fbamodel",
			fba_output_id => $genomeid.".fba_com",
			media_id => "Complete",
			media_workspace => Bio::KBase::utilities::conf("ModelSEED","default_media_workspace"),
			target_reaction => "bio1",
			fva => 1,
			minimize_flux => 1,
		},$datachannel->{fbamodel});
		my $rxnhash;
		my $rxns = $datachannel->{fbamodel}->modelreactions();
		for (my $i=0; $i < @{$rxns}; $i++) {
			my $rxnid = $rxns->[$i]->id();
			$rxnid =~ s/_[a-z]+\d+$//;
			$rxnhash->{$rxnid} = $rxns->[$i];
		}
		my $fba = $handler->util_get_object("NULL/".$genomeid.".fba_min");
		my $fbarxns = $fba->FBAReactionVariables();
		for (my $i=0; $i < @{$fbarxns}; $i++) {
			my $rxnid = $fbarxns->[$i]->modelreaction()->id();
			if (abs($fbarxns->[$i]->value()) > 1e-7) {
				$rxnid =~ s/_[a-z]+\d+$//;
				$rxnhash->{$rxnid}->{minclass} = "f";
				if ($fbarxns->[$i]->max() < -1e-7 || $fbarxns->[$i]->min() > 1e-7) {
					$rxnhash->{$rxnid}->{minclass} = "e";
				}
			} else {
				$rxnhash->{$rxnid}->{minclass} = "n";
			}
		}
		$fba = $handler->util_get_object("NULL/".$genomeid.".fba_com");
		$fbarxns = $fba->FBAReactionVariables();
		for (my $i=0; $i < @{$fbarxns}; $i++) {
			my $rxnid = $fbarxns->[$i]->modelreaction()->id();
			$rxnid =~ s/_[a-z]+\d+$//;
			$rxnhash->{$rxnid}->{comclass} = "ne";
			if ($fbarxns->[$i]->max() < -1e-7 || $fbarxns->[$i]->min() > 1e-7) {
				$rxnhash->{$rxnid}->{comclass} = "ne";#TODO: this is technically wrong
			}
		}
		foreach my $rxn (keys(%{$rxnhash})) {
			#Reaction is mapped to a biomass component and it's carrying flux in MM
			if (defined($rxndata->{$rxn}) && defined($rxnhash->{$rxn}->{minclass}) && defined($rxnhash->{$rxn}->{comclass}) && $rxnhash->{$rxn}->{minclass} ne "n" && $rxnhash->{$rxn}->{comclass} ne "e") {
				foreach my $biocpd (keys(%{$rxndata->{$rxn}->{biomass_cpds}})) {
					if (!defined($auxotrophy_hash->{$biocpd}->{$genomeid})) {
						$auxotrophy_hash->{$biocpd}->{$genomeid} = {
							rxn => 0,
							gfrxn => 0,
							gfrxns => {},
							rxns => {}
						};
					}
					$auxotrophy_hash->{$biocpd}->{$genomeid}->{rxns}->{$rxn} = $rxnhash->{$rxn};
					$auxotrophy_hash->{$biocpd}->{$genomeid}->{rxn}++;
					if ($rxnhash->{$rxn}->gprString() eq "Unknown") {
						$auxotrophy_hash->{$biocpd}->{$genomeid}->{gfrxns}->{$rxn} = $rxnhash->{$rxn};
						$auxotrophy_hash->{$biocpd}->{$genomeid}->{gfrxn}++;
					}
				}
			}
		}
		foreach my $biocpd (keys(%{$auxotrophy_hash})) {
			$auxotrophy_hash->{$biocpd}->{$genomeid}->{auxotrophic} = 0;
			if (defined($auxotrophy_threshold_hash->{$biocpd})) {
				if (defined($auxotrophy_hash->{$biocpd}->{$genomeid}) && ($auxotrophy_hash->{$biocpd}->{$genomeid}->{gfrxn} >= $auxotrophy_threshold_hash->{$biocpd}->[1] || $auxotrophy_hash->{$biocpd}->{$genomeid}->{rxn} <= $auxotrophy_threshold_hash->{$biocpd}->[0])) {
					$auxotrophy_hash->{$biocpd}->{$genomeid}->{auxotrophic} = 1;
					$current_media->add("mediacompounds",{
						compound_ref => "kbase/default/compounds/id/".$biocpd,
						id => $biocpd,
						name => $cpddatahash->{$biocpd}->{name},
						concentration => 0.001,
						maxFlux => 100,
						minFlux => -100
					});
				}
			}
		}
		$current_media->parent($handler->util_store());
		my $wsmeta = $handler->util_save_object($current_media,$params->{workspace}."/".$genomeid.".auxo_media");
	}
	print "Class\tCompound\tAve gf";
	for (my $i=0; $i < @{$genomes}; $i++) {
		print "\t".$genomes->[$i];
	}
	print "\n";
	for (my $i=0; $i < @{$cpddata}; $i++) {
		print $cpddata->[$i]->{class}."\t".$cpddata->[$i]->{name}." (".$cpddata->[$i]->{id}.")\t".$cpddata->[$i]->{avegf};
		for (my $j=0; $j < @{$genomes}; $j++) {
			if (defined($auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]})) {
				print "\t".$auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]}->{gfrxn}."/".$auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]}->{rxn}."/".$auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]}->{auxotrophic};
			} else {
				print "\t-";
			}
		}
		print "\n";
	}

	my $htmlreport = "<html><head><script type='text/javascript' src='https://www.google.com/jsapi'></script><script type='text/javascript'>google.load('visualization', '1', {packages:['controls'], callback: drawDashboard});google.setOnLoadCallback(drawDashboard);";
	$htmlreport .= "function drawDashboard() {var data = new google.visualization.DataTable();";
	$htmlreport .= "data.addColumn('string','Class');";
	$htmlreport .= "data.addColumn('string','Essential metabolite');";
	for (my $i=0; $i < @{$genomes}; $i++) {
		$htmlreport .= "data.addColumn('number','".$genomes->[$i]."');";
	}
	$htmlreport .= "data.addRows([";
	for (my $i=0; $i < @{$cpddata}; $i++) {
		my $row = [];
		$htmlreport .= '["'.$cpddata->[$i]->{class}.'","'.$cpddata->[$i]->{name}." (".$cpddata->[$i]->{id}.")".'",';
		for (my $j=0; $j < @{$genomes}; $j++) {
			if (defined($auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]})) {
				if ($auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]}->{auxotrophic} == 1) {
					push(@{$row},'{v:1,f:"Gapfilling: '.$auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]}->{gfrxn}.'<br>Reactions: '.$auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]}->{rxn}.'<br>Auxotrophic"}');
				} else {
					push(@{$row},'{v:0,f:"Gapfilling: '.$auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]}->{gfrxn}.'<br>Reactions: '.$auxotrophy_hash->{$cpddata->[$i]->{id}}->{$genomes->[$j]}->{rxn}.'"}');
				}
			} else {
				push(@{$row},'{v:0,f:""}');
			}
		}
		$htmlreport .= join(',',@{$row}).'],';
	}
	$htmlreport .= "]);var filterColumns = [];var tab_columns = [];for (var j = 0, dcols = data.getNumberOfColumns(); j < dcols; j++) {filterColumns.push(j);tab_columns.push(j);}filterColumns.push({type: 'string',calc: function (dt, row) {for (var i = 0, vals = [], cols = dt.getNumberOfColumns(); i < cols; i++) {vals.push(dt.getFormattedValue(row, i));}return vals.join('\\n');}});";
	$htmlreport .= "var table = new google.visualization.ChartWrapper({chartType: 'Table',containerId: 'table_div',options: {allowHtml: true,showRowNumber: true,page: 'enable',pageSize: 20},view: {columns: tab_columns}});";
	$htmlreport .= "var search_filter = new google.visualization.ControlWrapper({controlType: 'StringFilter',containerId: 'search_div',options: {filterColumnIndex: data.getNumberOfColumns(),matchType: 'any',caseSensitive: false,ui: {label: 'Search data:'}},view: {columns: filterColumns}});";
	$htmlreport .= "var dashboard = new google.visualization.Dashboard(document.querySelector('#dashboard_div'));var formatter = new google.visualization.ColorFormat();formatter.addRange(0.5, null, 'red', 'white');";
	for (my $j=0; $j < @{$genomes}; $j++) {
		$htmlreport .= "formatter.format(data, ".($j+2).");";
	}
	$htmlreport .= "dashboard.bind([search_filter], [table]);dashboard.draw(data);}</script></head>";
	$htmlreport .= "<body><h4>Results from auxotrophy prediction on all genomes</h4><div id='dashboard_div'><table class='columns'><tr><td><div id='search_div'></div></td></tr><tr><td><div id='table_div'></div></td></tr></table></div></body></html>";
	print $htmlreport;
	Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	return $auxotrophy_hash;
}

sub func_predict_metabolite_biosynthesis_pathway {
	my ($params,$datachannel) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id","target_metabolite_list","fba_output_id"],{
		fbamodel_workspace => $params->{workspace},
		media_id => undef,
		media_workspace => $params->{workspace},
		thermodynamic_constraints => 0,
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
		default_max_uptake => 0,
		source_metabolite_list => [],
		gapfill_model => 0
	});
	my $base_source = ["cpd00103_c0","cpd00171_c0","cpd00146_c0","cpd00020_c0","cpd00024_c0","cpd00169_c0","cpd00102_c0","cpd00072_c0","cpd00032_c0",
			"cpd00079_c0","cpd00022_c0","cpd00236_c0","cpd00101_c0","cpd00061_c0","cpd00041_c0","cpd00002_c0","cpd00038_c0","cpd00023_c0","cpd00053_c0"];
	my $hash = {};
	for (my $i=0; $i < @{$base_source}; $i++) {
		$hash->{$base_source->[$i]} = 1;
	}
	if (ref($params->{source_metabolite_list}) ne "ARRAY") {
		$params->{source_metabolite_list} = [split(/;/,$params->{source_metabolite_list})];
	}
	if (ref($params->{target_metabolite_list}) ne "ARRAY") {
		$params->{target_metabolite_list} = [split(/;/,$params->{target_metabolite_list})];
	}
	for (my $i=0; $i < @{$params->{source_metabolite_list}}; $i++) {
		if (!defined($hash->{$params->{source_metabolite_list}->[$i]})) {
			push(@{$base_source},$params->{source_metabolite_list}->[$i]);
		}
	}
	if (!defined($datachannel->{fbamodel})) {
		$handler->util_log("Retrieving model.");
		$datachannel->{fbamodel} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	my $mdlrxnhash = {};
	my $mdlrxns = $datachannel->{fbamodel}->modelreactions();
	for (my $i=0; $i < @{$mdlrxns}; $i++) {
		$mdlrxnhash->{$mdlrxns->[$i]->id()} = $mdlrxns->[$i];
	}
	my $mdlcpdhash = {};
	my $mdlcpds = $datachannel->{fbamodel}->modelcompounds();
	for (my $i=0; $i < @{$mdlcpds}; $i++) {
		$mdlcpdhash->{$mdlcpds->[$i]->id()} = $mdlcpds->[$i];
	}
	my $filelist = [];
	Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis({
		workspace => $params->{workspace},
		fbamodel_id => $params->{fbamodel_id},
		fba_output_id => $params->{fba_output_id},
		media_id => $params->{media_id},
		media_workspace => $params->{media_workspace},
		target_reaction => "bio1",
		metabolite_production_analysis => 1,
		source_metabolite_list => $base_source,
		target_metabolite_list => $params->{target_metabolite_list},
	},$datachannel);
	my $output = $datachannel->{fba}->outputfiles()->{MetaboliteProductionResults};
	print $output->[0];
#	my $htmlreport = "<html><head><script type='text/javascript' src='https://www.google.com/jsapi'></script><script type='text/javascript'>google.load('visualization', '1', {packages:['controls'], callback: drawDashboard});google.setOnLoadCallback(drawDashboard);";
#	$htmlreport .= "function drawDashboard() {var data = new google.visualization.DataTable();";
#	$htmlreport .= "data.addColumn('string','Compound ID');";
#	$htmlreport .= "data.addColumn('string','Reaction ID');";
#	$htmlreport .= "data.addColumn('string','Equation');";
#	$htmlreport .= "data.addColumn('string','Genes');";
#	$htmlreport .= "data.addRows([";
#	for (my $k=1; $k < @{$output}; $k++) {
#		my $array = [split(/\t/,$output->[$k])];
#		my $cpd = $array->[1];
#		$cpd =~ s/_c0//;
#		if ($array->[2] ne "none") {
#			my $rxns = [split(/;/,$array->[2])];
#			my $featurehash = {};
#			for (my $m=0; $m < @{$rxns}; $m++) {
#				if ($rxns->[$m] =~ m/(.)(.+)(_[a-zA-Z]\d):(.+)/) {
#					my $rxnid = $2;
#					my $comp = $3;
#					my $flux = $4;
#					print $cpd."\t".$rxnid."\n";
#					my $definition = $mdlrxnhash->{$rxnid.$comp}->definition();
#					if ($flux < 0) {
#						my $list = [split(/\s<=>\s/,$definition)];
#						$definition = $list->[1]." => ".$list->[0];
#					}
#					my $ftrs = $mdlrxnhash->{$rxnid.$comp}->featureIDs();
#					for (my $m=0; $m < @{$ftrs}; $m++) {
#						$featurehash->{$ftrs->[$m]} = [$datachannel->{fbamodel}->genome_ref()];
#					}
#					$htmlreport .= '["'.$mdlcpdhash->{$array->[1]}->name()." (".$cpd.")".'","'.$rxnid.'","'.$definition.'","'.$mdlrxnhash->{$rxnid.$comp}->gprString().'"],';
#				}
#			}
#			my $geneobj = {
#				description => "",
#  				element_ordering => [sort keys(%{$featurehash})],
#  				elements => $featurehash
#			};
#			my $meta = $handler->util_save_object($geneobj,$params->{workspace}."/".$cpd."_genes",{hash => 1,type => "KBaseCollections.FeatureSet"});
#		}
#	}
#	$htmlreport .= "]);var filterColumns = [];var tab_columns = [];for (var j = 0, dcols = data.getNumberOfColumns(); j < dcols; j++) {filterColumns.push(j);tab_columns.push(j);}filterColumns.push({type: 'string',calc: function (dt, row) {for (var i = 0, vals = [], cols = dt.getNumberOfColumns(); i < cols; i++) {vals.push(dt.getFormattedValue(row, i));}return vals.join('\\n');}});";
#	$htmlreport .= "var table = new google.visualization.ChartWrapper({chartType: 'Table',containerId: 'table_div',options: {allowHtml: true,showRowNumber: true,page: 'enable',pageSize: 20},view: {columns: tab_columns}});";
#	$htmlreport .= "var search_filter = new google.visualization.ControlWrapper({controlType: 'StringFilter',containerId: 'search_div',options: {filterColumnIndex: data.getNumberOfColumns(),matchType: 'any',caseSensitive: false,ui: {label: 'Search data:'}},view: {columns: filterColumns}});";
#	$htmlreport .= "var dashboard = new google.visualization.Dashboard(document.querySelector('#dashboard_div'));var formatter = new google.visualization.ColorFormat();formatter.addRange(0.5, null, 'red', 'white');";
#	#for (my $j=0; $j < @{$genomes}; $j++) {
#	#	$htmlreport .= "formatter.format(data, ".($j+2).");";
#	#}
#	$htmlreport .= "dashboard.bind([search_filter], [table]);dashboard.draw(data);}</script></head>";
#	$htmlreport .= "<body><h4>Results from pathway analysis</h4><div id='dashboard_div'><table class='columns'><tr><td><div id='search_div'></div></td></tr><tr><td><div id='table_div'></div></td></tr></table></div></body></html>";
#	print $htmlreport;
#	Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	return {}
}

sub func_build_metagenome_metabolic_model {
	my ($params,$datachannel) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","input_ref"],{
		input_workspace => $params->{workspace},
		fbamodel_output_id => undef,
		media_id => undef,
		media_workspace => $params->{workspace},
		gapfill_model => 1,
		max_objective_limit => 1.4,
		minimum_target_flux => undef,
		contig_coverage_file => undef,
		rast_probability => 1,
		other_anno_probability => 0.5,
		use_kegg => 1,
		reads_refs => []
	});
	my $htmlreport = "";
	my $contig_coverages = {};
	my $coverage_data = 0;
	#Retrieving metagenome annotation object
	my $object = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{input_ref},$params->{input_workspace}));
	my $dfu = Bio::KBase::kbaseenv::data_file_client();
	my $output = $dfu->shock_to_file({handle_id => $object->{features_handle_ref},file_path => Bio::KBase::utilities::conf("fba_tools","scratch")});
	system("gunzip --force ".$output->{file_path});
	$output->{file_path} =~ s/.gz//;
	my $lines = Bio::KBase::ObjectAPI::utilities::LOADFILE($output->{file_path});
	my $feature_data = Bio::KBase::ObjectAPI::utilities::FROMJSON(join("\n",@{$lines}));
	my $proteins = [];
	my $contigs = [];
	my $totalcoverage = 0;
	for (my $i=0; $i < @{$feature_data}; $i++) {
		if ($i < 100) {
			print Bio::KBase::ObjectAPI::utilities::TOJSON($feature_data->[$i],1)."\n";
		}
		my $prot = Bio::KBase::ObjectAPI::KBaseGenomes::Feature::translate_seq({},$feature_data->[$i]->{dna_sequence});
		push(@{$proteins},$prot);
		if (defined($feature_data->[$i]->{location}->[0]->[0])) {
			push(@{$contigs},$feature_data->[$i]->{location}->[0]->[0]);
			$contig_coverages->{$feature_data->[$i]->{location}->[0]->[0]} = 1;
			$totalcoverage++;
		} else {
			push(@{$contigs},"");
		}
	}
	#Reading the contig coverage file if provided
	if (defined($params->{contig_coverage_file})) {
		$totalcoverage = 0;
		my $lines;
		if (ref($params->{contig_coverage_file}) eq "HASH") {
			$params->{contig_coverage_file} = $handler->util_get_file_path($params->{contig_coverage_file},Bio::KBase::utilities::conf("fba_tools","scratch"));
			$lines = Bio::KBase::ObjectAPI::utilities::LOADFILE($params->{contig_coverage_file});
		} elsif ($params->{contig_coverage_file} =~ m/^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$/) {
			my $ua = LWP::UserAgent->new();
			my $shock_url = Bio::KBase::utilities::conf("fba_tools","shock-url")."/node/".$params->{contig_coverage_file}."?download";
			my $token = Bio::KBase::utilities::token();
			my $res = $ua->get($shock_url,Authorization => "OAuth " . $token);
			$lines = [split(/\n/,$res->{_content})];
		} else {
			$lines = Bio::KBase::ObjectAPI::utilities::LOADFILE($params->{contig_coverage_file});
		}
		for (my $i=0; $i < @{$lines}; $i++) {
			my $array = [split(/\t/,$lines->[$i])];
			if (defined($array->[1])) {
				$totalcoverage += $array->[1];
				$contig_coverages->{$array->[0]} = $array->[1];
			}
		}
		$coverage_data = 1;
	} elsif (@{$params->{reads_refs}} > 0) {
		$totalcoverage = 0;
		print "Reads files recieved: computing coverages!\n";
		my $params = {
		   reads => $params->{reads_refs},
		   assembly_ref => $params->{input_ref}.";".$object->{assembly_ref}
		};
		my $readmapper = Bio::KBase::kbaseenv::readmapper_client();
   		my $result = $readmapper->readmapper($params);
   		print Bio::KBase::ObjectAPI::utilities::TOJSON($result)."\n\n";
		my $lines = Bio::KBase::ObjectAPI::utilities::LOADFILE($result->{file_name});
		for (my $i=0; $i < @{$lines}; $i++) {
			my $array = [split(/\t/,$lines->[$i])];
			$totalcoverage += $array->[2];
			$contig_coverages->{$array->[0]} = $array->[2]+0;
		}
		$coverage_data = 1;
	}
	#Normalizing contig coverages into relative coverages
	foreach my $contig (keys(%{$contig_coverages})) {
		$contig_coverages->{$contig} = $contig_coverages->{$contig}/$totalcoverage;
	}
	#Loading metagenome template
	my $template_trans = Bio::KBase::constants::template_trans();
	my $template = $handler->util_get_object(Bio::KBase::utilities::buildref($template_trans->{metagenome},Bio::KBase::utilities::conf("ModelSEED","default_template_workspace")));
	#Parsing through feature array
	my $function_hash = {};
	my $reaction_hash = {};
	my $ontology_hash = Bio::KBase::kbaseenv::get_ontology_hash();
	my $sso_hash = Bio::KBase::kbaseenv::get_sso_hash();
	my $ftrcount = 0;
	my $ssocount = 0;
	for (my $i=0; $i < @{$feature_data}; $i++) {
		$ftrcount++;
		if (defined($feature_data->[$i]->{db_xrefs})) {
			for (my $j=0; $j < @{$feature_data->[$i]->{db_xrefs}}; $j++) {
				my $type;
				my $term;
				if ($feature_data->[$i]->{db_xrefs}->[$j]->[0] eq "KEGG") {
					if ($feature_data->[$i]->{db_xrefs}->[$j]->[1] =~ m/^K/) {
						$type = "KEGG_KO";
						$term = $feature_data->[$i]->{db_xrefs}->[$j]->[1];
					} elsif ($feature_data->[$i]->{db_xrefs}->[$j]->[1] =~ m/^R/) {
						$type = "KEGG_RXN";
						$term = $feature_data->[$i]->{db_xrefs}->[$j]->[1];
					}
				}

				if ( $params->{ use_kegg }
					&& defined $type
					&& defined $ontology_hash->{ $term }
					&& ( $type eq "KEGG_KO" || $type eq "KEGG_RXN" ) ) {
					for my $rid ( keys %{ $ontology_hash->{ $term } } ) {
						$reaction_hash->{ $rid }{ u } //= {
							hit_count			 => 0,
							non_gene_probability  => 0,
							non_gene_coverage	 => 0,
							sources			   => {}
						};
						$reaction_hash->{$rid}->{u}->{non_gene_probability} = $reaction_hash->{$rid}->{u}->{non_gene_probability}*$reaction_hash->{$rid}->{u}->{hit_count}+$params->{other_anno_probability};
						$reaction_hash->{$rid}->{u}->{hit_count}++;
						$reaction_hash->{$rid}->{u}->{non_gene_probability} = $reaction_hash->{$rid}->{u}->{non_gene_probability}/$reaction_hash->{$rid}->{u}->{hit_count};
						$reaction_hash->{$rid}->{u}->{non_gene_coverage} += $contig_coverages->{$contigs->[$i]};
						if (!defined($reaction_hash->{$rid}->{u}->{sources}->{$type}->{$term})) {
							$reaction_hash->{$rid}->{u}->{sources}->{$type}->{$term} = 0;
						}
						$reaction_hash->{$rid}->{u}->{sources}->{$type}->{$term}++;
					}
				}
			}
		}
		if (defined($feature_data->[$i]->{functions})) {
			my $function_list = $feature_data->[$i]->{functions};
			for (my $j=0; $j < @{$function_list}; $j++) {
				my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($function_list->[$j]);
				if (defined($template->roleSearchNameHash()->{$searchrole})) {
					$ssocount++;
					foreach my $roleid (keys(%{$template->roleSearchNameHash()->{$searchrole}})) {
						if ($template->roleSearchNameHash()->{$searchrole}->{$roleid}->source() ne "KEGG") {
							if (!defined($function_hash->{$roleid}->{u})) {
								$function_hash->{$roleid}->{u} = {
									hit_count => 0,
									non_gene_probability => 0,
									non_gene_coverage => 0,
									sources => {},
								};
							}
							$function_hash->{$roleid}->{u}->{non_gene_probability} = $function_hash->{$roleid}->{u}->{non_gene_probability}*$function_hash->{$roleid}->{u}->{hit_count}+$params->{rast_probability};
							$function_hash->{$roleid}->{u}->{hit_count}++;
							$function_hash->{$roleid}->{u}->{non_gene_probability} = $function_hash->{$roleid}->{u}->{non_gene_probability}/$function_hash->{$roleid}->{u}->{hit_count};
							$function_hash->{$roleid}->{u}->{non_gene_coverage} += $contig_coverages->{$contigs->[$i]};
							if (!defined($function_hash->{$roleid}->{u}->{sources}->{RAST}->{$function_list->[$j]})) {
								$function_hash->{$roleid}->{u}->{sources}->{RAST}->{$function_list->[$j]} = 0;
							}
							$function_hash->{$roleid}->{u}->{sources}->{RAST}->{$function_list->[$j]}++;
						}
					}
				}
			}
		}
	}
	#Checking if it looks like this metagenome was annotated with RAST and if not - reannotating with RAST
	print "Feature count:".$ftrcount."\n";
	print "SSO count:".$ssocount."\n";
	if ($ftrcount > 0 && $ssocount/$ftrcount < 0.1) {
		print "Reannotating with RAST because SEED role count is below 500!\n\n";
		#Parsing protein sequences from metagenome assembly file
		$function_hash = {};
		$output = Bio::KBase::ObjectAPI::functions::annotate_proteins({proteins => $proteins});
		my $function_list = $output->{functions};
		for (my $i=0; $i < @{$function_list}; $i++) {
			for (my $j=0; $j < @{$function_list->[$i]}; $j++) {
				my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($function_list->[$i]->[$j]);
				if (defined($template->roleSearchNameHash()->{$searchrole})) {
					foreach my $roleid (keys(%{$template->roleSearchNameHash()->{$searchrole}})) {
						if ($template->roleSearchNameHash()->{$searchrole}->{$roleid}->source() ne "KEGG") {
							if (!defined($function_hash->{$roleid}->{u})) {
								$function_hash->{$roleid}->{u} = {
									hit_count => 0,
									non_gene_probability => 0,
									non_gene_coverage => 0,
									sources => {},
								};
							}
							$function_hash->{$roleid}->{u}->{non_gene_probability} = $function_hash->{$roleid}->{u}->{non_gene_probability}*$function_hash->{$roleid}->{u}->{hit_count}+$params->{rast_probability};
							$function_hash->{$roleid}->{u}->{hit_count}++;
							$function_hash->{$roleid}->{u}->{non_gene_probability} = $function_hash->{$roleid}->{u}->{non_gene_probability}/$function_hash->{$roleid}->{u}->{hit_count};
							$function_hash->{$roleid}->{u}->{non_gene_coverage} += $contig_coverages->{$contigs->[$i]};
							if (!defined($function_hash->{$roleid}->{u}->{sources}->{RAST}->{$function_list->[$i]->[$j]})) {
								$function_hash->{$roleid}->{u}->{sources}->{RAST}->{$function_list->[$i]->[$j]} = 0;
							}
							$function_hash->{$roleid}->{u}->{sources}->{RAST}->{$function_list->[$i]->[$j]}++;
						}
					}
				}
			}
		}
	}
	#Building model from functions
	if (!defined($params->{fbamodel_output_id})) {
		$params->{fbamodel_output_id} = $object->{_wsinfo}->[1].".mdl";
	}
	my $mdl = $template->NewBuildModel({
		function_hash => $function_hash,
		reaction_hash => $reaction_hash,
		modelid => $params->{fbamodel_output_id}
	});
	if ($coverage_data == 1) {
		$mdl->contig_coverages($contig_coverages);
	}
	$mdl->type("Metagenome");
	$mdl->genome_ref("PlantSEED/Empty");
	$mdl->EnsureProperATPProduction({
		anaerobe => 0,
		max_objective_limit => $params->{max_objective_limit}
	});
	#Gapfilling model if requested
	my $function_output = {};
	if ($params->{gapfill_model} == 1) {
		$function_output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
			target_reaction => "bio1",
			minimum_target_flux => $params->{minimum_target_flux},
			workspace => $params->{workspace},
			fbamodel_id => $params->{fbamodel_output_id},
			fbamodel_output_id => $params->{fbamodel_output_id},
			media_workspace => $params->{media_workspace},
			media_id => $params->{media_id},
			atp_production_check => 1
		},{fbamodel => $mdl});
		$htmlreport .= $function_output->{html_report}." Model was saved with the name ".$params->{fbamodel_output_id}.". The final model includes ".@{$mdl->modelreactions()}." reactions, ".@{$mdl->modelcompounds()}." compounds, and ".$mdl->gene_count()." genes.</p>".Bio::KBase::utilities::gapfilling_html_table()."</div>";
	} else {
		#If not gapfilling, then we just save the model directly
		$function_output->{number_gapfilled_reactions} = 0;
		$function_output->{new_fbamodel_ref} = Bio::KBase::utilities::buildref($params->{fbamodel_output_id},$params->{workspace});
		my $wsmeta = $handler->util_save_object($mdl,$function_output->{new_fbamodel_ref},{type => "KBaseFBA.FBAModel"});
		$htmlreport .= " No gapfilling was performed on the model. It is expected that the model will not be capable of producing biomass on any growth condition until gapfilling is run. Model was saved with the name ".$params->{fbamodel_output_id}.". The final model includes ".@{$mdl->modelreactions()}." reactions, ".@{$mdl->modelcompounds()}." compounds, and ".$mdl->gene_count()." genes.</p></div>"
	}
	$datachannel->{fbamodel} = $mdl;
	Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	return $function_output;
}

sub func_model_based_genome_characterization {
	my ($params,$datachannel) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","genome_id"],{
		fbamodel_output_id => $params->{genome_id}.".mdl",
		template_id => "auto",
		genome_workspace => $params->{workspace},
		template_workspace => undef,
		use_annotated_functions => 1,
		merge_all_annotations => 0,
		source_ontology_list => [],
		metagenome_model_id => undef,
		metagenome_model_workspace => $params->{workspace},
		coverage_propagation => "mag"
	});
	Bio::KBase::ObjectAPI::functions::func_build_metabolic_model({
		workspace => $params->{workspace},
		genome_id => $params->{genome_id},
		fbamodel_output_id => $params->{genome_id}.".basemodel",
		template_id => $params->{template_id},
		genome_workspace => $params->{genome_workspace},
		template_workspace => $params->{template_workspace},
		gapfill_model => 0,
		anaerobe => 0,
		use_annotated_functions => $params->{use_annotated_functions},
		merge_all_annotations => $params->{merge_all_annotations},
		source_ontology_list => $params->{source_ontology_list},
		add_auxotrophy_transporters => 1
	},$datachannel);
	return Bio::KBase::ObjectAPI::functions::func_run_model_chacterization_pipeline({
		workspace => $params->{workspace},
		fbamodel_id => $params->{genome_id}.".basemodel",
		fbamodel_output_id => $params->{fbamodel_output_id},
		metagenome_model_id => $params->{metagenome_model_id},
		metagenome_model_workspace => $params->{metagenome_model_workspace}
	},$datachannel);
}

sub func_run_model_chacterization_pipeline {
	my ($params,$datachannel) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","fbamodel_id"],{
		fbamodel_workspace => $params->{workspace},
		fbamodel_output_id => $params->{fbamodel_id},
		metagenome_model_id => undef,
		metagenome_model_workspace => $params->{workspace},
		coverage_propagation => "mag",
		predict_auxotrophy => 1
	});
	#Pulling and stashing original input model for the analysis
	if (!defined($datachannel->{fbamodel})) {
		$datachannel->{fbamodel} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	}
	if (defined($datachannel->{fbamodel}->attributes())) {
		$datachannel->{fbamodel}->attributes()->{pathways} = {};
		$datachannel->{fbamodel}->attributes()->{fba} = {};
		$datachannel->{fbamodel}->attributes()->{auxotrophy} = {};
	}
	#Propagating coverage from input metagenome object
	if (defined($params->{metagenome_model_id})) {
		my $metamodel = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{metagenome_model_id},$params->{metagenome_model_workspace}));
		if (!defined($metamodel->contig_coverages())) {
			print "Input metagenome model does not include coverage information, so coverages cannot be computed for this metagenome assembled genome.\n";	
		} else {
			my $covhash = $metamodel->contig_coverages();
			if ($params->{coverage_propagation} eq "mag") {
				my $totallength = 0;
				my $magcoverage = 0;
				my $assembly_object = $handler->util_get_object(Bio::KBase::utilities::buildref($datachannel->{fbamodel}->genome()->assembly_ref(),$params->{input_workspace}));
				my $allfound = 1;
				foreach my $contigid (keys(%{$assembly_object->{contigs}})) {
					$totallength += $assembly_object->{contigs}->{$contigid}->{"length"};
					if (defined($covhash->{$contigid})) {
						$magcoverage += $assembly_object->{contigs}->{$contigid}->{"length"}*$covhash->{$contigid};
					} else {
						$allfound = 0;
					}
				}
				if ($allfound == 1) {
					$magcoverage = $magcoverage/$totallength;
					my $rxns = $datachannel->{fbamodel}->modelreactions();
					for (my $i=0; $i < @{$rxns}; $i++) {
						my $proteins = $rxns->[$i]->modelReactionProteins();
						my $count = @{$proteins};
						$rxns->[$i]->coverage($count*$magcoverage);
					}
				} else {
					print "MAG contains one or more contigs that are not included in the metagenome model!\n";
				}
			} else {
				my $ftrs = $datachannel->{fbamodel}->genome()->features();
				my $gene_coverages = {};
				my $allfound = 1;
				for (my $i=0; $i < @{$ftrs}; $i++) {
					my $contig = $ftrs->[$i]->location()->[0]->[0];
					if (defined($covhash->{$contig})) {
						$gene_coverages->{$ftrs->[$i]->id()} = $covhash->{$contig};
					} else {
						$allfound = 0;
					}
				}
				if ($allfound == 1) {
					my $rxns = $datachannel->{fbamodel}->modelreactions();
					for (my $i=0; $i < @{$rxns}; $i++) {
						$rxns->[$i]->compute_reaction_coverage_from_gene_coverage($gene_coverages);
					}
				} else {
					print "MAG contains one or more contigs that are not included in the metagenome model!\n";
				}
			}
		}
	}
	#Instantiating attribute data
	my $attributes = {
		pathways => {},
		auxotrophy => {},
		fbas => {},
		gene_count => 0,
		auxotroph_count => 0
	};
	#Cloning the original model and removing all gapfilled reactions to create a base model
	my $clone_model = $datachannel->{fbamodel}->cloneObject();
	$clone_model->parent($datachannel->{fbamodel}->parent());
	$clone_model->remove_all_gapfilled_reactions();
	#Computing base ATP and gapfilling attributes : only recomputed if original numbers didn't exist
	if (!defined($clone_model->attributes()->{base_atp}) || $clone_model->attributes()->{base_atp} == 0) {
		$clone_model->EnsureProperATPProduction();
	}
	$attributes->{base_atp} = $clone_model->attributes()->{base_atp};
	$attributes->{initial_atp} = $clone_model->attributes()->{initial_atp};
	$attributes->{base_rejected_reactions} = $clone_model->attributes()->{base_rejected_reactions};
	$attributes->{core_gapfilling} = $clone_model->attributes()->{core_gapfilling};
	#Predicting auxotrophy against using just the base model
	$datachannel->{fbamodel} = $clone_model;
	my $auxomedia = "Carbon-D-Glucose";
	my $auxomedia_ws = "KBaseMedia";
	if ($params->{predict_auxotrophy} == 1) {
		my $auxo_output = Bio::KBase::ObjectAPI::functions::func_predict_auxotrophy_from_model({
			workspace => $params->{workspace},
			fbamodel_id => $params->{fbamodel_output_id},
		},$datachannel);
		foreach my $cpd (keys(%{$auxo_output->{auxotrophy_data}})) {
			$attributes->{auxotrophy}->{$cpd} = {
				compound_name => $auxo_output->{auxotrophy_data}->{$cpd}->{name},
				reactions_required => $auxo_output->{auxotrophy_data}->{$cpd}->{totalrxn},
				gapfilled_reactions => $auxo_output->{auxotrophy_data}->{$cpd}->{gfrxn},
				is_auxotrophic => $auxo_output->{auxotrophy_data}->{$cpd}->{auxotrophic}
			};
			if ($auxo_output->{auxotrophy_data}->{$cpd}->{auxotrophic} == 1) {
				$attributes->{auxotroph_count}++;
			}
		}
		$auxomedia = $params->{fbamodel_output_id}.".auxo_media";
		$auxomedia_ws = $params->{workspace};
	} else {
		my $baseline_solution = Bio::KBase::ObjectAPI::functions::func_baseline_gapfilling({
			workspace => "NULL",
			fbamodel_id => $params->{fbamodel_id},
		},$datachannel);
	}
	$attributes->{baseline_gapfilling} = $datachannel->{fbamodel}->attributes()->{baseline_gapfilling};
	#This is weird, but now I am clearing the cache because the cloning process seems to corrupt the original model object somehow
	$datachannel->{fbamodel}->parent()->cache({});
	#Now gapfilling original model in auxotrophic media
	$datachannel->{fbamodel} = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{fbamodel_id},$params->{fbamodel_workspace}));
	if (defined($datachannel->{fbamodel}->attributes())) {
		$datachannel->{fbamodel}->attributes()->{pathways} = {};
		$datachannel->{fbamodel}->attributes()->{fba} = {};
		$datachannel->{fbamodel}->attributes()->{auxotrophy} = {};
	}
	Bio::KBase::ObjectAPI::functions::add_auxotrophy_transporters({fbamodel => $datachannel->{fbamodel}});
	my $gapfill_output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
		workspace => $params->{workspace},
		fbamodel_id => $params->{fbamodel_id},
		media_id => $auxomedia,
		media_workspace => $auxomedia_ws,
		fbamodel_output_id => $params->{fbamodel_output_id}
	},$datachannel);
	$attributes->{auxotrophy_gapfilling} = $gapfill_output->{number_gapfilled_reactions};
	my $fba_output = Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis({
		workspace => $params->{workspace},
		fbamodel_id => $params->{fbamodel_output_id},
		fba_output_id => $params->{fbamodel_output_id}.".fba",
		media_id => $auxomedia,
		media_workspace => $auxomedia_ws,
		fva => 1,
		minimize_flux => 1,
		max_c_uptake => 30
	},$datachannel);
	$attributes->{fbas}->{auxomedia}->{biomass} = $fba_output->{objective}+0;
	$attributes->{fbas}->{auxomedia}->{fba_ref} = $datachannel->{fba}->_reference();
	$attributes->{fbas}->{auxomedia}->{Blocked} = 0;
	$attributes->{fbas}->{auxomedia}->{Negative} = 0;
	$attributes->{fbas}->{auxomedia}->{Positive} = 0;
	$attributes->{fbas}->{auxomedia}->{Variable} = 0;
	$attributes->{fbas}->{auxomedia}->{PositiveVariable} = 0;
	$attributes->{fbas}->{auxomedia}->{NegativeVariable} = 0;
	my $rxnvar = $datachannel->{fba}->FBAReactionVariables();
	my $classhash = {};
	for (my $i=0; $i < @{$rxnvar}; $i++) {
		if ($rxnvar->[$i]->modelreaction_ref() =~ m/(rxn\d+)/) {
			$classhash->{$1}->{auxo} = $rxnvar->[$i]->{class};
		}
		$rxnvar->[$i]->{class} =~ s/\sv/V/;
		$attributes->{fbas}->{auxomedia}->{$rxnvar->[$i]->{class}}++;
	}
	$fba_output = Bio::KBase::ObjectAPI::functions::func_run_flux_balance_analysis({
		workspace => $params->{workspace},
		fbamodel_id => $params->{fbamodel_output_id}.".gapfilled",
		fba_output_id => $params->{fbamodel_output_id}.".fba",
		fva => 1,
		minimize_flux => 1,
		max_c_uptake => 30
	},$datachannel);
	$attributes->{fbas}->{complete}->{biomass} = $fba_output->{objective}+0;
	$attributes->{fbas}->{complete}->{fba_ref} = $datachannel->{fba}->_reference();
	$attributes->{fbas}->{complete}->{Blocked} = 0;
	$attributes->{fbas}->{complete}->{Negative} = 0;
	$attributes->{fbas}->{complete}->{Positive} = 0;
	$attributes->{fbas}->{complete}->{PositiveVariable} = 0;
	$attributes->{fbas}->{complete}->{NegativeVariable} = 0;
	$attributes->{fbas}->{complete}->{Variable} = 0;
	$rxnvar = $datachannel->{fba}->FBAReactionVariables();
	for (my $i=0; $i < @{$rxnvar}; $i++) {
		if ($rxnvar->[$i]->modelreaction_ref() =~ m/(rxn\d+)/) {
			$classhash->{$1}->{comp} = $rxnvar->[$i]->{class};
		}
		$rxnvar->[$i]->{class} =~ s/\sv/V/;
		$attributes->{fbas}->{complete}->{$rxnvar->[$i]->{class}}++;
	}
	$attributes->{gene_count} = @{$datachannel->{fbamodel}->features()};
	if ($attributes->{gene_count} == 0) {
		my $mdlrxns = $datachannel->{fbamodel}->modelreactions();
		foreach my $rxn (@{$mdlrxns}) {
			if (defined($rxn->gene_count())) {
				$attributes->{gene_count} += $rxn->gene_count();
			}
		}
	}
	$datachannel->{fbamodel}->ComputePathwayAttributes($classhash);
	$attributes->{pathways} = $datachannel->{fbamodel}->attributes()->{pathways};
	$datachannel->{fbamodel}->attributes($attributes);
	my $wsmeta = $handler->util_save_object($datachannel->{fbamodel},Bio::KBase::utilities::buildref($params->{fbamodel_output_id},$params->{workspace}));

	my $string;
	Bio::KBase::Templater::render_template(
		Bio::KBase::utilities::conf("fba_tools","model_characterisation_template"),
		{ template_data => $datachannel->{ fbamodel }->serializeToDB() },
		\$string,
	);

	#print "TEMPLATE:".$string."\n\n";

	Bio::KBase::utilities::print_report_message( {
		message => $string,
		append  => 0,
		html	=> 1,
	} );

	return {
		new_fbamodel_ref => $datachannel->{fbamodel}->_wswsid()."/".$datachannel->{fbamodel}->_wsobjid()."/".$datachannel->{fbamodel}->_wsversion(),
		new_fba_ref => $datachannel->{fba}->_wswsid()."/".$datachannel->{fba}->_wsobjid()."/".$datachannel->{fbamodel}->_wsversion()
	};
}

sub func_lookup_modelseed_ids {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","chemical_abundance_matrix_id"],{
		chemical_abundance_matrix_out_id => $params->{chemical_abundance_matrix_id},
		matrix_workspace => $params->{workspace}
	});
	my $object = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{chemical_abundance_matrix_id},$params->{matrix_workspace}));
	my $mapping = $handler->util_get_object($object->{row_attributemapping_ref});
	my $attribute_hash = {};
	my $count = 0;
	for (my $m=0; $m < @{$mapping->{attributes}}; $m++) {
		if ($mapping->{attributes}->[$m]->{attribute} eq "seed_id") {
			$mapping->{attributes}->[$m]->{attribute} = "modelseed";
		}
		$attribute_hash->{$mapping->{attributes}->[$m]->{attribute}} = $m;
		$count++;
	}
	if (!defined($attribute_hash->{modelseed})) {
		push(@{$mapping->{attributes}},{
			attribute => "modelseed",
			attribute_ont_id => "Custom:Term",
			attribute_ont_ref => "KbaseOntologies/Custom",
			source => "ModelSEED"
		});
		$attribute_hash->{modelseed} = $count;
	}
	my $args = {
		priority => 0,
		compartment => ""
	};
	Bio::KBase::utilities::metabolite_hash($args);
	my $metabolite_hash = $args->{hashes};
	foreach my $rowid (keys(%{$mapping->{instances}})) {
		my $seedhash = {};
		#First check if there is already a modelseed ID associated with the compound
		if (defined($attribute_hash->{modelseed}) && defined($mapping->{instances}->{$rowid}->[$attribute_hash->{modelseed}]) && length($mapping->{instances}->{$rowid}->[$attribute_hash->{modelseed}]) > 0) {
			my $array = [split(/;\|/,$mapping->{instances}->{$rowid}->[$attribute_hash->{modelseed}])];
			foreach my $item (@{$array}) {
				$seedhash->{$item} = 1;
			}
		}
		if (keys(%{$seedhash}) == 0 && defined($attribute_hash->{kegg}) && defined($mapping->{instances}->{$rowid}->[$attribute_hash->{kegg}]) && length($mapping->{instances}->{$rowid}->[$attribute_hash->{kegg}]) > 0) {
			#Now check if there is a KEGG ID
			my $array = [split(/[;\|]/,$mapping->{instances}->{$rowid}->[$attribute_hash->{kegg}])];
			for (my $i=0; $i < @{$array}; $i++) {
				if (defined($metabolite_hash->{ids}->{$array->[$i]})) {
					foreach my $seedid (keys(%{$metabolite_hash->{ids}->{$array->[$i]}})) {
						$seedhash->{$seedid} = 1;
					}
				}
			}
		}
		if (keys(%{$seedhash}) == 0 && defined($attribute_hash->{inchikey}) && defined($mapping->{instances}->{$rowid}->[$attribute_hash->{inchikey}]) && length($mapping->{instances}->{$rowid}->[$attribute_hash->{inchikey}]) > 0) {
			#Now check if there is an inchikey
			my $inchikey = $mapping->{instances}->{$rowid}->[$attribute_hash->{inchikey}];
			my $found = 0;
			if (defined($metabolite_hash->{structures}->{$inchikey})) {
				foreach my $seedid (keys(%{$metabolite_hash->{structures}->{$inchikey}})) {
					$found = 1;
					$seedhash->{$seedid} = 1;
				}
			}
			if ($found == 0) {
				$inchikey =~ s/-.$//;
				if (defined($metabolite_hash->{nochargestructures}->{$inchikey})) {
					foreach my $seedid (keys(%{$metabolite_hash->{structures}->{$inchikey}})) {
						$found = 1;
						$seedhash->{$seedid} = 1;
					}
				}
			}
		}
		if (keys(%{$seedhash}) == 0 && defined($attribute_hash->{inchi}) && defined($mapping->{instances}->{$rowid}->[$attribute_hash->{inchi}]) && length($mapping->{instances}->{$rowid}->[$attribute_hash->{inchi}]) > 0) {
			#Now check if there is an inchi
			if (defined($metabolite_hash->{structures}->{$mapping->{instances}->{$rowid}->[$attribute_hash->{inchi}]})) {
				foreach my $seedid (keys(%{$metabolite_hash->{structures}->{$mapping->{instances}->{$rowid}->[$attribute_hash->{inchi}]}})) {
					$seedhash->{$seedid} = 1;
				}
			}
		}
		if (keys(%{$seedhash}) == 0 && defined($attribute_hash->{smiles}) && defined($mapping->{instances}->{$rowid}->[$attribute_hash->{smiles}]) && length($mapping->{instances}->{$rowid}->[$attribute_hash->{smiles}]) > 0) {
			#Now check if there is a smiles
			if (defined($metabolite_hash->{structures}->{$mapping->{instances}->{$rowid}->[$attribute_hash->{smiles}]})) {
				foreach my $seedid (keys(%{$metabolite_hash->{structures}->{$mapping->{instances}->{$rowid}->[$attribute_hash->{smiles}]}})) {
					$seedhash->{$seedid} = 1;
				}
			}
		}
		if (keys(%{$seedhash}) == 0 && defined($attribute_hash->{name}) && defined($mapping->{instances}->{$rowid}->[$attribute_hash->{name}]) && length($mapping->{instances}->{$rowid}->[$attribute_hash->{name}]) > 0) {
			#Now check if there is a name
			my $searchname = Bio::KBase::utilities::nameToSearchname($mapping->{instances}->{$rowid}->[$attribute_hash->{name}]);
			if (defined($metabolite_hash->{names}->{$searchname})) {
				foreach my $seedid (keys(%{$metabolite_hash->{names}->{$searchname}})) {
					$seedhash->{$seedid} = 1;
				}
			}
		}
		if (keys(%{$seedhash}) == 0) {
			#Now check if the ID matches an ID
			if (defined($metabolite_hash->{ids}->{$rowid})) {
				foreach my $seedid (keys(%{$metabolite_hash->{ids}->{$rowid}})) {
					$seedhash->{$seedid} = 1;
				}
			}
		}
		if (keys(%{$seedhash}) == 0) {
			#Now check if the ID matches an ID
			my $searchname = Bio::KBase::utilities::nameToSearchname($rowid);
			if (defined($metabolite_hash->{names}->{$searchname})) {
				foreach my $seedid (keys(%{$metabolite_hash->{names}->{$searchname}})) {
					$seedhash->{$seedid} = 1;
				}
			}
		}
		if (keys(%{$seedhash}) == 0 && defined($attribute_hash->{formula}) && defined($mapping->{instances}->{$rowid}->[$attribute_hash->{formula}]) && length($mapping->{instances}->{$rowid}->[$attribute_hash->{formula}]) > 0) {
			#Now check if there is a formula
			if (defined($metabolite_hash->{formula}->{$mapping->{instances}->{$rowid}->[$attribute_hash->{formula}]})) {
				foreach my $seedid (keys(%{$metabolite_hash->{formula}->{$mapping->{instances}->{$rowid}->[$attribute_hash->{formula}]}})) {
					$seedhash->{$seedid} = 1;
				}
			}
		}
		if (keys(%{$seedhash}) > 0) {
			$mapping->{instances}->{$rowid}->[$attribute_hash->{modelseed}] = join(";",keys(%{$seedhash}));
		} else {
			$mapping->{instances}->{$rowid}->[$attribute_hash->{modelseed}] = "";
		}
	}
#	my $string;
#	Bio::KBase::Templater::render_template(
#		Bio::KBase::utilities::conf("fba_tools","metabolomics_template"),
#		{ template_data => $metabolomics_data },
#		\$string,
#	);
#	Bio::KBase::utilities::print_report_message({message => $htmlreport,append => 0,html => 1});
	my $attmapping = $handler->util_save_object($mapping,Bio::KBase::utilities::buildref($params->{chemical_abundance_matrix_out_id}."AttMap",$params->{workspace}),{hash => 1,type => "KBaseExperiments.AttributeMapping"});
	$object->{row_attributemapping_ref} = util_get_ref($attmapping);
	my $wsmeta = $handler->util_save_object($object,Bio::KBase::utilities::buildref($params->{chemical_abundance_matrix_out_id},$params->{workspace}),{hash => 1,type => "KBaseMatrices.ChemicalAbundanceMatrix"});
	return {
		new_chemical_abundance_matrix_ref => util_get_ref($wsmeta)
	};
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
	my $bio = $handler->util_get_object(Bio::KBase::utilities::conf("ModelSEED","default_biochemistry"),{});
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
				minFlux => $params->{compounds_to_add}->[$i]->{add_minflux},
				maxFlux => $params->{compounds_to_add}->[$i]->{add_maxflux}
			};
			if (defined($cpd)) {
				$newmediacpd->{id} = $cpd->id();
				$newmediacpd->{name} = $cpd->name();
				$newmediacpd->{compound_ref} = Bio::KBase::utilities::conf("ModelSEED","default_biochemistry")."/compounds/id/".$cpd->id();
			} else {
				$newmediacpd->{id} = $params->{compounds_to_add}->[$i]->{add_id};
				$newmediacpd->{name} = $params->{compounds_to_add}->[$i]->{add_id};
				$newmediacpd->{compound_ref} = Bio::KBase::utilities::conf("ModelSEED","default_biochemistry")."/compounds/id/cpd00000";
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

sub func_run_pickaxe {
	my ($params,$datachannel) = @_;
	$params = Bio::KBase::utilities::args($params,["workspace","model_id"],{
		rule_sets => ["enzymatic"],
		generations => 1,
		prune => "none",
		add_transport => 0,
		out_model_id => $params->{model_id}.".pickax",
		template_id => "gramneg",
		template_workspace => undef,
		metabolomics_data => undef,
		metabolomics_workspace => $params->{workspace},
		model_workspace => $params->{workspace},
		compound_limit => 100000,
		keep_seed_hits => 1,
		keep_metabolomic_hits => 1,
		discard_orphan_hits => 0,
		target_id => undef,
		target_workspace => $params->{workspace},
		max_new_cpds_per_gen_per_ruleset => 3000,
		max_hits_to_keep_per_peak => 10
	});
	#Setting generation if this is the first time calling the function
	if (!defined($datachannel->{currentgen})) {
		$datachannel->{currentgen} = 1;
	} else {
		$datachannel->{currentgen}++;
	}
	if (!defined($datachannel->{metabolomics_data})) {
		$datachannel->{peak_hits} = {};
		$datachannel->{cpd_hits} = {};
		$datachannel->{metabolomics_data} = {
			formula_to_peaks => {},
			inchikey_to_peaks => {},
			smiles_to_peaks => {}
		};
		if (defined($params->{metabolomics_data})) {
			my $data;
			if (-e $params->{metabolomics_data}) {
				$data = Bio::KBase::ObjectAPI::functions::load_matrix($params->{metabolomics_data});
				$datachannel->{MetabolomicsDBLINKSKey} = "MetabolomicsDataset";
			} else {
				$datachannel->{KBaseMetabolomicsObject} = Bio::KBase::utilities::buildref($params->{metabolomics_data},$params->{metabolomics_workspace});
				my $object = $handler->util_get_object($datachannel->{KBaseMetabolomicsObject});
				$datachannel->{KBaseMetabolomicsObject} = "KBWS/".$datachannel->{KBaseMetabolomicsObject};
				$datachannel->{MetabolomicsDBLINKSKey} = $datachannel->{KBaseMetabolomicsObject};
				$data = Bio::KBase::ObjectAPI::functions::process_matrix($object);
			}
			for (my $i=0; $i < @{$data->{row_ids}}; $i++) {
				my $types = ["inchikey","smiles","formula"];
				my $found = 0;
				for (my $j=0; $j < @{$types}; $j++) {
				   if ($found == 0) {
						for (my $k=0; $k < @{$data->{attributes}}; $k++) {
							if ($data->{attributes}->[$k] eq $types->[$j]) {
								my $key = $types->[$j]."_to_peaks";
								my $value = $data->{attribute_values}->[$i]->[$k];
								if ($types->[$j] eq "inchikey") {
									my $array = [split(/[-]/,$value)];
									$value = $array->[0];
								}
								if (length($value) > 0) {
									$datachannel->{metabolomics_data}->{$key}->{$value}->{$data->{row_ids}->[$i]} = 1;
									$found = 1;
								}
							}
						}
					}
				}
			}
		}
	}
	 #Loading model or compound set
	my $seedhash =  Bio::KBase::utilities::compound_hash();
	my $seedrxnhash =  Bio::KBase::utilities::reaction_hash();
	#Populating structure hash data for entire SEED database
	if (!defined($datachannel->{smileshash})) {
		my $cpddata = {};
		$datachannel->{cpd_hits} = {};
		$datachannel->{peak_hits} = {};
		$datachannel->{reaction_hash} = {};
		foreach my $cpdid (keys(%{$seedhash})) {
			my $data = {
				id => $cpdid,
				name => $seedhash->{$cpdid}->{name},
				charge => $seedhash->{$cpdid}->{charge},
				formula => $seedhash->{$cpdid}->{neutral_formula},
				rxncount => 0,
				source => "seed"
			};
			$cpddata->{$cpdid} = $data;
			if (defined($seedhash->{$cpdid}->{smiles})) {
				$datachannel->{smileshash}->{$seedhash->{$cpdid}->{smiles}}->{seed}->{$cpdid} = $data;
				$data->{smiles} = $seedhash->{$cpdid}->{smiles};
				if (defined($seedhash->{$cpdid}->{inchikey}) && !defined($datachannel->{inchihash}->{$seedhash->{$cpdid}->{inchikey}})) {
					$data->{inchikey} = $seedhash->{$cpdid}->{inchikey};
					$datachannel->{inchihash}->{$seedhash->{$cpdid}->{inchikey}} = $data;
				}
			} elsif (defined($seedhash->{$cpdid}->{inchikey}) && !defined($datachannel->{inchihash}->{$seedhash->{$cpdid}->{inchikey}})) {
				$datachannel->{inchihash}->{$seedhash->{$cpdid}->{inchikey}} = $data;
				$data->{inchikey} = $seedhash->{$cpdid}->{inchikey};
			}
			#Checking SEED database for metabolomics matches
			Bio::KBase::ObjectAPI::functions::check_for_peakmatch($datachannel->{metabolomics_data},$datachannel->{cpd_hits},$datachannel->{peak_hits},$data,0,"seed",1,$datachannel->{KBaseMetabolomicsObject});
		}
		foreach my $rxnid (keys(%{$seedrxnhash})) {
			foreach my $cpdid (@{$seedrxnhash->{$rxnid}->{compound_ids}}) {
				$cpddata->{$cpdid}->{rxncount}++;
			}
		}
	}
	my $directory = Bio::KBase::utilities::conf("kb_pickaxe","scratch");
	my $input_model_array = ["id\tstructure"];
	my $input_compounds_with_no_structure = [];
	my $input_compounds_with_structure = 0;
	my $dbhits = {inchi => 0,seed => 0,model => 0};
	my $input_ids = {};
	if (!defined($datachannel->{fbamodel})) {
		#This must be the first time calling the function
		$datachannel->{targethash} = {};
		#Processing target list if provided
		if (defined($params->{target_id})) {
				my $object = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{target_id},$params->{target_workspace}));
				for (my $i=0; $i<@{$object->{compounds}}; $i++) {
				my $cpd = $object->{compounds}->[$i];
				if (defined($cpd->{smiles}) && length($cpd->{smiles}) > 0) {
					$datachannel->{targethash}->{$cpd->{smiles}} = [$cpd->{id},$cpd->{name}];
				}
			}
		}
		my $object = $handler->util_get_object(Bio::KBase::utilities::buildref($params->{model_id},$params->{model_workspace}));
		#Creating model to contain chemistry generated by pickaxe
		my $template_trans = Bio::KBase::constants::template_trans();
		$datachannel->{fbamodel} = {
			id => $params->{out_model_id},
			source => "PickAxe",
			source_id => $params->{out_model_id},
			type => "MINE",
			name => $params->{out_model_id},
			template_ref => Bio::KBase::utilities::conf("ModelSEED","default_template_workspace")."/".$template_trans->{$params->{template_id}},
			template_refs => [Bio::KBase::utilities::conf("ModelSEED","default_template_workspace")."/".$template_trans->{$params->{template_id}}],
			gapfillings => [],
			gapgens => [],
			biomasses => [],
			modelcompartments => [{
					compartmentIndex => 0,
					compartment_ref => "~/template/compartments/id/c",
					id => "c0",
					label => "Cytoplasm",
					pH => 7.3,
					potential => 1
				},{
					compartmentIndex => 0,
					compartment_ref => "~/template/compartments/id/e",
					id => "e0",
					label => "Extracellular",
					pH => 7.3,
					potential => 1
				}],
			modelcompounds => [],
			modelreactions => []
		};
		#Processing input object with initial compounds
		if (ref($object) eq "HASH") {
			#Rather than a metabolic model, a compound set is the input
			for (my $i=0; $i<@{$object->{compounds}}; $i++) {
				my $cpd = $object->{compounds}->[$i];
				#Checking input compoundset for metabolomics matches
				Bio::KBase::ObjectAPI::functions::check_for_peakmatch($datachannel->{metabolomics_data},$datachannel->{cpd_hits},$datachannel->{peak_hits},$cpd,0,"model",0,$datachannel->{KBaseMetabolomicsObject});
				if (!defined($cpd->{smiles}) || length($cpd->{smiles}) == 0) {
					push(@{$input_compounds_with_no_structure},$cpd->{id}."\t".$cpd->{name});
				} else {
					$input_compounds_with_structure++;
					$cpd->{id} =~ s/_[a-z]\d+$/_c0/;
					if (!defined($input_ids->{$cpd->{id}})) {
						my $cpdref = "cpd00000";
						if ($cpd->{id} =~ m/(cpd\d+)/) {
							$cpdref = $1;
						}
						$input_ids->{$cpd->{id}} = 1;
						push(@{$input_model_array},$cpd->{id}."\t".$cpd->{smiles});
						$datachannel->{smileshash}->{$cpd->{smiles}}->{model}->{$cpd->{id}} = $cpd;
						$datachannel->{cpdhash}->{$cpd->{id}} = {
							id => $cpd->{id},
							name => $cpd->{id},
							charge => 0,
							smiles => $cpd->{smiles},
							numerical_attributes => {generation => 0},
							aliases => [],
							compound_ref => "~/template/compounds/id/".$cpdref,
							dblinks => {},
							modelcompartment_ref => "~/modelcompartments/id/c0",
							string_attributes => {}
						};
						push(@{$datachannel->{fbamodel}->{modelcompounds}},$datachannel->{cpdhash}->{$cpd->{id}});
					}
				}
			}
		} else {
			#Populating structure hash data for input model
			$datachannel->{inputmdl} = $object;
			my $cpds = $object->modelcompounds();
			my $cpddatahash = {};
			for (my $i=0; $i < @{$cpds}; $i++) {
				my $id = $cpds->[$i]->id();
				$id =~ s/_[a-z]\d+$/_c0/;
				$cpddatahash->{$id} = {
					rxncount => 0,
					id => $id,
					name => $cpds->[$i]->name(),
					charge => $cpds->[$i]->charge(),
					formula => $cpds->[$i]->neutral_formula(),
					aliases => [],
					compound_ref => $cpds->[$i]->compound_ref(),
					dblinks => {},
					modelcompartment_ref => "~/modelcompartments/id/c0",
					string_attributes => {}
				};
				if (!defined($cpds->[$i]->smiles()) && length($cpds->[$i]->smiles()) == 0) {
					push(@{$input_compounds_with_no_structure},$id."\t".$cpds->[$i]->name());
				} elsif (!defined($cpds->[$i]->inchikey()) && length($cpds->[$i]->inchikey()) > 0) {
					#This is for the unlikely scenario that there is an inchikey but no smiles
					$datachannel->{inchihash}->{$cpds->[$i]->inchikey()}->{model}->{$id} = $cpddatahash->{$id};
					$cpddatahash->{$id}->{inchikey} = $cpds->[$i]->inchikey();
				} else {
					$cpddatahash->{$id}->{smiles} = $cpds->[$i]->smiles();
					$datachannel->{smileshash}->{$cpds->[$i]->smiles()}->{model}->{$id} = $cpddatahash->{$id};
					if (defined($cpds->[$i]->inchikey()) && length($cpds->[$i]->inchikey()) > 0) {
						$cpddatahash->{$id}->{inchikey} = $cpds->[$i]->inchikey();
						$datachannel->{inchihash}->{$cpds->[$i]->inchikey()}->{model}->{$id} = $cpddatahash->{$id};
					}
					$input_compounds_with_structure++;
					$input_ids->{$id} = 1;
					push(@{$input_model_array},$id."\t".$cpds->[$i]->smiles());
					$cpds->[$i]->{numerical_attributes}->{generation} = 0;
					$datachannel->{cpdhash}->{$id} = $cpds->[$i]->serializeToDB();
					push(@{$datachannel->{fbamodel}->{modelcompounds}},$datachannel->{cpdhash}->{$id});
				}
				#Checking input compoundset for metabolomics matches
				Bio::KBase::ObjectAPI::functions::check_for_peakmatch($datachannel->{metabolomics_data},$datachannel->{cpd_hits},$datachannel->{peak_hits},$cpddatahash->{$cpds->[$i]->id()},0,"model",0,$datachannel->{KBaseMetabolomicsObject});
			}
			my $rxns = $object->modelreactions();
			for (my $i=0; $i < @{$rxns}; $i++) {
				my $rgts = $rxns->[$i]->modelReactionReagents();
				for (my $j=0; $j < @{$rgts}; $j++) {
					$cpddatahash->{$rgts->[$j]->modelcompound()->id()}->{rxncount}++;
				}
			}
		}
		#Populating initial compound and peak stats
		print "Structures found for ".$input_compounds_with_structure." compounds in the input!\n";
		print "No structures found for ".@{$input_compounds_with_no_structure}." compounds, as follows:\n".join("\n",@{$input_compounds_with_no_structure})."\n";
	} else {
		#This is a second or greater generation run and we want to create pickaxe input from new compounds in the input model
		my $cpds = $datachannel->{fbamodel}->{modelcompounds};
		for (my $i=0; $i < @{$cpds}; $i++) {
			if ($cpds->[$i]->{numerical_attributes}->{generation} == ($datachannel->{currentgen}-1)) {
				$input_ids->{$cpds->[$i]->{id}} = 1;
				$input_compounds_with_structure++;
				push(@{$input_model_array},$cpds->[$i]->{id}."\t".$cpds->[$i]->{smiles});
			}
		}
	}
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."/inputModel.tsv",$input_model_array);
	if ($input_compounds_with_structure == 0) {
		if ($datachannel->{currentgen} == 1) {
			Bio::KBase::utilities::print_report_message({message => "<p>Pickaxe could not be run. No input compounds with structure were provided. If inputing a metabolic model, try integrating the model with ModelSEED IDs prior to running pickaxe.</p>",append => 0,html => 1});
		} else {
			Bio::KBase::utilities::print_report_message({message => "<p>Pickaxe run ended prematurely at generation ".($datachannel->{currentgen}-1)." because no new compounds were generated in the last generation.</p>",append => 1,html => 1});
		}
	} else {
		#Iterating over rulesets and running the pickaxe command for each one
		my $rxn_id_prefix = "pkr";
		my $cpd_id_prefix = "pkc";
		my $peak_hit = {};
		my $cpd_hit = {};
		my $modelcpds = {};
		foreach my $ruleset (@{$params->{rule_sets}}) {
			print $ruleset."\n";
			my $command = "python3 ".Bio::KBase::utilities::conf("kb_pickaxe","pickaxe_path")."pickaxe.py -g 1 -c ".$directory."/inputModel.tsv -o ".$directory;
			my $coreactant_path = Bio::KBase::utilities::conf("kb_pickaxe","pickaxe_path")."/data/NoCoreactants.tsv";
			my $retro_rule_path = Bio::KBase::utilities::conf("kb_pickaxe","pickaxe_path")."/data/".$ruleset.".tsv --bnice -q -m 4";
			if ($ruleset eq 'spontaneous') {
				$rxn_id_prefix = "spontr";
				$cpd_id_prefix = "spontc";
				$command .= ' -C '.Bio::KBase::utilities::conf("kb_pickaxe","pickaxe_path").'/data/ChemicalDamageCoreactants.tsv -r '.Bio::KBase::utilities::conf("kb_pickaxe","pickaxe_path").'/data/ChemicalDamageReactionRules.tsv';
			} elsif ($ruleset eq 'enzymatic') {
				$rxn_id_prefix = "enzr";
				$cpd_id_prefix = "enzc";
				$command .= ' -C '.Bio::KBase::utilities::conf("kb_pickaxe","pickaxe_path").'/data/EnzymaticCoreactants.tsv -r '.Bio::KBase::utilities::conf("kb_pickaxe","pickaxe_path").'/data/EnzymaticReactionRules.tsv --bnice';
			} elsif ($ruleset =~ /retro_rules/) {
				$rxn_id_prefix = "rrr";
				$cpd_id_prefix = "rrc";
				$command .= " -C $coreactant_path -r $retro_rule_path";
			} else {
				die "Invalid reaction rule set or rule set not defined";
			}
			#Dealing with pruning policy
			if ($params->{prune} eq 'model') {
				$command .= ' -p '.$directory.'/inputModel.tsv';
			} elsif ($params->{prune} eq 'biochemistry') {
				$command .= ' -p '.Bio::KBase::utilities::conf("kb_pickaxe","pickaxe_path").'/data/Compounds.json';
			}
			#Running pickax
			system($command);
			#Parsing current pickax output and adding to model
			my $cpdfilename = $directory."/compounds.tsv";
			my $rxnfilename = $directory."/reactions.tsv";
			if (-e $cpdfilename && -e $rxnfilename) {
				#Adding compounds to model
				my $cpdarray = Bio::KBase::ObjectAPI::utilities::LOADFILE($cpdfilename);
				my $cpdid_translation = {};
				my $initially_pruned = {};
				my $newcpdcount = 0;
				for (my $i=1; $i < @{$cpdarray}; $i++) {
					if (!defined($datachannel->{current_id}->{$cpd_id_prefix})) {
						$datachannel->{current_id}->{$cpd_id_prefix} = 1;
					}
					my $array = [split(/\t/,$cpdarray->[$i])];
					my $original_id = $array->[0];
					my $id = $original_id;
					#Making sure the ID includes a compartment
					if ($id !~ m/_[a-z]\d+$/) {
						$original_id .= "_c0";
						$id .= "_c0";
					}
					my $name;
					my $inchikey = $array->[5];
					my $smiles = $array->[6];
					my $charge = $array->[4];
					my $formula = $array->[3];
					my $type = "pickax";
					$formula =~ s/(\+|-)\d*$//;#Removing formula charge
					my $nonneutral_formula = $formula;
					$formula = Bio::KBase::utilities::compute_neutral_formula($formula,$charge,$id);
					#Check if the ID already exists in the output model
					if (defined($datachannel->{cpdhash}->{$original_id})) {
						next;#Do nothing... compound is already in output
					#Check if the ID is in the input model submitted to start the app
					} elsif (defined($datachannel->{inputmdl}) && defined($datachannel->{inputmdl}->getObject("modelcompounds",$original_id))) {
						#Add compound to output model with data from the input model
						$type = "model";
						my $cpdobj = $datachannel->{inputmdl}->getObject("modelcompounds",$original_id);
						$id = $cpdobj->id();
						$name = $cpdobj->name();
						$charge = $cpdobj->charge();
						$nonneutral_formula = $cpdobj->formula();
						$formula = $cpdobj->neutral_formula();
						if (defined($cpdobj->inchikey()) && length($cpdobj->inchikey()) > 0) {
							$inchikey = $cpdobj->inchikey();
						}
						if (defined($cpdobj->smiles()) && length($cpdobj->smiles()) > 0) {
							$smiles = $cpdobj->smiles();
						}
					#Check if the ID is from the ModelSEED
					} elsif ($original_id =~ m/(cpd\d+)/ && defined($seedhash->{$1})) {
						#Add compound to output model with data from the SEED
						$type = "seed";
						my $baseid = $1;
						$name = $seedhash->{$baseid}->{name};
						$charge = $seedhash->{$baseid}->{charge};
						$nonneutral_formula = $seedhash->{$baseid}->{formula};
						$formula = $seedhash->{$baseid}->{neutral_formula};
						$smiles = $seedhash->{$baseid}->{smiles};
						$inchikey = $seedhash->{$baseid}->{inchikey};
					} elsif (defined($datachannel->{inchihash}->{$inchikey})) {
						$type = "inchimatch";
						$dbhits->{inchi}++;
						$id = $datachannel->{inchihash}->{$inchikey}->{id};
						$name = $datachannel->{inchihash}->{$inchikey}->{name};
						$charge = $datachannel->{inchihash}->{$inchikey}->{charge};
						$formula = $datachannel->{inchihash}->{$inchikey}->{formula};
						$smiles = $datachannel->{inchihash}->{$inchikey}->{smiles};
					} elsif (defined($datachannel->{smileshash}->{$smiles}->{model})) {
						$type = "modelsmiles";
						$dbhits->{model}++;
						my $best_rxn_score;
						my $best_cpd;
						foreach my $cpd (keys(%{$datachannel->{smileshash}->{$smiles}->{model}})) {
							if (!defined($best_cpd) || $datachannel->{smileshash}->{$smiles}->{model}->{$cpd}->{rxncount}) {
								$best_cpd = $cpd;
								$best_rxn_score = $datachannel->{smileshash}->{$smiles}->{model}->{$cpd}->{rxncount};
							}
						}
						$id = $datachannel->{smileshash}->{$smiles}->{model}->{$best_cpd}->{id};
						$name = $datachannel->{smileshash}->{$smiles}->{model}->{$best_cpd}->{name};
						$charge = $datachannel->{smileshash}->{$smiles}->{model}->{$best_cpd}->{charge};
						$formula = $datachannel->{smileshash}->{$smiles}->{model}->{$best_cpd}->{formula};
						$inchikey = $datachannel->{smileshash}->{$smiles}->{model}->{$best_cpd}->{inchikey};
					} elsif (defined($datachannel->{smileshash}->{$smiles}->{seed})) {
						$type = "seedsmiles";
						$dbhits->{seed}++;
						my $best_rxn_score;
						my $best_cpd;
						foreach my $cpd (keys(%{$datachannel->{smileshash}->{$smiles}->{seed}})) {
							if (!defined($best_cpd) || $datachannel->{smileshash}->{$smiles}->{seed}->{$cpd}->{rxncount}) {
								$best_cpd = $cpd;
								$best_rxn_score = $datachannel->{smileshash}->{$smiles}->{seed}->{$cpd}->{rxncount};
							}
						}
						$id = $datachannel->{smileshash}->{$smiles}->{seed}->{$best_cpd}->{id};
						$name = $datachannel->{smileshash}->{$smiles}->{seed}->{$best_cpd}->{name};
						$charge = $datachannel->{smileshash}->{$smiles}->{seed}->{$best_cpd}->{charge};
						$formula = $datachannel->{smileshash}->{$smiles}->{seed}->{$best_cpd}->{formula};
						$inchikey = $datachannel->{smileshash}->{$smiles}->{seed}->{$best_cpd}->{inchikey};
					}
					$id =~ s/_[a-z]\d+$/_c0/;
					if (!defined($smiles)) {
							print "Undefined smiles:".$id."\t".$type."\t".$original_id."\n";
					}
					if (!defined($inchikey)) {
							print "Undefined inchi:".$id."\t".$type."\t".$original_id."\n";
					}
					if (!defined($charge)) {
							print "Undefined charge:".$id."\t".$type."\t".$original_id."\n";
					}
					if ($id =~ m/^pkc/) {
						if (!defined($datachannel->{current_id}->{$cpd_id_prefix})) {
							$datachannel->{current_id}->{$cpd_id_prefix} = 1;
						}
						$id = $cpd_id_prefix.$datachannel->{current_id}->{$cpd_id_prefix};
						$datachannel->{current_id}->{$cpd_id_prefix}++;
					}
					#Making sure the ID includes a compartment
					if ($id !~ m/_[a-z]\d+$/) {
						$id .= "_c0";
					}
					if (!defined($name)) {
						$name = $id;
					}
					#Adding compound to smiles and inchihash
					my $cpddata = {
						id => $id,
						name => $name,
						charge => $charge,
						formula => $nonneutral_formula,
						smiles => $smiles,
						inchikey => $inchikey,
						aliases => [],
						compound_ref => "~/template/compounds/id/",
						dblinks => {},
						modelcompartment_ref => "~/modelcompartments/id/c0",
						string_attributes => {}
					};
					if (!defined($cpddata->{charge})) {
							$cpddata->{charge} = 0;
					}
					if (!defined($cpddata->{smiles})) {
							delete($cpddata->{smiles});
					}
					if (!defined($cpddata->{inchikey})) {
							delete($cpddata->{inchikey});
					}
					if (defined($smiles) && !defined($datachannel->{smileshash}->{$smiles}->{$type}->{$id})) {
						$datachannel->{smileshash}->{$smiles}->{$type}->{$id} = $cpddata;
					}
					if (defined($inchikey) &&  !defined($datachannel->{inchihash}->{$inchikey})) {
						$datachannel->{inchihash}->{$inchikey} = $datachannel->{smileshash}->{$smiles}->{$type}->{$id};
					}
					#Saving ID translation so reactions can be adjusted
					$cpdid_translation->{$original_id} = $id;
					#Adding the compound to the model
					$datachannel->{rulesetcpds}->{$ruleset}->{$id} = 1;
					#Checking that the generated compound if a metabolomics hit
					Bio::KBase::ObjectAPI::functions::check_for_peakmatch($datachannel->{metabolomics_data},$datachannel->{cpd_hits},$datachannel->{peak_hits},$cpddata,$datachannel->{currentgen},$ruleset,0,$datachannel->{KBaseMetabolomicsObject},$params->{max_hits_to_keep_per_peak});
					$cpddata->{formula} = $formula;
					if ($id =~ /(cpd\d+)/) {
						$cpddata->{compound_ref}.$1;
					} else {
						$cpddata->{compound_ref}."cpd00000";
					}
					if (!defined($datachannel->{cpdhash}->{$id})) {
						$cpddata->{formula} = $formula;
						$datachannel->{cpdhash}->{$id} = $cpddata;
						if (defined($datachannel->{targethash}->{$cpddata->{smiles}}) ||
							$array->[1] eq "Coreactant" || defined($input_ids->{$id}) ||
							($params->{keep_seed_hits} == 1 && $id =~ /cpd\d+/) ||
							($params->{keep_metabolomic_hits} == 1 && defined($cpddata->{dblinks}->{$datachannel->{MetabolomicsDBLINKSKey}}) && !defined($cpddata->{numerical_attributes}->{redundant_hit}))) {
							$newcpdcount++;
							push(@{$datachannel->{fbamodel}->{modelcompounds}},$cpddata);
							$cpddata->{numerical_attributes}->{generation} = $datachannel->{currentgen};
							$modelcpds->{$id} = 1;
						} else {
							$initially_pruned->{$cpddata->{id}} = $cpddata;
						}
					} else {
						$cpddata = $datachannel->{cpdhash}->{$id};
					}
					if ($array->[1] eq "Coreactant") {
						$cpddata->{string_attributes}->{"pickaxe_".$ruleset."_type"} = "coreactant";
					}
					if (!defined($input_ids->{$cpddata->{id}}) && !defined($cpddata->{numerical_attributes}->{"generation_".$ruleset})) {
						$cpddata->{numerical_attributes}->{"generation_".$ruleset} = $datachannel->{currentgen};
					}   
				}
				#If keeping all compounds and seed, targets, metabolite hits are under the limit, fill in remaining slots with diverse compounds
				if ($newcpdcount < $params->{max_new_cpds_per_gen_per_ruleset} && $params->{discard_orphan_hits} == 0) {
						my $remaining = $params->{max_new_cpds_per_gen_per_ruleset} - $newcpdcount;
						for (my $i=0; $i < $remaining; $i++) {
							my $keylist = [keys(%{$initially_pruned})];
							my $numkeys = @{$keylist};
							my $random = int(rand($numkeys));
							push(@{$datachannel->{fbamodel}->{modelcompounds}},$initially_pruned->{$keylist->[$random]});
							$initially_pruned->{$keylist->[$random]}->{numerical_attributes}->{generation} = $datachannel->{currentgen};
							$modelcpds->{$initially_pruned->{$keylist->[$random]}->{id}} = 1;
							delete($initially_pruned->{$keylist->[$random]});
						}
				}
				#Adding reactions to model
				my $rxndarray = Bio::KBase::ObjectAPI::utilities::LOADFILE($rxnfilename);
				for (my $i=1; $i < @{$rxndarray}; $i++) {
					if (!defined($datachannel->{current_rxn_id}->{$rxn_id_prefix})) {
						$datachannel->{current_rxn_id}->{$rxn_id_prefix} = 1;
					}
					my $array = [split(/\t/,$rxndarray->[$i])];
					if (!defined($datachannel->{reaction_ids}->{$array->[4]})) {
						$datachannel->{reaction_ids}->{$array->[4]} = 1;
					}
					my $equation = $array->[2];
					my $eqarray = [split(" ",$equation)];
					my $multiplier = -1;
					my $coef = 1;
					my $reagents = [];
					my $pruned = 0;
					my $netcharge = 0;
					my $protons = 0;
					for (my $j=0; $j < @{$eqarray}; $j++) {
						if ($eqarray->[$j] =~ /=/) {
							$multiplier = 1;
						} elsif ($eqarray->[$j] =~ /\((\d+\.*\d*)\)/) {
							$coef = $1+0;
						} elsif ($eqarray->[$j] =~ /(.+)\[.+]/) {
							my $cpdid = $1;
							#Because some compounds will have _c0 and some not, we just strip them all off and readd
							$cpdid =~ s/_[a-z]\d$//;
							$cpdid .= "_c0";
							my $orig = $cpdid;
							if (defined($cpdid_translation->{$cpdid})) {
								$cpdid = $cpdid_translation->{$cpdid};
							}
							$netcharge += $multiplier*$coef*$datachannel->{cpdhash}->{$cpdid}->{charge};
							if (!defined($modelcpds->{$cpdid}) && !defined($input_ids->{$cpdid})) {
								$pruned = 1;
							}
							if ($cpdid =~ m/cpd00067/) {
								$protons += $multiplier*$coef;
							} else {
								push(@{$reagents},{
									coefficient => $multiplier*$coef,
									modelcompound_ref => "~/modelcompounds/id/".$cpdid
								});
							}
							$coef = 1;
						}
					}
					$protons = $protons - $netcharge;
					if ($protons != 0) {
						push(@{$reagents},{
							coefficient => $protons,
							modelcompound_ref => "~/modelcompounds/id/cpd00067_c0"
						});
					}
					my $rxndata = {
						id => $rxn_id_prefix.$datachannel->{current_rxn_id}->{$rxn_id_prefix}."_c0",
						reaction_ref => "~/template/reactions/id/rxn00000_c",
						dblinks => {"PickAxe" => [$ruleset.".".$array->[5]]},
						direction => ">",
						maxforflux => 1000,
						maxrevflux => 0,
						modelcompartment_ref => "~/modelcompartments/id/c0",
						modelReactionReagents => $reagents,
						modelReactionProteins => [],
						string_attributes => {},
						gapfill_data => {}
					};
					my $sorted_reagents = [sort { $a->{modelcompound_ref} cmp $b->{modelcompound_ref} } @{$reagents}];
					my $reactstring = "";
					my $prodstring = "";
					for (my $j=0; $j < @{$sorted_reagents}; $j++) {
						my $newarray = [split(/\//,$sorted_reagents->[$j]->{modelcompound_ref})];
						my $cpdid = pop(@{$newarray});
						if ($cpdid =~ m/cpd00067/) {
							$reactstring .= "";
						} elsif ($sorted_reagents->[$j]->{coefficient} < 0) { 
							$reactstring .= "(".(-1*$sorted_reagents->[$j]->{coefficient}).")".$cpdid;
						} else {
							$prodstring .= "(".($sorted_reagents->[$j]->{coefficient}).")".$cpdid;
						}
					}
					my $code = $reactstring."=".$prodstring;
					my $reversecode = $prodstring."=".$reactstring;
					if (!defined($datachannel->{reaction_hash}->{$code})) {
						if (!defined($datachannel->{reaction_hash}->{$reversecode})) {
							if (!defined($datachannel->{operator_counts}->{$array->[5]})) {
								$datachannel->{operator_counts}->{$array->[5]} = 0;
							}
							$datachannel->{reaction_hash}->{$code} = $rxndata;
							if ($pruned == 0) {
								$datachannel->{operator_counts}->{$array->[5]}++;
								$rxndata->{name} = $array->[5]."_".$datachannel->{operator_counts}->{$array->[5]};
								push(@{$datachannel->{fbamodel}->{modelreactions}},$rxndata);
								$rxndata->{numerical_attributes}->{generation} = $datachannel->{currentgen};
								$datachannel->{current_rxn_id}->{$rxn_id_prefix}++;
							}
						} else {
							$datachannel->{reaction_hash}->{$reversecode}->{direction} = "=";
							my $found = 0;
							foreach my $alias (@{$datachannel->{reaction_hash}->{$reversecode}->{dblinks}->{PickAxe}}) {
								 if ($alias eq $ruleset.".".$array->[5]) {
									 $found = 1;
								 }
							}
							if ($found == 0) {
								push(@{$datachannel->{reaction_hash}->{$reversecode}->{dblinks}->{PickAxe}},$ruleset.".".$array->[5]);
							}
							$rxndata = $datachannel->{reaction_hash}->{$reversecode};
						}
					} else {
						my $found = 0;
						foreach my $alias (@{$datachannel->{reaction_hash}->{$code}->{dblinks}->{PickAxe}}) {
							 if ($alias eq $ruleset.".".$array->[5]) {
								 $found = 1;
							 }
						}
						if ($found == 0) {
							push(@{$datachannel->{reaction_hash}->{$code}->{dblinks}->{PickAxe}},$ruleset.".".$array->[5]);
						}
						$rxndata = $datachannel->{reaction_hash}->{$code};
					}
					if (!defined($rxndata->{numerical_attributes}->{"generation_".$ruleset})) {
						$rxndata->{numerical_attributes}->{"generation_".$ruleset} = $datachannel->{currentgen};
					}
				}
				#unlink($cpdfilename);
				#unlink($rxnfilename);
				system("mv ".$cpdfilename." ".$cpdfilename.$ruleset);
				system("mv ".$rxnfilename." ".$rxnfilename.$ruleset);
			}
		}
		#If more generations are desired, call this function again recursively
		my $cpdcount = @{$datachannel->{fbamodel}->{modelcompounds}};
		if ($datachannel->{currentgen} < $params->{generation} && $cpdcount < $params->{compound_limit}) {
			Bio::KBase::ObjectAPI::functions::func_run_pickaxe($params,$datachannel);
		}
	}
	if ($datachannel->{currentgen} == 1 && defined($datachannel->{fbamodel})) {
		$datachannel->{fbamodel} = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new($datachannel->{fbamodel});
		my $wsmeta = $handler->util_save_object($datachannel->{fbamodel},$params->{workspace}."/".$params->{out_model_id},{type => "KBaseFBA.FBAModel"});
	}
	return {
		peak_hits => $datachannel->{peak_hits},
		cpd_hits => $datachannel->{cpd_hits},
		operator_counts => $datachannel->{operator_counts},
		metabolomics_data => $datachannel->{metabolomics_data}
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
		$params->{media_workspace} = Bio::KBase::utilities::conf("ModelSEED","default_media_workspace");
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
	my $bio = $handler->util_get_object(Bio::KBase::utilities::conf("ModelSEED","default_biochemistry"),{});
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
			compound_ref => Bio::KBase::utilities::conf("ModelSEED","default_biochemistry")."/compounds/id/cpd00000"
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
	my $bio = $handler->util_get_object(Bio::KBase::utilities::conf("ModelSEED","default_biochemistry"),{});
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
					$striped_id =~ s/[^\w]/_/g;
					$striped_id =~ s/-/_/g;
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
				rootid => $striped_id,
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
	print("Adding Reactions\n");
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
			if (($args->{format} eq "tsv" || $args->{format} eq "fulltsv") && ($args->{object} eq "model" || $args->{object} eq "fba")) {
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
			if (($args->{format} eq "tsv" || $args->{format} eq "fulltsv") && ($args->{object} eq "model" || $args->{object} eq "fba")) {
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

sub annotate_proteins {
	my ($params) = @_;
	$params = Bio::KBase::utilities::args($params,["proteins"],{});
	my $inputgenome = {
			features => []
	};
	my $return = {functions => []};
	my $rast_client = Bio::KBase::kbaseenv::rast_client();
	for (my $i=0; $i <= @{$params->{proteins}}; $i++) {
			push(@{$inputgenome->{features}},{
				id => "peg.".$i,
				protein_translation => $params->{proteins}->[$i]
			});
			if ($i > 0 && $i % 4000 == 0) {
				print "Annotating ".($i-4000)."-".$i."\n";
				my $genome = $rast_client->run_pipeline($inputgenome,{stages => [
				{ name => 'annotate_proteins_kmer_v2', kmer_v2_parameters => {min_hits => 5,annotate_hypothetical_only => 0} },
				{ name => 'annotate_proteins_kmer_v1', kmer_v1_parameters => { annotate_hypothetical_only => 1 } },
				{ name => 'annotate_proteins_similarity', similarity_parameters => { annotate_hypothetical_only => 1 } }
			]});
			for (my $j=0; $j < @{$genome->{features}}; $j++) {
				my $funcarray = [];
				if (defined($genome->{features}->[$j]->{function})) {
					$funcarray = [split(/\s*;\s+|\s+[\@\/]\s+/,$genome->{features}->[$j]->{function})];
				}
				push(@{$return->{functions}},$funcarray);
			}
			$inputgenome = {
					features => []
			};
			}
	}
	if (@{$inputgenome->{features}} > 0) {
			print "Final annotation\n";
			my $genome = $rast_client->run_pipeline($inputgenome,{stages => [
			{ name => 'annotate_proteins_kmer_v2', kmer_v2_parameters => {min_hits => 5,annotate_hypothetical_only => 0} },
			{ name => 'annotate_proteins_kmer_v1', kmer_v1_parameters => { annotate_hypothetical_only => 1 } },
			{ name => 'annotate_proteins_similarity', similarity_parameters => { annotate_hypothetical_only => 1 } }
		]});
		for (my $j=0; $j < @{$genome->{features}}; $j++) {
			my $funcarray = [];
			if (defined($genome->{features}->[$j]->{function})) {
				$funcarray = [split(/\s*;\s+|\s+[\@\/]\s+/,$genome->{features}->[$j]->{function})];
			}
			push(@{$return->{functions}},$funcarray);
		}
	}
	return $return;
}

sub process_matrix {
	my ($matrix) = @_;
	my $data = {
		attributes => [],
		attribute_values => [],
		col_ids => $matrix->{data}->{col_ids},
		row_ids => $matrix->{data}->{row_ids},
		lowest => [],
		highest => [],
		data => []
	};
	for (my $j=0; $j < @{$matrix->{data}->{values}}; $j++) {
		for (my $i=0; $i < @{$matrix->{data}->{col_ids}}; $i++) {
			$data->{data}->[$j]->[$i] = $matrix->{data}->{values}->[$j]->[$i];
			if (!defined($data->{highest}->[$i]) || $data->{highest}->[$i] < abs($matrix->{data}->{values}->[$j]->[$i])) {
				$data->{highest}->[$i] = $matrix->{data}->{values}->[$j]->[$i];
			}
			if (!defined($data->{lowest}->[$i]) || $data->{lowest}->[$i] > abs($matrix->{data}->{values}->[$j]->[$i])) {
				$data->{lowest}->[$i] = $matrix->{data}->{values}->[$j]->[$i];
			}
		}
	}
	if (defined($matrix->{row_attributemapping_ref}) && length($matrix->{row_attributemapping_ref}) > 0) {
		my $mapping = $handler->util_get_object($matrix->{row_attributemapping_ref});
		for (my $m=0; $m < @{$mapping->{attributes}}; $m++) {
			if (ref($mapping->{attributes}->[$m]) eq "HASH") {
				$data->{attributes}->[$m] = $mapping->{attributes}->[$m]->{attribute};
			} else {
				$data->{attributes}->[$m] = $mapping->{attributes}->[$m];
			}
			for (my $j=0; $j < @{$data->{row_ids}}; $j++) {
				if (defined($mapping->{instances}->{$data->{row_ids}->[$j]}->[$m])) {
					$data->{attribute_values}->[$j]->[$m] = $mapping->{instances}->{$data->{row_ids}->[$j]}->[$m];
				}
			}
		}
	}
	return $data;
}

sub load_matrix {
	my ($filename) = @_;
	my $data = {
		attributes => [],
		attribute_values => [],
		col_ids => [],
		row_ids => [],
		lowest => [],
		highest => [],
		data => []
	};
	my $array = Bio::KBase::ObjectAPI::utilities::LOADFILE($filename);
	for (my $i=0; $i < @{$array}; $i++) {
		$array->[$i] = [split(/\t/,$array->[$i])];
	}
	my $peak_id_col;
	for (my $i=0; $i < @{$array->[0]}; $i++) {
		if ($array->[0]->[$i] eq "peak_id") {
			$peak_id_col = $i;
			for (my $j=1; $j < @{$array}; $j++) {
				push(@{$data->{row_ids}},$array->[$j]->[$i]);
			}
		} elsif (defined($peak_id_col)) {
			push(@{$data->{col_ids}},$array->[0]->[$i]);
			for (my $j=1; $j < @{$array}; $j++) {
				push(@{$data->{data}->[$j]},$array->[$j]->[$i]);
				my $true_col_id = ($i - $peak_id_col - 1);
				if (!defined($data->{highest}->[$true_col_id]) || $data->{highest}->[$true_col_id] < abs($array->[$j]->[$i])) {
					$data->{highest}->[$true_col_id] = $array->[$j]->[$i];
				}
				if (!defined($data->{lowest}->[$true_col_id]) || $data->{lowest}->[$true_col_id] > abs($array->[$j]->[$i])) {
					$data->{lowest}->[$true_col_id] = $array->[$j]->[$i];
				}
			}
		} else {
			push(@{$data->{attributes}},$array->[0]->[$i]);
			for (my $j=1; $j < @{$array}; $j++) {
				push(@{$data->{attribute_values}->[$j]},$array->[$j]->[$i]);
			}
		}
	}
	return $data;
}

sub check_for_peakmatch {
	my ($metabolomics_data,$cpd_hit,$peak_hit,$cpddata,$generation,$ruleset,$noall,$dbkey,$max_hits_to_keep_per_peak) = @_;
	my $typelist = ["inchikey","smiles","formula"];
	if (!defined($max_hits_to_keep_per_peak)) {
		$max_hits_to_keep_per_peak = 1000000;
	}
	if (!defined($dbkey)) {
		$dbkey = "MetabolomicsDataset";
	}
	my $hit = [];
	for (my $i=0; $i < @{$typelist}; $i++) {
		my $type = $typelist->[$i];
		if (defined($cpddata->{$type}) && length($cpddata->{$type}) > 0) {
			my $cpdatt = $cpddata->{$type};
			if ($type eq "inchikey") {
				my $array = [split(/-/,$cpdatt)];
				$cpdatt = $array->[0];
			}
			if (defined($metabolomics_data->{$type."_to_peaks"}->{$cpdatt})) {
				foreach my $peakid (keys(%{$metabolomics_data->{$type."_to_peaks"}->{$cpdatt}})) {
					my $hitcount = keys(%{$metabolomics_data->{$type."_to_peaks"}->{$cpdatt}});
					if ($hitcount >= $max_hits_to_keep_per_peak) {
						$cpddata->{numerical_attributes}->{redundant_hit} = ($hitcount+1);
					}
					push(@{$hit},$peakid);
					if (!defined($cpddata->{dblinks}->{$dbkey})) {
						$cpddata->{dblinks}->{$dbkey} = [];
					}
					push(@{$cpddata->{dblinks}->{$dbkey}},$peakid);
					if ($noall == 0) {
						$cpd_hit->{all}->{allgen}->{$cpddata->{id}}->{$type}->{$peakid} = 1;
						$cpd_hit->{all}->{$generation}->{$cpddata->{id}}->{$type}->{$peakid} = 1;
						$peak_hit->{all}->{allgen}->{$peakid}->{$type}->{$cpddata->{id}} = $cpddata;
						$peak_hit->{all}->{$generation}->{$peakid}->{$type}->{$cpddata->{id}} = $cpddata;
					}
					$cpd_hit->{$ruleset}->{allgen}->{$cpddata->{id}}->{$type}->{$peakid} = 1;
					$cpd_hit->{$ruleset}->{$generation}->{$cpddata->{id}}->{$type}->{$peakid} = 1;
					$peak_hit->{$ruleset}->{allgen}->{$peakid}->{$type}->{$cpddata->{id}} = $cpddata;
					$peak_hit->{$ruleset}->{$generation}->{$peakid}->{$type}->{$cpddata->{id}} = $cpddata;
				}
			}
		}
	}
	return $hit;
}

1;