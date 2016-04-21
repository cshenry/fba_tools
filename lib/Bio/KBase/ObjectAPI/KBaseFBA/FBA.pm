########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBA - This is the moose object corresponding to the FBAFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-04-28T22:56:11
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBA;
package Bio::KBase::ObjectAPI::KBaseFBA::FBA;
use Moose;
use Bio::KBase::ObjectAPI::utilities;
use File::Path;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBA';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has jobID => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobid' );
has jobPath => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobpath' );
has jobDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobdirectory' );
has command => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, default => '' );
has mfatoolkitBinary => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmfatoolkitBinary' );
has mfatoolkitDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmfatoolkitDirectory' );
has readableObjective => ( is => 'rw', isa => 'Str',printOrder => '30', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreadableObjective' );
has mediaID => ( is => 'rw', isa => 'Str',printOrder => '0', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmediaID' );
has knockouts => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildknockouts' );
has promBounds => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildpromBounds' );
has tintlePenalty => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildtintlePenalty' );
has additionalCompoundString => ( is => 'rw', isa => 'Str',printOrder => '4', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildadditionalCompoundString' );
has templates => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, default => sub { return {}; } );
has gauranteedrxns => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgauranteedrxns'  );
has blacklistedrxns => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildblacklistedrxns'  );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildgauranteedrxns {
	my ($self) = @_;
	return [qw(
		rxn07301 rxn25468 rxn31542 rxn31420 rxn04468 rxn15786 rxn10095 rxn31005 rxn24334 rxn24256 rxn25469
		rxn22880 rxn25980 rxn25981 rxn30838 rxn31505 rxn01659
		rxn1 rxn2 rxn3 rxn4 rxn5 rxn6 rxn7 rxn8 rxn11572
		rxn07298 rxn24256 rxn04219 rxn17241 rxn19302 rxn25468 rxn23165
		rxn25469 rxn23171 rxn23067 rxn30830 rxn30910 rxn31440 rxn01659
		rxn13782 rxn13783 rxn13784 rxn05295 rxn05296 rxn10002
		rxn10088 rxn11921 rxn11922 rxn10200 rxn11923 rxn05029
	)];
}
sub _buildblacklistedrxns {
	my ($self) = @_;
	return [qw(
		rxn12985 rxn00238 rxn07058 rxn05305 rxn00154 rxn09037 rxn10643
		rxn11317 rxn05254 rxn05257 rxn05258 rxn05259 rxn05264 rxn05268
		rxn05269 rxn05270 rxn05271 rxn05272 rxn05273 rxn05274 rxn05275
		rxn05276 rxn05277 rxn05278 rxn05279 rxn05280 rxn05281 rxn05282
		rxn05283 rxn05284 rxn05285 rxn05286 rxn05963 rxn05964 rxn05971
		rxn05989 rxn05990 rxn06041 rxn06042 rxn06043 rxn06044 rxn06045
		rxn06046 rxn06079 rxn06080 rxn06081 rxn06086 rxn06087 rxn06088
		rxn06089 rxn06090 rxn06091 rxn06092 rxn06138 rxn06139 rxn06140
		rxn06141 rxn06145 rxn06217 rxn06218 rxn06219 rxn06220 rxn06221
		rxn06222 rxn06223 rxn06235 rxn06362 rxn06368 rxn06378 rxn06474
		rxn06475 rxn06502 rxn06562 rxn06569 rxn06604 rxn06702 rxn06706
		rxn06715 rxn06803 rxn06811 rxn06812 rxn06850 rxn06901 rxn06971
		rxn06999 rxn07123 rxn07172 rxn07254 rxn07255 rxn07269 rxn07451
		rxn09037 rxn10018 rxn10077 rxn10096 rxn10097 rxn10098 rxn10099
		rxn10101 rxn10102 rxn10103 rxn10104 rxn10105 rxn10106 rxn10107
		rxn10109 rxn10111 rxn10403 rxn10410 rxn10416 rxn11313 rxn11316
		rxn11318 rxn11353 rxn05224 rxn05795 rxn05796 rxn05797 rxn05798
		rxn05799 rxn05801 rxn05802 rxn05803 rxn05804 rxn05805 rxn05806
		rxn05808 rxn05812 rxn05815 rxn05832 rxn05836 rxn05851 rxn05857
		rxn05869 rxn05870 rxn05884 rxn05888 rxn05896 rxn05898 rxn05900
		rxn05903 rxn05904 rxn05905 rxn05911 rxn05921 rxn05925 rxn05936
		rxn05947 rxn05956 rxn05959 rxn05960 rxn05980 rxn05991 rxn05992
		rxn05999 rxn06001 rxn06014 rxn06017 rxn06021 rxn06026 rxn06027
		rxn06034 rxn06048 rxn06052 rxn06053 rxn06054 rxn06057 rxn06059
		rxn06061 rxn06102 rxn06103 rxn06127 rxn06128 rxn06129 rxn06130
		rxn06131 rxn06132 rxn06137 rxn06146 rxn06161 rxn06167 rxn06172
		rxn06174 rxn06175 rxn06187 rxn06189 rxn06203 rxn06204 rxn06246
		rxn06261 rxn06265 rxn06266 rxn06286 rxn06291 rxn06294 rxn06310
		rxn06320 rxn06327 rxn06334 rxn06337 rxn06339 rxn06342 rxn06343
		rxn06350 rxn06352 rxn06358 rxn06361 rxn06369 rxn06380 rxn06395
		rxn06415 rxn06419 rxn06420 rxn06421 rxn06423 rxn06450 rxn06457
		rxn06463 rxn06464 rxn06466 rxn06471 rxn06482 rxn06483 rxn06486
		rxn06492 rxn06497 rxn06498 rxn06501 rxn06505 rxn06506 rxn06521
		rxn06534 rxn06580 rxn06585 rxn06593 rxn06609 rxn06613 rxn06654
		rxn06667 rxn06676 rxn06693 rxn06730 rxn06746 rxn06762 rxn06779
		rxn06790 rxn06791 rxn06792 rxn06793 rxn06794 rxn06795 rxn06796
		rxn06797 rxn06821 rxn06826 rxn06827 rxn06829 rxn06839 rxn06841
		rxn06842 rxn06851 rxn06866 rxn06867 rxn06873 rxn06885 rxn06891
		rxn06892 rxn06896 rxn06938 rxn06939 rxn06944 rxn06951 rxn06952
		rxn06955 rxn06957 rxn06960 rxn06964 rxn06965 rxn07086 rxn07097
		rxn07103 rxn07104 rxn07105 rxn07106 rxn07107 rxn07109 rxn07119
		rxn07179 rxn07186 rxn07187 rxn07188 rxn07195 rxn07196 rxn07197
		rxn07198 rxn07201 rxn07205 rxn07206 rxn07210 rxn07244 rxn07245
		rxn07253 rxn07275 rxn07299 rxn07302 rxn07651 rxn07723 rxn07736
		rxn07878 rxn11417 rxn11582 rxn11593 rxn11597 rxn11615 rxn11617
		rxn11619 rxn11620 rxn11624 rxn11626 rxn11638 rxn11648 rxn11651
		rxn11665 rxn11666 rxn11667 rxn11698 rxn11983 rxn11986 rxn11994
		rxn12006 rxn12007 rxn12014 rxn12017 rxn12022 rxn12160 rxn12161
		rxn01267 rxn05294
	)];
}
sub _buildjobid {
	my ($self) = @_;
	my $path = $self->jobPath();
	my $jobid = Bio::KBase::ObjectAPI::utilities::CurrentJobID();
	if (!defined($jobid)) {
		my $fulldir = File::Temp::tempdir(DIR => $path);
		if (!-d $fulldir) {
			File::Path::mkpath ($fulldir);
		}
		$path.="/" if substr($path,-1) ne "/";
		$jobid = substr($fulldir,length($path));
	}
	return $jobid
}

sub _buildjobpath {
	my ($self) = @_;
	my $path = Bio::KBase::ObjectAPI::config::mfatoolkit_job_dir();
	if (!defined($path) || length($path) == 0) {
		$path = "/tmp/fbajobs/";
	}
	if (!-d $path) {
		File::Path::mkpath ($path);
	}
	return $path;
}

sub _buildjobdirectory {
	my ($self) = @_;
	my $directory = $self->jobPath()."/".$self->jobID();
	$directory =~ s/\/\//\//g;
	return $directory;
}

sub _buildmfatoolkitBinary {
	my ($self) = @_;
	my $bin;
	if (defined(Bio::KBase::ObjectAPI::config::mfatoolkit_binary()) && length(Bio::KBase::ObjectAPI::config::mfatoolkit_binary()) > 0 && -e Bio::KBase::ObjectAPI::config::mfatoolkit_binary()) {
		$bin = Bio::KBase::ObjectAPI::config::mfatoolkit_binary();
	} else {
		$bin = `which mfatoolkit 2>/dev/null`;
		chomp $bin;
	}
	if ((! defined $bin) || (!-e $bin)) {
		Bio::KBase::ObjectAPI::utilities::error("MFAToolkit binary could not be found at ".Bio::KBase::ObjectAPI::config::mfatoolkit_binary()."!");
	}
	return $bin;
}

sub _buildmfatoolkitDirectory {
	my ($self) = @_;
	my $bin = $self->mfatoolkitBinary();
	if ($bin =~ m/^(.+\/)[^\/]+$/) {
		return $1;
	}
	return "";
}

sub _buildreadableObjective {
	my ($self) = @_;
	my $string = "Maximize ";
	if ($self->maximizeObjective() == 0) {
		$string = "Minimize ";
	}
	foreach my $objid (keys(%{$self->compoundflux_objterms()})) {
		if (length($string) > 10) {
			$string .= " + ";
		}
		$string .= "(".$self->compoundflux_objterms()->{$objid}.") ".$objid;
	}
	foreach my $objid (keys(%{$self->reactionflux_objterms()})) {
		if (length($string) > 10) {
			$string .= " + ";
		}
		$string .= "(".$self->reactionflux_objterms()->{$objid}.") ".$objid;
	}
	foreach my $objid (keys(%{$self->biomassflux_objterms()})) {
		if (length($string) > 10) {
			$string .= " + ";
		}
		$string .= "(".$self->biomassflux_objterms()->{$objid}.") ".$objid;
	}
	if (defined($self->objectiveValue())) {
		$string .= " = ".$self->objectiveValue();
	}
	return $string;
}
sub _buildmediaID {
	my ($self) = @_;
	return $self->media()->id();
}
sub _buildknockouts {
	my ($self) = @_;
	my $string = "";
	my $genekos = $self->geneKOs();
	for (my $i=0; $i < @{$genekos}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $genekos->[$i]->id();
	}
	my $rxnstr = "";
	my $rxnkos = $self->reactionKOs();
	for (my $i=0; $i < @{$rxnkos}; $i++) {
		if ($i > 0) {
			$rxnstr .= ", ";
		}
		$rxnstr .= $rxnkos->[$i]->id();
	}
	if (length($string) > 0 && length($rxnstr) > 0) {
		return $string.", ".$rxnstr;
	}
	return $string.$rxnstr;
}
sub _buildpromBounds {
	my ($self) = @_;
	my $bounds = {};
	my $final_bounds = {};
	my $clone = $self->cloneObject();
	$clone->parent($self->parent());
	$clone->promconstraint_ref("");
	$clone->fva(1);
	$clone->runFBA();
	my $fluxes = $clone->FBAReactionVariables();
	for (my $i=0; $i < @{$fluxes}; $i++) {
		my $flux = $fluxes->[$i];
		$bounds->{$flux->modelreaction()->id()}->[0] = $flux->min();
		$bounds->{$flux->modelreaction()->id()}->[1] = $flux->max();
	}
	my $mdlrxns = $self->fbamodel()->modelreactions();
	my $geneReactions = {};
	foreach my $mdlrxn (@{$mdlrxns}) {
		foreach my $prot (@{$mdlrxn->modelReactionProteins()}) {
			foreach my $subunit (@{$prot->modelReactionProteinSubunits()}) {
				foreach my $feature (@{$subunit->features()}) {
					$geneReactions->{$feature->id()}->{$mdlrxn->id()} = 1;
				}
			}				
		} 
	}
	my $promconstraint = $self->promconstraint();
	my $genekos = $self->geneKOs();
	my $tfmaps = $promconstraint->transcriptionFactorMaps();
	foreach my $gene (@{$genekos}) {
		foreach my $tfmap (@$tfmaps) {
		if ($tfmap->transcriptionFactor_ref() eq $gene->id()) {
			my $targets = $tfmap->targetGeneProbs();
			foreach my $target (@{$targets}) {
				my $offProb = $target->probTGonGivenTFoff();
				my $onProb = $target->probTGonGivenTFon();
				foreach my $rxn (keys(%{$geneReactions->{$target->target_gene_ref()}})) {
					my $bounds = $bounds->{$rxn};
					$bounds->[0] *= $offProb;
					$bounds->[1] *= $offProb;
					$final_bounds->{$rxn}->[0] = $bounds->[0];
					$final_bounds->{$rxn}->[1] = $bounds->[1];
				}
			}
			last;
		}
		}
	}	

	return $final_bounds;
}

sub _buildtintlePenalty {
	my ($self) = @_;

	my $penalty = {};

	my $sample = $self->tintlesample();
	my $kappa =  $self->tintleKappa();
	foreach my $feature_id (keys %{$sample->expression_levels()}) {
		my $p = $sample->expression_levels()->{$feature_id};
		$penalty->{$feature_id}->{"penalty_score"} = abs($p - 0.5);
		if ($p > 0.5 + $kappa) {
			# This feature is likely to be on
			$penalty->{$feature_id}->{"case"} = "3";
		} elsif ($p < 0.5 -$kappa) {
			# This feature is likely to be off
			$penalty->{$feature_id}->{"case"} = "1";
		} else {
			# This feature state is unknown
			$penalty->{$feature_id}->{"case"} = "2";
		}
	}
	return $penalty;
}

sub _buildadditionalCompoundString {
	my ($self) = @_;
	my $output = "";
	my $addCpds = $self->additionalCpds();
	for (my $i=0; $i < @{$addCpds}; $i++) {
		if (length($output) > 0) {
			$output .= ";";
		}
		$output .= $addCpds->[$i]->name();
	}
	return $output;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 biochemistry

Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry = biochemistry();
Description:
	Returns biochemistry behind FBA object

=cut

sub biochemistry {
	my ($self) = @_;
	$self->fbamodel()->template()->biochemistry();	
}

=head3 genome

Definition:
	Bio::KBase::ObjectAPI::KBaseGenomes::Genome = genome();
Description:
	Returns genome behind FBA object

=cut

sub genome {
	my ($self) = @_;
	$self->fbamodel()->genome();	
}

=head3 mapping

Definition:
	Bio::KBase::ObjectAPI::KBaseOntology::Mapping = mapping();
Description:
	Returns mapping behind FBA object

=cut

sub mapping {
	my ($self) = @_;
	$self->fbamodel()->template()->mapping();	
}

=head3 runFBA

Definition:
	Bio::KBase::ObjectAPI::FBAResults = Bio::KBase::ObjectAPI::FBAFormulation->runFBA();
Description:
	Runs the FBA study described by the fomulation and returns a typed object with the results

=cut

sub runFBA {
	my ($self) = @_;
	if (!-e $self->jobDirectory()."/runMFAToolkit.sh") {
		$self->createJobDirectory();
	}
	system($self->command());
	$self->loadMFAToolkitResults();
	if (defined(Bio::KBase::ObjectAPI::config::FinalJobCache())) {
		if (Bio::KBase::ObjectAPI::config::FinalJobCache() eq "SHOCK") {
			system("cd ".$self->jobPath().";tar -czf ".$self->jobPath().$self->jobID().".tgz ".$self->jobID());
			my $node = Bio::KBase::ObjectAPI::utilities::LoadToShock($self->jobPath().$self->jobID().".tgz");
			unlink($self->jobPath().$self->jobID().".tgz");
			$self->jobnode($node);
		} elsif (Bio::KBase::ObjectAPI::config::FinalJobCache() ne "none") {
			if (!-d Bio::KBase::ObjectAPI::config::FinalJobCache()) {
				File::Path::mkpath (Bio::KBase::ObjectAPI::config::FinalJobCache());
			}
			system("cd ".$self->jobPath().";tar -czf ".Bio::KBase::ObjectAPI::config::FinalJobCache()."/".$self->jobID().".tgz ".$self->jobID());
		}
	}
	if ($self->jobDirectory() =~ m/\/fbajobs\/.+/) {
		if (!defined($self->parameters()->{nodelete}) || $self->parameters()->{nodelete} == 0) {
			system("rm -rf ".$self->jobDirectory());
		}
	}
	return $self->objectiveValue();
}

#=head3 createLPDirectory
#
#Definition:
#	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->createLPDirectory();
#Description:
#	Creates the LP job directory
#
#=cut
#
#sub createLPDirectory {
#	my ($self) = @_;
#	my $model = $self->fbamodel();
#	my $directory = $self->jobDirectory()."/";
#	
#	my $output = [];
#	my $variables = {};
#	#Printing objective
#	my $line = "";
#	if () {
#		#Minimizing deviation from proportional flux
#		
#		#Maximizing change to conform with transcriptomics
#		
#		#Minimizing deviation from identical ranking
#	}
#	
#	push(@{$output},$line);
#	
#	#Printing mass balance constraints
#	my $cpds = $model->modelcompounds();
#	my $cpdrxns = {};
#	my $output = 0;
#	for (my $i=0; $i < @{$cpds}; $i++) {
#		my $line = "";
#		foreach my $rxn (keys(%{$cpdrxns->{$cpds->[$i]}})) {
#			my $var = $rxn."_f";
#			$line .= " + ".$cpdrxns->{$cpds->[$i]}->{$rxn}." ".$var;
#		}
#		push(@{$output},$line);
#	}
#	#Printing variable bounds
#	
#	#Printing binary variables
#	
#	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."Problem.lp",$output);
#	
#	#Solve LP
#	
#	#Parse solution
#	
#}

=head3 PrepareForGapfilling

Definition:
	
Description:
	Preparing FBA for gapfilling

=cut

sub PrepareForGapfilling {
	my ($self,$args) = @_;
	$args = Bio::KBase::ObjectAPI::utilities::args([],{
		minimum_target_flux => 1,
		booleanexp => "absolute",
		expsample => undef,
		expression_threshold_percentile => 0.5,
		kappa => 0.1,
		source_model => undef,
		timePerSolution => 43200,
		totalTimeLimit => 45000,
		target_reactions => [],		
		completeGapfill => 0,
		solver => "SCIP",
		fastgapfill => 1,
		alpha => 0,
		omega => 0,
		num_solutions => 1,
		nomediahyp => 1,
		nobiomasshyp => 1,#
		nogprhyp => 1,#
		nopathwayhyp => 0,#
		allowunbalanced => 0,
		drainpen => 10,
		directionpen => 5,
		nostructpen => 1,
		unfavorablepen => 0.1,
		nodeltagpen => 1,
		biomasstranspen => 3,
		singletranspen => 3,
		transpen => 1,
		blacklistedrxns => [],
		gauranteedrxns => [],
		add_external_rxns => 1,
		make_model_rxns_reversible => 1,
		activate_all_model_reactions => 1,
		use_discrete_variables => 0,
		integrate_gapfilling_solution => 0
	}, $args);
	$self->parameters()->{integrate_gapfilling_solution} = $args->{integrate_gapfilling_solution};
	push(@{$self->gauranteedrxns()},@{$args->{gauranteedrxns}});
	push(@{$self->blacklistedrxns()},@{$args->{blacklistedrxns}});
	$self->parameters()->{minimum_target_flux} = $args->{minimum_target_flux};
	$self->parameters()->{"scale penalty by flux"} = 0;#I think this may be sufficiently flawed we might consider removing altogether
	$self->parameters()->{add_external_rxns} = $args->{add_external_rxns};
	$self->parameters()->{make_model_rxns_reversible} = $args->{make_model_rxns_reversible};
	$self->parameters()->{add_gapfilling_solution_to_model} = 0;
	if ($self->parameters()->{add_external_rxns} == 1 || $self->parameters()->{make_model_rxns_reversible} == 1) {
		$self->parameters()->{add_gapfilling_solution_to_model} = 1;
	}
	$self->parameters()->{omega} = $args->{omega};
	$self->parameters()->{alpha} = $args->{alpha};
	$self->parameters()->{"CPLEX solver time limit"} = $args->{timePerSolution};
	$self->parameters()->{"Recursive MILP timeout"} = $args->{totalTimeLimit};
	if (defined($args->{source_model})) {
		$self->{_source_model} = $args->{source_model};
	}
	if (defined($args->{expsample})) {
		$self->{_expsample} = $args->{expsample};
	}
	$self->parameters()->{"Reactions use variables"} = 0;
	if (defined($self->{_expsample})) {
		$self->comboDeletions(0);
		$self->fluxMinimization(1);
		$self->findMinimalMedia(0);
		$self->parameters()->{expression_threshold_percentile} = $args->{expression_threshold_percentile};
		$self->parameters()->{kappa} = $args->{kappa};	
		$self->parameters()->{booleanexp} = $args->{booleanexp};	
		$self->parameters()->{"transcriptome analysis"} = 1;
	}
	$self->numberOfSolutions($args->{num_solutions});
	if ($args->{completeGapfill} == 1 && @{$args->{target_reactions}} == 0) {
		my $rxnfoundhash = {};
		my $rxnmdlrxnhash = {};
		my $rxns = $self->fbamodel()->modelreactions();
		for (my $i=0; $i < @{$rxns}; $i++) {
			$rxnfoundhash->{$rxns->[$i]->reaction()->msid()} = 0;	
			$rxnmdlrxnhash->{$rxns->[$i]->reaction()->msid()}->{$rxns->[$i]->id()} = 1;	
		}
		my $priorities = $self->reactionPriorities();
		for (my $i=0; $i < @{$priorities}; $i++) {
			if (defined($rxnfoundhash->{$priorities->[$i]})) {
				foreach my $mdlrxn (keys %{$rxnmdlrxnhash->{$priorities->[$i]}}){
				push(@{$args->{target_reactions}},$mdlrxn);
				}
				$rxnfoundhash->{$priorities->[$i]} = 1;
			}
		}
		for (my $i=0; $i < @{$rxns}; $i++) {
			if ($rxnfoundhash->{$rxns->[$i]->reaction()->msid()} == 0) {
				push(@{$args->{target_reactions}},$rxns->[$i]->id());
			}	
		}
	}
	if (@{$args->{target_reactions}} > 0) {
		Bio::KBase::ObjectAPI::utilities::report("ArgumentReconciliation","When gapfilling to multiple target reactions, only one solution can be obtained, and use variables cannot be used");
		$self->numberOfSolutions(1);
		$self->parameters()->{"Reactions use variables"} = 0;
		$self->parameters()->{"Gapfilling target reactions"} = join(";",@{$args->{target_reactions}});
	}
	$self->parameters()->{"Perform gap filling"} = 1;
	$self->parameters()->{"just print LP file"} = "0";
	$self->parameters()->{"Balanced reactions in gap filling only"} = (1-$args->{allowunbalanced});
	$self->parameters()->{"drain flux penalty"} = $args->{drainpen};#Penalty doesn't exist in MFAToolkit yet
	$self->parameters()->{"directionality penalty"} = $args->{directionpen};#5
	$self->parameters()->{"delta G multiplier"} = $args->{unfavorablepen};#Penalty doesn't exist in MFAToolkit yet
	$self->parameters()->{"unknown structure penalty"} = $args->{nostructpen};#1
	$self->parameters()->{"no delta G penalty"} = $args->{nodeltagpen};#1
	$self->parameters()->{"biomass transporter penalty"} = $args->{biomasstranspen};#3
	$self->parameters()->{"single compound transporter penalty"} = $args->{singletranspen};#3
	$self->parameters()->{"transporter penalty"} = $args->{transpen};#0
	$self->parameters()->{"unbalanced penalty"} = "10";
	$self->parameters()->{"no functional role penalty"} = "2";
	$self->parameters()->{"no KEGG map penalty"} = "1";
	$self->parameters()->{"non KEGG reaction penalty"} = "1";
	$self->parameters()->{"no subsystem penalty"} = "1";
	$self->parameters()->{"subsystem coverage bonus"} = "1";
	$self->parameters()->{"scenario coverage bonus"} = "1";
	$self->parameters()->{"Biomass modification hypothesis"} = (1-$args->{nobiomasshyp});
	$self->parameters()->{"Biomass component reaction penalty"} = "500";
#	if ($self->media()->name() eq "Complete") {
#		if ($self->defaultMaxDrainFlux() < 10000) {
#			$self->defaultMaxDrainFlux(10000);
#		}	
#	} else {
#		my $mediacpds = $self->media()->mediacompounds();
#		foreach my $cpd (@{$mediacpds}) {
#			if ($cpd->maxFlux() > 0) {
#				$cpd->maxFlux(10000);
#			}
#			if ($cpd->minFlux() < 0) {
#				$cpd->minFlux(-10000);
#			}
#		}
#	}
#	$self->defaultMaxFlux(10000);
#	$self->defaultMinDrainFlux(-10000);
	#Setup approved compartment list
	$self->SetupApprovedCompartmentList();
}

sub reactionPriorities {
	my ($self) = @_;
	return [qw(rxn01387 rxn00520 rxn08527 rxn01388 rxn08900 rxn01241 rxn00257 rxn00441 rxn00973 rxn00505 rxn00306 rxn00799 rxn08901 rxn00285 rxn00974 rxn08528 rxn05939 rxn00199 rxn09272 rxn00935 rxn01872 rxn02376 rxn01200 rxn00604 rxn03643 rxn01333 rxn01116 rxn01975 rxn01477 rxn03644 rxn00785 rxn01187 rxn00770 rxn00777 rxn01115 rxn00548 rxn01476 rxn00018 rxn01345 rxn00786 rxn05105 rxn00782 rxn01870 rxn00781 rxn01331 rxn01334 rxn00549 rxn01111 rxn01100 rxn00747 rxn05734 rxn02853 rxn00459 rxn01457 rxn01830 rxn01122 rxn07191 rxn03885 rxn01171 rxn00506 rxn01775 rxn10116 rxn00216 rxn01107 rxn01123 rxn01121 rxn01169 rxn01459 rxn01080 rxn01108 rxn00779 rxn01106 rxn05735 rxn00148 rxn00221 rxn01109 rxn01275 rxn01286 rxn00290 rxn01654 rxn00330 rxn00910 rxn00690 rxn00251 rxn00272 rxn00422 rxn01211 rxn01453 rxn00331 rxn01355 rxn04954 rxn00692 rxn00907 rxn00602 rxn02889 rxn02480 rxn03079 rxn01102 rxn01653 rxn00247 rxn00336 rxn00802 rxn01434 rxn00192 rxn02465 rxn01019 rxn00469 rxn01636 rxn01917 rxn07295 rxn02484 rxn01539 rxn01537 rxn02305 rxn00269 rxn09997 rxn00440 rxn00438 rxn01538 rxn03075 rxn03108 rxn01302 rxn01301 rxn01069 rxn00260 rxn03446 rxn01300 rxn00337 rxn01643 rxn02339 rxn01637 rxn01973 rxn05012 rxn00649 rxn05153 rxn05733 rxn00953 rxn05176 rxn09240 rxn05239 rxn00423 rxn00742 rxn00566 rxn00361 rxn00623 rxn05256 rxn00806 rxn09310 rxn00283 rxn07292 rxn01575 rxn00904 rxn00903 rxn00191 rxn00902 rxn01573 rxn00737 rxn00898 rxn03437 rxn03062 rxn03435 rxn02187 rxn03194 rxn02186 rxn02789 rxn03436 rxn03068 rxn00804 rxn01045 rxn02185 rxn02811 rxn01790 rxn03841 rxn03175 rxn01682 rxn02507 rxn01964 rxn00474 rxn00726 rxn00727 rxn02508 rxn01257 rxn00791 rxn00187 rxn00193 rxn03409 rxn03407 rxn12822 rxn00085 rxn00340 rxn00184 rxn00189 rxn00182 rxn00347 rxn00416 rxn03406 rxn00342 rxn02160 rxn02834 rxn00527 rxn02320 rxn02835 rxn00863 rxn02159 rxn02473 rxn00838 rxn00493 rxn00789 rxn03135 rxn04659 rxn06802 rxn04656 rxn02466 rxn03034 rxn06675 rxn02224 rxn04657 rxn01420 rxn01423 rxn03324 rxn04660 rxn00202 rxn04658 rxn02227 rxn02226 rxn01663 rxn00510 rxn01991 rxn01974 rxn07441 rxn00313 rxn01972 rxn01644 rxn03030 rxn03031 rxn02929 rxn03086 rxn03087 rxn06078 rxn05614 rxn03052 rxn02302 rxn00952 rxn05958 rxn05219 rxn06799 rxn00693 rxn02028 rxn01304 rxn01303 rxn11944 rxn00126 rxn00740 rxn05957 rxn05613 rxn00141 rxn01816 rxn00452 rxn05183 rxn01256 rxn00929 rxn02356 rxn02373 rxn00179 rxn00931 rxn02358 rxn01101 R02607 rxn02914 rxn03445 rxn00420 rxn02212 rxn02331 rxn01332 rxn00525 rxn01364 rxn02213 rxn01255 rxn00526 rxn01269 rxn01739 rxn01740 rxn01268 rxn10125 rxn02988 rxn10060 rxn01438 rxn00262 rxn05117 rxn02155 rxn00938 rxn01927 rxn05119 rxn01437 rxn10181 rxn00138 rxn00338 rxn02177 rxn00941 rxn00775 rxn00105 rxn00076 rxn02989 rxn01265 rxn00083 rxn01930 rxn01671 rxn02402 rxn00077 rxn00190 rxn00478 rxn04139 rxn03395 rxn12224 rxn11946 rxn00966 rxn03394 rxn03893 rxn01258 rxn08333 rxn11702 rxn05024 rxn02831 rxn02832 rxn11703 rxn04673 rxn02898 rxn00143 rxn01858 rxn00203 rxn01022 rxn01021 rxn01137 R06860 rxn10044 rxn03492 rxn07586 rxn05054 rxn02775 rxn02897 rxn04046 rxn04052 rxn04045 rxn07587 rxn04384 rxn04413 rxn03537 rxn03514 rxn03536 rxn03150 rxn04385 rxn06979 rxn04048 rxn04050 rxn03513 rxn05029 rxn03538 rxn11544 rxn03540 rxn04047 rxn03512 rxn00100 rxn02341 rxn09177 rxn01791 rxn12510 rxn02128 R04233 rxn10180 rxn00912 rxn12512 rxn02175 rxn00346 rxn03541 rxn05187 rxn11545 rxn00074 rxn07589 rxn03534 rxn03491 rxn08194 rxn10476 rxn02287 rxn07588 rxn03535 rxn10147 rxn11650 rxn05515 rxn00124 rxn03909 rxn01807 rxn01396 rxn00123 rxn00208 rxn05144 rxn00209 rxn04070 rxn03951 rxn01398 rxn02939 rxn03638 rxn01483 rxn00555 rxn00461 rxn01505 rxn01485 rxn00293 rxn02285 rxn01316 rxn00292 rxn00297 rxn00827 rxn06299 rxn07307 rxn03962 rxn00642 rxn04599 rxn11932 rxn04598 rxn08707 rxn04600 rxn03991 rxn05189 rxn10133 rxn04597 rxn03990 rxn03419 rxn00302 rxn01351 rxn01518 rxn00689 rxn00299 rxn02200 rxn01519 rxn01143 rxn03168 rxn03174 rxn01602 rxn02986 rxn01520 rxn02201 rxn02504 rxn01962 rxn02503 rxn03173 rxn01521 rxn02518 rxn00463 rxn03421 rxn00686 rxn00301 rxn00514 rxn01603 rxn01210 rxn02056 rxn00029 rxn03384 rxn09180 rxn02774 rxn04704 rxn01629 rxn02288 rxn00060 rxn00599 rxn06591 rxn06937 rxn00224 rxn02304 rxn02264 rxn02303 rxn02866 rxn00872 rxn00991 rxn00988 rxn01504 rxn00947 rxn05249 rxn02296 rxn05250 rxn05252 rxn08180 rxn09449 rxn05247 rxn05223 rxn02297 rxn05248 rxn05251 rxn05736 rxn00792 rxn02277 rxn09448 rxn02312 rxn09450 rxn10318 rxn10324 rxn10320 rxn10319 rxn10191 rxn10321 rxn10322 rxn10316 rxn10317 rxn10323 rxn05229 rxn02937 rxn03137 rxn00832 rxn03136 rxn03147 rxn03084 rxn00800 rxn00790 rxn04783 rxn02938 rxn03004 rxn02895 rxn01018 rxn00710 rxn00711 rxn01360 rxn01465 rxn01361 rxn00414 rxn08335 rxn01362 rxn08336 rxn05391 rxn05330 rxn05408 rxn05422 rxn05448 rxn05415 rxn05328 rxn05372 rxn05341 rxn05412 rxn05460 rxn05346 rxn05335 rxn05381 rxn05386 rxn05428 rxn05334 rxn06022 rxn05354 rxn05376 rxn05342 rxn05350 rxn05437 rxn05463 rxn05396 rxn05363 rxn05324 rxn05464 rxn05359 rxn05322 rxn05416 rxn05458 rxn05453 rxn05337 rxn05367 rxn05385 rxn05443 rxn05434 rxn05432 rxn05417 rxn05436 rxn05397 rxn05421 rxn05329 rxn05427 rxn05392 rxn05340 rxn05403 rxn05461 rxn05356 rxn05368 rxn05351 rxn05362 rxn05418 rxn06023 rxn05355 rxn05393 rxn05440 rxn05345 rxn05444 rxn05431 rxn05382 rxn05433 rxn05373 rxn05465 rxn05452 rxn05336 rxn05325 rxn05407 rxn05449 rxn05377 rxn05459 rxn05357 rxn05323 rxn05398 rxn05333 rxn05383 rxn05441 rxn05426 rxn05364 rxn05419 rxn05430 rxn05402 rxn05413 rxn05348 rxn05370 rxn05445 rxn05369 rxn05446 rxn05435 rxn05361 rxn05456 rxn05410 rxn06673 rxn05394 rxn05378 rxn05326 rxn05455 rxn05344 rxn05387 rxn05349 rxn05374 rxn05388 rxn05429 rxn05424 rxn05406 rxn05352 rxn05365 rxn05439 rxn05339 rxn05451 rxn05401 rxn05371 rxn05347 rxn05338 rxn05400 rxn05442 rxn05425 rxn05358 rxn05332 rxn05447 rxn05399 rxn05360 rxn05438 rxn05409 rxn05420 rxn05414 rxn05390 rxn05405 rxn05327 rxn05423 rxn05404 rxn05462 rxn05450 rxn05375 rxn05457 rxn05411 rxn06672 rxn05379 rxn05384 rxn05389 rxn05366 rxn05380 rxn05331 rxn05395 rxn05454 rxn05343 rxn05353 rxn10295 rxn10304 rxn03852 rxn10277 rxn10288 rxn10193 rxn10281 rxn10297 rxn10292 rxn10278 rxn10280 rxn10308 rxn10302 rxn10311 rxn10296 rxn10273 rxn10305 rxn03901 rxn10287 rxn10192 rxn10271 rxn10315 rxn10309 rxn10298 rxn10274 rxn10306 rxn10284 rxn10303 rxn10195 rxn10283 rxn10286 rxn10279 rxn10272 rxn10299 rxn00621 rxn10293 rxn10197 rxn10300 rxn10275 rxn10307 rxn10285 rxn10312 rxn10290 rxn10310 rxn10194 rxn10291 rxn10294 rxn10314 rxn10282 rxn10276 rxn08040 rxn10289 rxn10301 rxn10196 rxn10313 rxn03907 rxn09996 rxn00211 rxn00433 rxn05184 rxn05193 rxn01867 rxn05181 rxn05505 rxn05192 rxn01868 rxn05504 rxn00752 rxn05180 rxn00756 rxn10770 rxn06729 rxn02404 rxn03159 rxn06865 rxn02405 rxn01117 rxn03439 rxn06848 rxn03146 rxn03130 rxn03181 rxn03182 rxn06723 rxn00612 rxn03975 rxn00611 rxn00351 rxn02792 rxn01981 rxn00646 rxn00350 rxn02791 rxn00186 rxn01834 rxn01274 rxn00748 rxn00205 rxn00086 rxn02762 rxn02521 rxn02522 rxn03483 rxn01403 rxn02377 rxn01675 rxn01997 rxn09289 rxn01999 rxn08954 rxn03511 rxn08713 rxn03916 rxn08709 rxn03919 rxn08712 rxn08620 rxn08619 rxn08708 rxn03918 rxn08583 rxn08618 rxn08711 rxn03917 rxn08710 rxn03910 rxn00829 rxn03908 rxn04308 rxn01607 rxn04113 rxn04996 rxn03958 rxn00830 rxn08756 rxn05293 rxn01501 rxn01454 rxn08352 rxn02322 rxn03843 rxn10199 rxn02286 rxn02008 rxn03933 rxn03408 rxn02011 rxn03904 rxn03903 rxn00851 rxn01270 rxn01000 rxn00490 rxn01134 rxn00605 rxn02004 rxn00497 rxn01833 rxn01715 rxn01450 rxn00529 rxn00484 rxn10011 rxn02949 rxn03241 rxn10014 rxn03245 rxn02911 rxn10010 rxn02167 rxn10013 rxn05732 rxn03250 rxn01452 rxn02527 rxn02934 rxn03240 rxn03247 rxn10012 rxn00868 rxn04713 rxn02345 rxn01923 rxn02933 rxn00990 rxn04750 rxn03244 rxn01451 rxn00875 rxn03239 rxn03246 rxn03242 rxn02168 rxn00871 rxn01480 rxn03249 rxn01236 rxn06777 rxn02268 rxn12008 rxn01486 rxn11684 rxn03892 rxn05287 rxn03891 rxn07468 rxn05028 rxn00541 rxn00471 rxn05300 rxn00274 rxn01068 rxn00671 rxn07430 rxn07435 rxn07434 rxn06586 rxn01924 rxn07431 rxn03433 rxn07432 rxn06335 rxn07433 rxn01925 rxn02270 rxn03422 rxn00503 rxn00405 rxn02944 rxn05164 rxn00183 rxn00601 rxn00470 rxn00853 rxn00291 rxn00395 rxn05303 rxn02927 rxn05156 rxn05151 rxn00322 rxn00856 rxn00467 rxn00394 rxn05154 rxn10131 rxn01029 rxn00114 rxn00858 rxn00999 rxn03055 rxn02366 rxn05306 rxn01315 rxn02883 rxn01203 rxn02885 rxn03041 rxn00473 rxn00479 rxn05663 rxn04989 rxn03040 rxn05301 rxn01685 rxn00640 rxn00638 rxn05574 rxn05673 rxn01329 rxn01737 rxn00577 rxn00558 rxn00704 rxn00222 rxn02380 rxn09978 rxn02760 rxn09979 rxn01977 rxn00213 rxn00225 rxn00670 rxn00173 rxn01199 rxn01753 rxn05671 rxn01751 rxn01041 rxn01649 rxn05680 rxn01548 rxn01859 rxn08471 rxn05621 rxn05656 rxn05171 rxn05737 rxn05585 rxn08467 rxn03630 rxn05172 rxn10067 rxn05594 rxn05552 rxn08468 rxn05599 rxn05512 rxn05620 rxn03974 rxn08469 rxn08470 rxn00327 rxn01747 rxn00010 rxn03842 rxn01746 rxn02102 rxn01280 rxn01748 rxn02103 rxn01281 rxn08851 rxn08800 rxn08823 rxn08807 rxn08809 rxn09134 rxn08844 rxn09125 rxn08814 rxn08816 rxn09157 rxn09128 rxn08803 rxn09142 rxn08840 rxn09161 rxn08822 rxn09147 rxn08847 rxn08812 rxn08808 rxn08806 rxn08841 rxn09164 rxn09152 rxn09124 rxn09131 rxn08815 rxn09133 rxn08817 rxn08799 rxn09138 rxn09143 rxn09153 rxn08838 rxn08821 rxn09160 rxn08850 rxn09158 rxn08802 rxn08848 rxn09148 rxn09144 rxn08842 rxn09150 rxn09130 rxn08818 rxn09149 rxn09163 rxn08810 rxn09159 rxn09132 rxn08805 rxn09127 rxn09140 rxn08813 rxn08796 rxn08845 rxn08849 rxn09145 rxn09137 rxn08801 rxn09154 rxn08820 rxn08819 rxn08811 rxn09151 rxn09146 rxn08804 rxn09123 rxn09139 rxn08839 rxn08843 rxn08798 rxn08797 rxn08846 rxn09126 rxn09141 rxn09135 rxn09136 rxn09155 rxn09162 rxn09129 rxn09156 rxn12500 rxn08179 rxn10128 rxn10127 rxn08178 rxn10120 rxn01893 rxn00540 rxn00171 rxn00560 rxn05667 rxn00101 rxn05214 rxn00265 rxn05213 rxn05589 rxn10150 rxn05226 rxn05655 rxn00787 rxn05563 rxn10188 rxn10187 rxn00691 rxn00598 rxn05168 rxn05179 rxn05161 rxn05536 rxn05544 rxn12848 rxn12851 rxn05539 rxn05541 rxn05537 rxn05543 rxn12849 rxn05533 rxn05540 rxn05534 rxn05547 rxn05546 rxn05542 rxn05535 rxn12850 rxn05545 rxn05538 rxn05152 rxn05146 rxn05155 rxn10473 rxn00102 rxn06077 rxn05225 rxn00607 rxn04020 rxn05611 rxn00007 rxn00606 rxn01967 rxn02005 rxn05573 rxn05555 rxn05149 rxn05618 rxn05619 rxn05174 rxn05150 rxn10481 rxn05528 rxn05177 rxn05645 rxn05145 rxn02166 rxn00743 rxn03167 rxn05560 rxn05647 rxn05485 rxn05501 rxn05289 rxn01094 rxn01093 rxn10855 rxn05557 rxn05217 rxn05298 rxn05507 rxn05305 rxn09699 rxn05561 rxn05204 rxn05622 rxn10892 rxn10857 rxn05526 rxn05605 rxn10868 rxn05159 rxn05508 rxn05669 rxn05566 rxn05654 rxn05215 rxn05559 rxn05216 rxn05506 rxn05244 rxn05516 rxn05514 rxn05527 rxn10343 rxn05211 rxn05167 rxn10344 rxn05625 rxn05243 rxn10895 rxn01277 rxn02363 rxn01945 rxn02113 rxn02115 rxn02112 rxn00702 rxn01871 rxn01750 rxn02632 rxn09953 rxn00763 rxn00543 rxn02275 rxn03869 rxn02222 rxn01843 rxn00231 rxn03839 rxn00849 rxn05466 rxn09313 rxn08354 rxn03126 rxn11934 rxn08356 rxn09315 rxn01466 rxn01213 rxn01943 rxn02411 rxn01840 rxn02971 rxn02143 rxn02782 rxn00588 rxn00584 rxn00959 rxn03898 rxn03897 rxn05518 rxn03481 rxn00020 rxn09992 rxn00608 rxn03482 rxn08025 rxn06526 rxn05937 rxn05616 rxn10474 rxn08258 rxn05031 rxn01489 rxn02945 rxn02144 rxn02788 rxn00892 rxn00552 rxn00016 rxn01484 rxn02733 rxn04152 rxn04162 rxn04153 rxn02716 rxn11942 rxn04160 rxn04158 rxn04161 rxn04705 rxn04154 rxn11940 rxn02959 rxn04159 rxn11941 rxn04602 rxn02416 rxn04601 rxn01895 rxn04604 rxn04603 rxn03038 rxn05315 rxn04016 rxn05517 rxn00717 rxn01025 rxn05292 rxn05063 rxn10132 rxn10046 rxn01368 rxn01800 rxn12636 rxn07584 rxn00011 rxn02342 rxn00567 rxn05890 rxn01806 rxn11937 rxn05316 R02299 rxn01648 rxn01986 rxn09687 rxn05317 rxn00772 rxn01987 rxn01146 rxn05198 rxn09688 rxn05199 rxn05200 rxn01366 rxn00784 rxn09685 rxn05318 rxn00778 rxn05205 rxn05572 rxn01634 rxn02346 rxn03887 rxn07845 rxn01990 rxn01989 rxn05565 rxn00783 rxn10160 rxn02173 rxn02429 rxn01857 rxn05681 rxn03954 rxn03953 rxn01291 rxn05571 rxn01279 rxn08345 rxn10167 rxn01278 rxn00744 rxn05581 rxn00745 rxn00615 rxn00634 rxn00883 rxn00882 rxn00881 rxn00609 rxn01819 rxn13783 rxn05549 rxn05160 rxn05644 rxn09661 rxn02313 rxn03886 rxn10184 rxn05648 rxn05567 rxn00545 rxn03856 rxn01343 rxn02000 rxn02003 rxn00095 rxn00776 rxn05551 rxn00539 rxn10042 rxn10161 rxn10162 rxn10163 rxn00499 rxn00146 rxn08783 rxn08792 rxn01057 rxn00145 rxn08793 rxn00500 not_in_KEGG rxn00157 rxn10114 rxn00371 rxn10118 rxn03236 rxn05147 rxn05173 rxn00818 rxn10169 rxn03838 rxn00817 rxn02596 rxn05170 rxn01492 rxn02314 rxn00547 rxn10155 rxn10157 rxn00288 rxn00656 rxn08291 rxn05126 rxn05127 rxn02925 rxn00816 rxn01205 rxn02171 rxn00194 rxn03641 rxn01201 rxn00069 rxn01252 rxn00509 rxn01204 rxn03642 rxn01851 rxn00508 rxn10136 rxn05564 rxn03906 rxn04745 rxn00589 rxn04748 rxn04724 rxn01011 rxn00512 rxn00324 rxn01013 rxn01015 rxn01416 rxn01073 rxn00762 rxn05158 rxn08669 rxn00616 rxn08557 rxn00758 rxn08556 rxn00066 rxn08558 rxn00614 rxn00768 rxn02235 rxn00769 rxn10215 rxn09104 rxn08297 rxn10266 rxn10230 rxn10225 rxn10259 rxn08311 rxn09200 rxn10340 rxn08294 rxn09103 rxn09208 rxn08202 rxn10219 rxn10206 rxn10255 rxn09107 rxn08203 rxn10334 rxn10203 rxn08298 rxn08549 rxn09111 rxn08089 rxn10212 rxn10337 rxn10235 rxn10221 rxn09199 rxn08083 rxn10209 rxn09105 rxn08204 rxn08551 rxn08308 rxn08199 rxn10214 rxn10338 rxn10263 rxn10341 rxn10269 rxn09207 rxn09114 rxn08309 rxn08312 rxn09210 rxn10256 rxn10211 rxn10205 rxn10218 rxn10335 rxn10229 rxn08300 rxn09110 rxn08552 rxn10267 rxn10236 rxn10222 rxn08295 rxn09203 rxn10204 rxn08086 rxn09206 rxn10227 rxn09113 rxn08547 rxn10233 rxn10342 rxn10217 rxn08307 rxn08205 rxn10264 rxn10208 rxn09108 rxn08299 rxn10261 rxn10232 rxn08296 rxn09202 rxn09197 rxn10339 rxn10226 rxn10237 rxn10223 rxn10210 rxn09101 rxn08087 rxn10268 rxn10253 rxn09205 rxn08548 rxn08546 rxn09112 rxn08088 rxn10265 rxn09102 rxn10234 rxn10202 rxn08200 rxn10207 rxn08306 rxn08085 rxn09109 rxn10258 rxn10228 rxn10216 rxn09211 rxn08550 rxn10336 rxn10257 rxn09209 rxn09198 rxn09106 rxn10270 rxn10224 rxn10231 rxn10262 rxn08310 rxn08201 rxn09201 rxn08084 rxn10260 rxn10254 rxn10213 rxn10220 rxn06377 rxn05649 rxn00166 rxn05307 rxn00165 rxn06600 rxn06493 rxn05494 rxn09296 rxn08941 rxn08126 rxn08615 rxn08129 rxn08127 rxn08128 rxn08943 rxn00695 rxn05740 rxn08942 rxn00979 rxn08657 rxn05470 rxn08655 rxn00980 rxn08656 rxn00551 rxn00147 rxn00151 rxn00248 rxn03884 rxn00328 rxn00256 rxn05148 rxn05188 rxn00546 rxn00375 rxn01642 rxn01641 rxn01640 rxn01639 rxn02085 rxn05299 rxn00867 rxn00001 rxn01626 rxn00654 rxn03188 rxn02190 rxn09657 rxn05197 rxn05682 rxn10117 rxn10119 rxn03393 rxn05596 rxn00379 rxn00137 rxn05902 rxn05651 rxn00879 rxn05593 rxn02007 rxn00502 rxn00501 rxn00880 rxn01176 rxn00065 rxn06510 rxn03248 rxn00676 rxn02804 rxn00874 rxn03243 rxn00178 rxn02680 rxn00675 rxn00175 rxn00986 rxn05938 rxn05602 rxn00295 rxn00214 rxn02332 rxn02318 rxn10865 rxn00355 rxn00808 rxn05162 rxn01763 rxn05500 rxn01292 rxn01114 rxn04082 rxn01828 rxn09988 rxn01633 rxn01289 rxn04928 rxn01911 rxn01912 rxn02321 rxn02319 rxn02263 rxn01620 rxn01615 rxn05646 rxn01053 rxn01390 rxn02161 rxn01761 rxn05598 rxn01621 rxn10148 rxn00321 rxn00312 rxn01578 rxn01729 rxn01662 rxn11943 rxn01630 rxn01580 rxn00511 rxn00320 rxn02344 rxn01579 rxn01631 rxn01581 rxn12206 rxn12432 rxn08934 rxn05746 rxn08935 rxn10174 rxn01133 rxn01259 rxn08936 rxn05608 rxn00575 rxn01966 rxn01132 rxn08933 rxn00022 rxn05607 rxn09989 rxn05617 rxn00629 rxn00641 rxn00975 rxn05610 rxn05612 rxn00847 rxn03020 rxn11938 rxn03085 rxn03127 rxn02431 rxn05106 rxn02894 rxn05104 rxn03057 rxn05092 rxn05108 rxn03061 rxn00669 rxn03060 rxn00289 rxn00679 rxn01618 rxn00239 rxn09562 rxn01509 rxn13784 rxn05209 rxn09167 rxn00672 rxn05313 rxn10121 rxn03978 rxn00568 rxn05893 rxn00569 rxn05627 rxn00400 rxn00082 rxn06874 rxn00369 rxn00720 rxn00715 rxn01028 rxn00709 rxn00368 rxn00365 rxn00713 rxn00056 rxn00006 rxn07438 rxn01842 rxn02449 rxn05312 rxn11268 rxn02900 rxn00537 rxn05493 rxn09264 rxn01406 rxn10182 rxn05687 rxn00127 rxn02061 rxn09265 rxn05683 rxn12405 rxn05484 rxn00038 rxn00992 rxn00994 rxn10168 rxn05206 rxn10945 rxn09188 rxn02071 rxn01635 rxn00933 rxn05221 rxn02029 rxn02946 rxn00196 rxn05638 rxn02360 rxn02359 rxn00932 rxn01709 rxn00985 rxn01879 rxn01996 rxn12644 rxn12637 rxn12844 rxn12640 rxn12645 rxn12845 rxn12641 rxn12633 rxn00650 rxn12646 rxn12846 rxn12642 rxn12634 rxn12639 rxn12847 rxn12638 rxn12643 rxn12635 rxn02483 rxn01192 rxn02369 rxn01313 rxn01314 rxn02985 rxn01324 rxn01367 rxn00835 rxn01678 rxn00117 rxn00915 rxn00839 rxn01508 rxn01139 rxn00409 rxn01673 rxn01127 rxn00134 rxn01507 rxn01298 rxn00916 rxn00836 rxn01524 rxn02400 rxn01670 rxn00363 rxn00927 rxn00708 rxn01444 rxn00515 rxn00917 rxn01218 rxn01299 rxn01226 rxn01704 rxn00834 rxn00926 rxn00837 rxn00131 rxn10052 rxn00097 rxn00139 rxn01445 rxn01512 rxn01549 rxn01225 rxn00913 rxn01352 rxn01145 rxn01545 rxn00914 rxn01353 rxn01544 rxn00132 rxn00237 rxn01961 rxn00063 rxn00831 rxn01523 rxn05202 rxn01522 rxn01297 rxn05201 rxn02761 rxn04453 rxn01674 rxn00797 rxn01370 rxn01813 rxn00362 rxn01706 rxn01223 rxn00408 rxn00120 rxn01222 rxn00366 rxn00714 rxn01221 rxn01516 rxn01677 rxn01219 rxn00410 rxn00116 rxn01515 rxn01510 rxn01511 rxn04464 rxn01513 rxn00364 rxn01672 rxn01220 rxn00712 rxn01128 rxn01679 rxn01129 rxn01514 rxn00118 rxn01705 rxn00412 rxn01541 rxn00707 rxn01517 rxn00407 rxn00160 rxn10152 rxn00252 rxn05207 rxn10154 rxn00161 rxn10151 rxn00305 rxn00162 rxn10153 rxn01285 rxn04143 rxn00250 rxn01847 rxn00159 rxn05604 rxn05208 rxn01103 rxn00544 rxn00227 rxn9167 rxn00152 rxn00172 rxn01188 rxn00206 rxn10122 rxn08978 rxn08977 rxn10123 rxn08976 rxn08975 rxn08971 rxn10124 rxn08979 rxn00430 rxn00431 rxn01383 rxn03883 rxn01385 rxn00048 rxn02474 rxn05039 rxn00122 rxn00392 rxn02475 rxn00300 rxn03080 rxn05040 rxn05232 rxn05231 rxn05236 rxn05234 rxn06076 rxn05235 rxn05233 rxn06075 rxn13782 rxn02569 rxn01506 rxn01322 rxn01951 rxn00897 rxn02046 rxn00303 rxn00242 rxn10806 rxn10126 rxn10113 rxn01044 rxn00223 rxn05023 rxn10043 rxn00058 rxn00449 rxn02279 rxn00245 rxn02122 rxn04794 rxn04454 rxn04938 rxn04712 rxn05297)];
}

=head3 SetupApprovedCompartmentList

Definition:
	
Description:
	Setup compartment approval

=cut

sub SetupApprovedCompartmentList {
	my ($self) = @_;
	my $badCompList = [];
	my $approvedHash = {};
	my $cmps = $self->fbamodel()->modelcompartments();
	for (my $i=0; $i < @{$cmps}; $i++) {
		$approvedHash->{$cmps->[$i]->compartment()->id()} = 1;	
	}
	$cmps = $self->fbamodel()->template()->compartments();
	for (my $i=0; $i < @{$cmps}; $i++) {
		if (!defined($approvedHash->{$cmps->[$i]->id()})) {
			push(@{$badCompList},$cmps->[$i]->id());
		}	
	}
	$self->parameters()->{"dissapproved compartments"} = join(";",@{$badCompList});
}

=head3 RunQuantitativeOptimization

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->RunQuantitativeOptimization({
		TimePerSolution => int,
		TotalTimeLimit => int,
		Num_solutions => int,
		MaxBoundMult => float,
		MinFluxCoef => float,
		Constraints => {}
	});
Description:
	Runs a quantitative optimization to fit quantitative model predictions to experimental data

=cut

sub RunQuantitativeOptimization {
	my ($self,$args) = @_;
	$args = Bio::KBase::ObjectAPI::utilities::args([],{
		ReactionCoef => 100,
		DrainCoef => 10,
		BiomassCoef => 0.1,
		ATPSynthCoef => 1,
		ATPMaintCoef => 1,
		TimePerSolution => 3600,
		TotalTimeLimit => 3600,
		Num_solutions => 1,
		MaxBoundMult => 2,
		MinFluxCoef => 0.000001,
		Constraints => [],
		Resolution => 0.01,
		MinVariables => 4
	}, $args);
	$self->quantitativeOptimization(1);
	$self->parameters()->{"Quantopt threshold"} = $args->{Resolution};
	$self->parameters()->{"Quantopt minimum variables"} = $args->{MinVariables};
	$self->parameters()->{"Quantopt fva bound multiplier"} = $args->{MaxBoundMult};
	$self->parameters()->{"QuantOpt min flux coefficient"} = $args->{MinFluxCoef};
	$self->parameters()->{"Quantopt reaction objective coefficient"} = $args->{ReactionCoef};
	$self->parameters()->{"Quantopt drain objective coefficient"} = $args->{DrainCoef};
	$self->parameters()->{"Quantopt biomass objective coefficient"} = $args->{BiomassCoef};
	$self->parameters()->{"Quantopt atpsynth objective coefficient"} = $args->{ATPSynthCoef};
	$self->parameters()->{"Quantopt atpsmaint objective coefficient"} = $args->{ATPMaintCoef};
	$self->createJobDirectory();
	my $mediaData = Bio::KBase::ObjectAPI::utilities::LOADFILE($self->jobDirectory()."/media.tbl");
	my $data = {};
	for (my $i=0; $i < @{$args->{Constraints}}; $i++) {
		my $comp = "c0";
		if ($data->{var} =~ m/_([a-z]\d+)/) {
			$comp = $1;
		}
		push(@{$data->{var}},$args->{Constraints}->[$i]->[0]);
		push(@{$data->{type}},$args->{Constraints}->[$i]->[1]);
		push(@{$data->{max}},$args->{Constraints}->[$i]->[3]);
		push(@{$data->{min}},$args->{Constraints}->[$i]->[2]);
		push(@{$data->{comp}},$comp);
		push(@{$data->{conc}},0.001);
	}
	push(@{$mediaData},
		"QuantOptMedia\tQuantOptMedia\t".
		join("|",@{$data->{var}})."\t".
		join("|",@{$data->{type}})."\t".
		join("|",@{$data->{max}})."\t".
		join("|",@{$data->{min}})."\t".
		join("|",@{$data->{comp}})."\t".
		join("|",@{$data->{conc}})
	);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($self->jobDirectory()."/media.tbl",$mediaData);
	$self->runFBA();
	if (!defined($self->QuantitativeOptimizationSolutions()->[0])) {
		Bio::KBase::ObjectAPI::utilities::error("Quantitative optimization completed, but no solutions obtained!");
	}
}

=head3 createJobDirectory

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->createJobDirectory();
Description:
	Creates the MFAtoolkit job directory

=cut

sub createJobDirectory {
	my ($self) = @_;
	my $directory = $self->jobDirectory()."/";
	File::Path::mkpath ($directory."reaction");
	File::Path::mkpath ($directory."MFAOutput/RawData/");
	my $translation = {
		drainflux => "DRAIN_FLUX",
		flux => "FLUX",
		biomassflux => "FLUX"
	};
	#This is a list of exchange species expressed generically for base compounds
	my $genex = {
		cpd11416 => {
			c => [-10000,0]
		},
		cpd02701 => {
			c => [-10000,0]
		}
	};
	my $exchangehash;
	#Print model to Model.tbl
	my $model = $self->fbamodel();
	my $BioCpd = ["id	abbrev	charge	formula	mass	name	deltaG"];
	my $mdlcpd = $model->modelcompounds();
	my $cpdhash = {};
	for (my $i=0; $i < @{$mdlcpd}; $i++) {
		my $cpd = $mdlcpd->[$i];
		my $id = $cpd->id();
		if (defined($genex->{$cpd->compound()->id()})) {
			if (defined($genex->{$cpd->compound()->id()}->{$cpd->modelcompartment()->compartment()->id()})) {
				if ($cpd->modelcompartment()->compartment()->id() eq "e") {
					$exchangehash->{$cpd->id()}->{e} = $genex->{$cpd->compound()->id()}->{$cpd->modelcompartment()->compartment()->id()};
				} else {
					$exchangehash->{$cpd->id()}->{c} = $genex->{$cpd->compound()->id()}->{$cpd->modelcompartment()->compartment()->id()};
				}				
			}
		}
		my $name = $cpd->name();
		my $abbrev = $cpd->id();
		if (!defined($cpdhash->{$id})) {
			push(@{$BioCpd},$id."\t".$abbrev."\t".$cpd->charge()."\t".$cpd->formula()."\t0\t".$name."\t".$cpd->compound()->deltaG());
			$cpdhash->{$id} = $cpd;
		}
	}
	#We add all gapfill candidates to an input file
	my $actcoef = {};
	my $gfcoef = {};
	my $additionalrxn = ["id\tdirection\ttag"];
	my $rxnhash = {};
	my $mdlData = ["REACTIONS","LOAD;DIRECTIONALITY;COMPARTMENT;ASSOCIATED PEG;COMPLEXES"];
	my $BioRxn = ["id	abbrev	deltaG	deltaGErr	equation	name	reversibility	status	thermoReversibility"];
	my $mdlrxn = $model->modelreactions();
	my $compindecies = {};
	my $comps = $model->modelcompartments();
	for (my $i=0; $i < @{$comps}; $i++) {
		$compindecies->{$comps->[$i]->compartmentIndex()}->{$comps->[$i]->compartment()->id()} = 1;
	}
	my $biomasses = $model->biomasses();
	for (my $i=0; $i < @{$biomasses}; $i++) {
		my $biocpds = $biomasses->[$i]->biomasscompounds();
		my $partnermolecules = {
			cpd15665 => "cpd15666",
			cpd15669 => "cpd15666",
			cpd15668 => "cpd15666",
			cpd15667 => "cpd15666",
			cpd00002 => "cpd00012",
			cpd00038 => "cpd00012",            
		    cpd00052 => "cpd00012",
			cpd00062 => "cpd00012",
			cpd00115 => "cpd00012",
			cpd00241 => "cpd00012",
		    cpd00356 => "cpd00012",
			cpd00357 => "cpd00012",
			cpd00023 => "cpd00001",
			cpd00033 => "cpd00001",
		    cpd00039 => "cpd00001",
			cpd00035 => "cpd00001",
			cpd00041 => "cpd00001",
			cpd00051 => "cpd00001",
			cpd00053 => "cpd00001",
			cpd00054 => "cpd00001",
			cpd00065 => "cpd00001",
			cpd00060 => "cpd00001",
		    cpd00066 => "cpd00001",
			cpd00069 => "cpd00001",
			cpd00084 => "cpd00001",
			cpd00107 => "cpd00001",
			cpd00129 => "cpd00001",
			cpd00119 => "cpd00001",
			cpd00322 => "cpd00001",
			cpd00161 => "cpd00001",
			cpd00156 => "cpd00001",
			cpd00132 => "cpd00001",
			cpd11493 => "cpd12370",
			cpd00166 => "cpd01997|cpd03422",
		};
		for (my $j=0; $j < @{$biocpds}; $j++) {
			if ($biocpds->[$j]->coefficient() < 0) {
				my $array = [split(/\//,$biocpds->[$j]->modelcompound_ref())];
				my $id = pop(@{$array});
				if ($id =~ m/(.+)_[a-z]+(\d+)/) {
					my $coreid = $1;
					my $index = $2;
					my $equation = "=> (0.0001) ".$id;
					if (defined($partnermolecules->{$coreid})) {
						$array = [split(/\|/,$partnermolecules->{$coreid})];
						my $reactants = join("_c".$index." + (0.0001) ",@{$array});
						$reactants = "(0.0001) ".$reactants."_c".$index;
						$equation = $reactants." ".$equation;
					}
					push(@{$BioRxn},$biomasses->[$i]->id()."_".$id."\t".$biomasses->[$i]->id()."\t0\t".$biocpds->[$j]->coefficient()."\t".$equation."\t".$biomasses->[$i]->id()."\t=>\tOK\t=>");
					if ($id !~ m/cpd11416_c\d+/) {
						push(@{$additionalrxn},$biomasses->[$i]->id()."_".$id."\t>\tbiomasssupply");
					}
				}
			}
		}
	}
	#Building the model data file for MFAToolkit
	for (my $i=0; $i < @{$mdlrxn}; $i++) {
		my $rxn = $mdlrxn->[$i];
		my $direction = $rxn->direction();
		my $rxndir = "<=>";
		if (defined($self->parameters()->{activate_all_model_reactions}) && $self->parameters()->{activate_all_model_reactions} == 1) {
			$actcoef->{$rxn->id()} = 1;
		}
		if ($direction eq ">") {
			$rxndir = "=>";
			if (defined($self->parameters()->{make_model_rxns_reversible}) && $self->parameters()->{make_model_rxns_reversible} == 1) {
				if ($rxn->reaction()->id() eq "rxn00000_c" || $rxn->reaction()->GapfillDirection() eq "<" || $rxn->reaction()->GapfillDirection() eq "=") {
					$rxndir = "<=>";
					$gfcoef->{$rxn->id()} = {"reverse" => 1,tag => "MDLRXN"};
				}
			}
		} elsif ($direction eq "<") {
			$rxndir = "<=";
			if (defined($self->parameters()->{make_model_rxns_reversible}) && $self->parameters()->{make_model_rxns_reversible} == 1) {
				if ($rxn->reaction()->id() eq "rxn00000_c" || $rxn->reaction()->GapfillDirection() eq ">" || $rxn->reaction()->GapfillDirection() eq "=") {
					$rxndir = "<=>";
					$gfcoef->{$rxn->id()} = {forward => 1,tag => "MDLRXN"};
				}
			}
		}
		my $id = $rxn->id();
		my $name = $rxn->name();
		my $line = $id.";".$rxndir.";c;".$rxn->gprString().";".$rxn->complexString();
		$line =~ s/\|/___/g;
		push(@{$mdlData},$line);
		if (!defined($rxnhash->{$id})) {
			$rxnhash->{$id} = $rxn;
			my $reactants = "";
			my $products = "";
			my $rgts = $rxn->modelReactionReagents();
			for (my $j=0;$j < @{$rgts}; $j++) {
				my $rgt = $rgts->[$j];
				my $suffix = "";
				if ($rgt->modelcompound()->modelcompartment()->compartment()->id() eq "e") {
					$suffix = "[e]";
				}
				if ($rgt->coefficient() < 0) {
					if (length($reactants) > 0) {
						$reactants .= " + ";
					}
					$reactants .= "(".abs($rgt->coefficient()).") ".$rgt->modelcompound()->id().$suffix;
				} elsif ($rgt->coefficient() > 0) {
					if (length($products) > 0) {
						$products .= " + ";
					}
					$products .= "(".$rgt->coefficient().") ".$rgt->modelcompound()->id().$suffix;
				}
			}
			my $equation = $reactants." ".$rxndir." ".$products;
			(my $dg, my $dge, my $st) = (0,0,"OK");
			if (defined($rxn->reaction()->deltaG())) {
				$dg = $rxn->reaction()->deltaG();
			}
			if (defined($rxn->reaction()->deltaGErr())) {
				$dge = $rxn->reaction()->deltaGErr();
			}
			if (defined($rxn->reaction()->status())) {
				$st = $rxn->reaction()->status();
			}
			if ($self->quantitativeOptimization() == 1 && $id eq "rxn10042_c0") {
				$equation =~ s/\(4\)\scpd00067_e0/(7) cpd00067_e0/g;
				$equation =~ s/\(3\)\scpd00067_c0/(6) cpd00067_c0/g;
			}
			push(@{$BioRxn},$id."\t".$id."\t".$dg."\t".$dge."\t".$equation."\t".$id."\t".$rxndir."\t".$st."\t".$rxndir);
		}
	}
	my $final_gauranteed = [];
	my $final_ko = [];
	#Adding biomass component reactions to database for quantitative optimization
	if ($self->quantitativeOptimization() == 1) {
		my $bio = $self->fbamodel()->biomasses()->[0];
		my $biocpds = $bio->biomasscompounds();
		my $energycoef;
		push(@{$additionalrxn},"SixATPSynth\t=\tATPSYNTH");
		push(@{$additionalrxn},"OneATPSynth\t=\tATPSYNTH");
		push(@{$additionalrxn},"ATPMaintenance\t=\tATPMAINT");
		push(@{$additionalrxn},"EnergyBiomass\t=\tBiomassComp");
		$gfcoef->{"EnergyBiomass"} = {"reverse" => 10,forward => 10,tag => "BiomassComp"};
		push(@{$BioRxn},"SixATPSynth\tSixATPSynth\t0\t0\t(6) cpd00067_e0[e] + cpd00008_c0[c] + cpd00009_c0[c] <=> cpd00002_c0[c] + (5) cpd00067_c0[c] + cpd00001_c0[c]\tSixATPSynth\t<=>\tOK\t<=>");
		push(@{$BioRxn},"OneATPSynth\tOneATPSynth\t0\t0\t(1) cpd00067_e0[e] + cpd00008_c0[c] + cpd00009_c0[c] <=> cpd00002_c0[c] + cpd00001_c0[c]\tOneATPSynth\t<=>\tOK\t<=>");
		push(@{$BioRxn},"ATPMaintenance\tATPMaintenance\t0\t0\tcpd00002_c0[c] + cpd00001_c0[c] <=> cpd00067_c0[c] + cpd00008_c0[c] + cpd00009_c0[c]\tATPMaintenance\t=>\tOK\t=>");
		push(@{$BioRxn},"EnergyBiomass\tEnergyBiomass\t0\t0\tcpd00002_c0[b] + cpd00001_c0[b] <=> cpd00008_c0[b] + cpd00009_c0[b] + cpd00067_c0[b]\tEnergyBiomass\t<=>\tOK\t<=>");
		my $comprxn = {};
		foreach my $cpd (@{$biocpds}) {
			if ($cpd->coefficient() > 0) {
				if ($cpd->modelcompound()->compound()->id() eq "cpd00008") {
					$energycoef = $cpd->coefficient();
				}
			} else {
				my $component = "other";
				if ($cpd->modelcompound()->compound()->class() eq "amino_acid") {
					$component = "protein";
				} elsif ($cpd->modelcompound()->compound()->class() eq "deoxynucleotide") {
					$component = "dna";
				} elsif ($cpd->modelcompound()->compound()->class() eq "nucleotide") {
					$component = "rna";
				} elsif ($cpd->modelcompound()->compound()->class() eq "cellwall") {
					$component = "cellwall";
				} elsif ($cpd->modelcompound()->compound()->class() eq "lipid") {
					$component = "lipid";
				}
				if ($component eq "other") {
					$comprxn->{$cpd->modelcompound()->compound()->id()}->{compounds}->{$cpd->modelcompound()->compound()->id()} = 1;
					$comprxn->{$cpd->modelcompound()->compound()->id()}->{totalmass} = 0.001*$cpd->modelcompound()->compound()->mass();
					my $coprods = $cpd->modelcompound()->compound()->biomass_coproducts();
					foreach my $cocpd (@{$coprods}) {
						my $cpdobj = $self->template()->searchForCompound($cocpd->[0]);
						$comprxn->{$cpd->modelcompound()->compound()->id()}->{compounds}->{$cpdobj->id()} = $cocpd->[1];
						$comprxn->{$cpd->modelcompound()->compound()->id()}->{totalmass} += 0.001*$cpdobj->mass()*$cocpd->[1];
					}
				} elsif ($component ne "dependent") {
					my $massadaptor = 0;
					$comprxn->{$component}->{compounds}->{$cpd->modelcompound()->compound()->id()} = $cpd->coefficient();
					if (!defined($comprxn->{$component}->{totalmass})) {
						$comprxn->{$component}->{totalmass} = 0;
					}
					$comprxn->{$component}->{totalmass} += $cpd->coefficient()*0.001*$cpd->modelcompound()->compound()->mass();
					my $coprods = $cpd->modelcompound()->compound()->biomass_coproducts();
					foreach my $cocpd (@{$coprods}) {
						my $cpdobj = $self->template()->searchForCompound($cocpd->[0]);
						$comprxn->{$component}->{compounds}->{$cpdobj->id()} = $cpd->coefficient()*$cocpd->[1];
						$comprxn->{$component}->{totalmass} += 0.001*$cpd->coefficient()*$cpdobj->mass()*$cocpd->[1];
					}
				}
			}
		}
		my $biomasscomps = "EnergyBiomass:".$energycoef;
		foreach my $component (keys(%{$comprxn})) {
			if ($comprxn->{$component}->{totalmass} == 0) {
				$comprxn->{$component}->{totalmass} = 1;
				print "Zero mass ".$component."\n";
			}
			$biomasscomps .= ";".$component."Biomass:".$comprxn->{$component}->{totalmass};
			my $reactant = "";
			my $product = "";
			foreach my $cpd (keys(%{$comprxn->{$component}->{compounds}})) {
				#Rescaling the coefficient for a one gram basis
				$comprxn->{$component}->{compounds}->{$cpd} = $comprxn->{$component}->{compounds}->{$cpd}/$comprxn->{$component}->{totalmass};
				if ($comprxn->{$component}->{compounds}->{$cpd} < 0) {
					if (length($reactant) > 0) {
						$reactant .= " + ";
					}
					my $coef = -1*$comprxn->{$component}->{compounds}->{$cpd};
					$reactant .= "(".$coef.") ".$cpd."_c0[b]";
				} else {
					if (length($product) > 0) {
						$product .= " + ";
					}
					my $coef = $comprxn->{$component}->{compounds}->{$cpd};
					$product .= "(".$coef.") ".$cpd."_c0[b]";
				}
			}
			push(@{$additionalrxn},$component."Biomass\t=\tBiomassComp");
			$gfcoef->{$component."Biomass"} = {"reverse" => 10,forward => 10,tag => "BiomassComp"};
			push(@{$BioRxn},$component."Biomass\t".$component."Biomass\t0\t0\t".$reactant." <=> ".$product."\t".$component."Biomass\t<=>\tOK\t<=>");
		}
		$self->parameters()->{"Biomass component coefficients"} = $biomasscomps;
		$self->parameters()->{"quantitative optimization"} = 1;
	}
	#Adding gapfilling candidates from template
	if (defined($self->parameters()->{add_external_rxns}) && $self->parameters()->{add_external_rxns} == 1 && defined($self->parameters()->{"Perform gap filling"}) && $self->parameters()->{"Perform gap filling"} == 1) {	
		my $gauranteed = {};
		my $rxnlist = $self->gauranteedrxns();
		foreach my $rxn (@{$rxnlist}) {
			$gauranteed->{$rxn} = 1;
		}
		my $blacklist = {};
		$rxnlist = $self->blacklistedrxns();
		foreach my $rxn (@{$rxnlist}) {
			$blacklist->{$rxn} = 1;
		}
		my $gfcpdhash;
		foreach my $compindex (keys(%{$compindecies})) {
			my $tmp = $model->template();
			if (defined($compindecies->{1})) {
				if ($compindex == 0) {
					next;
				} else {
					if (defined($self->templates()->{$compindex})) {
						$tmp = $self->templates()->{$compindex};
					} elsif (defined($model->templates()->[$compindex])) {
						$tmp = $model->templates()->[$compindex];
					}
				}
			}
			my $tmprxns = $tmp->reactions();
			for (my $i=0; $i < @{$tmprxns}; $i++) {
				my $tmprxn = $tmprxns->[$i];
				my $tmpid = $tmprxn->id().$compindex;
				my $rxndir = "<=>";
				if ($tmprxn->direction() eq ">") {
					$rxndir = "=>";
				} elsif ($tmprxn->direction() eq "<") {
					$rxndir = "<=";
				}
				if (!defined($rxnhash->{$tmpid})) {
					if (defined($gauranteed->{$tmprxn->msid()}) || !defined($blacklist->{$tmprxn->msid()})) {
						push(@{$additionalrxn},$tmpid."\t".$tmprxn->GapfillDirection()."\tGFDB");
						$gfcoef->{$tmpid} = {tag => "GFDB"};
						if ($tmprxn->GapfillDirection() eq ">" || $tmprxn->GapfillDirection() eq "=") {
							$gfcoef->{$tmpid}->{forward} = 1;#$tmprxn->forward_penalty();
						}
						if ($tmprxn->GapfillDirection() eq "<" || $tmprxn->GapfillDirection() eq "=") {
							$gfcoef->{$tmpid}->{"reverse"} = 1;#$tmprxn->reverse_penalty();
						}
					}
					$rxnhash->{$tmpid} = 1;
					my $reactants = "";
					my $products = "";
					my $rgts = $tmprxn->templateReactionReagents();
					my $multcomp = 0;
					for (my $j=1;$j < @{$rgts}; $j++) {
						if ($rgts->[0]->templatecompcompound()->templatecompartment()->id() ne $rgts->[$j]->templatecompcompound()->templatecompartment()->id()) {
							$multcomp = 1;
							last;
						}
					}
					for (my $j=0;$j < @{$rgts}; $j++) {
						my $rgt = $rgts->[$j];
						my $suffix = $compindex;
						if ($rgt->templatecompcompound()->templatecompartment()->id() eq "e") {
							$suffix = "0";
						}
						$gfcpdhash->{$rgt->templatecompcompound()->id().$suffix} = $rgt->templatecompcompound()->templatecompound();
						if ($rgt->templatecompcompound()->templatecompartment()->id() eq "e") {
							$suffix .= "[e]";
						}
						if ($rgt->coefficient() < 0) {
							if (length($reactants) > 0) {
								$reactants .= " + ";
							}
							$reactants .= "(".abs($rgt->coefficient()).") ".$rgt->templatecompcompound()->id().$suffix;
						} elsif ($rgt->coefficient() > 0) {
							if (length($products) > 0) {
								$products .= " + ";
							}
							$products .= "(".$rgt->coefficient().") ".$rgt->templatecompcompound()->id().$suffix;
						}
					}
					my $equation = $reactants." ".$rxndir." ".$products;
					(my $dg, my $dge, my $st) = (0,0,"OK");
					if (defined($tmprxn->deltaG())) {
						$dg = $tmprxn->deltaG();
					}
					if (defined($tmprxn->deltaGErr())) {
						$dge = $tmprxn->deltaGErr();
					}
					if (defined($tmprxn->status())) {
						$st = $tmprxn->status();
					}		
					push(@{$BioRxn},$tmpid."\t".$tmpid."\t".$dg."\t".$dge."\t".$equation."\t".$tmpid."\t".$rxndir."\t".$st."\t".$rxndir);
				}
			}
		}
		foreach my $cpdid (keys(%{$gfcpdhash})) {
			if (!defined($cpdhash->{$cpdid})) {
				my $cpd = $gfcpdhash->{$cpdid};
				my $comp;
				if ($cpdid =~ m/_(\w)(\d+)$/) {
					$comp = $1;
					if (defined($genex->{$cpd->id()})) {
						if (defined($genex->{$cpd->id()}->{$comp})) {
							if ($comp eq "e") {
								$exchangehash->{$cpdid}->{e} = $genex->{$cpd->id()}->{$comp};
							} else {
								$exchangehash->{$cpdid}->{c} = $genex->{$cpd->id()}->{$comp};
							}				
						}
					}
				}
				push(@{$BioCpd},$cpdid."\t".$cpdid."\t".$cpd->defaultCharge()."\t".$cpd->formula()."\t0\t".$cpdid."\t".$cpd->deltaG());
			}
		}
	}
	if (defined($self->parameters()->{add_external_rxns}) && $self->parameters()->{add_external_rxns} == 1 && defined($self->{_source_model})) {
		my $gfm = $self->{_source_model};
		if (defined($gfm)) {
			$mdlcpd = $gfm->modelcompounds();
			$mdlrxn = $gfm->modelreactions();
			foreach my $compindex (keys(%{$compindecies})) {
				if (defined($compindecies->{1})) {
					if ($compindex == 0) {
						next;
					}
				}
				for (my $i=0; $i < @{$mdlcpd}; $i++) {
					my $cpd = $mdlcpd->[$i];
					my $id = $cpd->id();
					if ($id =~ /(.+)_([a-z]+)(\d+)/) {
						my $trueid = $1."_".$2.$compindex;
						my $oldcmp = $2.$3;
						my $newcmp = $2.$compindex;
						if ($2 eq "e") {
							$trueid = $1."_".$2."0";
							$oldcmp = $2.$3;
							$newcmp = $2."0";
						}
						if (defined($genex->{$cpd->compound()->id()})) {
							if (defined($genex->{$cpd->compound()->id()}->{$cpd->modelcompartment()->compartment()->id()})) {
								if ($cpd->modelcompartment()->compartment()->id() eq "e") {
									$exchangehash->{$trueid}->{e} = $genex->{$cpd->compound()->id()}->{$cpd->modelcompartment()->compartment()->id()};
								} else {
									$exchangehash->{$trueid}->{c} = $genex->{$cpd->compound()->id()}->{$cpd->modelcompartment()->compartment()->id()};
								}				
							}
						}
						my $name = $cpd->name();
						$name =~ s/$oldcmp/$newcmp/;
						my $abbrev = $trueid;
						if (!defined($cpdhash->{$trueid})) {
							push(@{$BioCpd},$trueid."\t".$abbrev."\t".$cpd->charge()."\t".$cpd->formula()."\t0\t".$name);
							$cpdhash->{$trueid} = $cpd;
						}
					}
				}
				for (my $i=0; $i < @{$mdlrxn}; $i++) {
					my $rxn = $mdlrxn->[$i];
					my $direction = $rxn->direction();
					my $rxndir = "<=>";
					if ($direction eq ">") {
						$rxndir = "=>";
					} elsif ($direction eq "<") {
						$rxndir = "<=";
					}
					my $id = $rxn->id();
					if ($id =~ /(.+)_([a-z]+)(\d+)/) {
						my $trueid = $1."_".$2.$compindex;
						my $oldcmp = $2.$3;
						my $newcmp = $2.$compindex;
						my $name = $rxn->name();
						$name =~ s/$oldcmp/$newcmp/;
						if (!defined($rxnhash->{$trueid})) {
							push(@{$additionalrxn},$trueid."\t".$direction."\tSRCMDL");
							$gfcoef->{$trueid} = {tag => "SRCMDL"};
							if ($direction eq ">" || $direction eq "=") {
								$gfcoef->{$trueid}->{forward} = "10";
							}
							if ($direction eq "<" || $direction eq "=") {
								$gfcoef->{$trueid}->{"reverse"} = "10";
							}
							$rxnhash->{$trueid} = $rxn;
							my $reactants = "";
							my $products = "";
							my $rgts = $rxn->modelReactionReagents();
							for (my $j=0;$j < @{$rgts}; $j++) {
								my $rgt = $rgts->[$j];
								my $rgtid = $rgt->modelcompound()->id();
								if ($rgtid =~ /(.+)_([a-z]+)(\d+)/) {
									$rgtid = $1."_".$2.$compindex;
									if ($2 eq "e") {
										$rgtid = $1."_".$2."0";
									}	
									my $suffix = "";
									if ($rgt->modelcompound()->modelcompartment()->compartment()->id() eq "e") {
										$suffix = "[e]";
									}
									if ($rgt->coefficient() < 0) {
										if (length($reactants) > 0) {
											$reactants .= " + ";
										}
										$reactants .= "(".abs($rgt->coefficient()).") ".$rgtid.$suffix;
									} elsif ($rgt->coefficient() > 0) {
										if (length($products) > 0) {
											$products .= " + ";
										}
										$products .= "(".$rgt->coefficient().") ".$rgtid.$suffix;
									}
								}
							}
							my $equation = $reactants." ".$rxndir." ".$products;
							(my $dg, my $dge, my $st) = (0,0,"OK");
							if (defined($rxn->reaction()->deltaG())) {
								$dg = $rxn->reaction()->deltaG();
							}
							if (defined($rxn->reaction()->deltaGErr())) {
								$dge = $rxn->reaction()->deltaGErr();
							}
							if (defined($rxn->reaction()->status())) {
								$st = $rxn->reaction()->status();
							}
							push(@{$BioRxn},$trueid."\t".$trueid."\t".$dg."\t".$dge."\t".$equation."\t".$trueid."\t".$rxndir."\t".$st."\t".$rxndir);
						}
					}
				}
			}
		}
	}
	if ($self->minimize_reactions() == 1) {
		my $hash = $self->minimize_reaction_costs();
		foreach my $key (keys(%{$hash})) {
			my $mdlrxn = $model->getObject("modelreactions",$key);
			if (defined($key)) {
				$gfcoef->{$mdlrxn->id()} = {tag => "MDLRXN"};
				if ($mdlrxn->direction() eq ">" || $mdlrxn->direction() eq "=") {
					$gfcoef->{$mdlrxn->id()}->{forward} = $hash->{$key};
				}
				if ($mdlrxn->direction() eq "<" || $mdlrxn->direction() eq "=") {
					$gfcoef->{$mdlrxn->id()}->{"reverse"} = $hash->{$key};
				}
			}
		}
	}
	if (defined($self->{_expsample})) {
		my $coef = $self->process_expression_data();
		foreach my $key (keys(%{$coef->{lowexp}})) {
			delete $actcoef->{$key};
			if (defined($coef->{lowexp}->{$key}->{forward})) {
				$gfcoef->{$key}->{forward} = $coef->{lowexp}->{$key}->{forward};
			}
			if (defined($coef->{lowexp}->{$key}->{"reverse"})) {
				$gfcoef->{$key}->{"reverse"} = $coef->{lowexp}->{$key}->{"reverse"};
			}
			$gfcoef->{$key}->{tag} = "MDLRXN";
		}
		foreach my $key (keys(%{$coef->{highexp}})) {
			$actcoef->{$key} = $coef->{highexp}->{$key};
		}
	}
	for (my $i=0; $i < @{$biomasses}; $i++) {
		my $bio = $biomasses->[$i];
		push(@{$mdlData},$bio->id().";=>;c;UNIVERSAL");
		my $reactants = "";
		my $products = "";
		my $rgts = $bio->biomasscompounds();
		for (my $j=0;$j < @{$rgts}; $j++) {
			my $rgt = $rgts->[$j];
			if ($rgt->coefficient() < 0) {
				my $suffix = "";
				if ($rgt->modelcompound()->modelcompartment()->compartment()->id() eq "e") {
					$suffix = "[e]";
				}
				if (length($reactants) > 0) {
					$reactants .= " + ";
				}
				$reactants .= "(".(-1*$rgt->coefficient()).") ".$rgt->modelcompound()->id().$suffix;
			}
		}
		for (my $j=0;$j < @{$rgts}; $j++) {
			my $rgt = $rgts->[$j];
			if ($rgt->coefficient() > 0) {
				my $suffix = "";
				if ($rgt->modelcompound()->modelcompartment()->compartment()->id() eq "e") {
					$suffix = "[e]";
				}
				if (length($products) > 0) {
					$products .= " + ";
				}
				$products .= "(".$rgt->coefficient().") ".$rgt->modelcompound()->id().$suffix;
			}
		}
		my $equation = $reactants." => ".$products;
		my $rxnline = $bio->id()."\t".$bio->id()."\t0\t0\t".$equation."\tBiomass\t=>\tOK\t=>";
		push(@{$BioRxn},$rxnline);
	}
	my $gfcoefficients = ["Reaction\tDirection\tCoefficient\tTag"];
	foreach my $key (keys(%{$gfcoef})) {
		if (defined($gfcoef->{$key}->{forward})) {
			push(@{$gfcoefficients},$key."\tforward\t".$gfcoef->{$key}->{forward}."\t".$gfcoef->{$key}->{tag});
		}
		if (defined($gfcoef->{$key}->{"reverse"})) {
			push(@{$gfcoefficients},$key."\treverse\t".$gfcoef->{$key}->{"reverse"}."\t".$gfcoef->{$key}->{tag});
		}
	}
	my $actcoeffile = ["Reaction\tPenalty"];
	foreach my $key (keys(%{$actcoef})) {
		push(@{$actcoeffile},$key."\t".$actcoef->{$key});
	}
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."Compounds.tbl",$BioCpd);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."Reactions.tbl",$BioRxn);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."Model.tbl",$mdlData);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."ActivationCoefficients.txt",$actcoeffile);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."AdditionalReactions.txt",$additionalrxn);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."GapfillingCoefficients.txt",$gfcoefficients);
	#Printing additional input files specified in formulation
	my $inputfileHash = $self->inputfiles();
	foreach my $filename (keys(%{$inputfileHash})) {
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory.$filename,$inputfileHash->{$filename});
	}
	#Setting drain max based on media
	my $primMedia = $self->media();
	if ($primMedia->name() eq "Complete") {
		if ($self->defaultMaxDrainFlux() <= 0) {
			$self->defaultMaxDrainFlux($self->defaultMaxFlux());
		}
	}
	my $addnlCpds = $self->additionalCpds();
	if (@{$addnlCpds} > 0) {
		my $newPrimMedia = $primMedia->cloneObject();
		$newPrimMedia->name("TempPrimaryMedia");
		$newPrimMedia->id("TempPrimaryMedia");
		my $mediaCpds = $newPrimMedia->mediacompounds();
		for (my $i=0; $i < @{$addnlCpds}; $i++) {
			my $found = 0;
			for (my $j=0; $j < @{$mediaCpds}; $j++) {
				if ($mediaCpds->[$j]->compound_ref() eq $addnlCpds->[$i]->_reference()) {
					$mediaCpds->[$j]->maxFlux() = 100;
				}
			}
			if ($found == 0) {
				$newPrimMedia->add("mediacompounds",{compound_ref => $addnlCpds->[$i]->_reference()});
			}
		}
		$primMedia = $newPrimMedia;
	}
	#Selecting the solver based on whether the problem is MILP
	#First check whether the user has set a specific solver
	my $solver = defined $self->parameters()->{MFASolver} ? $self->parameters()->{MFASolver} : "GLPK";
	if ($self->fluxUseVariables() == 1 || $self->drainfluxUseVariables() == 1 || $self->findMinimalMedia() || defined $self->{_expsample}) {
		$solver = "SCIP" if $solver ne "CPLEX";
	}
	#Setting gene KO
	my $geneKO = "none";
	for (my $i=0; $i < @{$self->geneKOs()}; $i++) {
		my $gene = $self->geneKOs()->[$i];
		if ($i == 0) {
			$geneKO = $gene->id();	
		} else {
			$geneKO .= ";".$gene->id();
		}
	}
	$geneKO =~ s/\|/___/g;
	#Setting reaction KO
	my $rxnKO = "none";
	for (my $i=0; $i < @{$self->reactionKOs()}; $i++) {
		my $rxn = $self->reactionKOs()->[$i];
		if ($i == 0) {
			$rxnKO = $rxn->id();	
		} else {
			$rxnKO .= ";".$rxn->id();
		}
	}
	if (@{$final_ko} > 0) {
		if ($rxnKO eq "none") {
			$rxnKO = join(";",@{$final_ko});
		} else {
			$rxnKO .= ";".join(";",@{$final_ko});
		}
	}
	#Setting the objective
	my $objective = "MAX";
	my $metToOpt = "REACTANTS;bio1";
	my $optMetabolite = 1;
	if ($self->fva() == 1 || $self->comboDeletions() > 0) {
		$optMetabolite = 0;
	}
	if ($self->maximizeObjective() == 0) {
		$objective = "MIN";
		$optMetabolite = 0;
	}
	foreach my $objid (keys(%{$self->compoundflux_objterms()})) {
		my $entity = $model->getObject("modelcompounds",$objid);
		if (defined($entity)) {
			my $comp = "c";
			if ($entity->modelcompartment()->compartment()->id() eq "e") {
				$comp = "e";
			}
			$objective .= ";DRAIN_FLUX;".$objid.";".$comp.";".$self->compoundflux_objterms()->{$objid};
			$exchangehash->{$objid} = {$comp => [-10000,0]};
		}
	}
	foreach my $objid (keys(%{$self->reactionflux_objterms()})) {
		my $entity = $model->getObject("modelreactions",$objid);
		if (defined($entity)) {
			my $comp = "c";
			if ($entity->modelcompartment()->compartment()->id() eq "e") {
				$comp = "e";
			}
			$objective .= ";FLUX;".$objid.";".$comp.";".$self->reactionflux_objterms()->{$objid};
		}
	}
	foreach my $objid (keys(%{$self->biomassflux_objterms()})) {
		my $entity = $model->getObject("biomasses",$objid);
		if (defined($entity)) {
			$objective .= ";FLUX;".$objid.";c;".$self->biomassflux_objterms()->{$objid};
		}
	}
	#Setting up uptake limits
	my $uptakeLimits = "none";
	foreach my $atom (keys(%{$self->uptakeLimits()})) {
		if ($uptakeLimits eq "none") {
			$uptakeLimits = $atom.":".$self->uptakeLimits()->{$atom};
		} else {
			$uptakeLimits .= ";".$atom.":".$self->uptakeLimits()->{$atom};
		}
	}
	#Creating FBA experiment file
	my $medialist = [$primMedia];
	my $fbaExpFile = $self->setupFBAExperiments($medialist);
	if ($fbaExpFile ne "none") {
		$optMetabolite = 0;
	}
	#Setting parameters
	my $parameters = {
		"fit phenotype data" => 0,
		"deltagslack" => 10,
		"maximize active reactions" => 0,
		"calculate reaction knockout sensitivity" => 0,
		"write LP file" => 0,
		"write variable key" => 1,
		"new fba pipeline" => 1,
		"perform MFA" => 1,
		"Default min drain flux" => $self->defaultMinDrainFlux(),
		"Default max drain flux" => $self->defaultMaxDrainFlux(),
		"Max flux" => $self->defaultMaxFlux(),
		"Min flux" => -1*$self->defaultMaxFlux(),
		"user bounds filename" => $primMedia->name(),
		"create file on completion" => "FBAComplete.txt",
		"Reactions to knockout" => $rxnKO,
		"Genes to knockout" => $geneKO,
		"output folder" => $self->jobID()."/",
		"use database fields" => 1,
		"MFASolver" => $solver,
		"database spec file" => $directory."StringDBFile.txt",
		"Reactions use variables" => $self->fluxUseVariables(),
		"Force use variables for all reactions" => 1,
		"Add use variables for any drain fluxes" => $self->drainfluxUseVariables(),
		"Decompose reversible reactions" => $self->decomposeReversibleFlux(),
		"Decompose reversible drain fluxes" => $self->decomposeReversibleDrainFlux(),
		"Make all reactions reversible in MFA" => $self->allReversible(),
		"Constrain objective to this fraction of the optimal value" => $self->objectiveConstraintFraction(),
		"objective" => $objective,
		"find tight bounds" => $self->fva(),
		"flux minimization" => $self->fluxMinimization(), 
		"uptake limits" => $uptakeLimits,
		"optimize metabolite production if objective is zero" => $optMetabolite,
		"metabolites to optimize" => $metToOpt,
		"FBA experiment file" => $fbaExpFile,
		"determine minimal required media" => $self->findMinimalMedia(),
		"Recursive MILP solution limit" => $self->numberOfSolutions(),
		"database root output directory" => $self->jobPath()."/",
		"database root input directory" => $self->jobDirectory()."/",
		"Min flux multiplier" => 1,
		"Max deltaG" => 10000
	};
	if (defined($self->{"fit phenotype data"})) {
		$parameters->{"fit phenotype data"} = $self->{"fit phenotype data"};
	}
	if ($self->calculateReactionKnockoutSensitivity() == 1) {
		$parameters->{"calculate reaction knockout sensitivity"} = 1;
	}
	if ($self->comboDeletions() == 1) {
		$parameters->{"perform single KO experiments"} = 1;
	}
	if (@{$final_gauranteed} > 0) {
		$parameters->{"Allowable unbalanced reactions"} = join(",",@{$final_gauranteed});
	}
	if (defined($self->promconstraint_ref()) && length($self->promconstraint_ref()) > 0) {
		$self->promconstraint()->PrintPROMModel($self->jobDirectory()."/PROMModel.txt");
		$parameters->{"PROM model filename"} = "PROMModel.txt";
		$parameters->{"PROM Kappa"} = $self->PROMKappa();
		$parameters->{"prom constraints"} = 1;
	}
	#if ($solver eq "SCIP") {
		$parameters->{"use simple variable and constraint names"} = 1;
	#}
	if ($^O =~ m/^MSWin/) {
		$parameters->{"scip executable"} = "scip.exe";
		$parameters->{"perl directory"} = "C:/Perl/bin/perl.exe";
		$parameters->{"os"} = "windows";
	} else {
		$parameters->{"scip executable"} = "scip";
		$parameters->{"perl directory"} = "/usr/bin/perl";
		$parameters->{"os"} = "linux";
	}
	#Setting thermodynamic constraints
	if ($self->thermodynamicConstraints() eq "1") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"Account for error in delta G"} = 0;
		$parameters->{"minimize deltaG error"} = 0;
		if ($self->noErrorThermodynamicConstraints() eq "0") {
			$parameters->{"Account for error in delta G"} = 1;
		}
		if ($self->minimizeErrorThermodynamicConstraints() eq "1") {
			$parameters->{"minimize deltaG error"} = 1;
		}
	} elsif ($self->simpleThermoConstraints() eq "1") {
		$parameters->{"simple thermo constraints"} = 1;
	}
	#Setting overide parameters
	foreach my $param (keys(%{$self->parameters()})) {
		$parameters->{$param} = $self->parameters()->{$param};
	}
	#Printing specialized bounds
	my $mediaData = ["ID\tNAMES\tVARIABLES\tTYPES\tMAX\tMIN\tCOMPARTMENTS\tCONCENTRATIONS"];
	my $cpdbnds = $self->FBACompoundBounds();
	my $rxnbnds = $self->FBAReactionBounds();
	foreach my $media (@{$medialist}) {
		$media->parent($self->parent());
		my $userBounds = {};
		my $mediaCpds = $media->mediacompounds();
		for (my $i=0; $i < @{$mediaCpds}; $i++) {
			my $cid = $mediaCpds->[$i]->compound_ref();
			$cid =~ s/^.+\///g;
			my $cmp = "e";
			if ($cid !~ m/_[a-z]+\d+$/) {
				$cid .= "_e0";
			} else {
				$cmp = "c";
			}
			$userBounds->{$cid}->{$cmp}->{"DRAIN_FLUX"} = {
				max => $mediaCpds->[$i]->maxFlux(),
				min => $mediaCpds->[$i]->minFlux(),
				conc => $mediaCpds->[$i]->concentration()
			};
			if ($cmp ne "e") {
				$exchangehash->{$cid}->{c} = [$mediaCpds->[$i]->minFlux(),$mediaCpds->[$i]->maxFlux()];
			}
		}
		for (my $i=0; $i < @{$cpdbnds}; $i++) {
			my $comp = "c";
			if ($cpdbnds->[$i]->modelcompound()->modelcompartment()->compartment()->id() eq "e") {
				$comp = "e";
			}
			$userBounds->{$cpdbnds->[$i]->modelcompound()->id()}->{$comp}->{$translation->{$cpdbnds->[$i]->variableType()}} = {
				max => $cpdbnds->[$i]->upperBound(),
				min => $cpdbnds->[$i]->lowerBound(),
				conc => 0.001
			};
			if ($comp ne "e") {
				$exchangehash->{$cpdbnds->[$i]->modelcompound()->id()}->{c} = [$cpdbnds->[$i]->lowerBound(),$cpdbnds->[$i]->upperBound()];
			}
		}
		for (my $i=0; $i < @{$rxnbnds}; $i++) {
			$userBounds->{$rxnbnds->[$i]->modelreaction()->id()}->{c}->{$translation->{$rxnbnds->[$i]->variableType()}} = {
				max => $rxnbnds->[$i]->upperBound(),
				min => $rxnbnds->[$i]->lowerBound(),
				conc => 0.001
			};
		}
		my $dataArrays;
		foreach my $var (keys(%{$userBounds})) {
			foreach my $comp (keys(%{$userBounds->{$var}})) {
				foreach my $type (keys(%{$userBounds->{$var}->{$comp}})) {
					push(@{$dataArrays->{var}},$var);
					push(@{$dataArrays->{type}},$type);
					push(@{$dataArrays->{min}},$userBounds->{$var}->{$comp}->{$type}->{min});
					push(@{$dataArrays->{max}},$userBounds->{$var}->{$comp}->{$type}->{max});
					push(@{$dataArrays->{comp}},$comp);
					push(@{$dataArrays->{conc}},$userBounds->{$var}->{$comp}->{$type}->{conc});
				}
			}
		}
		my $newLine = $media->name()."\t".$media->name()."\t";
		if (defined($dataArrays->{var}) && @{$dataArrays->{var}} > 0) {
			$newLine .= 
				join("|",@{$dataArrays->{var}})."\t".
				join("|",@{$dataArrays->{type}})."\t".
				join("|",@{$dataArrays->{max}})."\t".
				join("|",@{$dataArrays->{min}})."\t".
				join("|",@{$dataArrays->{comp}})."\t".
				join("|",@{$dataArrays->{conc}});
		} else {
			$newLine .= "\t\t\t\t\t";
		}
		push(@{$mediaData},$newLine);
	}
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."media.tbl",$mediaData);
	my $genereg = {};
	if (defined($self->regulome_ref())) {
		my $rmodel = $self->regulome();
		my $regulons = $rmodel->regulons();
		for (my $i=0; $i < @{$regulons}; $i++) {
			my $operons = $regulons->[$i]->operons();
			my $tfs = $regulons->[$i]->tfs();
			my $effectors = $regulons->[$i]->effectors();
			for (my $j=0; $j < @{$operons}; $j++) {
				my $sign = 1;
				my $sites = $operons->[$j]->sites();
				if (defined($sites->[0]->regulatory_mechanism())) {
					$sign = $sites->[0]->regulatory_mechanism();
				}
				my $genes = $operons->[$j]->genes();
				my $found = 0;
				for (my $m=0; $m < @{$tfs}; $m++) {
					if ($tfs->[$m]->locus_tag() ne "RNA") {
						$found = 1;
						for (my $n=0; $n < @{$effectors}; $n++) {
							if ($effectors->[$n]->effector_class() =~ m/(.+)b$/) {
								my $sign = $1;
								my $compname = $effectors->[$n]->effector_name();
								my $array = [split(/\-\-/,$compname)];
								my $type = "standard";
								if (defined($array->[1])) {
									$type = $array->[1];
									$compname = $array->[0];
								}
								my $comp = $self->template()->searchForCompound($compname);
								if (!defined($comp)) {
									print STDERR "Could not find compound stimuli ".$compname."!\n";
									$genereg->{$tfs->[$m]->locus_tag()}->{stimuli}->{$compname} = $sign;
								} else {
									$genereg->{$tfs->[$m]->locus_tag()}->{compounds}->{$comp->id()} = [$sign,$type];
								}
							} elsif ($effectors->[$n]->effector_class() =~ m/(.+)[a-z]$/) {
								my $sign = $1;
								$genereg->{$tfs->[$m]->locus_tag()}->{stimuli}->{$effectors->[$n]->effector_name()} = $sign;
							}
						}
					}
				}
				for (my $k=0; $k < @{$genes}; $k++) {
					for (my $m=0; $m < @{$tfs}; $m++) {
						if ($tfs->[$m]->locus_tag() eq "RNA") {
							$genereg->{$genes->[$k]->locus_tag()}->{stimuli}->{$tfs->[$m]->locus_tag()} = $sign;
						} else {
							$genereg->{$genes->[$k]->locus_tag()}->{tfs}->{$tfs->[$m]->locus_tag()} = $sign;
						}
					}
					if ($found == 0) {
						for (my $n=0; $n < @{$effectors}; $n++) {
							if ($effectors->[$n]->effector_class() =~ m/(.+)b$/) {
								my $esign = $1;
								my $compname = $effectors->[$n]->effector_name();
								my $array = [split(/\-\-/,$compname)];
								my $type = "standard";
								if (defined($array->[1])) {
									$type = $array->[1];
									$compname = $array->[0];
								}
								my $comp = $self->template()->searchForCompound($compname);
								if (!defined($comp)) {
									print STDERR "Could not find compound stimuli ".$compname."!\n";
									$genereg->{$genes->[$k]->locus_tag()}->{stimuli}->{$compname} = $esign*$sign;
								} else {
									$genereg->{$genes->[$k]->locus_tag()}->{compounds}->{$comp->id()} = [$esign*$sign,$type];
								}
							} elsif ($effectors->[$n]->effector_class() =~ m/(.+)[a-z]$/) {
								my $esign = $1;
								$genereg->{$genes->[$k]->locus_tag()}->{stimuli}->{$effectors->[$n]->effector_name()} = $esign*$sign;
							}
						}
					}	
				}
			}
		}
	}
	my $genedata = ["ID\tTFS\tSTIMULI\tCOMPOUNDS"];
	if (keys(%{$genereg}) > 0) {
		$parameters->{"gene list"} = join(";",keys(%{$genereg}));
		foreach my $gene (keys(%{$genereg})) {
			my $line = $gene."\t";
			if (defined($genereg->{$gene}->{tfs})) {
				my $item = "";
				foreach my $stim (keys(%{$genereg->{$gene}->{tfs}})) {
					if (length($item)) {
						$item .= "|";
					}
					$item .= $stim.":".$genereg->{$gene}->{tfs}->{$stim}.":1";
				}
				$line .= $item;
			}
			$line .= "\t";
			if (defined($genereg->{$gene}->{stimuli})) {
				my $item = "";
				foreach my $stim (keys(%{$genereg->{$gene}->{stimuli}})) {
					if (length($item)) {
						$item .= "|";
					}
					$item .= $stim.":".$genereg->{$gene}->{stimuli}->{$stim}.":1";
				}
				$line .= $item;
			}
			$line .= "\t";
			if (defined($genereg->{$gene}->{compounds})) {
				my $item = "";
				foreach my $stim (keys(%{$genereg->{$gene}->{compounds}})) {
					if (length($item)) {
						$item .= "|";
					}
					$item .= $stim.":".$genereg->{$gene}->{compounds}->{$stim}->[0];
					if ($genereg->{$gene}->{compounds}->{$stim}->[1] eq "standard") {
						$item .= ":1:1:1";
					} elsif ($genereg->{$gene}->{compounds}->{$stim}->[1] eq "stress") {
						$item .= ":0.5:0:1";
					} elsif ($genereg->{$gene}->{compounds}->{$stim}->[1] eq "extracellular") {
						$item .= ":1:0:0";
					}
				}
				$line .= $item;
			}
			push(@{$genedata},$line);
		}
	}
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."genes.tbl",$genedata);
	#Printing parameter file
	$parameters->{MFASolver} = "CPLEX";#TODO - need to remove
	my $exchange = "";
	foreach my $key (keys(%{$exchangehash})) {
		if (length($exchange) > 0) {
			$exchange .= ";";
		}
		foreach my $comp (keys(%{$exchangehash->{$key}})) {
			$exchange .= $key."[".$comp."]:".$exchangehash->{$key}->{$comp}->[0].":".$exchangehash->{$key}->{$comp}->[1];
		}
	}
	$parameters->{"exchange species"} = $exchange;
	my $paramData = [];
	foreach my $param (keys(%{$parameters})) {
		push(@{$paramData},$param."|".$parameters->{$param}."|Specialized parameters");
	}
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."SpecializedParameters.txt",$paramData);
	#Set StringDBFile.txt
	my $mfatkdir = $self->mfatoolkitDirectory();
	my $stringdb = [
		"Name\tID attribute\tType\tPath\tFilename\tDelimiter\tItem delimiter\tIndexed columns",
		"compound\tid\tSINGLEFILE\t\t".$directory."Compounds.tbl\tTAB\tSC\tid",
		"reaction\tid\tSINGLEFILE\t".$directory."reaction/\t".$directory."Reactions.tbl\tTAB\t|\tid",
		"cue\tNAME\tSINGLEFILE\t\t".$mfatkdir."../etc/MFAToolkit/cueTable.txt\tTAB\t|\tNAME",
		"media\tID\tSINGLEFILE\t".$directory."media/\t".$directory."media.tbl\tTAB\t|\tID;NAMES",
		"gene\tID\tSINGLEFILE\t".$directory."gene/\t".$directory."genes.tbl\tTAB\t|\tID;NAMES"		
	];
	
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."StringDBFile.txt",$stringdb);
	#Write shell script
	my $exec = [
		$self->mfatoolkitBinary().' resetparameter "MFA input directory" "'.$directory.'ReactionDB/" parameterfile "'.$directory.'SpecializedParameters.txt" LoadCentralSystem "'.$directory.'Model.tbl" > "'.$directory.'log.txt"'
	];
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."runMFAToolkit.sh",$exec);
	chmod 0775,$directory."runMFAToolkit.sh";
	$self->command($self->mfatoolkitBinary().' parameterfile "'.$directory.'SpecializedParameters.txt" LoadCentralSystem "'.$directory.'Model.tbl" > "'.$directory.'log.txt"');
}

=head3 setupFBAExperiments

Definition:
	string:FBA experiment filename = setupFBAExperiments());
Description:
	Converts phenotype simulation specs into an FBA experiment file for the MFAToolkit

=cut

sub process_expression_data {
	my ($self) = @_;
	my $booleanexp = $self->parameters()->{booleanexp};
	my $sample = $self->{_expsample};
	my $exphash = $sample;
	my $exp_scores = {};
	my $max_exp_score = 0;
	my $min_exp_score = -1;
	my $mdlrxns = $self->fbamodel()->modelreactions();
	my $inactiveList = ["bio1"];
	my $rxnhash = {};
	foreach my $mdlrxn (@{$mdlrxns}) {
		$rxnhash->{$mdlrxn->id()} = $mdlrxn;
		push(@{$inactiveList},$mdlrxn->id());
		# Maximal gene expression for a reaction
		my $rxn_score;
		foreach my $prot (@{$mdlrxn->modelReactionProteins()}) {
			# Minimal gene expression for a complex
			my $prot_score;
			foreach my $subunit (@{$prot->modelReactionProteinSubunits()}) {
				if (@{$subunit->features()} == 0) {
					next; # Not last, since there may be scores for other subunits
				}
				# Maximal gene expression for a subunit
				my $subunit_score;
				foreach my $feature (@{$subunit->features()}) {
					my $ftr_id = $feature->id();
					if (defined($exphash->{$feature->id()})) {
						my $ftr_score = $exphash->{$feature->id};
						if ($ftr_score > $max_exp_score) {
							$max_exp_score = $ftr_score;
						}
						if ($min_exp_score >= 0 && $ftr_score < $min_exp_score) {
						$min_exp_score = $ftr_score;
						}
						if (!defined($subunit_score) || $subunit_score <  $ftr_score) {
							$subunit_score = $ftr_score;
						}
					}
				}
				if (defined($subunit_score)) {
					if (!defined($prot_score) || $prot_score > $subunit_score) {
						$prot_score = $subunit_score;
					}
				}
			}
			if (defined($prot_score)) {
				if (!defined($rxn_score) || $rxn_score < $prot_score) {
					$rxn_score = $prot_score;
				}
			}
		}
		if (defined($rxn_score)) {
			$mdlrxn->{raw_exp_score} = $rxn_score;
			$exp_scores->{$mdlrxn->id()} = $rxn_score;
		}
	}
	# don't scale probabilities - they are already on a 0 to 1 scale
	if ($booleanexp eq "absolute") {
		my $sortedrxns = [keys(%{$exp_scores})];
		$sortedrxns = [sort { $exp_scores->{$a} <=> $exp_scores->{$b} } @{$sortedrxns}];
		my $multiple = @{$sortedrxns};
		if ($multiple > 0) {
			$multiple = 1/$multiple;
			for (my $i=0; $i < @{$sortedrxns}; $i++) {
				$exp_scores->{$sortedrxns->[$i]} = $i*$multiple;
				$rxnhash->{$sortedrxns->[$i]}->{norm_exp_score} = $exp_scores->{$sortedrxns->[$i]};
			}
		}
	}
	
	my $coef = {
		highexp => {},
		lowexp => {}
	};
	my $threshold = $self->parameters()->{expression_threshold_percentile};
	my $kappa = $self->parameters()->{kappa};
	my $high_expression_threshold = $threshold+$kappa;
	my $low_expression_threshold = $threshold-$kappa;

	for (my $i=0; $i < @{$inactiveList}; $i++) {
		if($inactiveList->[$i] eq "bio1"){
			$coef->{highexp}->{bio1} = 1;
		} elsif(exists($exp_scores->{$inactiveList->[$i]})){
			if($exp_scores->{$inactiveList->[$i]} <= $low_expression_threshold) {
				$rxnhash->{$inactiveList->[$i]}->{exp_state} = "off";
				my $penalty = ($threshold-$exp_scores->{$inactiveList->[$i]})/$threshold;
				if ($self->fbamodel()->getObject("modelreactions",$inactiveList->[$i])->direction() eq "=") {
					$coef->{lowexp}->{$inactiveList->[$i]}->{forward} = $penalty;
					$coef->{lowexp}->{$inactiveList->[$i]}->{"reverse"} = $penalty;
				} elsif ($self->fbamodel()->getObject("modelreactions",$inactiveList->[$i])->direction() eq ">") {
					$coef->{lowexp}->{$inactiveList->[$i]}->{forward} = $penalty;
				} elsif ($self->fbamodel()->getObject("modelreactions",$inactiveList->[$i])->direction() eq "<") {
					$coef->{lowexp}->{$inactiveList->[$i]}->{"reverse"} = $penalty;
				}
			} elsif ($exp_scores->{$inactiveList->[$i]} > $high_expression_threshold) {
				$rxnhash->{$inactiveList->[$i]}->{exp_state} = "on";
				my $penalty = ($exp_scores->{$inactiveList->[$i]}-$threshold)/$threshold;
				$coef->{highexp}->{$inactiveList->[$i]} = $penalty;
			}
		}
	}
	push(@{$self->{outputfiles}->{gapfillrxns}},"Lowexp reactions:".join("|",keys(%{$coef->{lowexp}})));
	push(@{$self->{outputfiles}->{gapfillrxns}},"Highexp reactions:".join("|",keys(%{$coef->{highexp}})));
	push(@{$self->{outputfiles}->{gapfillstats}},"Lowexp reactions:".keys(%{$coef->{lowexp}}));
	push(@{$self->{outputfiles}->{gapfillstats}},"Highexp reactions:".keys(%{$coef->{highexp}}));
	return $coef;
}

=head3 setupFBAExperiments

Definition:
	string:FBA experiment filename = setupFBAExperiments());
Description:
	Converts phenotype simulation specs into an FBA experiment file for the MFAToolkit

=cut

sub setupFBAExperiments {
	my ($self,$medialist) = @_;
	my $fbaExpFile = "none";
	if (defined($self->phenotypeset_ref()) && defined($self->phenotypeset())) {
		$self->parameters()->{"phenotype analysis"} = 1;
		my $phenoset = $self->phenotypeset();
		$fbaExpFile = "FBAExperiment.txt";
		my $phenoData = ["Label\tKO\tMedia\tGrowth"];
		my $mediaHash = {};
		my $tempMediaIndex = 1;
		my $phenos = $phenoset->phenotypes();
		for (my $i=0; $i < @{$phenos}; $i++) {
			my $pheno = $phenos->[$i];
			my $phenoko = "none";
			my $addnlCpds = $pheno->additionalcompound_refs();
			my $media = $pheno->media()->name();
			if (@{$addnlCpds} > 0) {
				if (!defined($mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))})) {
					$mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))} = $self->createTemporaryMedia({
						name => "Temp".$tempMediaIndex,
						media => $pheno->media(),
						additionalCpd => $pheno->additionalcompounds()
					});
					$tempMediaIndex++;
				}
				$media = $mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))}->name();
			} else {
				$mediaHash->{$media} = $pheno->media();
			}
			for (my $j=0; $j < @{$pheno->genekos()}; $j++) {
				if ($phenoko eq "none") {
					$phenoko = $pheno->genekos()->[$j]->id();
				} else {
					$phenoko .= ";".$pheno->genekos()->[$j]->id();
				}
			}
			$phenoko =~ s/\|/___/g;
			push(@{$phenoData},$pheno->id()."\t".$phenoko."\t".$media."\t".$pheno->normalizedGrowth());
		}
		foreach my $key (keys(%{$mediaHash})) {
			push(@{$medialist},$mediaHash->{$key});
		}
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($self->jobDirectory()."/".$fbaExpFile,$phenoData);
	}
	return $fbaExpFile;
}

=head3 createTemporaryMedia

Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Media = createTemporaryMedia({
		name => "Temp".$tempMediaIndex,
		media => $fbaSims->[$i]->media(),
		additionalCpd => $fbaSims->[$i]->additionalCpds()
	});
Description:
	Creates a temporary media conditions with the specified base media plus the specified additional compounds

=cut

sub createTemporaryMedia {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["name","media","additionalCpd"],{}, @_);
	my $newMedia = Bio::KBase::ObjectAPI::KBaseBiochem::Media->new({
		source_id => $args->{name},
		isDefined => 1,
		isMinimal => 0,
		id => $args->{name},
		name => $args->{name},
		type => "temporary"
	});
	$newMedia->parent($self->parent());
	my $cpds = $args->{media}->mediacompounds();
	my $cpdHash = {};
	foreach my $cpd (@{$cpds}) {
		$cpdHash->{$cpd->compound_ref()} = {
			compound_ref => $cpd->compound_ref(),
			concentration => $cpd->concentration(),
			maxFlux => $cpd->maxFlux(),
			minFlux => $cpd->minFlux(),
		};
	}
	foreach my $cpd (@{$args->{additionalCpd}}) {
		$cpdHash->{$cpd->_reference()} = {
			compound_ref => $cpd->_reference(),
			concentration => 0.001,
			maxFlux => 100,
			minFlux => -100,
		};
	}
	foreach my $cpd (keys(%{$cpdHash})) {
		$newMedia->add("mediacompounds",$cpdHash->{$cpd});	
	}
	return $newMedia;
}

=head3 export

Definition:
	string = Bio::KBase::ObjectAPI::KBaseFBA::FBA->export({
		format => readable/html/json
	});
Description:
	Exports media data to the specified format.

=cut

sub export {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["format"], {}, @_);
	if (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	}
	Bio::KBase::ObjectAPI::utilities::error("Unrecognized type for export: ".$args->{format});
}

=head3 buildFromOptSolution

Definition:
	ModelSEED::MS::FBAResults = ModelSEED::MS::FBAResults->runFBA();
Description:
	Runs the FBA study described by the fomulation and returns a typed object with the results

=cut

sub buildFromOptSolution {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["LinOptSolution"],{}, @_);
	my $solvars = $args->{LinOptSolution}->solutionvariables();
	for (my $i=0; $i < @{$solvars}; $i++) {
		my $var = $solvars->[$i];
		my $type = $var->variable()->type();
		if ($type eq "flux" || $type eq "forflux" || $type eq "revflux" || $type eq "fluxuse" || $type eq "forfluxuse" || $type eq "revfluxuse") {
			$self->integrateReactionFluxRawData($var);
		} elsif ($type eq "biomassflux") {
			$self->add("FBABiomassVariables",{
				biomass_ref => $var->variable()->entity_ref(),
				variableType => $type,
				lowerBound => $var->variable()->lowerBound(),
				upperBound => $var->variable()->upperBound(),
				min => $var->min(),
				max => $var->max(),
				value => $var->value()
			});
		} elsif ($type eq "drainflux" || $type eq "fordrainflux" || $type eq "revdrainflux" || $type eq "drainfluxuse" || $type eq "fordrainfluxuse" || $type eq "revdrainfluxuse") {
			$self->integrateCompoundFluxRawData($var);
		}
	}	
}

=head3 integrateReactionFluxRawData

Definition:
	void ModelSEED::MS::FBAResults->integrateReactionFluxRawData();
Description:
	Translates a raw flux or flux use variable into a reaction variable with decomposed reversible reactions recombined

=cut

sub integrateReactionFluxRawData {
	my ($self,$solVar) = @_;
	my $type = "flux";
	my $max = 0;
	my $min = 0;
	my $var = $solVar->variable();
	if ($var->type() =~ m/use$/) {
		$max = 1;
		$min = -1;
		$type = "fluxuse";	
	}
	my $fbavar = $self->queryObject("FBAReactionVariables",{
		modelreaction_ref => $var->entity_ref(),
		variableType => $type
	});
	if (!defined($fbavar)) {
		$fbavar = $self->add("FBAReactionVariables",{
			modelreaction_ref => $var->entity_ref(),
			variableType => $type,
			lowerBound => $min,
			upperBound => $max,
			min => $min,
			max => $max,
			value => 0
		});
	}
	if ($var->type() eq $type) {
		$fbavar->upperBound($var->upperBound());
		$fbavar->lowerBound($var->lowerBound());
		$fbavar->max($solVar->max());
		$fbavar->min($solVar->min());
		$fbavar->value($solVar->value());
	} elsif ($var->type() eq "for".$type) {
		if ($var->upperBound() > 0) {
			$fbavar->upperBound($var->upperBound());	
		}
		if ($var->lowerBound() > 0) {
			$fbavar->lowerBound($var->lowerBound());
		}
		if ($solVar->max() > 0) {
			$fbavar->max($solVar->max());
		}
		if ($solVar->min() > 0) {
			$fbavar->min($solVar->min());
		}
		if ($solVar->value() > 0) {
			$fbavar->value($fbavar->value() + $solVar->value());
		}
	} elsif ($var->type() eq "rev".$type) {
		if ($var->upperBound() > 0) {
			$fbavar->lowerBound((-1*$var->upperBound()));
		}
		if ($var->lowerBound() > 0) {
			$fbavar->upperBound((-1*$var->lowerBound()));
		}
		if ($solVar->max() > 0) {
			$fbavar->min((-1*$solVar->max()));
		}
		if ($solVar->min() > 0) {
			$fbavar->max((-1*$solVar->min()));
		}
		if ($solVar->value() > 0) {
			$fbavar->value($fbavar->value() - $solVar->value());
		}
	}
}

=head3 integrateCompoundFluxRawData

Definition:
	void ModelSEED::MS::FBAResults->integrateCompoundFluxRawData();
Description:
	Translates a raw flux or flux use variable into a compound variable with decomposed reversible reactions recombined

=cut

sub integrateCompoundFluxRawData {
	my ($self,$solVar) = @_;
	my $var = $solVar->variable();
	my $type = "drainflux";
	my $max = 0;
	my $min = 0;
	if ($var->type() =~ m/use$/) {
		$max = 1;
		$min = -1;
		$type = "drainfluxuse";	
	}
	my $fbavar = $self->queryObject("FBACompoundVariables",{
		modelcompound_ref => $var->entity_ref(),
		variableType => $type
	});
	if (!defined($fbavar)) {
		$fbavar = $self->add("FBACompoundVariables",{
			modelcompound_ref => $var->entity_ref(),
			variableType => $type,
			lowerBound => $min,
			upperBound => $max,
			min => $min,
			max => $max,
			value => 0
		});
	}
	if ($var->type() eq $type) {
		$fbavar->upperBound($var->upperBound());
		$fbavar->lowerBound($var->lowerBound());
		$fbavar->max($solVar->max());
		$fbavar->min($solVar->min());
		$fbavar->value($solVar->value());
	} elsif ($var->type() eq "for".$type) {
		if ($var->upperBound() > 0) {
			$fbavar->upperBound($var->upperBound());	
		}
		if ($var->lowerBound() > 0) {
			$fbavar->lowerBound($var->lowerBound());
		}
		if ($solVar->max() > 0) {
			$fbavar->max($solVar->max());
		}
		if ($solVar->min() > 0) {
			$fbavar->min($solVar->min());
		}
		if ($solVar->value() > 0) {
			$fbavar->value($fbavar->value() + $solVar->value());
		}
	} elsif ($var->type() eq "rev".$type) {
		if ($var->upperBound() > 0) {
			$fbavar->lowerBound((-1*$var->upperBound()));
		}
		if ($var->lowerBound() > 0) {
			$fbavar->upperBound((-1*$var->lowerBound()));
		}
		if ($solVar->max() > 0) {
			$fbavar->min((-1*$solVar->max()));	
		}
		if ($solVar->min() > 0) {
			$fbavar->max((-1*$solVar->min()));
		}
		if ($solVar->value() > 0) {
			$fbavar->value($fbavar->value() - $solVar->value());
		}
	}
}

=head3 loadMFAToolkitResults
Definition:
	void ModelSEED::MS::FBAResult->loadMFAToolkitResults();
Description:
	Loads problem result data from job directory

=cut

sub loadMFAToolkitResults {
	my ($self) = @_;
	$self->parseProblemReport();
	$self->parseBiomassRemovals();
	$self->parseGapfillingOutput();
	$self->parseFluxFiles();
	$self->parseMetaboliteProduction();
	$self->parseFBAPhenotypeOutput();
	$self->parseMinimalMediaResults();
	$self->parseCombinatorialDeletionResults();
	$self->parseFVAResults();
	$self->parsePROMResult();
	$self->parseTintleResult();
	$self->parseOutputFiles();
	$self->parseReactionMinimization();
	$self->parseMFALog();
}

=head3 parseBiomassRemovals
Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBA->parseBiomassRemovals();
Description:
	Parses files with flux data

=cut

sub parseBiomassRemovals {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/BiomassRemovals.txt") {
		my $data = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/BiomassRemovals.txt");
		if (@{$data} == 0 || (@{$data} == 1 && length($data->[0]) == 0)) {
			if ($self->parameters()->{add_external_rxns} == 1) {
				print "Model failed to be gapfilled for growth, and we could not identify the biomass components that could not be produced!\nIf this is a published or translated model, try rerunning gapfilling using the original published model as a source model.\n";
			} else {
				print "Model failed to grow, and we could not identify the biomass components that could not be produced!\nRun gapfilling on this model with the same media and objective, then try FBA again!\n";
			}
		} else {
			print "Model failed to grow. Could not produce the following biomass compounds:\n";
			for (my $i=0; $i < @{$data}; $i++) {
				if (length($data->[$i]) > 0 && $data->[$i] =~ m/^(bio\d+)_(.+)_([a-z]+\d+)$/) {
					my $biomass = $1;
					my $compound = $2."_".$3;
					push(@{$self->biomassRemovals()->{$biomass}},$compound);
					my $cpdobj = $self->fbamodel()->getObject("modelcompounds",$compound);
					if (defined($cpdobj)) {
						print $compound."\t".$cpdobj->name()."\n";
					} else {
						print $compound."\n";
					}
				}
			}
		}
	}
}

=head3 parseFluxFiles
Definition:
	void ModelSEED::MS::Model->parseFluxFiles();
Description:
	Parses files with flux data

=cut

sub parseFluxFiles {
	my ($self) = @_;
	$self->objectiveValue(0);
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/SolutionCompoundData.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/SolutionCompoundData.txt",";");
		my $drainCompartmentColumns = {};
		my $compoundColumn = -1;
		for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
			if ($tbl->{headings}->[$i] eq "Compound") {
				$compoundColumn = $i;
			} elsif ($tbl->{headings}->[$i] =~ m/Drain\[([a-zA-Z0-9]+)\]/) {
				$drainCompartmentColumns->{$1} = $i;
			}
		}
		my $mediaCpdHash = {};
		my $mediaCpds = $self->media()->mediacompounds();
		for (my $i=0; $i < @{$mediaCpds}; $i++) {
			$mediaCpdHash->{$mediaCpds->[$i]->compound()->id()} = $mediaCpds->[$i];
		}
		if ($compoundColumn != -1) {
			# Create a map from rxn id to bounds.
			my $cpdid2bound = {};
			foreach my $bound (@{$self->FBACompoundBounds()}) {
				$cpdid2bound->{$bound->modelcompound()->id()} = {
					lower => $bound->lowerBound(),
					upper => $bound->upperBound()
				}
			}
			foreach my $row (@{$tbl->{data}}) {
				foreach my $comp (keys(%{$drainCompartmentColumns})) {
					if ($row->[$drainCompartmentColumns->{$comp}] ne "none") {
						my $mdlcpd = $self->fbamodel()->getObject("modelcompounds",$row->[$compoundColumn]);
						if (defined($mdlcpd)) {
							my $value = $row->[$drainCompartmentColumns->{$comp}];
							if (abs($value) < 0.000000001) {
								$value = 0;
							}
							my $lower = $self->defaultMinDrainFlux();
							my $upper = $self->defaultMaxDrainFlux();
							if ($comp eq "e" && defined($mediaCpdHash->{$mdlcpd->compound()->id()})) {
								$upper = $mediaCpdHash->{$mdlcpd->compound()->id()}->maxFlux();
								$lower = $mediaCpdHash->{$mdlcpd->compound()->id()}->minFlux();
							} elsif (exists $cpdid2bound->{$mdlcpd->id()}) {
								$lower = $cpdid2bound->{$mdlcpd->id()}->{lower};
								$upper = $cpdid2bound->{$mdlcpd->id()}->{upper};
							}
							$self->add("FBACompoundVariables",{
								modelcompound_ref => "~/fbamodel/modelcompounds/id/".$mdlcpd->id(),
								variableType => "drainflux",
								value => $value,
								lowerBound => $lower,
								upperBound => $upper,
								min => $lower,
								max => $upper,
								class => "unknown"
							});
						}
					}
				}
			}
		}
	}
	if (-e $directory."/MFAOutput/SolutionReactionData.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/SolutionReactionData.txt",";");
		my $fluxCompartmentColumns = {};
		my $reactionColumn = -1;
		for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
			if ($tbl->{headings}->[$i] eq "Reaction") {
				$reactionColumn = $i;
			} elsif ($tbl->{headings}->[$i] =~ m/Flux\[([a-zA-Z0-9]+)\]/) {
				$fluxCompartmentColumns->{$1} = $i;
			}
		}
		if ($reactionColumn != -1) {
			# Create a map from rxn id to bounds.
			my $rxnid2bound = {};
			foreach my $bound (@{$self->FBAReactionBounds()}) {
				$rxnid2bound->{$bound->modelreaction()->msid()} = {
					lower => $bound->lowerBound(),
					upper => $bound->upperBound()
				}
			}

			foreach my $row (@{$tbl->{data}}) {
				foreach my $comp (keys(%{$fluxCompartmentColumns})) {
					if ($row->[$fluxCompartmentColumns->{$comp}] ne "none") {
						my $value = $row->[$fluxCompartmentColumns->{$comp}];
						if ($row->[$reactionColumn] eq "Objective") {
							$self->objectiveValue($value);
						} else {
							my $mdlrxn = $self->fbamodel()->getObject("modelreactions",$row->[$reactionColumn]);
							if (defined($mdlrxn)) {
								if (abs($value) < 0.000000001) {
									$value = 0;
								}
								my $lower = -1*$self->defaultMaxFlux();
								my $upper = $self->defaultMaxFlux();
								if ($mdlrxn->direction() eq "<") {
									$upper = 0;
								} elsif ($mdlrxn->direction() eq ">") {
									$lower = 0;
								}
								if (exists $rxnid2bound->{$mdlrxn->id()}) {
									$lower = $rxnid2bound->{$mdlrxn->id()}->{lower};
									$upper = $rxnid2bound->{$mdlrxn->id()}->{upper};
								}
								my $rxnvar = $self->add("FBAReactionVariables",{
									modelreaction_ref => "~/fbamodel/modelreactions/id/".$mdlrxn->id(),
									variableType => "flux",
									value => $value,
									lowerBound => $lower,
									upperBound => $upper,
									min => $lower,
									max => $upper,
									class => "unknown"
								});
								if (defined($mdlrxn->{raw_exp_score})) {
									$rxnvar->exp_state("unknown");
									$rxnvar->expression($mdlrxn->{raw_exp_score});
									$rxnvar->scaled_exp($mdlrxn->{raw_exp_score});
									if (defined($mdlrxn->{norm_exp_score})) {
										$rxnvar->scaled_exp($mdlrxn->{norm_exp_score});
									}
									if (defined($mdlrxn->{exp_state})) {
										$rxnvar->exp_state($mdlrxn->{exp_state});
									}
								}
							} else {
								my $biorxn = $self->fbamodel()->getObject("biomasses",$row->[$reactionColumn]);
								if (defined($biorxn)) {
									if (abs($value) < 0.000000001) {
										$value = 0;
									}
									my $lower = 0;
									my $upper = $self->defaultMaxFlux();
									$self->add("FBABiomassVariables",{
										biomass_ref => "~/fbamodel/biomasses/id/".$biorxn->id(),
										variableType => "biomassflux",
										value => $value,
										lowerBound => $lower,
										upperBound => $upper,
										min => $lower,
										max => $upper,
										class => "unknown"
									});
								} elsif (abs($value) > 0.000000001) {
									my $queryid = $row->[$reactionColumn];
									if ($queryid =~ m/(.+)\d+$/) {
										$queryid = $1;
									}
									my $tmprxn = $self->fbamodel()->template()->queryObject("reactions",{id => $queryid});
									if (defined($tmprxn)) {
										my $lower = -1*$self->defaultMaxFlux();
										my $upper = $self->defaultMaxFlux();
										if ($tmprxn->GapfillDirection() eq "<") {
											$upper = 0;
										} elsif ($tmprxn->GapfillDirection() eq ">") {
											$lower = 0;
										}
										if (exists $rxnid2bound->{$tmprxn->id()}) {
											$lower = $rxnid2bound->{$tmprxn->id()}->{lower};
											$upper = $rxnid2bound->{$tmprxn->id()}->{upper};
										}
										my $rxnvar = $self->add("FBAReactionVariables",{
											modelreaction_ref => $tmprxn->_reference(),
											variableType => "gapfillflux",
											value => $value,
											lowerBound => $lower,
											upperBound => $upper,
											min => $lower,
											max => $upper,
											class => "unknown"
										});
									} elsif (defined($self->{_source_model})) {
										my $srcrxn = $self->{_source_model}->getObject("modelreactions",$row->[$reactionColumn]);
										if (defined($srcrxn)) {
											my $lower = -1*$self->defaultMaxFlux();
											my $upper = $self->defaultMaxFlux();
											if ($srcrxn->direction() eq "<") {
												$upper = 0;
											} elsif ($srcrxn->direction() eq ">") {
												$lower = 0;
											}
											if (exists $rxnid2bound->{$srcrxn->id()}) {
												$lower = $rxnid2bound->{$srcrxn->id()}->{lower};
												$upper = $rxnid2bound->{$srcrxn->id()}->{upper};
											}
											my $rxnvar = $self->add("FBAReactionVariables",{
												modelreaction_ref => $srcrxn->_reference(),
												variableType => "srcgapfillflux",
												value => $value,
												lowerBound => $lower,
												upperBound => $upper,
												min => $lower,
												max => $upper,
												class => "unknown"
											});
										} else {
											#print STDERR "Could not find flux reaction ".$row->[$reactionColumn]."\n";
										}
									} else {
										#print STDERR "Could not find flux reaction ".$row->[$reactionColumn]."\n";
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

=head3 parseFBAPhenotypeOutput
Definition:
	void ModelSEED::MS::Model->parseFBAPhenotypeOutput();
Description:
	Parses output file generated by FBAPhenotypeSimulation

=cut

sub parseFBAPhenotypeOutput {
	my ($self) = @_;
	my $directory = $self->jobDirectory();

	# Other types of analyses that do not involve phenotype data (e.g. reaction sensitivity) use the same
	# output file. So we need to check that the data we need exists.
	if ( !defined($self->phenotypeset_ref()) || !defined($self->phenotypeset())) {
		return;
	}

	if (-e $directory."/FBAExperimentOutput.txt") {
		#Loading file results into a hash
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/FBAExperimentOutput.txt","\t");
		if (!defined($tbl->{data}->[0]->[5])) {
			return Bio::KBase::ObjectAPI::utilities::ERROR("output file did not contain necessary data");
		}
		$self->{_tempphenosim} = Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulationSet->new({
			id => $self->{_phenosimid},
			fbamodel_ref => $self->fbamodel()->_reference(),
			phenotypeset_ref => $self->phenotypeset_ref(),
			phenotypeSimulations => []
		});
		$self->{_tempphenosim}->parent($self->parent());
		$self->phenotypesimulationset_ref("");
		$self->phenotypesimulationset($self->{_tempphenosim});
		my $phenoOutputHash;
		foreach my $row (@{$tbl->{data}}) {
			if (defined($row->[5])) {
				my $fraction = 0;
				if ($row->[5] < 1e-7) {
					$row->[5] = 0;	
				}
				if ($row->[4] < 1e-7) {
					$row->[4] = 0;	
				} else {
					$fraction = $row->[5]/$row->[4];	
				}
				$phenoOutputHash->{$row->[0]} = {
					simulatedGrowth => $row->[5],
					wildtype => $row->[4],
					simulatedGrowthFraction => $fraction,
					noGrowthCompounds => [],
					dependantReactions => [],
					dependantGenes => [],
					fluxes => {},
					phenoclass => "UN",
					phenotype_ref => $self->phenotypeset()->_reference()."/phenotypes/id/".$row->[0]
				};
				if (defined($self->parameters()->{"Perform gap filling"}) && $self->parameters()->{"Perform gap filling"} == 1) {
					if ($row->[9] =~ m/_[a-z]+\d+$/) {
						$phenoOutputHash->{$row->[0]}->{gapfilledReactions} = [split(/;/,$row->[9])];
						$phenoOutputHash->{$row->[0]}->{numGapfilledReactions} = @{$phenoOutputHash->{$row->[0]}->{gapfilledReactions}};
					}
				}	
				if (defined($row->[6]) && length($row->[6]) > 0) {
					chomp($row->[6]);
					$phenoOutputHash->{$row->[0]}->{noGrowthCompounds} = [split(/;/,$row->[6])];
				}
				if (defined($row->[7]) && length($row->[7]) > 0) {
					$phenoOutputHash->{$row->[0]}->{dependantReactions} = [split(/;/,$row->[7])];
				}
				if (defined($row->[8]) && length($row->[8]) > 0) {
					$phenoOutputHash->{$row->[0]}->{dependantReactions} = [split(/;/,$row->[8])];
				}
				if (defined($row->[10]) && length($row->[10]) > 0) {
					my @fluxList = split(/;/,$row->[10]);
					for (my $j=0; $j < @fluxList; $j++) {
						my @temp = split(/:/,$fluxList[$j]);
						$phenoOutputHash->{$row->[0]}->{fluxes}->{$temp[0]} = $temp[1];
					}
				}
			}
		}
		#Scanning through all phenotype data in FBAFormulation and creating corresponding phenotype result objects
		my $phenos = $self->phenotypeset()->phenotypes();
		for (my $i=0; $i < @{$phenos}; $i++) {
			my $pheno = $phenos->[$i];
			if (defined($phenoOutputHash->{$pheno->id()})) {
				$phenoOutputHash->{$pheno->id()}->{id} = $pheno->id().".sim";
				if (defined($pheno->normalizedGrowth())) {
					if ($pheno->normalizedGrowth() > 0.0001) {
						if ($phenoOutputHash->{$pheno->id()}->{simulatedGrowthFraction} > 0) {
							$phenoOutputHash->{$pheno->id()}->{phenoclass} = "CP";
						} else {
							$phenoOutputHash->{$pheno->id()}->{phenoclass} = "FN";
						}
					} else {
						if ($phenoOutputHash->{$pheno->id()}->{simulatedGrowthFraction} > 0) {
							$phenoOutputHash->{$pheno->id()}->{phenoclass} = "FP";
						} else {
							$phenoOutputHash->{$pheno->id()}->{phenoclass} = "CN";
						}
					}
				}
				$self->{_tempphenosim}->add("phenotypeSimulations",$phenoOutputHash->{$pheno->id()});	
			}
		}
	}
}

=head3 parseMetaboliteProduction
Definition:
	void ModelSEED::MS::Model->parseMetaboliteProduction();
Description:
	Parses metabolite production file

=cut

sub parseMetaboliteProduction {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/MetaboliteProduction.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/MetaboliteProduction.txt",";");
		foreach my $row (@{$tbl->{data}}) {
			if (defined($row->[1])) {
				my $cpd = $self->fbamodel()->getObject("modelcompounds",$row->[0]);
				if (defined($cpd)) {
					$self->add("FBAMetaboliteProductionResults",{
						modelcompound_ref => "~/fbamodel/modelcompounds/id/".$cpd->id(),
						maximumProduction => -1*$row->[1]
					});
				}
			}
		}
		return 1;
	}
	return 0;
}

=head3 parseProblemReport
Definition:
	void ModelSEED::MS::Model->parseProblemReport();
Description:
	Parses problem report

=cut

sub parseProblemReport {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/ProblemReport.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/ProblemReport.txt",";");
		my $column;
		for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
			if ($tbl->{headings}->[$i] eq "Objective") {
				$column = $i;
				last;
			}
		}
		my $row = 0;
		while (defined($tbl->{data}->[$row]->[$column])) {
			$row++;
		}
		$row--;
		if (defined($tbl->{data}->[$row]) && defined($tbl->{data}->[$row]->[$column])) {
			$self->objectiveValue($tbl->{data}->[$row]->[$column]);
		}
		return 1;
	}
	return 0;
}

=head3 parseMinimalMediaResults
Definition:
	void ModelSEED::MS::Model->parseMinimalMediaResults();
Description:
	Parses minimal media result file

=cut

sub parseMinimalMediaResults {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MinimalMediaSolutions.txt") {
		my $data = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/MinimalMediaSolutions.txt");
		my $essIDs = [];
		my $essCpds;
		my $essuuids = [];
		if ($data->[0] =~ m/Essentials:(.+)/) {
			print "Essentials:\n";
			$essIDs = [split(/\t/,$1)];
			for (my $i=0; $i < @{$essIDs};$i++) {
				if ($essIDs->[$i] =~ m/(.+)_(.+)$/) {
					$essIDs->[$i] = $1;
				}
				my $cpd = $self->template()->biochemistry()->getObject("compounds",$essIDs->[$i]);
				if (defined($cpd)) {
					print "\t",$cpd->id(), "\t", $cpd->name(), "\n";
					push(@{$essCpds},$cpd);
					push(@{$essuuids},$cpd->_reference());	
				}
				else {
					print "\t", $essIDs->[$i], "\n";
				}
			}
		}
		my $count = 1;
		my $mediaresults = [{
			essentialNutrient_refs => $essuuids,
			optionalNutrient_refs => []
		}];
		for (my $i=1; $i < @{$data}; $i++) {
			print "Optionals:\n";
			my $base = [];
			push(@{$base},@{$mediaresults->[0]->{optionalNutrient_refs}});
			if ($data->[$i] =~ m/\d+:(.+)/) {
				my $optsets = [split(/\t/,$1)];
				for (my $j=0; $j < @{$optsets}; $j++) {
					print "Set $j\n";
					my $group = [split(/;/,$optsets->[$j])];
					for (my $k = 0; $k < @{$group}; $k++) {
						if ($group->[$k] =~ m/(.+)_(.+)$/) {
							$group->[$k] = $1;
						}
						my $cpd = $self->template()->biochemistry()->getObject("compounds",$group->[$k]);
						if (defined($cpd)) {
							print "\t",$cpd->id(), "\t", $cpd->name(), "\n";
							$group->[$k] = $cpd->_reference();	
						}
						else {
							print "\t", $group->[$k], "\t", $group->[$k], "\n";
						}
					}
					if ($j == 0) {
						for (my $k = 0; $k < @{$mediaresults}; $k++) {
							push(@{$mediaresults->[$k]->{optionalNutrient_refs}},@{$group});
						}
					} else {
						my $newoptarray = [];
						push(@{$mediaresults},{
							essentialNutrient_refs => $essuuids,
							optionalNutrient_refs => $newoptarray
						});
						push(@{$newoptarray},@{$base});
						push(@{$newoptarray},@{$group});
					}
				}
			}
		}
		for (my $i=0; $i < @{$mediaresults}; $i++) {
			$self->add("FBAMinimalMediaResults",$mediaresults->[$i])
		}
	}
}

=head3 parseCombinatorialDeletionResults
Definition:
	void ModelSEED::MS::Model->parseCombinatorialDeletionResults();
Description:
	Parses combinatorial deletion results

=cut

sub parseCombinatorialDeletionResults {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/CombinationKO.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/CombinationKO.txt","\t");
		foreach my $row (@{$tbl->{data}}) {
			if (defined($row->[1])) {
				my $array = [split(/;/,$row->[0])];
				my $geneArray = [];
				for (my $i=0; $i < @{$array}; $i++) {
					my $geneID = $array->[$i];
					$geneID =~ s/___/|/;
					my $gene = $self->genome()->getObject("features",$geneID);
					if (defined($gene)) {
						push(@{$geneArray},$gene->_reference());	
					}
				}
				if (@{$geneArray} > 0) {
					$self->add("FBADeletionResults",{
						feature_refs => $geneArray,
						growthFraction => $row->[1]
					});
				}
			}
		}
		return 1;
	}
	return 0;
}

=head3 parseFVAResults
Definition:
	void ModelSEED::MS::Model->parseFVAResults();
Description:
	Parses FVA results

=cut

sub parseFVAResults {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/TightBoundsReactionData.txt" && -e $directory."/MFAOutput/TightBoundsCompoundData.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/TightBoundsReactionData.txt",";",1);
		if (defined($tbl->{headings}) && defined($tbl->{data})) {
			my $idColumn = -1;
			my $vartrans = {
				FLUX => ["flux",-1,-1],
				DELTAGG_ENERGY => ["deltag",-1,-1],
				REACTION_DELTAG_ERROR => ["deltagerr",-1,-1]
			};
			my $deadRxn = {};
			if (-e $directory."/DeadReactions.txt") {
				my $inputArray = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/DeadReactions.txt","");
				if (defined($inputArray)) {
					for (my $i=0; $i < @{$inputArray}; $i++) {
						$deadRxn->{$inputArray->[$i]} = 1;
					}
				}
			}
			for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
				if ($tbl->{headings}->[$i] eq "DATABASE ID") {
					$idColumn = $i;
				} else {
					foreach my $vartype (keys(%{$vartrans})) {
						if ($tbl->{headings}->[$i] eq "Max ".$vartype) {
							$vartrans->{$vartype}->[2] = $i;
							last;
						} elsif ($tbl->{headings}->[$i] eq "Min ".$vartype) {
							$vartrans->{$vartype}->[1] = $i;
							last;
						}
					}
				}
			}
			if ($idColumn >= 0) {
				for (my $i=0; $i < @{$tbl->{data}}; $i++) {
					my $row = $tbl->{data}->[$i];
					if (defined($row->[$idColumn])) {
						my $mdlrxn = $self->fbamodel()->getObject("modelreactions",$row->[$idColumn]);
						if (defined($mdlrxn)) {
							foreach my $vartype (keys(%{$vartrans})) {
								if ($vartrans->{$vartype}->[1] != -1 && $vartrans->{$vartype}->[2] != -1) {
									my $min = $row->[$vartrans->{$vartype}->[1]];
									my $max = $row->[$vartrans->{$vartype}->[2]];
									if (abs($min) < 0.000000001) {
										$min = 0;	
									}
									if (abs($max) < 0.000000001) {
										$max = 0;	
									}
									my $fbaRxnVar = $self->queryObject("FBAReactionVariables",{
										modelreaction_ref => "~/fbamodel/modelreactions/id/".$mdlrxn->id(),
										variableType => $vartrans->{$vartype}->[0],
									});
									if (!defined($fbaRxnVar)) {
										$fbaRxnVar = $self->add("FBAReactionVariables",{
											modelreaction_ref => "~/fbamodel/modelreactions/id/".$mdlrxn->id(),
											variableType => $vartrans->{$vartype}->[0],
												upperBound => 0.0,
												lowerBound => 0.0,
												value => 0.0
										});	
									}
									$fbaRxnVar->min($min);
									$fbaRxnVar->max($max);
									if (defined($deadRxn->{$row->[$idColumn]})) {
										$fbaRxnVar->class("Dead");
									} elsif ($fbaRxnVar->min() > 0) {
										$fbaRxnVar->class("Positive");
									} elsif ($fbaRxnVar->max() < 0) {
										$fbaRxnVar->class("Negative");
									} elsif ($fbaRxnVar->min() == 0 && $fbaRxnVar->max() > 0) {
										$fbaRxnVar->class("Positive variable");
									} elsif ($fbaRxnVar->max() == 0 && $fbaRxnVar->min() < 0) {
										$fbaRxnVar->class("Negative variable");
									} elsif ($fbaRxnVar->max() == 0 && $fbaRxnVar->min() == 0) {
										$fbaRxnVar->class("Blocked");
									} else {
										$fbaRxnVar->class("Variable");
									}
								}
							}
						}
					}
				}
			}
		}
		$tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/TightBoundsCompoundData.txt",";",1);
		if (defined($tbl->{headings}) && defined($tbl->{data})) {
			my $idColumn = -1;
			my $compColumn = -1;
			my $vartrans = {
				DRAIN_FLUX => ["drainflux",-1,-1],
				LOG_CONC => ["conc",-1,-1],
				DELTAGF_ERROR => ["deltagferr",-1,-1],
				POTENTIAL => ["potential",-1,-1]
			};
			my $deadCpd = {};
			my $deadendCpd = {};
			if (-e $directory."/DeadMetabolites.txt") {
				my $inputArray = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/DeadMetabolites.txt","");
				if (defined($inputArray)) {
					for (my $i=0; $i < @{$inputArray}; $i++) {
						$deadCpd->{$inputArray->[$i]} = 1;
					}
				}
			}
			if (-e $directory."/DeadEndMetabolites.txt") {
				my $inputArray = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/DeadEndMetabolites.txt","");
				if (defined($inputArray)) {
					for (my $i=0; $i < @{$inputArray}; $i++) {
						$deadendCpd->{$inputArray->[$i]} = 1;
					}
				}
			}
			for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
				if ($tbl->{headings}->[$i] eq "DATABASE ID") {
					$idColumn = $i;
				} elsif ($tbl->{headings}->[$i] eq "COMPARTMENT") {
					$compColumn = $i;
				} else {
					foreach my $vartype (keys(%{$vartrans})) {
						if ($tbl->{headings}->[$i] eq "Max ".$vartype) {
							$vartrans->{$vartype}->[2] = $i;
						} elsif ($tbl->{headings}->[$i] eq "Min ".$vartype) {
							$vartrans->{$vartype}->[1] = $i;
						}
					}
				}
			}
			if ($idColumn >= 0) {
				for (my $i=0; $i < @{$tbl->{data}}; $i++) {
					my $row = $tbl->{data}->[$i];
					if (defined($row->[$idColumn])) {
						my $mdlcpd = $self->fbamodel()->getObject("modelcompounds",$row->[$idColumn]);
						if (defined($mdlcpd)) {
							foreach my $vartype (keys(%{$vartrans})) {
								if ($vartrans->{$vartype}->[1] != -1 && $vartrans->{$vartype}->[2] != -1) {
									my $min = $row->[$vartrans->{$vartype}->[1]];
									my $max = $row->[$vartrans->{$vartype}->[2]];
									if ($min != 10000000) {
										if (abs($min) < 0.000000001) {
											$min = 0;	
										}
										if (abs($max) < 0.000000001) {
											$max = 0;	
										}
										my $fbaCpdVar = $self->queryObject("FBACompoundVariables",{
											modelcompound_ref => "~/fbamodel/modelcompounds/id/".$mdlcpd->id(),
											variableType => $vartrans->{$vartype}->[0],
										});
										if (!defined($fbaCpdVar)) {
											$fbaCpdVar = $self->add("FBACompoundVariables",{
												modelcompound_ref => "~/fbamodel/modelcompounds/id/".$mdlcpd->id(),
												variableType => $vartrans->{$vartype}->[0],
												upperBound => 0.0,
												lowerBound => 0.0,
												value => 0.0
											});
										}
										$fbaCpdVar->min($min);
										$fbaCpdVar->max($max);
										if (defined($deadCpd->{$row->[$idColumn]})) {
											$fbaCpdVar->class("Dead");
										} elsif (defined($deadendCpd->{$row->[$idColumn]})) {
											$fbaCpdVar->class("Deadend");
										} elsif ($fbaCpdVar->min() > 0) {
											$fbaCpdVar->class("Positive");
										} elsif ($fbaCpdVar->max() < 0) {
											$fbaCpdVar->class("Negative");
										} elsif ($fbaCpdVar->min() == 0 && $fbaCpdVar->max() > 0) {
											$fbaCpdVar->class("Positive variable");
										} elsif ($fbaCpdVar->max() == 0 && $fbaCpdVar->min() < 0) {
											$fbaCpdVar->class("Negative variable");
										} elsif ($fbaCpdVar->max() == 0 && $fbaCpdVar->min() == 0) {
											$fbaCpdVar->class("Blocked");
										} else {
											$fbaCpdVar->class("Variable");
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

=head3 parsePROMResult

Definition:
	void parsePROMResult();
Description:
	Parses PROM result file.

=cut

sub parsePROMResult {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/PROMResult.txt") {
		#Loading file results into a hash
		my $data = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/PROMResult.txt");
		if (@{$data} < 3) {
			return Bio::KBase::ObjectAPI::utilities::ERROR("output file did not contain necessary data");
		}
		my $promOutputHash;
		foreach my $row (@{$data}) {
			my @line = split /\t/, $row;
			$promOutputHash->{$line[0]} = $line[1] if ($line[0] =~ /alpha|beta|objectFraction/);
		}		
		$self->add("FBAPromResults",$promOutputHash);				   
		return 1;
	}
	return 0;
}

=head3 parseTintleResult

Definition:
	void parseTintleResult();
Description:
	Parses Tintle2014 result file.

=cut

sub parseTintleResult {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/GeneActivityStateFBAResult.txt") {
		#Loading file results into a hash
		my $table = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/GeneActivityStateFBAResult.txt", "\t", 0);
		my $tintleOutputHash;

		foreach my $row (@{$table->{"data"}}) {
			if ($row->[0] =~ /\d+/) {
				# Assume gene variables has number, but not other labels.
				next if ($row->[1] eq "0");
				$row->[0] =~ s/___/|/ if ($row->[0] =~ /kb___g/ || $row->[0] =~ /fig___/);
				if ($row->[0] =~ /Not_(.*)/) {
					# Case 3: the gene was likely to be on, but actually inactive.
					$tintleOutputHash->{"conflicts"}->{$1} = "InactiveOn";
				} else {
					# Case1: the gene was likely to be off, but actually active.
					$tintleOutputHash->{"conflicts"}->{$row->[0]} = "ActiveOff";				
				}
			} else {
				$tintleOutputHash->{$row->[0]} = $row->[1];
			}
		}
		$self->add("FBATintleResults",$tintleOutputHash);
		# debug	
		my $ftrhash = {};
		my $rxns = $self->fbamodel()->modelreactions();
		for (my $i=0; $i < @{$rxns};$i++) {
			my $rxn = $rxns->[$i];
			my $ftrs = $rxn->featureIDs();
			foreach my $ftr (@{$ftrs}) {
			push @{$ftrhash->{$ftr}}, $rxn->id();
			}
		}

		foreach my $feature (keys %{$tintleOutputHash->{"conflicts"}}) {
			print $feature, "\t", $tintleOutputHash->{"conflicts"}->{$feature}, "\t", (join ",", @{$ftrhash->{$feature}}), "\n";
		}
		return 1;
	}
	return 0;
}

=head3 parseQuantOptResult

Definition:
	void parseQuantOptResult();
Description:
	Parses quantitative optimization results file

=cut

sub parseQuantOptResult {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/QuantitativeOptimization.txt") {
		#Loading file results into a hash
		#TODO
		my $table = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/QuantitativeOptimization.txt", "\t", 0);
		my $tintleOutputHash;

		foreach my $row (@{$table->{"data"}}) {
			if ($row->[0] =~ /\d+/) {
				# Assume gene variables has number, but not other labels.
				next if ($row->[1] eq "0");
				$row->[0] =~ s/___/|/ if ($row->[0] =~ /kb___g/);
				if ($row->[0] =~ /Not_(.*)/) {
					# Case 3: the gene was likely to be on, but actually inactive.
					$tintleOutputHash->{"conflicts"}->{$1} = "InactiveOn";
				} else {
					# Case1: the gene was likely to be off, but actually active.
					$tintleOutputHash->{"conflicts"}->{$row->[0]} = "ActiveOff";				
				}
			} else {
				$tintleOutputHash->{$row->[0]} = $row->[1];
			}
		}
		$self->add("QuantitativeOptimizationSolutions",$tintleOutputHash);
	}
}

=head3 parseGapfillingOutput

Definition:
	void parseGapfillingOutput();
Description:
	Parsing gapfilling output

=cut

sub parseGapfillingOutput {
	my $self = shift;
	my $directory = $self->jobDirectory();

	sub addExpressionLeveltoGPR {
	my ($gprstring, $sample) = @_;
	my $exphash = $sample;
	if (ref($sample) ne "HASH") {
		$exphash = $sample->expression_levels();
	}
	my $gpr = Bio::KBase::ObjectAPI::utilities::translateGPRHash(Bio::KBase::ObjectAPI::utilities::parseGPR($gprstring));
	my @result;
	foreach my $node (@$gpr) {
		my @inner;
		foreach my $fa (@$node) {
		my @innerinner;
		foreach my $innerinner (@$fa) {
			push @innerinner, $innerinner.":".sprintf("%.2f",$exphash->{$innerinner});
		}
		if (@innerinner > 1) {
			push @inner, "(".(join " or ", @innerinner).")";
		}
		else {
			push @inner, @innerinner;
		}
		}
		if (@inner > 1) {
		push @result, "(".(join " and ", @inner).")";
		}
		else {
		push @result, @inner;
		}
	}
	return "(".(join " or ", @result).")";
	}

	sub fluxForRxn {
	my  ($self, $rxn) = @_;
	my $fbaRxnVar = $self->queryObject("FBAReactionVariables",{
		modelreaction_ref => "~/fbamodel/modelreactions/id/".$rxn->id()});
	return $fbaRxnVar->variableType().":".$fbaRxnVar->value();
	}

	if (-e $directory."/GapfillingOutput.txt") {
		my $rxns = $self->fbamodel()->modelreactions();
		my $rxnhash;
		for (my $i=0; $i < @{$rxns}; $i++) {
			$rxnhash->{$rxns->[$i]->id()} = $rxns->[$i];
		}	
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/GapfillingOutput.txt","\t");
		if (!defined($tbl->{data}->[0]->[3])) {
			Bio::KBase::ObjectAPI::utilities::error("Gapfilling failed to find a solution to permit model growth on specified media condition!");
		}	
		my $solution;
		my $round = 0;
		my $temparray = [split(/\//,$tbl->{data}->[0]->[3])];
		push(@{$self->{outputfiles}->{gapfillstats}},"Gapfilled:".$temparray->[1]);
		#print "Number of gapfilled reactions [includes low expression reactions that must carry flux] (lower better): ".$temparray->[1]."\n";
		if (defined($tbl->{data}->[0]->[7])) {
			for my $rxn (split ";", $tbl->{data}->[0]->[7]) {
				if ($rxn =~ /^(.)(.+)/) {
					if (defined($rxnhash->{$2})) {
						#print "\t", $rxn, "\t", $rxnhash->{$2}->name(), "\t", fluxForRxn($self, $rxnhash->{$2}), "\t", $rxnhash->{$2}->gprString(), "\n";
					}
				}
			}
		}
		$temparray = [split(/\//,$tbl->{data}->[0]->[4])];
		push(@{$self->{outputfiles}->{gapfillstats}},"Active on:".$temparray->[1]);
		#print "Activated high expression reactions [do carry flux] (higher better): ".$temparray->[1]."\n";
		$temparray = [split(/\//,$tbl->{data}->[0]->[5])];
		push(@{$self->{outputfiles}->{gapfillstats}},"Inactive on:".$temparray->[1]);
		#print "High expression reactions that were not activated [do not carry flux] (lower better): ".$temparray->[1]."\n";
		if (defined($tbl->{data}->[0]->[9])) {
			for my $rxn (split ";", $tbl->{data}->[0]->[9]) {
				if (defined($rxnhash->{$rxn})) {
					#print "\t", $rxn, "\t", $rxnhash->{$rxn}->name(), "\t", $rxnhash->{$rxn}->gprString(), "\n";
				}
			}
		}
		push(@{$self->{outputfiles}->{gapfillrxns}},"Active reactions:".$tbl->{data}->[0]->[7]);
		my $count = [0];
		if (defined($tbl->{data}->[0]->[7])) {
			my $currrxns = [split(/;/,$tbl->{data}->[0]->[7])];
			for (my $i=0; $i < @{$currrxns}; $i++) {
				if ($currrxns->[$i] =~ /^(.)(.+)/) {
					my $rxnid = $2;
					my $sign = $1;
					if (defined($rxnhash->{$rxnid})) {
						if ($rxnhash->{$rxnid}->direction() eq "=") {
							$count->[0]++;
						}
						if ($sign eq "-") {
							if ($rxnhash->{$rxnid}->direction() eq "<") {
								$count->[0]++;
							}
						} else {
							if ($rxnhash->{$rxnid}->direction() eq ">") {
								$count->[0]++;
							}
						}
					}
				}
			}
		}
		push(@{$self->{outputfiles}->{gapfillstats}},"Active off:".$count->[0]);
		#print "Activated low expression reactions [must carry flux] (lower better): ".$count->[0]."\n";
		foreach my $row (@{$tbl->{data}}) {
			if (!defined($solution)) {
				$solution = {
					id => "sol.0",
					solutionCost => 0,
					biomassRemoval_refs => [],
					mediaSupplement_refs => [],
					koRestore_refs => [],
					integrated => 0,
					suboptimal => 0,
					objective => $row->[1],
					gfscore => 0,
					actscore => 0,
					rejscore => 0,
					candscore => 0,
					ejectedCandidates => [],
					failedReaction_refs => [],
					activatedReactions => [],
					gapfillingSolutionReactions => []
				};
			}
			$solution->{solutionCost} += $row->[2];
			my $temparray = [split(/\//,$row->[3])];
			$solution->{gfscore} += $temparray->[0];
			$temparray = [split(/\//,$row->[4])];
			$solution->{actscore} += $temparray->[0];
			$temparray = [split(/\//,$row->[5])];
			$solution->{rejscore} += $temparray->[0];
			$temparray = [split(/\//,$row->[6])];
			$solution->{candscore} += $temparray->[0];
			next if (@$row < 8);
			my $array = [split(/;/,$row->[7])];
			for (my $i=0; $i < @{$array}; $i++) {
				if ($array->[$i] =~ m/([+\-])(.+)_([a-z])(\d+)/) {
					my $ind = $4;
					my $dir = $1;
					if ($dir eq "+") {
						$dir = ">";
					} else {
						$dir = "<";
					}
					my $rxnref = "~/fbamodel/modelreactions/id/".$2."_".$3.$4;
					my $rxn = $self->fbamodel()->searchForReaction($2."_".$3.$4);
					my $cmp = $self->fbamodel()->template()->searchForCompartment($3);
					if (!defined($rxn)) {
						$rxnref = "~/fbamodel/template/reactions/id/".$2."_".$3;
						$rxn = $self->fbamodel()->template()->searchForReaction($2."_".$3);
						if (!defined($rxn)) {
							if (defined($self->{_source_model})) {
								$rxnref = $self->{_source_model}->_reference()."/modelreactions/id/".$2."_".$3.$4;
								$rxn = $self->{_source_model}->searchForReaction($2."_".$3.$4);
							}
							if (!defined($rxn) && $ind != 0) {
								$rxnref = $self->{_source_model}->_reference()."/modelreactions/id/".$2."_".$3."0";
								$rxn = $self->{_source_model}->searchForReaction($2."_".$3."0");
							}
							if (!defined $rxn) {
								print "Skipping gapfilling ".$array->[$i]."\n";
								next;	
							}
						}
					}
					push(@{$solution->{gapfillingSolutionReactions}},{
						round => $round+0,
						reaction_ref => $rxnref,
						compartment_ref => $cmp->_reference(),
						direction => $dir,
						compartmentIndex => $ind+0,
						candidateFeature_refs => []
					});
				}
			}
			next if (@$row < 9);
			$array = [split(/;/,$row->[8])];
			for (my $i=0; $i < @{$array}; $i++) {
				my $mdlrxn = $self->fbamodel()->searchForReaction($array->[$i]);
				if (defined($mdlrxn)) {
					push(@{$solution->{activatedReactions}},{
						round => $round,
						modelreaction_ref => "~/fbamodel/modelreactions/id/".$mdlrxn->id()
					});
				}
			}
			next if (@$row < 10);
			$array = [split(/;/,$row->[9])];
			for (my $i=0; $i < @{$array}; $i++) {
				my $mdlrxn = $self->fbamodel()->searchForReaction($array->[$i]);
				if (defined($mdlrxn)) {
					push(@{$solution->{failedReaction_refs}},modelreaction_ref => "~/fbamodel/modelreactions/id/".$mdlrxn->id());
				}
			}
			next if (@$row < 11);
			$array = [split(/;/,$row->[10])];
			for (my $i=0; $i < @{$array}; $i++) {
				if ($array->[$i] =~ m/([+\-])(.+)_([a-z])(\d+)/) {
					my $ind = $4;
					my $dir = $1;
					if ($dir eq "+") {
						$dir = ">";
					} else {
						$dir = "<";
					}
					my $cmp = $self->fbamodel()->template()->searchForCompartment($3);
					my $rxn = $self->fbamodel()->template()->searchForReaction($2."_".$3);
					if (!defined $rxn) {
						$rxn = $self->fbamodel()->searchForReaction($2."_".$3.$4);
						if (!defined $rxn) {
							#print "Skipping candidate ".$array->[$i]."\n";
							next;	
						}
					}
					push(@{$solution->{rejectedCandidates}},{
						round => $round+0,
						reaction_ref => $rxn->_reference(),
						compartment_ref => $cmp->_reference(),
						direction => $dir,
						compartmentIndex => $ind+0,
						candidateFeature_refs => []
					});
				}
			}
			$round++;
		}
		$self->add("gapfillingSolutions",$solution);
		if ($self->parameters()->{add_gapfilling_solution_to_model} == 1) {
			my $gfs = $self->fbamodel()->gapfillings();
			my $currentid = 0;
			for (my $i=0; $i < @{$gfs}; $i++) {
				if ($gfs->[$i]->id() =~ m/gf\.(\d+)$/) {
					if ($1 >= $currentid) {
						$currentid = $1+1;
					}
				}
			}
			my $gfid = "gf.".$currentid;
			my $input = {
				object => $self,
				id => $gfid
			};
			if ($self->parameters()->{integrate_gapfilling_solution} == 1) {
				$input->{solution_to_integrate} = 0;
			}
			$self->fbamodel()->add_gapfilling($input);
		}
	}
}

=head3 parseMFALog
Definition:
	void ModelSEED::MS::Model->parseMFALog();
Description:
	Parses MFA Log

=cut

sub parseMFALog {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFALog.txt") {
	    open (MFALOG, $directory."/MFALog.txt");
	    my $loglines = join "", <MFALOG>;
	    $self->MFALog($loglines);
	}
	else {
	    $self->MFALog("Couldn't open MFALog.txt\n");	    
	}
}

=head3 parseReactionMinimization

Definition:
	void parseReactionMinimization();
Description:
	Parsing reaction minimization results

=cut

sub parseReactionMinimization {
	my $self = shift;
	my $directory = $self->jobDirectory();
	if ($self->minimize_reactions() == 1 && -e $directory."/CompleteGapfillingOutput.txt") {
		my $data = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/CompleteGapfillingOutput.txt");
		my $mdl = $self->fbamodel();
		my $line;
		my $has_unneeded = 0;
		for (my $i=(@{$data}-1); $i >= 0; $i--) {
			my $array = [split(/\t/,$data->[$i])];
			if ($array->[1] =~ m/rxn\d+/) {
				$line = $i;
				last;
			}
			# Keep this separate becasue otherwise iterative gap fill breaks.
			# If we find UNNEEDED and lines with reactions in them we only care about the latter.
			if ( $array->[1] =~ m/UNNEEDED/ ) {
				$has_unneeded = 1;
			}
		}
		if (!defined($self->parameters()->{"suboptimal solutions"})) {
			$self->parameters()->{"suboptimal solutions"} = 0;
		}
		if (defined($line)) {
			my $array = [split(/\t/,$data->[$line])];
			my $solutionsArray = [split(/\|/,$array->[1])];
			my $solcount = 0;
			for (my $k=0; $k < @{$solutionsArray}; $k++) {
				if (length($solutionsArray->[$k]) > 0) {
					my $count = 0;
					my $reactions = [];
					my $directions = [];
					my $subarray = [split(/[,;]/,$solutionsArray->[$k])];
					for (my $j=0; $j < @{$subarray}; $j++) {
						if ($subarray->[$j] =~ m/([\-\+])(.+)/) {
							my $rxnid = $2;
							my $sign = $1;
							if ($sign eq "+") {
								$sign = ">";
							} else {
								$sign = "<";
							}
							my $rxn = $mdl->queryObject("modelreactions",{id => $rxnid});
							if (!defined($rxn)) {
								Bio::KBase::ObjectAPI::utilities::ERROR("Could not find reaction ".$rxnid."!");
							}
							if (defined($self->minimize_reaction_costs()->{$rxnid})) {
								$count += $self->minimize_reaction_costs()->{$rxnid};
							} else {
								$count++;
							}
							push(@{$reactions},$rxn->_reference());
							push(@{$directions},$sign);
						}
					}
					if (!defined($self->objectiveValue())) {
						$self->objectiveValue($count);
					}
					$self->add("FBAMinimalReactionsResults",{
						id => $self->id().".minrxns.".$solcount,
						suboptimal => $self->parameters()->{"suboptimal solutions"},
						totalcost => $count,
						reaction_refs => $reactions,
						reaction_directions => $directions
					});
					$solcount++;
				}
			}
		} elsif ($has_unneeded) {
			if (!defined($self->objectiveValue())) {
				$self->objectiveValue(0);
			}
			$self->add("FBAMinimalReactionsResults",{
			   	id => $self->id().".minrxns.0",
			   	suboptimal => $self->parameters()->{"suboptimal solutions"},
				totalcost => 0,
				reaction_refs => [],
				reaction_directions => []
			});
		}
	}
}

=head3 parseOutputFiles

Definition:
	void parseOutputFiles();
Description:
	Parses output files specified in FBAFormulation

=cut

sub parseOutputFiles {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	foreach my $filename (keys(%{$self->outputfiles()})) {
		if (-e $directory."/".$filename) {
			$self->outputfiles()->{$filename} = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/".$filename);
		}
	}
	if (-e $directory."/suboptimalSolutions.txt") {
		$self->parameters()->{"suboptimal solutions"} = 0;
		$self->outputfiles()->{"suboptimalSolutions.txt"} = ["1"];
	} else {
		$self->parameters()->{"suboptimal solutions"} = 1;
	}
}

=head3 buildLPProblem

Definition:
	void buildLPProblem();
Description:
	

=cut

sub buildLPProblem {
	my ($self) = @_;
#	my $model = $self->fbamodel();
#	my $variables;
#	my $constraints;
#	
#	for (my $i=0; $i < @{$variables}; $i++) {
#		
#	}
#	
#	#Creating mass balance constraints
#	my $mdlrxns = $model->modelreactions();
#	my $mbconsts = {};
#	my $fluxvar = {};
#	for (my $i=0; $i < @{$mdlrxns}; $i++) {
#		my $rxn = $mdlrxns->[$i];
#		$fluxvar->{$rxn->id()} = {
#			type => "for_flux",
#			objectid => 
#			
#		}
#		my $rgts = $rxn->modelReactionReagents();
#		for (my $j=0; $j < @{$rgts}; $j++) {
#			my $cpd = $rgts->[$j]->modelcompound();
#			$mbconsts->{$cpd->id()}
#		}
#	}
	
}

sub translate_to_localrefs {
	my $self = shift;
	for (my $j=0; $j < @{$self->geneKO_refs()}; $j++) {
		if ($self->geneKO_refs()->[$j] =~ m/\/([^\/]+)$/) {
			$self->geneKO_refs()->[$j] = "~/fbamodel/genome/features/id/".$1;
		}
	}
	for (my $j=0; $j < @{$self->reactionKO_refs()}; $j++) {
		if ($self->reactionKO_refs()->[$j] =~ m/\/([^\/]+)$/) {
			$self->reactionKO_refs()->[$j] = "~/fbamodel/modelreactions/id/".$1;
		}
	}
	for (my $j=0; $j < @{$self->additionalCpd_refs()}; $j++) {
		if ($self->additionalCpd_refs()->[$j] =~ m/\/([^\/]+)$/) {
			$self->additionalCpd_refs()->[$j] = "~/fbamodel/modelcompounds/id/".$1;
		}
	}
	for (my $j=0; $j < @{$self->FBADeletionResults()}; $j++) {
		my $list = $self->FBADeletionResults()->[$j]->feature_refs();
		for (my $k=0; $k < @{$list}; $k++) {
			if ($list->[$k] =~ m/\/([^\/]+)$/) {
				$list->[$k] = "~/fbamodel/genome/features/id/".$1;
			}
		}
	}
	for (my $j=0; $j < @{$self->FBAMetaboliteProductionResults()}; $j++) {
		if ($self->FBAMetaboliteProductionResults()->[$j]->modelcompound_ref() =~ m/\/([^\/]+)$/) {
			$self->FBAMetaboliteProductionResults()->[$j]->modelcompound_ref("~/fbamodel/modelcompounds/id/".$1);
		}
	}
	for (my $j=0; $j < @{$self->FBAMinimalReactionsResults()}; $j++) {
		my $list = $self->FBAMinimalReactionsResults()->[$j]->reaction_refs();
		for (my $k=0; $k < @{$list}; $k++) {
			if ($list->[$k] =~ m/\/([^\/]+)$/) {
				$list->[$k] = "~/fbamodel/modelreactions/id/".$1;
			}
		}
	}
	for (my $j=0; $j < @{$self->FBAMinimalMediaResults()}; $j++) {
		my $list = $self->FBAMinimalMediaResults()->[$j]->essentialNutrient_refs();
		for (my $k=0; $k < @{$list}; $k++) {
			if ($list->[$k] =~ m/\/([^\/]+)$/) {
				$list->[$k] = "~/fbamodel/template/compounds/id/".$1;
			}
		}
		$list = $self->FBAMinimalMediaResults()->[$j]->optionalNutrient_refs();
		for (my $k=0; $k < @{$list}; $k++) {
			if ($list->[$k] =~ m/\/([^\/]+)$/) {
				$list->[$k] = "~/fbamodel/template/compounds/id/".$1;
			}
		}
	}
	my $subobject_ref_trans = {
		FBAReactionBounds => ["modelreaction_ref","modelreactions"],
		FBACompoundBounds => ["modelcompound_ref","modelcompounds"],
		FBACompoundVariables => ["modelcompound_ref","modelcompounds"],
		FBAReactionVariables => ["modelreaction_ref","modelreactions"],
		FBABiomassVariables => ["biomass_ref","biomasses"],
		FBAMetaboliteProductionResults => ["modelcompound_ref","modelcompounds"]
	};
	foreach my $item (keys(%{$subobject_ref_trans})) {
		my $objects = $self->$item();
		for (my $j=0; $j < @{$objects}; $j++) {
			my $fn = $subobject_ref_trans->{$item}->[0];
			if ($objects->[$j]->$fn() =~ m/\/([^\/]+)$/) {
				$objects->[$j]->$fn("~/fbamodel/".$subobject_ref_trans->{$item}->[1]."/id/".$1);
			}
		}
	}
	my $solutions = $self->gapfillingSolutions();
	for (my $j=0; $j < @{$solutions}; $j++) {
		my $solution = $solutions->[$j];
		my $gfrxns = $solution->gapfillingSolutionReactions();
		for (my $k=0; $k < @{$gfrxns}; $k++) {
			my $gfrxn = $gfrxns->[$k];
			if ($gfrxn->compartment_ref() =~ m/\/([^\/]+)$/) {
				my $comp = $1;
				$gfrxn->compartment_ref("~/fbamodel/template/compartments/id/".$comp);
				if ($gfrxn->reaction_ref() =~ m/\/([^\/]+_[a-z])$/) {
					$gfrxn->reaction_ref("~/fbamodel/template/reactions/id/".$1);
				} elsif ($gfrxn->reaction_ref() =~ m/\/([^\/]+)$/) {
					my $rxn = $1;
					$gfrxn->reaction_ref("~/fbamodel/template/reactions/id/".$rxn."_".$comp);
				}
			}
		}
		my $list = $solution->biomassRemoval_refs();
		for (my $k=0; $k < @{$list}; $k++) {
			if ($list->[$k] =~ m/\/([^\/]+)$/) {
				$list->[$k] = "~/fbamodel/modelcompounds/".$1;
			}
		}
		$list = $solution->mediaSupplement_refs();
		for (my $k=0; $k < @{$list}; $k++) {
			if ($list->[$k] =~ m/\/([^\/]+)$/) {
				$list->[$k] = "~/fbamodel/modelcompounds/id/".$1;
			}
		}
		$list = $solution->koRestore_refs();
		for (my $k=0; $k < @{$list}; $k++) {
			if ($list->[$k] =~ m/\/([^\/]+)$/) {
				$list->[$k] = "~/fbamodel/modelreactions/id/".$1;
			}
		}
		$gfrxns = $solution->rejectedCandidates();
		for (my $k=0; $k < @{$gfrxns}; $k++) {
			my $gfrxn = $gfrxns->[$k];
			if ($gfrxn->compartment_ref() =~ m/\/([^\/]+)$/) {
				my $comp = $1;
				$gfrxn->compartment_ref("~/fbamodel/template/compartments/id/".$comp);
				if ($gfrxn->reaction_ref() =~ m/\/([^\/]+)$/) {
					$gfrxn->reaction_ref("~/fbamodel/template/reactions/id/".$1."_".$comp);
				}
			}
			$list = $gfrxn->candidateFeature_refs();
			for (my $k=0; $k < @{$list}; $k++) {
				if ($list->[$k] =~ m/\/([^\/]+)$/) {
					$list->[$k] = "~/fbamodel/genome/features/id/".$1;
				}
			}
		}
		$gfrxns = $solution->activatedReactions();
		for (my $k=0; $k < @{$gfrxns}; $k++) {
			my $gfrxn = $gfrxns->[$k];
			if ($gfrxn->modelreaction_ref() =~ m/\/([^\/]+)$/) {
				$gfrxn->modelreaction_ref("~/fbamodel/modelreactions/id/".$1);
			}
		}
		$gfrxns = $solution->failedReaction_refs();
		for (my $k=0; $k < @{$gfrxns}; $k++) {
			if ($gfrxns->[$k] =~ m/\/([^\/]+)$/) {
				$gfrxns->[$k] = "~/fbamodel/modelreactions/id/".$1;
			}
		}
	}					
}

__PACKAGE__->meta->make_immutable;
1;
