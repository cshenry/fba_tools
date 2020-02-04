#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use fba_tools::fba_toolsImpl;
local $| = 1;

my $impl = fba_tools::fba_toolsImpl->new();
Bio::KBase::kbaseenv::create_context_from_client_config();
Bio::KBase::ObjectAPI::functions::set_handler($impl);

#my $output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
#	workspace => 39597,
#	fbamodel_id => "P_flourescens_GW456-L13.mdl",
#	media_ref => "KBaseMedia/Carbon-D-Glucose",
#	exometabolite_condition => "exometabolite_assertion",
#	exometabolite_ref => "45463/14/2",
#	target_reaction => "bio1",
#	fbamodel_output_id => "P_flourescens_GW456-L13.recon",
#	atp_production_check => 1
#});

my $output = Bio::KBase::ObjectAPI::functions::func_gapfill_metabolic_model({
 "omindirectional" => 0,
 "reaction_ko_list" => "",
 "fbamodel_id" => "39182/67/1",
 "target_reaction" => "bio1",
 "fbamodel_output_id" => "DWP_FTICR.exomdl",
 "media_ref" => "39182/58/1",
 "exometabolite_ref" => "39182/90/1",
 "exomedia_output_id" => "DWP_FTICR.exomedia",
 "workspace" => "wcnelson:narrative_1546887895560",
 "equal_weighting" => 0,
 "minimum_target_flux" => 0.1,
 "exometabolite_condition" => "DWP"
});