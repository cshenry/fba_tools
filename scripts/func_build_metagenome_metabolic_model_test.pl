#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use fba_tools::fba_toolsImpl;
local $| = 1;

my $impl = fba_tools::fba_toolsImpl->new();
Bio::KBase::kbaseenv::create_context_from_client_config();
Bio::KBase::ObjectAPI::functions::set_handler($impl);

my $output = Bio::KBase::ObjectAPI::functions::func_build_metagenome_metabolic_model({
	workspace => 49110,
	input_ref => "TestMetagenomeAssembly",
	fbamodel_output_id => "TestMetagenomeModel",
	media_id => "Carbon-D-Glucose",
	media_workspace => "KBaseMedia",
	gapfill_model => 1,
	gff_file => "/Users/chenry/workspace/PNNLSFA/SoilSFA_WA_nrKO.gff"
});