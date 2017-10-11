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
#=head

# build_metabolic_model
lives_ok{
        $impl->build_metabolic_model({
            genome_id => "8248/9/1",
	        fbamodel_output_id =>  "test_model",
	        template_id =>  "auto",
	        gapfill_model =>  1,
	        minimum_target_flux =>  0.1,
            workspace => get_ws_name()
        })
   } "build_metabolic_model";

# gapfill_metabolic_model
lives_ok{
        $impl->gapfill_metabolic_model({
            fbamodel_id => "7601/194/1",
	        media_id => "8248/10/1",
	        fbamodel_output_id =>  "test_model_minimal",
	        workspace => get_ws_name(),
	        target_reaction => "bio1"
        })
   } "gapfill_metabolic_model";

# run_flux_balance_analysis
lives_ok{
        $impl->run_flux_balance_analysis({
            fbamodel_id => "8248/15/1",
	        media_id => "8248/10/1",
	        fba_output_id =>  "test_minimal_fba",
	        workspace => get_ws_name(),
	        target_reaction => "bio1",
            fva => 1,
            minimize_flux => 1
        })
   } "run_flux_balance_analysis";

# check_model_mass_balance
lives_ok{
        $impl->check_model_mass_balance({
            fbamodel_id => "8248/15/1",
            workspace   => get_ws_name()
        })
    } "check_model_mass_balance";

# propagate_model_to_new_genome
lives_ok{
        $impl->propagate_model_to_new_genome({
            fbamodel_id                 => "8248/15/1",
            proteincomparison_id        => "8248/14/1",
            media_id                    => "8248/10/1",
            fbamodel_output_id          => "test_propagated_model",
            workspace                   => "jjeffryes:narrative_1502586048308",
            keep_nogene_rxn             => 1,
            gapfill_model               => 0,
            custom_bound_list           => [],
            media_supplement_list       => "",
            minimum_target_flux         => 0.1,
            translation_policy          => "add_reactions_for_unique_genes"
        })
    } "propagate_model_to_new_genome";

# simulate_growth_on_phenotype_data
lives_ok{
        $impl->simulate_growth_on_phenotype_data({
            fbamodel_id            => "7601/194/1",
            phenotypeset_id        => "7601/50",
            phenotypesim_output_id => "custom_phenotype_sim",
            workspace              => "jjeffryes:narrative_1502586048308",
            gapfill_phenotypes     => 1,
            fit_phenotype_data     => 0,
            target_reaction        => "bio1"
        })
    } "simulate_growth_on_phenotype_data_w_bounds";

# compare_models
lives_ok{
        $impl->compare_models({
            mc_name       => "model_comparison",
            model_refs    => [ "7601/20/9", "7601/18/9" ],
            pangenome_ref => "7601/39/1",
            workspace     => get_ws_name()
        })
    } 'Compare Models';

lives_ok{
        $impl->compare_models({
            mc_name    => "model_comparison_test",
            model_refs => [ "7601/194/1", "7601/18/9"],
            workspace  => get_ws_name()
        })
    } 'Compare Models';

# build_multiple_metabolic_models
lives_ok{
        $impl->build_multiple_metabolic_models({
            "genome_text"           => "79/11/1",
            "genome_ids"            => [ "79/5/1" ],
            "media_id"              => undef,
            "template_id"           => "auto",
            "gapfill_model"         => 1,
            "custom_bound_list"     => [],
            "media_supplement_list" => [],
            "minimum_target_flux"   => 0.1,
            "workspace"             => get_ws_name()
        })
    } "build_multiple_metabolic_models";

# compare_fba_solutions
lives_ok{
        $impl->compare_fba_solutions({
            fba_id_list => ["8248/168/1", "8248/166/1"],
			fbacomparison_output_id => "fba_comparison",
			workspace => "chenry:narrative_1504151898593",
        })
    } "compare_fba_solutions";

# merge_metabolic_models_into_community_model
lives_ok{
        $impl->merge_metabolic_models_into_community_model({
            fbamodel_id_list => ["8248/162/23", "8248/15/1"],
			fbamodel_output_id => "Community_model",
			workspace => get_ws_name(),
			mixed_bag_model => 1
        })
    } "merge_metabolic_models_into_community_model";

# view_flux_network
lives_ok{
        $impl->view_flux_network({
            fba_id => "7601/135/11",
			workspace => get_ws_name(),
        })
    } "view_flux_network";

# compare_flux_with_expression
lives_ok{
        $impl->compare_flux_with_expression({
            "estimate_threshold" => 0,
            "maximize_agreement" => 0,
            "expression_condition" => "22c.5h_r1[sodium_chloride:0 mM,culture_temperature:22 Celsius,casamino_acids:0.3 mg/mL]",
            "fba_id"=> "7601/61/1",
            "fbapathwayanalysis_output_id" => "test",
            "exp_threshold_percentile" => 0.5,
            "expseries_id" => "7601/132/1",
            "workspace" => get_ws_name()
        })
    } "compare_flux_with_expression";

# edit_metabolic_model
lives_ok{
        $impl->edit_metabolic_model({
            workspace => "jjeffryes:narrative_1502586048308",
			fbamodel_id => "7601/194/1",
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
	    	fbamodel_output_id => "edited_model"
        })
    }, "Edit Model";

# edit_media
lives_ok{
        $impl->edit_media({
            workspace => "chenry:narrative_1504151898593",
			media_output_id => "edited_media",
			media_id => "8248/23/1",
	    	compounds_to_remove => "cpd00204",
	    	compounds_to_change => [{change_id => "cpd00001",change_concentration => 0.1,change_minflux => -100,change_maxflux => 1}],
	    	compounds_to_add => [{add_id => "Acetate",add_concentration => 0.1,add_minflux => -100,add_maxflux => 1}],
	    	pH_data => "8",
	    	temperature => 303,
	    	source_id => "edit_media_test_source_id",
	    	source => "edit_media_test_source",
	    	type => "test",
	    	isDefined => 1
        })
    } "Edit Media";

# excel_file_to_model
lives_ok{
        $impl->excel_file_to_model({
            model_file => {path => "/kb/module/test/data/test_model.xlsx"},
	        model_name => "excel_import",
	        workspace_name => get_ws_name(),
            genome         => "7601/4/1",
	        biomass => ["bio1"]
        })
    } 'import model from excel';

# sbml_file_to_model
lives_ok{
        $impl->sbml_file_to_model({
            model_file     =>
            { path => "/kb/module/test/data/e_coli_core.xml" },
            model_name     => "sbml_test",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "7601/4/1",
            biomass        => [ "R_BIOMASS_Ecoli_core_w_GAM" ]
        })
    } 'SBML import: test "R_" prefix';

lives_ok{
        $impl->sbml_file_to_model({
            model_file     =>
            { path => "/kb/module/test/data/PUBLIC_150.xml" },
            model_name     => "sbml_test2",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "Escherichia_coli_K-12_MG1655",
            biomass        => [ "bio00006" ]
        })
    } 'SBML import: test "_refference" error';

lives_ok{
        $impl->sbml_file_to_model({
            model_file       =>
            { path => "/kb/module/test/data/Community_model.sbml" },
            model_name       => "sbml_test3",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "7601/4/1",
            biomass          => [ "bio1", "bio2", 'bio3' ]
        })
    } 'SBML import: community model';

lives_ok{
        $impl->sbml_file_to_model({
            model_file     =>
            { path => "/kb/module/test/data/iYL1228.xml" },
            model_name     => "sbml_test4",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "7601/4/1",
            biomass        => [ "R_BIOMASS_" ]
        })
    } 'SBML import: annother model from BiGG';

dies_ok {
        $impl->sbml_file_to_model({
            model_file     =>
            { path => "/kb/module/test/data/PUBLIC_150.xml" },
            model_name     => "better_fail",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "Escherichia_coli_K-12_MG1655",
            biomass        => [ "foo" ]
        })
    }, 'SBML import: biomass not found';

# tsv_file_to_model
dies_ok{
        $impl->tsv_file_to_model({
            model_file     =>
            { path => "/kb/module/test/data/FBAModelReactions.tsv" },
            model_name     => "Pickaxe",
            workspace_name => get_ws_name(),
            biomass        => [],
            compounds_file =>
            { path => "/kb/module/test/data/FBAModelCompounds.tsv" }
        })
    } 'tsv_to_model_with_structure';

lives_ok{
        $impl->tsv_file_to_model({
            model_file     => { path => "/kb/module/test/data/test_model-reactions.tsv" },
            model_name     => "tsv_import",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "8248/9/1",
            biomass        => ["bio1"],
            compounds_file => { path => "/kb/module/test/data/test_model-compounds.tsv" }
        })
    } 'import model from tsv';

# model_to_excel_file
lives_ok{
        $impl->model_to_excel_file({
            input_ref => "8248/18/1",
        })
    } 'export model as excel';

# model_to_sbml_file
lives_ok{
        $impl->model_to_sbml_file({
            input_ref => "7601/167",
        })
    } 'export model as sbml';

# model_to_tsv_file
lives_ok{
        $impl->model_to_tsv_file({
            input_ref => "8248/18/1",
        })
    } 'export model as tsv';

# fba_to_excel_file
lives_ok{
        $impl->fba_to_excel_file({
			input_ref => "8248/21/1",
        })
    } 'export fba as excel';

# fba_to_tsv_file
lives_ok{
        $impl->fba_to_tsv_file({
			input_ref => "8248/21/1",
        })
    } 'export fba as tsv';

# tsv_file_to_media
lives_ok{
        $impl->tsv_file_to_media({
            media_file => {path => "/kb/module/test/data/media_example.tsv"},
	        media_name => "tsv_media",
            workspace_name => get_ws_name()
        })
    } 'TSV to media';

lives_ok{
        $impl->tsv_file_to_media({
            media_file => {path => "/kb/module/test/data/test_media.tsv"},
	        media_name => "tsv_media2",
            workspace_name     => get_ws_name()
        })
    } 'TSV to media 2';

# excel_file_to_media
lives_ok{
        $impl->excel_file_to_media({
            media_file => {path => "/kb/module/test/data/media_example.xls"},
	        media_name => "xls_media",
            workspace_name     => get_ws_name()
        })
    } 'Excel to media';

lives_ok{
        $impl->excel_file_to_media({
            media_file => {path => "/kb/module/test/data/test_media.xls"},
	        media_name => "xls_media2",
            workspace_name     => get_ws_name()
        })
    } 'Excel to media 2';

# media_to_tsv_file
lives_ok{
        $impl->media_to_tsv_file({
            input_ref => "7601/41/1",
        })
    } 'media to tsv file';

# media_to_excel_file
lives_ok{
        $impl->media_to_excel_file({
            input_ref => "7601/41/1",
        })
    } 'media to excel file';

# tsv_file_to_phenotype_set
lives_ok{
        $impl->tsv_file_to_phenotype_set({
            phenotype_set_file => {path => "/kb/module/test/data/JZ_UW_Phynotype_Set_test.txt"},
	        phenotype_set_name => "return_delimited",
	        workspace_name => get_ws_name(),
	        genome => "8248/9/1"
        })
    } 'TSV to Phenotype Set: import return delimented';

lives_ok{
    $impl->tsv_file_to_phenotype_set({
                phenotype_set_file => {path => "/kb/module/test/data/NewPhenotypeSet.tsv"},
                phenotype_set_name => "tsv_phenotypeset",
                workspace_name => get_ws_name(),
                genome => "7601/4/1"
        })
    }, 'TSV to Phenotype Set: custom columns';

dies_ok{
        $impl->tsv_file_to_phenotype_set({
            phenotype_set_file => {path => "/kb/module/test/data/EmptyPhenotypeSet.tsv"},
	        phenotype_set_name => "tsv_phenotypeset",
	        workspace_name => get_ws_name(),
            genome => "7601/4/1"
        })
    } 'import empty phenotype set fails';

# phenotype_set_to_tsv_file
lives_ok{
        $impl->phenotype_set_to_tsv_file({
            input_ref => "7601/50",
        })
    } 'export phenotypes as tsv';

# phenotype_simulation_set_to_excel_file
lives_ok{
        $impl->phenotype_simulation_set_to_excel_file({
            input_ref => "7601/80",
        })
    } 'phenosim to excel';

# phenotype_simulation_set_to_tsv_file
lives_ok{
        $impl->phenotype_simulation_set_to_tsv_file({
            input_ref => "7601/80",
        })
    } 'phenosim to tsv';

# bulk_export_objects
lives_ok{
        $impl->bulk_export_objects({
            refs => [ "7601/20/9", "7601/18/9" ],
	        workspace => "jjeffryes:narrative_1502586048308",
	        all_media => 1,
	        media_format => "excel"
        })
    } 'bulk export of modeling objects';

=cut
# export_model_as_excel_file
lives_ok{
        $impl->export_model_as_excel_file({
           input_ref => "chenry:narrative_1504151898593/test_model_minimal"
        })
    } 'export model as excel';

# export_model_as_tsv_file
lives_ok{
        $impl->export_model_as_tsv_file({
           input_ref => "chenry:narrative_1504151898593/test_model_minimal"
        })
    } 'export model as tsv';

# export_model_as_sbml_file
lives_ok{
        $impl->export_model_as_sbml_file({
           input_ref => "chenry:narrative_1504151898593/test_model_minimal"
        })
    } 'export model as sbml';

# export_fba_as_excel_file
lives_ok{
        $impl->export_fba_as_excel_file({
           input_ref => "chenry:narrative_1504151898593/test_minimal_fba"
        })
    } 'export fba as excel';

# export_fba_as_tsv_file
lives_ok{
        $impl->export_fba_as_tsv_file({
           input_ref => "chenry:narrative_1504151898593/test_minimal_fba"
        })
    } 'export fba as tsv';

# export_media_as_excel_file
lives_ok{
        $impl->export_media_as_excel_file({
            input_ref => "7601/41/1"
        })
    } 'export media as excel';

# export_media_as_tsv_file
lives_ok{
        $impl->export_media_as_tsv_file({
            input_ref => "7601/41/1"
        })
    } 'export media as tsv';

# export_phenotype_set_as_tsv_file
lives_ok{
        $impl->export_phenotype_set_as_tsv_file({
			input_ref => "chenry:narrative_1504151898593/SB2B_biolog_data"
        })
    } 'export phenotypes as tsv';

# export_phenotype_simulation_set_as_excel_file
lives_ok{
        $impl->export_phenotype_simulation_set_as_excel_file({
            input_ref => "jjeffryes:narrative_1502586048308/phenotype_simulation"
        })
    } 'export phenotypes sim set as excel';

# export_phenotype_simulation_set_as_tsv_file
lives_ok{
        $impl->export_phenotype_set_as_tsv_file({
            input_ref => "jjeffryes:narrative_1502586048308/phenotype_simulation"
        })
    } 'export phenotype sim set as tsv';
=cut

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
