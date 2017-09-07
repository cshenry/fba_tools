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
            genome_id => "Shewanella_amazonensis_SB2B",
	        fbamodel_output_id =>  "test_model",
	        template_id =>  "auto",
	        gapfill_model =>  1,
	        minimum_target_flux =>  0.1,
            genome_workspace => "chenry:narrative_1504151898593",
            workspace => get_ws_name()
        })
   } "build_metabolic_model";

# gapfill_metabolic_model
lives_ok{
        $impl->gapfill_metabolic_model({
            fbamodel_id => "test_model",
	        fbamodel_workspace => get_ws_name(),
	        media_id => "Carbon-D-Glucose",
	        media_workspace => "chenry:narrative_1504151898593",
	        fbamodel_output_id =>  "test_model_minimal",
	        workspace => get_ws_name(),
	        target_reaction => "bio1"
        })
   } "gapfill_metabolic_model";

# run_flux_balance_analysis
lives_ok{
        $impl->run_flux_balance_analysis({
          fbamodel_id => "test_model_minimal",
	        fbamodel_workspace => get_ws_name(),
	        media_id => "Carbon-D-Glucose",
	        media_workspace => "chenry:narrative_1504151898593",
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
            fbamodel_id        => "test_model",
            workspace          => get_ws_name()
        })
    } "check_model_mass_balance";

# propagate_model_to_new_genome
lives_ok{
        $impl->propagate_model_to_new_genome({
            fbamodel_id                 => "test_model",
            proteincomparison_id        => "MR1_to_SB2B_comparison",
            proteincomparison_workspace => "chenry:narrative_1504151898593",
            media_id                    => "Carbon-D-Glucose",
            media_workspace             => "chenry:narrative_1504151898593",
            fbamodel_output_id          => "test_propagated_model",
            workspace                   => get_ws_name(),
            keep_nogene_rxn             => 1,
            gapfill_model               => 1,
            custom_bound_list           => [],
            media_supplement_list       => "",
            minimum_target_flux         => 0.1,
            translation_policy          => "add_reactions_for_unique_genes"
        })
    } "propagate_model_to_new_genome";

# simulate_growth_on_phenotype_data
lives_ok{
        $impl->simulate_growth_on_phenotype_data({
            fbamodel_id            => "test_model",
            phenotypeset_id        => "test_biolog_data",
            phenotypeset_workspace => "jjeffryes:narrative_1502586048308",
            phenotypesim_output_id => "phenotype_simulation_test",
            workspace              => get_ws_name(),
            gapfill_phenotypes     => 1,
            fit_phenotype_data     => 0,
            target_reaction        => "bio1"
        })
    } "simulate_growth_on_phenotype_data";

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
            model_refs => [ "chenry:narrative_1504151898593/iMR1_799",
                get_ws_name() . "/test_model" ],
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

# merge_metabolic_models_into_community_model

# compare_flux_with_expression

# edit_metabolic_model

# edit_media

# excel_file_to_model
lives_ok{
        $impl->excel_file_to_model({
            model_file => {path => "/kb/module/test/data/test_model.xls"},
	        model_name => "excel_import",
	        workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "Escherichia_coli_K-12_MG1655",
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
            genome         => "Escherichia_coli_K-12_MG1655",
            biomass        => [ "R_BIOMASS_Ecoli_core_w_GAM" ]
        })
    } 'test "R_" prefix';

lives_ok{
        $impl->sbml_file_to_model({
            model_file     =>
            { path => "/kb/module/test/data/PUBLIC_150.xml" },
            model_name     => "sbml_test2",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "Escherichia_coli_K-12_MG1655",
            biomass        => [ "bio00006" ]
        })
    } 'test "_refference" error';

lives_ok{
        $impl->sbml_file_to_model({
            model_file       =>
            { path => "/kb/module/test/data/test_model.sbml" },
            model_name       => "sbml_test3",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "Escherichia_coli_K-12_MG1655",
            biomass          => [ "bio1" ]
        })
    } 'import model from SBML';

dies_ok {
        $impl->sbml_file_to_model({
            model_file     =>
            { path => "/kb/module/test/data/PUBLIC_150.xml" },
            model_name     => "better_fail",
            workspace_name => "jjeffryes:narrative_1502586048308",
            genome         => "Escherichia_coli_K-12_MG1655",
            biomass        => [ "foo" ]
        })
    }, 'biomass not found';

# tsv_file_to_model
lives_ok{
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
            workspace_name => "chenry:narrative_1504151898593",
            genome => "Shewanella_amazonensis_SB2B",
            biomass        => ["bio1"],
            compounds_file => { path => "/kb/module/test/data/test_model-compounds.tsv" }
        })
    } 'import model from tsv';

# model_to_excel_file
lives_ok{
        $impl->model_to_excel_file({
            model_name => "test_model_minimal",
			workspace_name => "chenry:narrative_1504151898593"
        })
    } 'export model as excel';
		
# model_to_sbml_file
lives_ok{
        $impl->model_to_sbml_file({
            model_name => "test_model_minimal",
			workspace_name => "chenry:narrative_1504151898593"
        })
    } 'export model as sbml';

# model_to_tsv_file
lives_ok{
        $impl->model_to_tsv_file({
            model_name => "test_model_minimal",
			workspace_name => "chenry:narrative_1504151898593"
        })
    } 'export model as tsv';
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
=cut
# fba_to_excel_file
lives_ok{
        $impl->fba_to_excel_file({
			fba_name => "test_minimal_fba",
			workspace_name => "chenry:narrative_1504151898593"
        })
    } 'export fba as excel';

# fba_to_tsv_file
lives_ok{
        $impl->fba_to_tsv_file({
			fba_name => "test_minimal_fba",
			workspace_name => "chenry:narrative_1504151898593"
        })
    } 'export fba as tsv';
=cut
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
=cut
# tsv_file_to_media
lives_ok{
        $impl->tsv_file_to_media({
            media_file => {path => "/kb/module/test/data/media_example.tsv"},
	        media_name => "tsv_media",
            workspace_name     => get_ws_name()
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
            media_name => "tsv_media",
			workspace_name => get_ws_name()
        })
    } 'media to tsv file';

# media_to_excel_file
lives_ok{
        $impl->media_to_excel_file({
            media_name => "tsv_media",
			workspace_name => get_ws_name()
        })
    } 'media to excel file';
=cut
# export_media_as_excel_file
lives_ok{
        $impl->export_media_as_excel_file({
            input_ref => get_ws_name()."/tsv_media"
        })
    } 'export media as excel';

# export_media_as_tsv_file
lives_ok{
        $impl->export_media_as_tsv_file({
            input_ref => get_ws_name()."/tsv_media"
        })
    } 'export media as tsv';
=cut
# tsv_file_to_phenotype_set
lives_ok{
        $impl->tsv_file_to_phenotype_set({
            phenotype_set_file => {path => "/kb/module/test/data/phenotype_simulation.tsv"},
	        phenotype_set_name => "tsv_phenotypeset",
	        workspace_name => get_ws_name(),
	        genome_workspace => "chenry:narrative_1504151898593",
	        genome => "Shewanella_amazonensis_SB2B"
        })
    } 'import phenotype set from tsv';

# phenotype_set_to_tsv_file
lives_ok{
        $impl->phenotype_set_to_tsv_file({
            phenotype_set_name => "SB2B_biolog_data",
			workspace_name => "chenry:narrative_1504151898593"
        })
    } 'export phenotypes as tsv';
=cut
# export_phenotype_set_as_tsv_file
lives_ok{
        $impl->export_phenotype_set_as_tsv_file({
			input_ref => "chenry:narrative_1504151898593/SB2B_biolog_data"
        })
    } 'export phenotypes as tsv';
=cut
# phenotype_simulation_set_to_excel_file
lives_ok{
        $impl->phenotype_simulation_set_to_excel_file({
            phenotype_simulation_set_name => "phenotype_simulation",
			workspace_name => "jjeffryes:narrative_1502586048308"
        })
    } 'phenosim to excel';

# phenotype_simulation_set_to_tsv_file
lives_ok{
        $impl->phenotype_simulation_set_to_tsv_file({
            phenotype_simulation_set_name => "phenotype_simulation",
			workspace_name => "jjeffryes:narrative_1502586048308"
        })
    } 'phenosim to tsv';
=cut
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
# bulk_export_objects
lives_ok{
        $impl->bulk_export_objects({
            refs => [ "7601/20/9", "7601/18/9" ],
	        workspace => "jjeffryes:narrative_1502586048308",
	        all_media => 1,
	        media_format => "excel"
        })
    } 'bulk export of modeling objects';

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
