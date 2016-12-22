use strict;
use Data::Dumper;
use Test::More;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::utilities;
use Bio::KBase::kbaseenv;
use fba_tools::fba_toolsImpl;

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
		eval {
			if (defined($parameters)) {
				$output = $self->{obj}->$function($parameters);
			} else {
				$output = $self->{obj}->$function();
			}
		};
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
		#my $wsname = "chenry:1456989658583";
		my $wsname = "chenry:1454960620516";
		my $output = $self->test_harness("build_metabolic_model",{
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