use strict;
use Data::Dumper;
use Test::More;
use Test::Exception;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::AuthToken;
#use Bio::KBase::workspace::Client;
use Workspace::WorkspaceClient;
use fba_tools::fba_toolsImpl;

local $| = 1;
my $token = $ENV{'KB_AUTH_TOKEN'};
my $config_file = $ENV{'KB_DEPLOYMENT_CONFIG'};
my $config = new Config::Simple($config_file)->get_block('fba_tools');
my $ws_url = $config->{"workspace-url"};
my $ws_name = undef;
my $test_ws = "fba_tools_unittests_ws";
#my $ws_client = new Bio::KBase::workspace::Client($ws_url,token => $token);
my $ws_client = Workspace::WorkspaceClient->new($ws_url,token => $token);
my $auth_token = Bio::KBase::AuthToken->new(token => $token, ignore_authrc => 1);
my $ctx = LocalCallContext->new($token, $auth_token->user_id);
$fba_tools::fba_toolsServer::CallContext = $ctx;
my $impl = new fba_tools::fba_toolsImpl();

sub get_ws_name {
    if (!defined($ws_name)) {
        my $suffix = int(time * 1000);
        $ws_name = 'test_fba_tools_' . $suffix;
        $ws_client->create_workspace({workspace => $ws_name});
    }
    return $ws_name;
}

# build_metabolic_model
lives_ok{
    $impl->build_metabolic_model({
	genome_id => $test_ws."/Escherichia_coli",
	fbamodel_output_id =>  "test_model",
	template_id =>  "auto",
	gapfill_model =>  1,
	minimum_target_flux =>  0.1,
	workspace => get_ws_name()})
   } "build_metabolic_model";

# build_plant_metabolic_model
lives_ok{
    $impl->build_plant_metabolic_model({
	genome_id => "Alyrata_v1.0",
	genome_workspace => "PlantSEED_v2",
	fbamodel_output_id =>  "test_model",
	workspace => get_ws_name()})
} "build_plant_metabolic_model";

# merge_metabolic_models_into_community_model
lives_ok{
    $impl->merge_metabolic_models_into_community_model({
	fbamodel_id_list => [ $test_ws."/test_model", $test_ws."/test_model_2" ],
	fbamodel_output_id => "Community_model",
	workspace => get_ws_name(),
	mixed_bag_model => 1})
} "merge_metabolic_models_into_community_model";

# gapfill_metabolic_model
lives_ok{
    $impl->gapfill_metabolic_model({
	fbamodel_id => $test_ws."/test_model",
	media_id => $test_ws."/Carbon-D-Glucose",
	fbamodel_output_id =>  "test_model_minimal",
	workspace => get_ws_name(),
	target_reaction => "bio1"})
} "gapfill_metabolic_model";

lives_ok{
        $impl->gapfill_metabolic_model({
            fbamodel_id => $test_ws."/test_model",
	    media_id => $test_ws."/nocarbon_media",
	    fbamodel_output_id =>  "test_model_nocarbon",
	    workspace => get_ws_name(),
	    target_reaction => "bio1"})
} "gapfill_metabolic_model_fails";

lives_ok{
    $impl->run_flux_balance_analysis({
	fbamodel_id => $test_ws."/test_model",
	media_id => $test_ws."/Carbon-D-Glucose",
	fba_output_id =>  "test_minimal_fba",
	workspace => get_ws_name(),
	target_reaction => "bio1",
	fva => 1,
	minimize_flux => 1})
} "run_flux_balance_analysis";

# check_model_mass_balance
lives_ok{
    $impl->check_model_mass_balance({
	fbamodel_id => $test_ws."/test_model",
	workspace   => get_ws_name()})
} "check_model_mass_balance";

# propagate_model_to_new_genome
lives_ok{
    $impl->propagate_model_to_new_genome({
	fbamodel_id => $test_ws."/test_model",
	media_id => $test_ws."/Carbon-D-Glucose",
	proteincomparison_id        => $test_ws."/Ecoli_vs_Paeruginosa",
	fbamodel_output_id          => "test_propagated_model",
	workspace                   => get_ws_name(),
	keep_nogene_rxn             => 1,
	gapfill_model               => 1,
	custom_bound_list           => [],
	media_supplement_list       => "",
	minimum_target_flux         => 0.1,
	translation_policy          => "add_reactions_for_unique_genes"})
} "propagate_model_to_new_genome";

# simulate_growth_on_phenotype_data
lives_ok{
        $impl->simulate_growth_on_phenotype_data({
	    fbamodel_id            => $test_ws."/test_model",
            phenotypeset_id        => $test_ws."/SB2B_biolog_data",
            phenotypesim_output_id => "test_phenotype_simset",
            workspace              => get_ws_name(),
            gapfill_phenotypes     => 0,
            fit_phenotype_data     => 1,
            target_reaction        => "bio1"
        })
} "simulate_growth_on_phenotype_data_w_bounds";

# compare_models
lives_ok{
    $impl->compare_models({
	mc_name    => "model_comparison_test",
	model_refs    => [ $test_ws."/test_model", $test_ws."/test_model_2" ],
	workspace  => get_ws_name()})
} 'Compare Models';

lives_ok{
    $impl->compare_models({
	mc_name       => "model_comparison",
	model_refs    => [ $test_ws."/test_model", $test_ws."/test_model_2" ],
	pangenome_ref => $test_ws."/test_pangenome",
	workspace     => get_ws_name()})
} 'Compare Models w/ pangenome';

# build_multiple_metabolic_models
lives_ok{
    $impl->build_multiple_metabolic_models({
	"genome_text"           => $test_ws."/Rhodobacter_sphaeroides",
	"genome_ids"            => [ $test_ws."/Escherichia_coli" ],
	"media_id"              => undef,
	"template_id"           => "auto",
	"gapfill_model"         => 1,
	"custom_bound_list"     => [],
	"media_supplement_list" => [],
	"minimum_target_flux"   => 0.1,
	"workspace"             => get_ws_name()})
} "build_multiple_metabolic_models";

# compare_fba_solutions
lives_ok{
    $impl->compare_fba_solutions({
	fba_id_list => [ $test_ws."/test_model_gf_fba", $test_ws."/test_model_2_gf_fba" ],
	fbacomparison_output_id => "fba_comparison",
	workspace => get_ws_name()})
} "compare_fba_solutions";

# view_flux_network
lives_ok{
    $impl->view_flux_network({
	fba_id => $test_ws."/test_model_gf_fba",
	workspace => get_ws_name()})
} "view_flux_network";

# compare_flux_with_expression
lives_ok{
    $impl->compare_flux_with_expression({
	estimate_threshold => 0,
	maximize_agreement => 0,
	expression_condition => "22c.5h_r1[sodium_chloride:0 mM,culture_temperature:22 Celsius,casamino_acids:0.3 mg/mL]",
	fba_id => $test_ws."/test_model_gf_fba",
	fbapathwayanalysis_output_id => "test",
	exp_threshold_percentile => 0.5,
	expseries_id => $test_ws."/expression_matrix_test",
	workspace => get_ws_name()})
} "compare_flux_with_expression";

# edit_metabolic_model
lives_ok{
    $impl->edit_metabolic_model({
	workspace => get_ws_name(),
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

# edit_media
lives_ok{
    $impl->edit_media({
	workspace => get_ws_name(),
	media_output_id => "edited_media",
	media_id => $test_ws."/Carbon-D-Glucose",
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

# excel_file_to_model
lives_ok{
    $impl->excel_file_to_model({
	model_file => {path => "/kb/module/test/data/test_model.xlsx"},
	model_name => "excel_import",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",
	biomass => ["bio1"]})
} 'import model from excel';

# sbml_file_to_model
lives_ok{
    $impl->sbml_file_to_model({
	model_file     => { path => "/kb/module/test/data/e_coli_core.xml" },
	model_name     => "sbml_test",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",
	biomass        => [ "R_BIOMASS_Ecoli_core_w_GAM" ]})
} 'SBML import: test "R_" prefix';

lives_ok{
    $impl->sbml_file_to_model({
	model_file     => { path => "/kb/module/test/data/PUBLIC_150.xml" },
	model_name     => "sbml_test2",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",
	biomass        => [ "bio00006" ]})
} 'SBML import: test "_reference" error';

lives_ok{
    $impl->sbml_file_to_model({
	model_file       => { path => "/kb/module/test/data/Community_model.sbml" },
	model_name       => "sbml_test3",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",
	biomass          => [ "bio1", "bio2", 'bio3' ]})
} 'SBML import: community model';

lives_ok{
    $impl->sbml_file_to_model({
	model_file     => { path => "/kb/module/test/data/iYL1228.xml" },
	model_name     => "sbml_test4",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",
	biomass        => [ "R_BIOMASS_" ]})
} 'SBML import: annother model from BiGG';

lives_ok{
    $impl->sbml_file_to_model({
	model_file     => { path => "/kb/module/test/data/Ec_iJR904.xml" },
	model_name     => "sbml_test5",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",
	biomass        => [ "bio1" ]})
} 'SBML import: yet annother model from BiGG';

lives_ok{
    $impl->sbml_file_to_model({
	model_file     => { path => "/kb/module/test/data/iMB155.xml" },
	model_name     => "sbml_test6",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",
	biomass        => [ "R_BIOMASS" ]})
} 'SBML import: yet annother model from BiGG';

dies_ok{
    $impl->sbml_file_to_model({
	model_file     => { path => "/kb/module/test/data/PUBLIC_150.xml" },
	model_name     => "better_fail",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",
	biomass        => [ "foo" ]})
} 'SBML import: biomass not found';
print $@."\n";

# tsv_file_to_model
dies_ok{
    $impl->tsv_file_to_model({
	model_file     => { path => "/kb/module/test/data/FBAModelReactions.tsv" },
	model_name     => "Pickaxe",
	workspace_name => get_ws_name(),
	biomass        => [],
	compounds_file => { path => "/kb/module/test/data/FBAModelCompounds.tsv" }})
} 'TSV to Model: invalid compound identifier';
print $@."\n";

lives_ok{
    $impl->tsv_file_to_model({
	model_file     => { path => "/kb/module/test/data/test_model-reactions.tsv" },
	model_name     => "tsv_import",
	workspace_name => get_ws_name(),
	genome         => $test_ws."/Escherichia_coli",,
	biomass        => ["bio1"],
	compounds_file => { path => "/kb/module/test/data/test_model-compounds.tsv" }})
} 'import model from tsv';

# model_to_excel_file
lives_ok{
    $impl->model_to_excel_file({
	input_ref => $test_ws."/test_model"})
} 'export model as excel';

# model_to_sbml_file
lives_ok{
    $impl->model_to_sbml_file({
	input_ref => $test_ws."/test_model"})
} 'export model as sbml';

# model_to_tsv_file
lives_ok{
    $impl->model_to_tsv_file({
	input_ref => $test_ws."/test_model"})
} 'export model as tsv';

# fba_to_excel_file
lives_ok{
    $impl->fba_to_excel_file({
	input_ref => $test_ws."/test_model_gf_fba"})
} 'export fba as excel';

# fba_to_tsv_file
lives_ok{
    $impl->fba_to_tsv_file({
	input_ref => $test_ws."/test_model_gf_fba"})
} 'export fba as tsv';


# tsv_file_to_media
lives_ok{
    $impl->tsv_file_to_media({
	media_file => {path => "/kb/module/test/data/media_example.tsv"},
	media_name => "tsv_media",
	workspace_name => get_ws_name()})
} 'TSV to media';

lives_ok{
    $impl->tsv_file_to_media({
	media_file => {path => "/kb/module/test/data/test_media.tsv"},
	media_name => "tsv_media2",
	workspace_name => get_ws_name()})
} 'TSV to media 2';

lives_ok{
    $impl->tsv_file_to_media({
	media_file => {path => "/kb/module/test/data/medio.tsv"},
	media_name => "tsv_media3",
	workspace_name => get_ws_name()})
} 'TSV to media: blank lines and trailing spaces';

# excel_file_to_media
lives_ok{
    $impl->excel_file_to_media({
	media_file => {path => "/kb/module/test/data/media_example.xls"},
	media_name => "xls_media",
	workspace_name => get_ws_name()})
} 'Excel to media';

lives_ok{
    $impl->excel_file_to_media({
	media_file => {path => "/kb/module/test/data/test_media.xls"},
	media_name => "xls_media2",
	workspace_name => get_ws_name()})
} 'Excel to media 2';

# media_to_tsv_file
lives_ok{
    $impl->media_to_tsv_file({
	input_ref => $test_ws."/Carbon-D-Glucose"})
} 'media to tsv file';

# media_to_excel_file
lives_ok{
    $impl->media_to_excel_file({
	input_ref => $test_ws."/Carbon-D-Glucose"})
} 'media to excel file';

# tsv_file_to_phenotype_set
lives_ok{
    $impl->tsv_file_to_phenotype_set({
	phenotype_set_file => {path => "/kb/module/test/data/JZ_UW_Phynotype_Set_test.txt"},
	phenotype_set_name => "return_delimited",
	workspace_name => get_ws_name(),
	genome => $test_ws."/Escherichia_coli"})
} 'TSV to Phenotype Set: import return delimented';

lives_ok{
    $impl->tsv_file_to_phenotype_set({
	phenotype_set_file => {path => "/kb/module/test/data/NewPhenotypeSet.tsv"},
	phenotype_set_name => "test_phenotype_set",
	workspace_name => get_ws_name(),
	genome => $test_ws."/Escherichia_coli"})
} 'TSV to Phenotype Set: custom columns';

dies_ok{
    $impl->tsv_file_to_phenotype_set({
	phenotype_set_file => {path => "/kb/module/test/data/EmptyPhenotypeSet.tsv"},
	phenotype_set_name => "test_phenotype_set",
	workspace_name => get_ws_name(),
	genome => $test_ws."/Escherichia_coli"})
} 'import empty phenotype set fails';
print $@."\n";

# phenotype_set_to_tsv_file
lives_ok{
    $impl->phenotype_set_to_tsv_file({
	input_ref => $test_ws."/test_phenotype_set"})
} 'export phenotypes as tsv';

# phenotype_simulation_set_to_excel_file
lives_ok{
    $impl->phenotype_simulation_set_to_excel_file({
	input_ref => $test_ws."/test_phenotype_simset"})
} 'phenosim to excel';

# phenotype_simulation_set_to_tsv_file
lives_ok{
    $impl->phenotype_simulation_set_to_tsv_file({
	input_ref => $test_ws."/test_phenotype_simset"})
} 'phenosim to tsv';

# bulk_export_objects
lives_ok{
    $impl->bulk_export_objects({
	refs => [ $test_ws."/test_model", $test_ws."/test_model_2" ],
	workspace => $test_ws,
	report_workspace => get_ws_name(),
	all_media => 1,
	media_format => "excel"})
} 'bulk export of modeling objects';


# export_model_as_excel_file
lives_ok{
    $impl->export_model_as_excel_file({
	input_ref => $test_ws."/test_model"})
} 'export model as excel';

# export_model_as_tsv_file
lives_ok{
    $impl->export_model_as_tsv_file({
	input_ref => $test_ws."/test_model"})
} 'export model as tsv';

# export_model_as_sbml_file
lives_ok{
    $impl->export_model_as_sbml_file({
	input_ref => $test_ws."/test_model"})
} 'export model as sbml';

# export_fba_as_excel_file
lives_ok{
    $impl->export_fba_as_excel_file({
	input_ref => $test_ws."/test_model_gf_fba"})
} 'export fba as excel';

# export_fba_as_tsv_file
lives_ok{
    $impl->export_fba_as_tsv_file({
	input_ref => $test_ws."/test_model_gf_fba"})
} 'export fba as tsv';

# export_media_as_excel_file
lives_ok{
    $impl->export_media_as_excel_file({
	input_ref => $test_ws."/Carbon-D-Glucose"})
} 'export media as excel';

# export_media_as_tsv_file
lives_ok{
    $impl->export_media_as_tsv_file({
	input_ref => $test_ws."/Carbon-D-Glucose"})
} 'export media as tsv';

# export_phenotype_set_as_tsv_file
lives_ok{
    $impl->export_phenotype_set_as_tsv_file({
	input_ref => $test_ws."/test_phenotype_set"})
} 'export phenotypes as tsv';

# export_phenotype_simulation_set_as_excel_file
lives_ok{
        $impl->export_phenotype_simulation_set_as_excel_file({
	input_ref => $test_ws."/test_phenotype_simset"})
} 'export phenotypes sim set as excel';

# export_phenotype_simulation_set_as_tsv_file
lives_ok{
    $impl->export_phenotype_set_as_tsv_file({
	input_ref => $test_ws."/test_phenotype_set"})
} 'export phenotype sim set as tsv';

done_testing();

if (defined($ws_name)) {
        $ws_client->delete_workspace({workspace => $ws_name});
        print("Test workspace was deleted\n");
    }
{
    package LocalCallContext;
    use strict;
    sub new {
        my($class,$token,$user) = @_;
        my $self = {
            token => $token,
            user_id => $user
        };
        return bless $self, $class;
    }
    sub user_id {
        my($self) = @_;
        return $self->{user_id};
    }
    sub token {
        my($self) = @_;
        return $self->{token};
    }
    sub provenance {
        my($self) = @_;
        return [{'service' => 'fba_tools', 'method' => 'please_never_use_it_in_production', 'method_params' => []}];
    }
    sub authenticated {
        return 1;
    }
    sub log_debug {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
    sub log_info {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
}
