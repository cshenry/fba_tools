use strict;
use Data::Dumper;
use Test::More;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::utilities;
use Bio::KBase::kbaseenv;
use fba_tools::fba_toolsImpl;
use KBaseReport::KBaseReportImpl;

my $tester = LocalTester->new($ENV{'KB_DEPLOYMENT_CONFIG'});
$tester->run_tests();

{
	package LocalTester;
	use strict;
	use Test::More;
    sub new {
        my ($class,$configfile) = @_;
        Bio::KBase::kbaseenv::create_context_from_client_config({
        	filename => "/Users/chenry/.kbase_config"
        });
        my $c = Bio::KBase::utilities::read_config({
        	filename => $configfile,
			service => 'fba_tools'
        });
        my $object = fba_tools::fba_toolsImpl->new();
        my $self = {
            token => Bio::KBase::utilities::token(),
            config_file => $configfile,
            config => $c->{fba_tools},
            user_id => Bio::KBase::utilities::user_id(),
            ws_client => Bio::KBase::kbaseenv::ws_client(),
            obj => $object,
            testcount => 0,
            completetestcount => 0,
            dumpoutput => 0,
            testoutput => {},
            showerrors => 1
        };
        return bless $self, $class;
    }
    sub test_harness {
		my($self,$function,$parameters,$name,$tests,$fail_to_pass,$dependency) = @_;
		$self->{testoutput}->{$name} = {
			output => undef,
			"index" => $self->{testcount},
			tests => $tests,
			command => $function,
			parameters => $parameters,
			dependency => $dependency,
			fail_to_pass => $fail_to_pass,
			pass => 1,
			function => 1,
			status => "Failed initial function test!"
		};
		$self->{testcount}++;
		if (defined($dependency) && $self->{testoutput}->{$dependency}->{function} != 1) {
			$self->{testoutput}->{$name}->{pass} = -1;
			$self->{testoutput}->{$name}->{function} = -1;
			$self->{testoutput}->{$name}->{status} = "Test skipped due to failed dependency!";
			return;
		}
		my $output;
		#eval {
			if (defined($parameters)) {
				$output = $self->{obj}->$function($parameters);
			} else {
				$output = $self->{obj}->$function();
			}
		#};
		my $errors;
		if ($@) {
			$errors = $@;
		}
		$self->{completetestcount}++;
		if (defined($output)) {
			$self->{testoutput}->{$name}->{output} = $output;
			$self->{testoutput}->{$name}->{function} = 1;
			if (defined($fail_to_pass) && $fail_to_pass == 1) {
				$self->{testoutput}->{$name}->{pass} = 0;
				$self->{testoutput}->{$name}->{status} = $name." worked, but should have failed!"; 
				ok $self->{testoutput}->{$name}->{pass} == 1, $self->{testoutput}->{$name}->{status};
			} else {
				ok 1, $name." worked as expected!";
				for (my $i=0; $i < @{$tests}; $i++) {
					$self->{completetestcount}++;
					$tests->[$i]->[2] = eval $tests->[$i]->[0];
					if ($tests->[$i]->[2] == 0) {
						$self->{testoutput}->{$name}->{pass} = 0;
						$self->{testoutput}->{$name}->{status} = $name." worked, but sub-tests failed!"; 
					}
					ok $tests->[$i]->[2] == 1, $tests->[$i]->[1];
				}
			}
		} else {
			$self->{testoutput}->{$name}->{function} = 0;
			if (defined($fail_to_pass) && $fail_to_pass == 1) {
				$self->{testoutput}->{$name}->{pass} = 1;
				$self->{testoutput}->{$name}->{status} = $name." failed as expected!";
			} else {
				$self->{testoutput}->{$name}->{pass} = 0;
				$self->{testoutput}->{$name}->{status} = $name." failed to function at all!";
			}
			ok $self->{testoutput}->{$name}->{pass} == 1, $self->{testoutput}->{$name}->{status};
			if ($self->{showerrors} && $self->{testoutput}->{$name}->{pass} == 0 && defined($errors)) {
				print "Errors:\n".$errors."\n";
			}
		}
		if ($self->{dumpoutput}) {
			print "$function output:\n".Data::Dumper->Dump([$output])."\n\n";
		}
		return $output;
	}
	sub run_tests {
		my($self) = @_;
		
		my $output = $self->test_harness("sbml_file_to_model",{
			model_file => {path => "/Users/chenry/workspace/KBaseDemo/iMR1_799.xml"},
	        model_name => "iMR1_799",
	        workspace_name => "chenry:1484863241748",
	        genome => "Shewanella_oneidensis_MR1",
	        biomass => ["SO_BIOMASSMACRO_DM_NOATP2"]
		},"import model from SBML",[],0,undef);
		exit();
		
		my $output = $self->test_harness("edit_media",{
			workspace => "chenry:1454960620516",
			media_output_id => "edit_media_test",
			media_id => "test_media",
	    	compounds_to_remove => "cpd00204",
	    	compounds_to_change => [{change_id => "cpd00001",change_concentration => 0.1,change_minflux => -100,change_maxflux => 1}],
	    	compounds_to_add => [{add_id => "Acetate",add_concentration => 0.1,add_minflux => -100,add_maxflux => 1}],
	    	pH_data => 8,
	    	temperature => 303,
	    	source_id => "edit_media_test_source_id",
	    	source => "edit_media_test_source",
	    	type => "test",
	    	isDefined => 1
		},"edited media",[],0,undef);
		exit;
		my $output = $self->test_harness("tsv_file_to_model",{
			model_file => {path => "/Users/chenry/temp/SBW25Reactions.txt"},
	        model_name => "iSB1139",
	        workspace_name => "chenry:1485196974520",
	        genome => "Pseudomonas_SBW25",
	        biomass => ["BIOMASSRXN"],
	        compounds_file => {path => "/Users/chenry/temp/SBW25Compounds.txt"}
		},"import model from tsv",[],0,undef);
		exit;
		
		my $output = $self->test_harness("tsv_file_to_model",{
			model_file => {path => "/Users/chenry/temp/RhodoReactions.tsv"},
	        model_name => "tsv_import",
	        workspace_name => "chenry:1485812271066",
	        genome => "Rhodococcus_jostii_RHA1",
	        biomass => ["A00000"],
	        compounds_file => {path => "/Users/chenry/temp/RhodoCompounds.tsv"}
		},"import model from tsv",[],0,undef);
		exit;
		
		
		#my $wsname = "chenry:1456989658583";
		my $wsname = "chenry:1454960620516";
		
		my $output = $self->test_harness("edit_metabolic_model",{
			workspace => "chenry:1454960620516",
			fbamodel_id => "New211586.9.gf",
	    	compounds_to_add => [{
	    		add_compound_id => "testcompound_c0",
                add_compartment_id => "c0",
                add_compound_name => "test_compound_name",
                add_compound_charge => 0,
                add_compound_formula => "C4H4"
	    	},{
	    		add_compound_id => "testcompound_e0",
                add_compartment_id => "e0",
                add_compound_name => "test_compound_name",
                add_compound_charge => 0,
                add_compound_formula => "C4H4"
	    	}],
	    	compounds_to_change => [{
	    		compound_id => "cpd00036_c0",
                compound_name => "testname",
                compound_charge => 0,
                compound_formula => "C4H4"
	    	}],
	    	biomasses_to_add => [{
	    		biomass_name => "TestBiomass",
				biomass_dna => 0,
				biomass_rna => 0,
				biomass_protein => 1,
				biomass_cellwall => 0,
				biomass_lipid => 0,
				biomass_cofactor => 0,
				biomass_energy => 0
			}],
	    	biomass_compounds_to_change => [{
	    		biomass_id => "bio1",
                biomass_compound_id => "cpd00220_c0",
				biomass_coefficient => 0
	    	},{
	    		biomass_id => "bio1",
                biomass_compound_id => "cpd15352_c0",
				biomass_coefficient => -0.004
	    	}],
	    	reactions_to_remove => [
	    		"rxn00016_c0"
	    	],
	    	reactions_to_change => [{
	    		change_reaction_id => "rxn00015_c0",
                change_reaction_name => "testname",
                change_reaction_direction => "<",
				change_reaction_gpr => "(fig|211586.9.peg.3166 and fig|211586.9.peg.3640)"
	    	}],
	    	reactions_to_add => [{
	    		add_reaction_id => "rxn00021_c0",
                reaction_compartment_id => "c0",
                add_reaction_name => undef,
                add_reaction_direction => undef,
				add_reaction_gpr => "fig|211586.9.peg.3166",
	    	},{
	    		add_reaction_id => "testcustomreaction",
                reaction_compartment_id => "c0",
                add_reaction_name => "test_transporter",
                add_reaction_direction => ">",
				add_reaction_gpr => "fig|211586.9.peg.3166",
	    	}],
	    	edit_compound_stoichiometry => [{
	    		stoich_reaction_id => "testcustomreaction_c0",
                stoich_compound_id => "testcompound_c0",
                stoich_coefficient =>  -1
	    	},{
	    		stoich_reaction_id => "testcustomreaction_c0",
                stoich_compound_id => "testcompound_e0",
                stoich_coefficient => 1
	    	},{
	    		stoich_reaction_id => "rxn00022_c0",
                stoich_compound_id => "cpd00179_c0",
                stoich_coefficient => 0
	    	}],
	    	fbamodel_output_id => "New211586.9.edited"
		},"editing a metabolic model",[],0,undef);
		exit();
		
		my $output = $self->test_harness("sbml_file_to_model",{
			model_file => {path => "/Users/chenry/Downloads/pFluorescens.xml"},
	        model_name => "iSB1139",
	        workspace_name => "chenry:1485196974520",
	        genome => "Pseudomonas_SBW25",
	        biomass => ["GROWTH"]
		},"import model from SBML",[],0,undef);
		exit();
		
		my $output = $self->test_harness("sbml_file_to_model",{
			model_file => {path => "/Users/chenry/workspace/Metabolite repair/iPS189.xml"},
	        model_name => "iPS189",
	        #model_file => {path => "/Users/chenry/Downloads/Syn3_0_FBA.xml"},
	        #model_name => "JCVI-ZanModel",
	        workspace_name => "chenry:1484810346458",
	        genome => "Mycoplasma_genitalium",
	        #genome => "JCVI-Syn3.kbase",
	        biomass => ["Biomass"]
		},"import model from SBML",[],0,undef);
		exit();
		my $output = $self->test_harness("sbml_file_to_model",{
			model_file => {path => "/Users/chenry/temp/Syn3_0_FBA.xml"},
	        model_name => "ZanModel",
	        workspace_name => "chenry:1474434516205",
	        genome => "JCVI_Syn3.kbase",
	        biomass => ["Biomass"],
	        compounds_file => {path => "/Users/chenry/temp/Syn3_0_compounds.tsv"}
		},"import model from SBML",[],0,undef);
		exit();
		
		my $output = $self->test_harness("run_flux_balance_analysis",{
	        "fbamodel_id"=> "test_model_minimal",
	        "media_id"=> "Carbon-D-Glucose",
	        "target_reaction"=> "bio1",
	        "fba_output_id"=> "test_model_singleko_fba",
	        "fva"=> 1,
	        "minimize_flux"=> 1,
	        "simulate_ko"=> 1,
	        "feature_ko_list"=> [],
	        "reaction_ko_list"=> "",
	        "custom_bound_list"=> [],
	        "media_supplement_list"=> "",
	        "expseries_id"=> undef,
	        "expression_condition"=> undef,
	        "exp_threshold_percentile"=> 0.5,
	        "exp_threshold_margin"=> 0.1,
	        "activation_coefficient"=> 0.5,
	        "max_c_uptake"=> undef,
	        "max_n_uptake"=> undef,
	        "max_p_uptake"=> undef,
	        "max_s_uptake"=> undef,
	        "max_o_uptake"=> undef,
	        workspace => "chenry:1482435841726"
	    },"Run flux balance analysis",[],0,undef);
		
		exit;
		
		$output = $self->test_harness("export_phenotype_set_as_tsv_file",{
			input_ref => "chenry:1454960620516/shewy_phenotypes"
		},"export phenotypes as tsv",[],0,undef);
		$output = $self->test_harness("tsv_file_to_phenotype_set",{
			phenotype_set_file => {path => "/Users/chenry/temp/test_phenosim.tsv"},
	        phenotype_set_name => "tsv_phenotypeset",
	        workspace_name => "chenry:1454960620516",
	        genome => "211586.9.KBase"
		},"import phenotype set from tsv",[],0,undef);
		$output = $self->test_harness("export_model_as_sbml_file",{
			input_ref => "chenry:1454960620516/New211586.9.gf"
		},"export model as tsv",[],0,undef);
		$output = $self->test_harness("sbml_file_to_model",{
			model_file => {path => "/Users/chenry/temp/New211586.9.gf.sbml"},
	        model_name => "sbml_import",
	        workspace_name => "chenry:1454960620516",
	        genome => "211586.9.KBase",
	        biomass => ["bio1"]
		},"import model from SBML",[],0,undef);
		$output = $self->test_harness("export_model_as_excel_file",{
			input_ref => "chenry:1454960620516/New211586.9.gf"
		},"export model as tsv",[],0,undef);
		$output = $self->test_harness("excel_file_to_model",{
			model_file => {path => "/Users/chenry/temp/New211586.9.gf.xls"},
	        model_name => "excel_import",
	        workspace_name => "chenry:1454960620516",
	        genome => "211586.9.KBase",
	        biomass => ["bio1"]
		},"import model from excel",[],0,undef);
		$output = $self->test_harness("export_model_as_tsv_file",{
			input_ref => "chenry:1454960620516/New211586.9.gf"
		},"export model as tsv",[],0,undef);
		$output = $self->test_harness("tsv_file_to_model",{
			model_file => {path => "/Users/chenry/temp/New211586.9.gf-reactions.tsv"},
	        model_name => "tsv_import",
	        workspace_name => "chenry:1454960620516",
	        genome => "211586.9.KBase",
	        biomass => ["bio1"],
	        compounds_file => {path => "/Users/chenry/temp/New211586.9.gf-compounds.tsv"}
		},"import model from tsv",[],0,undef);
		$output = $self->test_harness("export_media_as_excel_file",{
			input_ref => "chenry:1454960620516/test_media"
		},"export media as excel",[],0,undef);
		$output = $self->test_harness("excel_file_to_media",{
			media_file => {path => "/Users/chenry/temp/test_media.xls"},
	        media_name => "xls_media",
	        workspace_name => "chenry:1454960620516",
		},"import media from excel",[],0,undef);
		$output = $self->test_harness("export_media_as_tsv_file",{
			input_ref => "chenry:1454960620516/test_media"
		},"export media as tsv",[],0,undef);		
		$output = $self->test_harness("tsv_file_to_media",{
			media_file => {path => "/Users/chenry/temp/test_media.tsv"},
	        media_name => "tsv_media",
	        workspace_name => "chenry:1454960620516",
		},"import media from tsv",[],0,undef);		
		$output = $self->test_harness("media_to_tsv_file",{
			media_name => "test_media",
			workspace_name => "chenry:1454960620516"
		},"export media as tsv",[],0,undef);
		$output = $self->test_harness("media_to_excel_file",{
			media_name => "test_media",
			workspace_name => "chenry:1454960620516"
		},"export media as excel",[],0,undef);
		$output = $self->test_harness("model_to_excel_file",{
			model_name => "New211586.9.gf",
			workspace_name => "chenry:1454960620516"
		},"export model as excel",[],0,undef);
		$output = $self->test_harness("model_to_tsv_file",{
			model_name => "New211586.9.gf",
			workspace_name => "chenry:1454960620516"
		},"export model as tsv",[],0,undef);
		$output = $self->test_harness("model_to_sbml_file",{
			model_name => "New211586.9.gf",
			workspace_name => "chenry:1454960620516"
		},"export model as sbml",[],0,undef);
		$output = $self->test_harness("export_fba_as_excel_file",{
			input_ref => "chenry:1454960620516/211586.9.single_ko_fba"
		},"export fba as excel",[],0,undef);
		$output = $self->test_harness("export_fba_as_tsv_file",{
			input_ref => "chenry:1454960620516/211586.9.single_ko_fba"
		},"export fba as tsv",[],0,undef);
		$output = $self->test_harness("fba_to_excel_file",{
			fba_name => "211586.9.single_ko_fba",
			workspace_name => "chenry:1454960620516"
		},"export fba as excel",[],0,undef);
		$output = $self->test_harness("fba_to_tsv_file",{
			fba_name => "211586.9.single_ko_fba",
			workspace_name => "chenry:1454960620516"
		},"export fba as tsv",[],0,undef);
		$output = $self->test_harness("phenotype_set_to_tsv_file",{
			phenotype_set_name => "shewy_phenotypes",
			workspace_name => "chenry:1454960620516"
		},"export phenotypes as tsv",[],0,undef);
		$output = $self->test_harness("export_phenotype_simulation_set_as_excel_file",{
			input_ref => "chenry:1454960620516/test_phenosim"
		},"export phenosim as excel",[],0,undef);
		$output = $self->test_harness("export_phenotype_simulation_set_as_tsv_file",{
			input_ref => "chenry:1454960620516/test_phenosim"
		},"export phenosim as tsv",[],0,undef);
		$output = $self->test_harness("phenotype_simulation_set_to_excel_file",{
			phenotype_simulation_set_name => "test_phenosim",
			workspace_name => "chenry:1454960620516"
		},"export phenosim as excel",[],0,undef);
		$output = $self->test_harness("phenotype_simulation_set_to_tsv_file",{
			phenotype_simulation_set_name => "test_phenosim",
			workspace_name => "chenry:1454960620516"
		},"export phenosim as tsv",[],0,undef);
		$output = $self->test_harness("bulk_export_objects",{
			refs => ["sbml_import","core_model"],
	        workspace => "chenry:1454960620516",
	        all_media => 1,
	        media_format => "excel"
		},"bulk export of modeling objects",[],0,undef);
		exit();
		exit();
		$output = $self->test_harness("build_metabolic_model",{
			genome_id => "Shewanella_amazonensis_SB2B",
			genome_workspace => $wsname,
			fbamodel_output_id => "draft_no_gapfill",
			workspace => $wsname,
			gapfill_model => 0,
		},"initial draft model reconstruction",[],0,undef);
		$output = $self->test_harness("build_metabolic_model",{
			genome_id => "new_genome",
			genome_workspace => $wsname,
			fbamodel_output_id => "new_genome_model",
			workspace => $wsname,
			gapfill_model => 0,
		},"initial draft model reconstruction",[],0,undef);		
		$output = $self->test_harness("build_metabolic_model",{
			genome_id => "Shewanella_amazonensis_SB2B",
			genome_workspace => $wsname,
			fbamodel_output_id => "core_model",
			workspace => $wsname,
			gapfill_model => 1,
			template_id => "core"
		},"initial draft model reconstruction",[],0,undef);
		$output = $self->test_harness("build_metabolic_model",{
			genome_id => "Shewanella_oneidensus_MR1_NCBI.kbase",
			genome_workspace => $wsname,
			fbamodel_output_id => "draft_complete_gapfill",
			workspace => $wsname,
			gapfill_model => 1,
			thermodynamic_constraints => 0,
			comprehensive_gapfill => 0,
			number_of_solutions => 1,
			expseries_id => "shewanella_expression_data",
			expseries_workspace => $wsname,
			expression_condition => "BU21_8.CEL.gz",
			exp_threshold_percentile => 0.5,
			exp_threshold_margin => 0.1,
			activation_coefficient => 0.1
		},"initial draft model reconstruction with built-in expression-based gapfilling in complete media",[],0,undef);
		$output = $self->test_harness("compare_models",{
			mc_name => "model_comparison",
	        model_refs => [$wsname."/draft_complete_gapfill", $wsname."/draft_no_gapfill"],
	        protcomp_ref => $wsname."/test_comparison",
	        pangenome_ref => undef,
	        workspace => $wsname
		},"model comparison",[],0,undef);
		$output = $self->test_harness("run_flux_balance_analysis",{
			fbamodel_id => "draft_complete_gapfill",
			target_reaction => "bio1",
			fba_output_id => "draft_complete_gapfill_fba",
			workspace => $wsname,
			fva => 1,
			minimize_flux => 1,
			simulate_ko => 0,
			find_min_media => 0,
			all_reversible => 0
		},"running flux balance analysis in complete media",[],0,"initial draft model reconstruction with built-in expression-based gapfilling in complete media");
		$output = $self->test_harness("run_flux_balance_analysis",{
			fbamodel_id => "draft_complete_gapfill",
			target_reaction => "bio1",
			fba_output_id => "draft_complete_gapfill_exp_fba",
			workspace => $wsname,
			fva => 1,
			minimize_flux => 1,
			simulate_ko => 0,
			find_min_media => 0,
			all_reversible => 0,
			expseries_id => "shewanella_expression_data",
			expseries_workspace => $wsname,
			expression_condition => "BU21_8.CEL.gz",
			exp_threshold_percentile => 0.5,
			exp_threshold_margin => 0.1,
			activation_coefficient => 0.1
		},"expression-based flux balance analysis in complete media",[],0,"initial draft model reconstruction with built-in expression-based gapfilling in complete media");		
		$output = $self->test_harness("propagate_model_to_new_genome",{
			fbamodel_id => "iMR1_799",
			fbamodel_workspace => $wsname,
			proteincomparison_id => "MR1_SB2B_comparison",
			proteincomparison_workspace => $wsname,
			fbamodel_output_id => "translated_SB2B_gapfilled_model",
			workspace => $wsname,
			keep_nogene_rxn => 0,
			gapfill_model => 1,
			media_id => "Lactate_minimal_media",
			media_workspace => $wsname
		},"propagating published shewanella model to new genome with built in minimal media gapfilling",[],0,undef);
		$output = $self->test_harness("gapfill_metabolic_model",{
			fbamodel_id => "iMR1_799",
			fbamodel_workspace => $wsname,
			target_reaction => "bio1",
			fbamodel_output_id => "expression_gapfilled_published_model",
			workspace => $wsname,
			expseries_id => "shewanella_expression_data",
			expseries_workspace => $wsname,
			expression_condition => "BU21_8.CEL.gz",
			exp_threshold_percentile => 0.5,
			exp_threshold_margin => 0.1,
			activation_coefficient => 0.1
		},"expression-based gapfilling of published model in complete media",[],0,"propagating published shewanella model to new genome with built in minimal media gapfilling");		
		$output = $self->test_harness("run_flux_balance_analysis",{
			fbamodel_id => "iMR1_799",
			fbamodel_workspace => $wsname,
			target_reaction => "bio1",
			fba_output_id => "iMR1799_exp_fba",
			workspace => $wsname,
			fva => 1,
			minimize_flux => 1,
			simulate_ko => 0,
			find_min_media => 0,
			all_reversible => 0,
			expseries_id => "shewanella_expression_data",
			expseries_workspace => $wsname,
			expression_condition => "BU21_8.CEL.gz",
			exp_threshold_percentile => 0.5,
			exp_threshold_margin => 0.1,
			activation_coefficient => 0.1
		},"expression-based flux balance analysis of published model in complete media",[],0,"propagating published shewanella model to new genome with built in minimal media gapfilling");		
		$output = $self->test_harness("simulate_growth_on_phenotype_data",{
			fbamodel_id => "translated_SB2B_gapfilled_model",
			phenotypeset_id => "shewy_phenotypes",
			phenotypeset_workspace => $wsname,
			phenotypesim_output_id => "shewy_phenotype_simulations",
			workspace => $wsname
		},"simulating phenotypes with propagated model",[],0,"propagating published shewanella model to new genome with built in minimal media gapfilling");
		$output = $self->test_harness("merge_metabolic_models_into_community_model",{
			fbamodel_id_list => ["translated_SB2B_gapfilled_model","draft_complete_gapfill"],
			fbamodel_output_id => "Community_model",
			workspace => $wsname,
			mixed_bag_model => 1
		},"merging draft and propated model into community model",[],0,"propagating published shewanella model to new genome with built in minimal media gapfilling");		
		$output = $self->test_harness("gapfill_metabolic_model",{
			fbamodel_id => "Community_model",
			target_reaction => "bio1",
			media_id => "Lactate_minimal_media",
			media_workspace => $wsname,
			fbamodel_output_id => "gapfilled_community_model",
			workspace => $wsname,
		},"gapfilling community model in minimal media",[],0,"merging draft and propated model into community model");		
		$output = $self->test_harness("run_flux_balance_analysis",{
			fbamodel_id => "Community_model",
			target_reaction => "bio1",
			fba_output_id => "Community_model_fba",
			media_id => "Lactate_minimal_media",
			media_workspace => $wsname,
			workspace => $wsname,
			fva => 1,
			minimize_flux => 1,
			simulate_ko => 0,
			find_min_media => 0,
			all_reversible => 0,
		},"running flux balance analysis in minimal media with community model",[],0,"gapfilling community model in minimal media");		
		$output = $self->test_harness("compare_fba_solutions",{
			fba_id_list => ["iMR1799_exp_fba","draft_complete_gapfill_fba"],
			fbacomparison_output_id => "fba_comparison",
			workspace => $wsname,
		},"comparing multiple FBA results",[],0,"expression-based flux balance analysis of published model in complete media");
	}
}