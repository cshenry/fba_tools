use strict;
use Data::Dumper;
use Test::More; qw( no_plan );
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
        $ws_name = 'test_kb_pickaxe_' . $suffix;
        $ws_client->create_workspace({workspace => $ws_name});
    }
    return $ws_name;
}

#=head
#=cut

# build_metabolic_model

# build_multiple_metabolic_models

# gapfill_metabolic_model

# run_flux_balance_analysis

# compare_fba_solutions

# propagate_model_to_new_genome

# simulate_growth_on_phenotype_data

# merge_metabolic_models_into_community_model

# compare_flux_with_expression

# check_model_mass_balance

# compare_models

# edit_metabolic_model

# edit_media

# excel_file_to_model

# sbml_file_to_model

# tsv_file_to_model

# model_to_excel_file

# model_to_sbml_file

# model_to_tsv_file

# export_model_as_excel_file

# export_model_as_tsv_file

# export_model_as_sbml_file

# fba_to_excel_file

# fba_to_tsv_file

# export_fba_as_excel_file

# export_fba_as_tsv_file

# tsv_file_to_media

# excel_file_to_media

# media_to_tsv_file

# media_to_excel_file

# export_media_as_excel_file

# export_media_as_tsv_file

# tsv_file_to_phenotype_set

# phenotype_set_to_tsv_file

# export_phenotype_set_as_tsv_file

# phenotype_simulation_set_to_excel_file

# phenotype_simulation_set_to_tsv_file

# export_phenotype_simulation_set_as_excel_file

# export_phenotype_simulation_set_as_tsv_file

# bulk_export_objects

done_testing(print("DONE!"));
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
