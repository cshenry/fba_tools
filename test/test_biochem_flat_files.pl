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
#Only works in production
my $test_ws = "fba_tools_unittests_ws";

my $start = 1;
if (defined($ARGV[0])) {
	$start = $ARGV[0];
}

if ($start < 2) {
    print "Running test 1:\n";
    lives_ok{
	$impl->model_to_tsv_file({
	    input_ref => $test_ws."/test_model"})
    } 'export model as tsv';
}

done_testing();
