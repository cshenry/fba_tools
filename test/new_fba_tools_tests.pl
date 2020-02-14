use strict;
use Data::Dumper;
use Test::More;
use Test::Exception;
use Config::Simple;
use Time::HiRes qw(time);
use Workspace::WorkspaceClient;
use fba_tools::fba_toolsImpl;

local $| = 1;
my $impl = fba_tools::fba_toolsImpl->new();
Bio::KBase::kbaseenv::create_context_from_client_config();
Bio::KBase::ObjectAPI::functions::set_handler($impl);
my $test_ws = "fba_tools_unittests";
$test_ws = "chenry:narrative_1504151898593";

my $start = 16;
if (defined($ARGV[0])) {
	$start = $ARGV[0];
}

# build_metabolic_model
if ($start < 2) {
	print "Running test 1:\n";
	lives_ok{
	    $impl->build_metabolic_model({
		genome_id => $test_ws."/Escherichia_coli",
		fbamodel_output_id =>  "test_model",
		template_id =>  "auto",
		gapfill_model =>  1,
		minimum_target_flux =>  0.1,
		workspace => $test_ws})
	} "build_metabolic_model";
}

# gapfill_metabolic_model
if ($start < 3) {
	print "Running test 2:\n";
	lives_ok{
	    $impl->gapfill_metabolic_model({
		fbamodel_id => $test_ws."/test_model",
		media_id => "KBaseMedia/Carbon-D-Glucose",
		fbamodel_output_id =>  "test_model_minimal",
		workspace => $test_ws,
		target_reaction => "bio1"})
	} "gapfill_metabolic_model";
}

if ($start < 4) {
	print "Running test 3:\n";
	lives_ok{
	    $impl->gapfill_metabolic_model({
	    fbamodel_id => $test_ws."/test_model",
		media_id => $test_ws."/No-carbon",
		fbamodel_output_id =>  "test_model_nocarbon",
		workspace => $test_ws,
		target_reaction => "bio1"})
	} "gapfill_metabolic_model_fails";
}

if ($start < 5) {
	print "Running test 4:\n";
	lives_ok{
	    $impl->run_flux_balance_analysis({
		fbamodel_id => $test_ws."/test_model_minimal",
		media_id => "KBaseMedia/Carbon-D-Glucose",
		fba_output_id =>  "test_minimal_fba",
		workspace => $test_ws,
		target_reaction => "bio1",
		fva => 1,
		minimize_flux => 1})
	} "run_flux_balance_analysis";
}

if ($start < 6) {
	print "Running test 5:\n";
	lives_ok{
	    $impl->run_flux_balance_analysis({
		fbamodel_id => $test_ws."/test_model_minimal",
		media_id => "KBaseMedia/Carbon-Glycine",
		fba_output_id =>  "test_glycine_fba",
		workspace => $test_ws,
		target_reaction => "bio1",
		fva => 1,
		minimize_flux => 1})
	} "run_flux_balance_analysis";
}

if ($start < 7) {
	print "Running test 6:\n";
	lives_ok{
	    $impl->check_model_mass_balance({
		fbamodel_id => $test_ws."/test_model_minimal",
		workspace   => $test_ws})
	} "check_model_mass_balance";
}

if ($start < 8) {
	print "Running test 7:\n";
	lives_ok{
	    $impl->propagate_model_to_new_genome({
		fbamodel_id => $test_ws."/test_model",
		media_id => "KBaseMedia/Carbon-D-Glucose",
		proteincomparison_id        => $test_ws."/Escherichia_coli_to_Shewanella_SB2B",
		fbamodel_output_id          => "test_propagated_model",
		workspace                   => $test_ws,
		keep_nogene_rxn             => 1,
		gapfill_model               => 1,
		translation_policy          => "add_reactions_for_unique_genes"})
	} "propagate_model_to_new_genome";
}

if ($start < 9) {
	print "Running test 8:\n";
	lives_ok{
	    $impl->merge_metabolic_models_into_community_model({
		fbamodel_id_list => [ $test_ws."/test_model", $test_ws."/test_propagated_model" ],
		fbamodel_output_id => "Community_model",
		workspace => $test_ws,
		mixed_bag_model => 1})
	} "merge_metabolic_models_into_community_model";
}

if ($start < 10) {
	print "Running test 9:\n";
	lives_ok{
	    $impl->merge_metabolic_models_into_community_model({
		fbamodel_id_list => [ $test_ws."/test_model", $test_ws."/test_propagated_model" ],
		fbamodel_output_id => "Compartmentalized_community_model",
		workspace => $test_ws,
		mixed_bag_model => 0})
	} "merge_metabolic_models_into_community_model";
}

if ($start < 11) {
	print "Running test 10:\n";
	lives_ok{
        $impl->simulate_growth_on_phenotype_data({
	    fbamodel_id            => $test_ws."/test_model_minimal",
            phenotypeset_id        => $test_ws."/SB2B_biolog_data",
            phenotypesim_output_id => "test_phenotype_simset",
            workspace              => $test_ws,
            gapfill_phenotypes     => 0,
            fit_phenotype_data     => 1,
            target_reaction        => "bio1"
        })
	} "simulate_growth_on_phenotype_data_w_bounds";
}

if ($start < 12) {
	print "Running test 11:\n";
	lives_ok{
	    $impl->compare_models({
		mc_name    => "model_comparison_test",
		model_refs    => [ $test_ws."/test_model_minimal", $test_ws."/test_propagated_model" ],
		workspace  => $test_ws})
	} 'Compare Models';
}

if ($start < 13) {
	print "Running test 12:\n";
	lives_ok{
	    $impl->compare_models({
		mc_name       => "model_comparison",
		model_refs    => [ $test_ws."/test_model", $test_ws."/test_propagated_model" ],
		pangenome_ref => $test_ws."/Ecoli_vs_SB2B",
		workspace     => $test_ws})
	} 'Compare Models w/ pangenome';
}

if ($start < 14) {
	print "Running test 13:\n";
	lives_ok{
	    $impl->build_multiple_metabolic_models({
		"genome_text"           => $test_ws."/Shewanella_amazonensis_SB2B.RAST",
		"genome_ids"            => [ $test_ws."/Escherichia_coli" ],
		"media_id"              => undef,
		"template_id"           => "auto",
		"gapfill_model"         => 1,
		"minimum_target_flux"   => 0.1,
		"workspace"             => $test_ws})
	} "build_multiple_metabolic_models";
}

if ($start < 15) {
	print "Running test 14:\n";
	lives_ok{
		my $output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
		 "omindirectional" => 0,
		 "reaction_ko_list" => "",
		 "fbamodel_id" => $test_ws."/test_model_minimal",
		 "target_reaction" => "bio1",
		 "fbamodel_output_id" => $test_ws."/test_model_minimal.exomodel",
		 "media_ref" => "KBaseMedia/Carbon-D-Glucose",
		 "exometabolite_ref" => $test_ws."/exodata",
		 "exomedia_output_id" => "Exomedia",
		 "workspace" => $test_ws,
		 "equal_weighting" => 0,
		 "minimum_target_flux" => 0.1,
		 "exometabolite_condition" => "R2A_Pseudomonas_GW456-L13"
		})
	} "fit_exometabolite_data";
}

if ($start < 16) {
	print "Running test 15:\n";
	lives_ok{
		$impl->characterize_genome_metabolism_using_model({
			workspace => $test_ws,
			genome_id => "Escherichia_coli"
		});
	} "characterize_genome_metabolism_using_model";
}

if ($start < 17) {
	print "Running test 16:\n";
	lives_ok{
		$impl->build_metagenome_metabolic_model({
			workspace => $test_ws,
			input_ref => "test_metagenome_annotation"
		});
	} "build_metagenome_metabolic_model";
}

done_testing();
exit();

if ($start < 18) {
	print "Running test 17:\n";
	lives_ok{
	    $impl->compare_fba_solutions({
		fba_id_list => [ $test_ws."/test_minimal_fba", $test_ws."/test_glycine_fba" ],
		fbacomparison_output_id => "fba_comparison",
		workspace => $test_ws})
	} "compare_fba_solutions";
}

if ($start < 19) {
	print "Running test 18:\n";
	lives_ok{
	    $impl->view_flux_network({
		fba_id => $test_ws."/test_minimal_fba",
		workspace => $test_ws})
	} "view_flux_network";
}

if ($start < 20) {
	print "Running test 19:\n";
	lives_ok{
	    $impl->compare_flux_with_expression({
		estimate_threshold => 0,
		maximize_agreement => 0,
		expression_condition => "22c.5h_r1[sodium_chloride:0 mM,culture_temperature:22 Celsius,casamino_acids:0.3 mg/mL]",
		fba_id => $test_ws."/test_minimal_fba",
		fbapathwayanalysis_output_id => "test",
		exp_threshold_percentile => 0.5,
		expseries_id => $test_ws."/test_expression_matrix",
		workspace => $test_ws})
	} "compare_flux_with_expression";
}

if ($start < 21) {
	print "Running test 20:\n";
	lives_ok{
	    $impl->edit_metabolic_model({
		workspace => $test_ws,
		fbamodel_id => $test_ws."/test_model",
		compounds_to_add => [{add_compound_id => "testcompound_c0",
				      add_compartment_id => "c0",
				      add_compound_name => "test_compound_name",
				      add_compound_charge => 0,
				      add_compound_formula => "C4H4"},
				     {add_compound_id => "testcompound_e0",
				      add_compartment_id => "e0",
				      add_compound_name => "test_compound_name",
				      add_compound_charge => 0,
				      add_compound_formula => "C4H4"}],
		compounds_to_change => [{compound_id => "cpd00036_c0",
					 compound_name => "testname",
					 compound_charge => 0,
					 compound_formula => "C4H4"}],
		biomasses_to_add => [{biomass_name => "TestBiomass",
				      biomass_dna => 0,
				      biomass_rna => 0,
				      biomass_protein => 1,
				      biomass_cellwall => 0,
				      biomass_lipid => 0,
				      biomass_cofactor => 0,
				      biomass_energy => 0}],
		biomass_compounds_to_change => [{biomass_id => "bio1",
						 biomass_compound_id => "cpd00220_c0",
						 biomass_coefficient => 0},
						{biomass_id => "bio1",
						 biomass_compound_id => "cpd15352_c0",
						 biomass_coefficient => -0.004}],
		reactions_to_remove => ["rxn00980_c0"],
		reactions_to_change => [{change_reaction_id => "rxn12642_c0",
					 change_reaction_name => "testname",
					 change_reaction_direction => "<",
					 change_reaction_gpr => "(b0688 and b0168)"}],
		reactions_to_add => [{add_reaction_id => "rxn00016_c0",
				      reaction_compartment_id => "c0",
				      add_reaction_name => undef,
				      add_reaction_direction => undef,
				      add_reaction_gpr => "b00234"},
				     {add_reaction_id => "testcustomreaction",
				      reaction_compartment_id => "c0",
				      add_reaction_name => "test_transporter",
				      add_reaction_direction => ">",
				      add_reaction_gpr => "b00235"}],
		edit_compound_stoichiometry => [{stoich_reaction_id => "testcustomreaction_c0",
						 stoich_compound_id => "testcompound_c0",
						 stoich_coefficient =>  -1},
						{stoich_reaction_id => "testcustomreaction_c0",
						 stoich_compound_id => "testcompound_e0",
						 stoich_coefficient => 1},
						{stoich_reaction_id => "rxn00022_c0",
						 stoich_compound_id => "cpd00179_c0",
						 stoich_coefficient => 0}],
		fbamodel_output_id => "edited_model"})
	} "Edit Model";
}

if ($start < 22) {
	print "Running test 21:\n";
	lives_ok{
	    $impl->edit_media({
		workspace => $test_ws,
		media_output_id => "edited_media",
		media_id => "KBaseMedia/Carbon-D-Glucose",
		compounds_to_remove => "cpd00027",
		compounds_to_change => [{change_id => "cpd00001",change_concentration => 0.1,change_minflux => -100,change_maxflux => 1}],
		compounds_to_add => [{add_id => "Acetate",add_concentration => 0.1,add_minflux => -100,add_maxflux => 1}],
		pH_data => "8",
		temperature => 303,
		source_id => "edit_media_test_source_id",
		source => "edit_media_test_source",
		type => "test",
		isDefined => 1})
	} "Edit Media";
}

if ($start < 23) {
	print "Running test 22:\n";
	lives_ok{
	    $impl->excel_file_to_model({
		model_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/test_model.xlsx"},
		model_name => "excel_import",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",
		biomass => ["bio1"]})
	} 'import model from excel';
}

if ($start < 24) {
	print "Running test 23:\n";
	lives_ok{
	    $impl->sbml_file_to_model({
		model_file     => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/e_coli_core.xml" },
		model_name     => "sbml_test",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",
		biomass        => [ "R_BIOMASS_Ecoli_core_w_GAM" ]})
	} 'SBML import: test "R_" prefix';
}

if ($start < 25) {
	print "Running test 24:\n";
	lives_ok{
	    $impl->sbml_file_to_model({
		model_file     => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/PUBLIC_150.xml" },
		model_name     => "sbml_test2",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",
		biomass        => [ "bio00006" ]})
	} 'SBML import: test "_reference" error';
}

if ($start < 26) {
	print "Running test 25:\n";
	lives_ok{
	    $impl->sbml_file_to_model({
		model_file       => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/Community_model.sbml" },
		model_name       => "sbml_test3",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",
		biomass          => [ "bio1", "bio2", 'bio3' ]})
	} 'SBML import: community model';
}

if ($start < 27) {
	print "Running test 26:\n";
	lives_ok{
	    $impl->sbml_file_to_model({
		model_file     => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/iYL1228.xml" },
		model_name     => "sbml_test4",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",
		biomass        => [ "R_BIOMASS_" ]})
	} 'SBML import: annother model from BiGG';
}

if ($start < 28) {
	print "Running test 27:\n";
	lives_ok{
	    $impl->sbml_file_to_model({
		model_file     => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/Ec_iJR904.xml" },
		model_name     => "sbml_test5",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",
		biomass        => [ "bio1" ]})
	} 'SBML import: yet annother model from BiGG';
}

if ($start < 29) {
	print "Running test 28:\n";
	lives_ok{
	    $impl->sbml_file_to_model({
		model_file     => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/iMB155.xml" },
		model_name     => "sbml_test6",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",
		biomass        => [ "R_BIOMASS" ]})
	} 'SBML import: yet annother model from BiGG';
}

if ($start < 30) {
	print "Running test 29:\n";
	dies_ok{
	    $impl->sbml_file_to_model({
		model_file     => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/PUBLIC_150.xml" },
		model_name     => "better_fail",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",
		biomass        => [ "foo" ]})
	} 'SBML import: biomass not found';
	print $@."\n";
}

if ($start < 31) {
	print "Running test 30:\n";
	dies_ok{
	    $impl->tsv_file_to_model({
		model_file     => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/FBAModelReactions.tsv" },
		model_name     => "Pickaxe",
		workspace_name => $test_ws,
		biomass        => [],
		compounds_file => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/FBAModelCompounds.tsv" }})
	} 'TSV to Model: invalid compound identifier';
	print $@."\n";
}

if ($start < 32) {
	print "Running test 31:\n";
	lives_ok{
	    $impl->tsv_file_to_model({
		model_file     => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/test_model-reactions.tsv" },
		model_name     => "tsv_import",
		workspace_name => $test_ws,
		genome         => $test_ws."/Escherichia_coli",,
		biomass        => ["bio1"],
		compounds_file => { path => Bio::KBase::utilities::conf("fba_tools","testdir")."/test_model-compounds.tsv" }})
	} 'import model from tsv';
}

if ($start < 33) {
	print "Running test 32:\n";
	lives_ok{
	    $impl->model_to_excel_file({
		input_ref => $test_ws."/test_model"})
	} 'export model as excel';
}

if ($start < 34) {
	print "Running test 33:\n";
	lives_ok{
	    $impl->model_to_sbml_file({
		input_ref => $test_ws."/test_model"})
	} 'export model as sbml';
}

if ($start < 35) {
	print "Running test 34:\n";
	lives_ok{
	    $impl->model_to_tsv_file({
		input_ref => $test_ws."/test_model"})
	} 'export model as tsv';
}

if ($start < 36) {
	print "Running test 35:\n";
	lives_ok{
	    $impl->fba_to_excel_file({
		input_ref => $test_ws."/test_minimal_fba"})
	} 'export fba as excel';
}

if ($start < 37) {
	print "Running test 36:\n";
	lives_ok{
	    $impl->fba_to_tsv_file({
		input_ref => $test_ws."/test_minimal_fba"})
	} 'export fba as tsv';
}

if ($start < 38) {
	print "Running test 37:\n";
	lives_ok{
	    $impl->tsv_file_to_media({
		media_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/media_example.tsv"},
		media_name => "tsv_media",
		workspace_name => $test_ws})
	} 'TSV to media';
}

if ($start < 39) {
	print "Running test 38:\n";
	lives_ok{
	    $impl->tsv_file_to_media({
		media_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/test_media.tsv"},
		media_name => "tsv_media2",
		workspace_name => $test_ws})
	} 'TSV to media 2';
}

if ($start < 40) {
	print "Running test 39:\n";
	lives_ok{
	    $impl->tsv_file_to_media({
		media_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/medio.tsv"},
		media_name => "tsv_media3",
		workspace_name => $test_ws})
	} 'TSV to media: blank lines and trailing spaces';
}

if ($start < 41) {
	print "Running test 40:\n";
	lives_ok{
	    $impl->excel_file_to_media({
		media_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/media_example.xls"},
		media_name => "xls_media",
		workspace_name => $test_ws})
	} 'Excel to media';
}

if ($start < 42) {
	print "Running test 41:\n";
	lives_ok{
	    $impl->excel_file_to_media({
		media_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/test_media.xls"},
		media_name => "xls_media2",
		workspace_name => $test_ws})
	} 'Excel to media 2';
}

if ($start < 43) {
	print "Running test 42:\n";
	lives_ok{
	    $impl->media_to_tsv_file({
		input_ref => "KBaseMedia/Carbon-D-Glucose"})
	} 'media to tsv file';
}

if ($start < 44) {
	print "Running test 43:\n";
	lives_ok{
	    $impl->media_to_excel_file({
		input_ref => "KBaseMedia/Carbon-D-Glucose"})
	} 'media to excel file';
}

if ($start < 45) {
	print "Running test 44:\n";
	lives_ok{
	    $impl->tsv_file_to_phenotype_set({
		phenotype_set_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/JZ_UW_Phynotype_Set_test.txt"},
		phenotype_set_name => "return_delimited",
		workspace_name => $test_ws,
		genome => $test_ws."/Escherichia_coli"})
	} 'TSV to Phenotype Set: import return delimented';
}

if ($start < 46) {
	print "Running test 45:\n";
	lives_ok{
	    $impl->tsv_file_to_phenotype_set({
		phenotype_set_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/NewPhenotypeSet.tsv"},
		phenotype_set_name => "test_phenotype_set",
		workspace_name => $test_ws,
		genome => $test_ws."/Escherichia_coli"})
	} 'TSV to Phenotype Set: custom columns';
}

if ($start < 47) {
	print "Running test 46:\n";
	dies_ok{
	    $impl->tsv_file_to_phenotype_set({
		phenotype_set_file => {path => Bio::KBase::utilities::conf("fba_tools","testdir")."/EmptyPhenotypeSet.tsv"},
		phenotype_set_name => "test_phenotype_set",
		workspace_name => $test_ws,
		genome => $test_ws."/Escherichia_coli"})
	} 'import empty phenotype set fails';
	print $@."\n";
}

if ($start < 48) {
	print "Running test 47:\n";
	lives_ok{
	    $impl->phenotype_set_to_tsv_file({
		input_ref => $test_ws."/test_phenotype_set"})
	} 'export phenotypes as tsv';
}

if ($start < 49) {
	print "Running test 48:\n";
	lives_ok{
	    $impl->phenotype_simulation_set_to_excel_file({
		input_ref => $test_ws."/test_phenotype_simset"})
	} 'phenosim to excel';
}

if ($start < 50) {
	print "Running test 49:\n";
	lives_ok{
	    $impl->phenotype_simulation_set_to_tsv_file({
		input_ref => $test_ws."/test_phenotype_simset"})
	} 'phenosim to tsv';
}

if ($start < 51) {
	print "Running test 50:\n";
	lives_ok{
	    $impl->bulk_export_objects({
		refs => [ $test_ws."/test_model", $test_ws."/test_propagated_model" ],
		workspace => $test_ws,
		report_workspace => $test_ws,
		all_media => 1,
		media_format => "excel"})
	} 'bulk export of modeling objects';
}

if ($start < 52) {
	print "Running test 51:\n";
	lives_ok{
	    $impl->export_model_as_excel_file({
		input_ref => $test_ws."/test_model"})
	} 'export model as excel';
}

if ($start < 53) {
	print "Running test 52:\n";
	lives_ok{
	    $impl->export_model_as_tsv_file({
		input_ref => $test_ws."/test_model"})
	} 'export model as tsv';
}

if ($start < 54) {
	print "Running test 53:\n";
	lives_ok{
	    $impl->export_model_as_sbml_file({
		input_ref => $test_ws."/test_model"})
	} 'export model as sbml';
}

if ($start < 55) {
	print "Running test 54:\n";
	lives_ok{
	    $impl->export_fba_as_excel_file({
		input_ref => $test_ws."/test_minimal_fba"})
	} 'export fba as excel';
}

if ($start < 56) {
	print "Running test 55:\n";
	lives_ok{
	    $impl->export_fba_as_tsv_file({
		input_ref => $test_ws."/test_minimal_fba"})
	} 'export fba as tsv';
}

if ($start < 57) {
	print "Running test 56:\n";
	lives_ok{
	    $impl->export_media_as_excel_file({
		input_ref => "KBaseMedia/Carbon-D-Glucose"})
	} 'export media as excel';
}

if ($start < 58) {
	print "Running test 57:\n";
	lives_ok{
	    $impl->export_media_as_tsv_file({
		input_ref => "KBaseMedia/Carbon-D-Glucose"})
	} 'export media as tsv';
}

if ($start < 59) {
	print "Running test 58:\n";
	lives_ok{
	    $impl->export_phenotype_set_as_tsv_file({
		input_ref => $test_ws."/test_phenotype_set"})
	} 'export phenotypes as tsv';
}

if ($start < 60) {
	print "Running test 59:\n";
	lives_ok{
	        $impl->export_phenotype_simulation_set_as_excel_file({
		input_ref => $test_ws."/test_phenotype_simset"})
	} 'export phenotypes sim set as excel';
}

if ($start < 61) {
	print "Running test 60:\n";
	lives_ok{
	    $impl->export_phenotype_set_as_tsv_file({
		input_ref => $test_ws."/test_phenotype_simset"})
	} 'export phenotype sim set as tsv';
}

done_testing();
