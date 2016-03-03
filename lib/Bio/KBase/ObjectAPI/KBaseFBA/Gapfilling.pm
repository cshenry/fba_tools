########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::Gapfilling - This is the moose object corresponding to the GapfillingFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-05-21T20:27:15
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::Gapfilling;
package Bio::KBase::ObjectAPI::KBaseFBA::Gapfilling;
use Bio::KBase::ObjectAPI::utilities;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::Gapfilling';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has guaranteedReactionString => ( is => 'rw',printOrder => 16, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildguaranteedReactionString' );
has blacklistedReactionString => ( is => 'rw',printOrder => 17, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildblacklistedReactionString' );
has allowableCompartmentString => ( is => 'rw',printOrder => 18, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildallowableCompartmentString' );
has mediaID => ( is => 'rw',printOrder => 19, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmediaID' );
has reactionKOString => ( is => 'rw',printOrder => 19, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionKOString' );
has geneKOString => ( is => 'rw',printOrder => 19, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgeneKOString' );
has biomassRemovals => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildguaranteedReactionString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->guaranteedReactions()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->guaranteedReactions()->[$i]->id();
	}
	return $string;
}
sub _buildblacklistedReactionString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->blacklistedReactions()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->blacklistedReactions()->[$i]->id();
	}
	return $string;
}
sub _buildallowableCompartmentString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->allowableCompartments()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->allowableCompartments()->[$i]->id();
	}
	return $string;
}
sub _buildmediaID {
	my ($self) = @_;
	return $self->fba()->media()->id();
}
sub _buildreactionKOString {
	my ($self) = @_;
	my $string = "";
	my $rxnkos = $self->fba()->reactionKOs();
	for (my $i=0; $i < @{$rxnkos}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $rxnkos->[$i]->id();
	}
	return $string;
}
sub _buildgeneKOString {
	my ($self) = @_;
	my $string = "";
	my $genekos = $self->fba()->geneKOs();
	for (my $i=0; $i < @{$genekos}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $genekos->[$i]->id();
	}
	return $string;
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
	Returns biochemistry behind gapfilling object

=cut

sub biochemistry {
	my ($self) = @_;
	$self->fbamodel()->template()->biochemistry();	
}

=head3 annotation

Definition:
	Bio::KBase::ObjectAPI::Annotation = annotation();
Description:
	Returns annotation behind gapfilling object

=cut

sub annotation {
	my ($self) = @_;
	$self->fbamodel()->annotation();	
}

=head3 mapping

Definition:
	Bio::KBase::ObjectAPI::KBaseOntology::Mapping = mapping();
Description:
	Returns mapping behind gapfilling object

=cut

sub mapping {
	my ($self) = @_;
	$self->fbamodel()->mapping();	
}

=head3 calculateReactionCosts

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::GapfillingSolution = Bio::KBase::ObjectAPI::KBaseFBA::GapfillingSolution->calculateReactionCosts({
		modelreaction => Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction
	});
Description:
	Calculates the cost of adding or adjusting the reaction directionality in the model

=cut

sub calculateReactionCosts {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["modelreaction"], {}, @_);
	my $rxn = $args->{modelreaction};
	my $rcosts = 1;
	my $fcosts = 1;
	if (@{$rxn->modelReactionProteins()} > 0 && $rxn->modelReactionProteins()->[0]->note() ne "CANDIDATE") {
		if ($rxn->direction() eq ">" || $rxn->direction() eq "=") {
			$fcosts = 0;	
		}
		if ($rxn->direction() eq "<" || $rxn->direction() eq "=") {
			$rcosts = 0;
		}
	}
	if ($fcosts == 0 && $rcosts == 0) {
		return {forwardDirection => $fcosts,reverseDirection => $rcosts};
	}
	#Handling directionality multiplier
	if ($rxn->direction() eq ">") {
		$rcosts = $rcosts*$self->directionalityMultiplier();
		if ($rxn->reaction()->deltaG() ne 10000000) {
			$rcosts = $rcosts*(1-$self->deltaGMultiplier()*$rxn->reaction()->deltaG());
		}
	} elsif ($rxn->direction() eq "<") {
		$fcosts = $fcosts*$self->directionalityMultiplier();
		if ($rxn->reaction()->deltaG() ne 10000000) {
			$fcosts = $fcosts*(1+$self->deltaGMultiplier()*$rxn->reaction()->deltaG());
		}
	}
	#Checking for structure
	if (!defined($rxn->reaction()->deltaG()) || $rxn->reaction()->deltaG() eq 10000000) {
		$rcosts = $rcosts*$self->noDeltaGMultiplier();
		$fcosts = $fcosts*$self->noDeltaGMultiplier();
	}
	#Checking for transport based penalties
	if ($rxn->isTransporter() == 1) {
		$rcosts = $rcosts*$self->transporterMultiplier();
		$fcosts = $fcosts*$self->transporterMultiplier();
		if ($rxn->biomassTransporter() == 1) {
			$rcosts = $rcosts*$self->biomassTransporterMultiplier();
			$fcosts = $fcosts*$self->biomassTransporterMultiplier();
		}
		if (@{$rxn->modelReactionReagents()} <= 2) {
			$rcosts = $rcosts*$self->singleTransporterMultiplier();
			$fcosts = $fcosts*$self->singleTransporterMultiplier();
		}
	}
	#Checking for structure based penalties
	if ($rxn->missingStructure() == 1) {
		$rcosts = $rcosts*$self->noStructureMultiplier();
		$fcosts = $fcosts*$self->noStructureMultiplier();
	}		
	#Handling reactionset multipliers
	for (my $i=0; $i < @{$self->reactionSetMultipliers()}; $i++) {
		my $setMult = $self->reactionSetMultipliers()->[$i];
		my $set = $setMult->reactionset();
		if ($set->containsReaction($rxn->reaction()) == 1) {
			if ($setMult->multiplierType() eq "absolute") {
				$rcosts = $rcosts*$setMult->multiplier();
				$fcosts = $fcosts*$setMult->multiplier();
			} else {
				my $coverage = $set->modelCoverage({model=>$rxn->parent()});
				my $multiplier = $setMult->multiplier()/$coverage;
			}	
		}
	}
	return {forwardDirection => $fcosts,reverseDirection => $rcosts};
}

=head3 prepareFBAFormulation

Definition:
	void prepareFBAFormulation();
Description:
	Ensures that an FBA formulation exists for the gapfilling, and that it is properly configured for gapfilling

=cut

sub prepareFBAFormulation {
	my ($self,$args) = @_;
	my $form;
	if (!defined($self->fba_ref())) {
		Bio::KBase::ObjectAPI::utilities::error("Must create FBA for gapfilling!");
	} else {
		$form = $self->fba();
	}
	if ($form->media()->name() eq "Complete") {
		if ($form->defaultMaxDrainFlux() < 10000) {
			$form->defaultMaxDrainFlux(10000);
		}	
	} else {
		my $mediacpds = $form->media()->mediacompounds();
		foreach my $cpd (@{$mediacpds}) {
			if ($cpd->maxFlux() > 0) {
				$cpd->maxFlux(10000);
			}
			if ($cpd->minFlux() < 0) {
				$cpd->minFlux(-10000);
			}
		}
	}
	$form->objectiveConstraintFraction(1);
	$form->defaultMaxFlux(10000);
	$form->defaultMinDrainFlux(-10000);
	my $inactiveList = ["bio1"];
	my $rxns = $self->fbamodel()->modelreactions();
	if ($self->completeGapfill() eq "1") {
		if (@{$self->targetedreactions()} > 0) {
			my $list = $self->targetedreactions();
			$inactiveList = [];
			for (my $i=0; $i < @{$list}; $i++) {
				push(@{$inactiveList},$list->[$i]->id());
			}
		} else {
			my $rxnfoundhash = {};
			my $rxnmdlrxnhash = {};
			for (my $i=0; $i < @{$rxns}; $i++) {
				$rxnfoundhash->{$rxns->[$i]->reaction()->id()} = 0;	
				$rxnmdlrxnhash->{$rxns->[$i]->reaction()->id()}{$rxns->[$i]->id()}=1;	
			}
			my $priorities = $self->reactionPriorities();
			for (my $i=0; $i < @{$priorities}; $i++) {
				if (defined($rxnfoundhash->{$priorities->[$i]})) {
				    foreach my $mdlrxn (keys %{$rxnmdlrxnhash->{$priorities->[$i]}}){
					push(@{$inactiveList},$mdlrxn);
				    }
					$rxnfoundhash->{$priorities->[$i]} = 1;
				}
			}
			for (my $i=0; $i < @{$rxns}; $i++) {
				if ($rxnfoundhash->{$rxns->[$i]->reaction()->id()} == 0) {
					push(@{$inactiveList},$rxns->[$i]->id());
				}	
			}
		}
	}
	if (defined($self->{expression_data})) {
		$form->{expression_data} = $self->{expression_data};
		$form->{expression_threshold_type} = $self->{expression_threshold_type};
	}
	$form->inputfiles()->{"InactiveModelReactions.txt"} = $inactiveList;
	$form->fluxUseVariables(1);
	$form->decomposeReversibleFlux(1);
	#Setting up dissapproved compartments
	my $badCompList = [];
	my $approvedHash = {};
	my $cmps = $self->allowableCompartments();
	for (my $i=0; $i < @{$cmps}; $i++) {
		$approvedHash->{$cmps->[$i]->id()} = 1;	
	}
	$cmps = $self->biochemistry()->compartments();
	for (my $i=0; $i < @{$cmps}; $i++) {
		if (!defined($approvedHash->{$cmps->[$i]->id()})) {
			push(@{$badCompList},$cmps->[$i]->id());
		}	
	}
	$form->parameters()->{"dissapproved compartments"} = join(";",@{$badCompList});
	
	#Setting up gauranteed reactions
	my $rxnlist = [];
	$rxns = $self->guaranteedReactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		push(@{$rxnlist},$rxns->[$i]->id());
	}
	$form->parameters()->{"Gapfilling guaranteed reactions"} = join(",",@{$rxnlist});
	#Adding blacklisted reactions to KO list
	$rxns = $self->blacklistedReactions();
	$rxnlist = [];
	for (my $i=0; $i < @{$rxns}; $i++) {
		push(@{$rxnlist},$rxns->[$i]->id());
	}
	$form->parameters()->{"Gapfilling blacklisted reactions"} = join(",",@{$rxnlist});
	#Setting other important parameters
	$form->parameters()->{"Complete gap filling"} = "1";
	$form->parameters()->{"Reaction activation bonus"} = $self->reactionActivationBonus();
	$form->parameters()->{"Minimum flux for use variable positive constraint"} = "10";
	$form->parameters()->{"Objective coefficient file"} = "NONE";
	$form->parameters()->{"just print LP file"} = "0";
	$form->parameters()->{"use database fields"} = "1";
	$form->parameters()->{"REVERSE_USE;FORWARD_USE;REACTION_USE"} = "1";
	$form->parameters()->{"CPLEX solver time limit"} = $self->timePerSolution();
	$form->parameters()->{"Recursive MILP timeout"} = $self->totalTimeLimit();
	$form->parameters()->{"Perform gap filling"} = "1";
	$form->parameters()->{"Add DB reactions for gapfilling"} = "1";
	$form->parameters()->{"Balanced reactions in gap filling only"} = $self->balancedReactionsOnly();
	$form->parameters()->{"drain flux penalty"} = $self->drainFluxMultiplier();#Penalty doesn't exist in MFAToolkit yet
	$form->parameters()->{"directionality penalty"} = $self->directionalityMultiplier();#5
	$form->parameters()->{"delta G multiplier"} = $self->deltaGMultiplier();#Penalty doesn't exist in MFAToolkit yet
	$form->parameters()->{"unknown structure penalty"} = $self->noStructureMultiplier();#1
	$form->parameters()->{"no delta G penalty"} = $self->noDeltaGMultiplier();#1
	$form->parameters()->{"biomass transporter penalty"} = $self->biomassTransporterMultiplier();#3
	$form->parameters()->{"single compound transporter penalty"} = $self->singleTransporterMultiplier();#3
	$form->parameters()->{"transporter penalty"} = $self->transporterMultiplier();#0
	$form->parameters()->{"unbalanced penalty"} = "10";
	$form->parameters()->{"no functional role penalty"} = "2";
	$form->parameters()->{"no KEGG map penalty"} = "1";
	$form->parameters()->{"non KEGG reaction penalty"} = "1";
	$form->parameters()->{"no subsystem penalty"} = "1";
	$form->parameters()->{"subsystem coverage bonus"} = "1";
	$form->parameters()->{"scenario coverage bonus"} = "1";
	$form->parameters()->{"Add positive use variable constraints"} = "0";
	$form->parameters()->{"Biomass modification hypothesis"} = "0";
	$form->parameters()->{"Biomass component reaction penalty"} = "500";
	$form->outputfiles()->{"CompleteGapfillingOutput.txt"} = [];
	$form->outputfiles()->{"ProblemReport.txt"} = [];
	if ($self->biomassHypothesis() == 1) {
		$form->parameters()->{"Biomass modification hypothesis"} = "1";
		$self->addBiomassComponentReactions();
	}
	if ($self->mediaHypothesis() == 1) {
		
	}
	if ($self->gprHypothesis() == 1) {
		
	}
	return $form;	
}

=head3 printBiomassComponentReactions

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::Gapfilling->printBiomassComponentReactions();
Description:
	Print biomass component reactions designed to simulate removal of biomass components from the model

=cut

sub addBiomassComponentReactions {
	my ($self,$args) = @_;
	my $form = $self->fba();
	my $filename = $form->jobDirectory()."/";
	my $output = ["id\tequation\tname"];
	my $bio = $self->fbamodel()->biomasses()->[0];
	my $biocpds = $bio->biomasscompounds();
	my $cpdsWithProducts = {
		cpd11493 => ["cpd12370"],
		cpd15665 => ["cpd15666"],
		cpd15667 => ["cpd15666"],
		cpd15668 => ["cpd15666"],
		cpd15669 => ["cpd15666"],
		cpd00166 => ["cpd01997","cpd03422"],
	};
	foreach my $cpd (@{$biocpds}) {
		if ($cpd->coefficient() < 0) {
			my $equation = "=> ".$cpd->modelcompound()->compound()->id()."[b]";
			if (defined($cpdsWithProducts->{$cpd->modelcompound()->compound()->id()})) {
				$equation = join("[b] + ",@{$cpdsWithProducts->{$cpd->modelcompound()->compound()->id()}})."[b] ".$equation;
			}
			push(@{$output},$cpd->modelcompound()->compound()->id()."DrnRxn\t".$equation."\t".$cpd->modelcompound()->compound()->id()."DrnRxn");
		}
	}
	$form->inputfiles()->{"BiomassHypothesisEquations.txt"} = $output;
}

=head3 runGapFilling

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::GapfillingSolution = Bio::KBase::ObjectAPI::KBaseFBA::GapfillingSolution->runGapFilling({
		model => Bio::KBase::ObjectAPI::KBaseFBA::FBAModel(REQ)
	});
Description:
	Identifies the solution that gapfills the input model

=cut

sub runGapFilling {
	my ($self,$args) = @_;
	#Preparing fba formulation describing gapfilling problem
	my $form = $self->prepareFBAFormulation();	
	#Running the gapfilling
	$form->runFBA();
	#Parsing solutions
	$self->parseGapfillingResults($form);
	return $self;
}

=head3 parseGapfillingResults

Definition:
	void parseGapfillingResults();
Description:
	Parses Gapfilling results

=cut

sub parseGapfillingResults {
	my ($self,$fbaResults) = @_;
	my $outputHash = $fbaResults->outputfiles();
	if (defined($outputHash->{"CompleteGapfillingOutput.txt"})) {
		my $filedata = $outputHash->{"CompleteGapfillingOutput.txt"};
		my $subopt = 0;
		if (defined($outputHash->{"suboptimalSolutions.txt"})) {
			$subopt = 1;
		}
		$self->createSolutionsFromArray({
			data => $filedata,
			subopt => $subopt
		});
	}
}

=head3 createSolutionsFromArray

Definition:
	void createSolutionsFromArray({
		data => [string]:gapfilling solution data,
		model => Bio::KBase::ObjectAPI::KBaseFBA::FBAModel:gapfilled model
	});
Description:
	Parsing input data to generate gapfilling solutions

=cut

sub createSolutionsFromArray {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["data"], { model => $self->fbamodel(),subopt => 0 }, @_ );
    if ($self->simultaneousGapfill() eq "1") {
    	$self->parse_simultaneous_gapfill($args);
    } else {
	    my $data = $args->{data};
		my $mdl = $args->{model};
		my $fba = $self->fba();
		my $gfm;
		if (defined($fba->parameters()->{"gapfilling source model"})) {
			$gfm = $self->getLinkedObject($fba->parameters()->{"gapfilling source model"});
		}
		my $bio = $mdl->template()->biochemistry();
		my $line;
	    my $has_unneeded = 0;	
		my $failrxnrefs = [];
		for (my $i=0; $i < @{$data}; $i++) {
			my $array = [split(/\t/,$data->[$i])];
			if ($array->[1] =~ m/rxn\d+/) {
				$line = $i;
			}
			if ( $array->[1] =~ m/UNNEEDED/ ) {
			    $has_unneeded = 1;
			} elsif ( $array->[1] =~ m/FAILED/ ) {
			    push(@{$failrxnrefs},$mdl->_reference()."/modelreactions/id/".$array->[0]);
			}
		}
		my $solcount = @{$self->gapfillingSolutions()};
		if (defined($line)) {
			my $array = [split(/\t/,$data->[$line])];
			my $solutionsArray = [split(/\|/,$array->[1])];   				
			my $gfsolution;
			my $count = 0;
			for (my $k=0; $k < @{$solutionsArray}; $k++) {
			    if (length($solutionsArray->[$k]) > 0) {
				my $rxnHash;
				if ($k == 0 || $self->completeGapfill() ne "1") {
				    if (defined($gfsolution)) {
					$gfsolution->solutionCost($count);
				    }
				    $count = 0;
				    $solcount++;
				    $gfsolution = $self->add("gapfillingSolutions",{
				    	id => $self->id().".gfsol.".$solcount,
				    	suboptimal => $args->{subopt},
				    	activatedReactions => [],
				    	failedReaction_refs => $failrxnrefs,
				    });
				}
				my $subarray = [split(/[,;]/,$solutionsArray->[$k])];
				for (my $j=0; $j < @{$subarray}; $j++) {
				    if ($subarray->[$j] =~ m/([\+])(.+)DrnRxn/) {
						my $cpdid = $2;
						my $sign = $1;
						my $bio = $mdl->biomasses()->[0];
						my $biocpds = $bio->biomasscompounds();
						my $found = 0;
						for (my $m=0; $m < @{$biocpds}; $m++) {
						    my $biocpd = $biocpds->[$m];
						    if ($biocpd->modelcompound()->compound()->id() eq $cpdid) {
							$found = 1;
							push(@{$gfsolution->biomassRemovals()},$biocpd->modelcompound());
							push(@{$gfsolution->biomassRemoval_refs()},$biocpd->modelcompound()->_reference());	
						    }
						}
						if ($found == 0) {
						    Bio::KBase::ObjectAPI::utilities::ERROR("Could not find compound to remove from biomass ".$cpdid."!");
						}
						$count += 5;
				    } elsif ($subarray->[$j] =~ m/([\-\+])(.+)/) {
						my $rxnid = $2;
						my $sign = $1;
						if ($sign eq "+") {
						    $sign = ">";
						} else {
						    $sign = "<";
						}
						my $comp = "c";
						my $index = 0;
						if ($rxnid =~ m/^(.+)_([a-zA-Z]+)(\d+)$/) {
							$rxnid = $1;
							$comp = $2;
							$index = $3;
						}
						my $rxn = $mdl->template()->biochemistry()->queryObject("reactions",{id => $rxnid});
						my $mdlrxn = 0;
						if (!defined($rxn)) {
							$rxn = $mdl->queryObject("modelreactions",{id => $rxnid."_".$comp.$index});
							if (!defined($rxn)) {
								if (defined($gfm)) {
									$rxn = $gfm->queryObject("modelreactions",{id => $rxnid."_".$comp.$index});
									$mdlrxn = 1;
								}
							    if (!defined($rxn)) {
									Bio::KBase::ObjectAPI::utilities::ERROR("Could not find gapfilled reaction ".$rxnid."!");
							    }
							}
						}
						my $cmp = $mdl->template()->biochemistry()->queryObject("compartments",{id => $comp});
						if (!defined($cmp)) {
						    Bio::KBase::ObjectAPI::utilities::ERROR("Could not find gapfilled reaction compartment ".$comp."!");
						}
						if (defined($rxnHash->{$rxn->_reference()}->{$cmp->_reference()}->{$index}) && $rxnHash->{$rxn->_reference()}->{$cmp->_reference()}->{$index} ne $sign) {
						    $rxnHash->{$rxn->_reference()}->{$cmp->_reference()}->{$index} = "=";
						} else {
						    $rxnHash->{$rxn->_reference()}->{$cmp->_reference()}->{$index} = $sign;
						}
						$count++;
				    }
				}
				foreach my $ruuid (keys(%{$rxnHash})) {
				    foreach my $cuuid (keys(%{$rxnHash->{$ruuid}})) {
				    	foreach my $ind (keys(%{$rxnHash->{$ruuid}->{$cuuid}})) {
							$gfsolution->add("gapfillingSolutionReactions",{
							    reaction_ref => $ruuid,
							    compartment_ref => $cuuid,
							    direction => $rxnHash->{$ruuid}->{$cuuid}->{$ind},
							    compartmentIndex => $ind
							});
				    	}
				    }
				}
			    }
			}
			$gfsolution->solutionCost($count);
		} elsif ($has_unneeded) {
		    # Create an empty solution if all lines were UNNEEDED
		    $solcount++;
		    my $gfsolution = $self->add("gapfillingSolutions",{id => $self->id().".gfsol.".$solcount});
		} # Otherwise we assume that all of the attempts failed.
	}
}

sub parse_simultaneous_gapfill {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["data"], { model => $self->fbamodel(),subopt => 0 }, @_ );
	my $data = $args->{data};
	my $mdl = $args->{model};
	my $fba = $self->fba();
	my $gfm;
	if (defined($fba->parameters()->{"gapfilling source model"})) {
		$gfm = $self->getLinkedObject($fba->parameters()->{"gapfilling source model"});
	}
	my $bio = $mdl->template()->biochemistry();
    my $has_unneeded = 0;
	my $failrxnrefs = [];
	my $rxnhash = {};
	my $actrxn = {};
	my $round = 0;
	for (my $i=0; $i < @{$data}; $i++) {
		my $array = [split(/\t/,$data->[$i])];
		if ($array->[1] =~ m/rxn\d+/ || $array->[2] =~ m/rxn\d+/) {
			my $subarray = [split(/[,;]/,$array->[1])];
			for (my $j=0; $j < @{$subarray}; $j++) {
				if ($subarray->[$j] =~ m/([\-\+])(.+)/) {
					my $sign = $1;
					my $rxnid = $2;
					if (defined($rxnhash->{$rxnid})) {
						$rxnhash->{$rxnid}->[1] = "=";
					} elsif ($sign eq "+") {
						$rxnhash->{$rxnid} = [$round,">"];
					} elsif ($sign eq "-") {
						$rxnhash->{$rxnid} = [$round,"<"];
					}
				}
			}
			$subarray = [split(/[,;]/,$array->[2])];
			for (my $j=0; $j < @{$subarray}; $j++) {
				if ($subarray->[$j] =~ m/([\-\+])(.+)/) {
					my $sign = $1;
					my $rxnid = $2;
					$actrxn->{$2} = $round;
				}
			}
			$round++;
		}
		if ( $array->[1] =~ m/UNNEEDED/ ) {
		    $has_unneeded = 1;
		} elsif ( $array->[1] =~ m/FAILED/ ) {
		    push(@{$failrxnrefs},$mdl->_reference()."/modelreactions/id/".$array->[0]);
		}
	}
	my $solcount = @{$self->gapfillingSolutions()};
	$solcount++;
	my $gfsolution = $self->add("gapfillingSolutions",{
		id => $self->id().".gfsol.".$solcount,
		suboptimal => 0,
		failedReaction_refs => $failrxnrefs
	});
	foreach my $key (keys(%{$actrxn})) {
		my $mdlrxn = $mdl->searchForReaction($key);
		if (defined($mdlrxn)) {
			$gfsolution->add("activatedReactions",{
			    modelreaction_ref => $mdlrxn->_reference(),
			    round => $actrxn->{$key}
			});
		}
	}
	my $cost = 0;
	foreach my $key (keys(%{$rxnhash})) {
		if ($key =~ m/(.+)DrnRxn/) {
			my $cpdid = $2;
			my $bio = $mdl->biomasses()->[0];
			my $biocpds = $bio->biomasscompounds();
			my $found = 0;
			for (my $m=0; $m < @{$biocpds}; $m++) {
			    my $biocpd = $biocpds->[$m];
			    if ($biocpd->modelcompound()->compound()->id() eq $cpdid) {
					$found = 1;
					push(@{$gfsolution->biomassRemovals()},$biocpd->modelcompound());
					push(@{$gfsolution->biomassRemoval_refs()},$biocpd->modelcompound()->_reference());	
			    }
			}
			if ($found == 0) {
			    Bio::KBase::ObjectAPI::utilities::ERROR("Could not find compound to remove from biomass ".$cpdid."!");
			}
			$cost += 5;
	    } else {
	    	my $rxnid = $key;
			my $comp = "c";
			my $index = 0;
			if ($rxnid =~ m/^(.+)_([a-zA-Z]+)(\d+)$/) {
				$rxnid = $1;
				$comp = $2;
				$index = $3;
			}
			my $rxn = $mdl->template()->biochemistry()->queryObject("reactions",{id => $rxnid});
			my $mdlrxn = 0;
			if (!defined($rxn)) {
				$rxn = $mdl->queryObject("modelreactions",{id => $rxnid."_".$comp.$index});
				if (!defined($rxn)) {
					if (defined($gfm)) {
						$rxn = $gfm->queryObject("modelreactions",{id => $rxnid."_".$comp.$index});
						$mdlrxn = 1;
					}
				    if (!defined($rxn)) {
						Bio::KBase::ObjectAPI::utilities::ERROR("Could not find gapfilled reaction ".$rxnid."!");
				    }
				}
			}
			my $cmp = $mdl->template()->biochemistry()->queryObject("compartments",{id => $comp});
			if (!defined($cmp)) {
			    Bio::KBase::ObjectAPI::utilities::ERROR("Could not find gapfilled reaction compartment ".$comp."!");
			}
			$gfsolution->add("gapfillingSolutionReactions",{
			    reaction_ref => $rxn->_reference(),
			    compartment_ref => $cmp->_reference(),
			    direction => $rxnhash->{$key}->[1],
			    compartmentIndex => $index,
			    round => $rxnhash->{$key}->[0]
			});
			$cost++;
	    }
	}
	$gfsolution->solutionCost($cost);
}

sub parseGeneCandidates {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["geneCandidates"], {}, @_);
	for (my $i=0; $i < @{$args->{geneCandidates}};$i++) {
		my $candidate = $args->{geneCandidates}->[$i];
		my $ftr = $self->interpretReference($candidate->{feature},"Feature");
		if (defined($ftr)) {
			(my $role,my $type,my $field,my $id) = $self->interpretReference($candidate->{role},"Role");
			if (!defined($role)) {
				$role = $self->mapping->add("roles",{
					name => $id,
					source => "GeneCandidates"
				});
			}
			(my $orthoGenome,$type,$field,$id) = $self->interpretReference($candidate->{orthologGenome},"Genome");
			if (!defined($orthoGenome)) {
				$orthoGenome = $self->annotation->add("genomes",{
					id => $id,
					name => $id,
					source => "GeneCandidates"
				});
			}
			(my $ortho,$type,$field,$id) = $self->interpretReference($candidate->{ortholog},"Feature");
			if (!defined($ortho)) {
				$ortho = $self->annotation->add("features",{
					id => $id,
					genome_ref => $orthoGenome->_reference(),
				});
				$ortho->add("featureroles",{
					role_ref => $role->_reference(),
				});
			}
			$self->add("gapfillingGeneCandidates",{
				feature_ref => $ftr->_reference(),
				ortholog_ref => $ortho->_reference(),
				orthologGenome_ref => $orthoGenome->_reference(),
				similarityScore => $candidate->{similarityScore},
				distanceScore => $candidate->{distanceScore},
				role_ref => $role->_reference()
			});
		}
	}
}

sub parseSetMultipliers {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["sets"], {}, @_);
	for (my $i=0; $i < @{$args->{sets}};$i++) {
		my $set = $args->{sets}->[$i];
		my $obj = $self->interpretReference($set->{set},"Reactionset");
		if (defined($obj)) {
			$self->add("reactionSetMultipliers",{
				reactionset_ref => $obj->_reference(),
				reactionsetType => $set->{reactionsetType},
				multiplierType => $set->{multiplierType},
				description => $set->{description},
				multiplier => $set->{multiplier}
			});
		}
	}
}

sub parseGuaranteedReactions {
	my ($self,$args) = @_;
	$args->{data} = "uuid";
	$args->{class} = "Reaction";
	$self->guaranteedReaction_refs($self->parseReferenceList($args));
}

sub parseBlacklistedReactions {
	my ($self,$args) = @_;
	$args->{data} = "uuid";
	$args->{class} = "Reaction";
	$self->blacklistedReaction_refs($self->parseReferenceList($args));
}

sub parseAllowableCompartments {
	my ($self,$args) = @_;
	$args->{data} = "uuid";
	$args->{class} = "Compartment";
	$self->allowableCompartment_refs($self->parseReferenceList($args));
}

=head3 printStudy

Definition:
	string printStudy();
Description:
	Prints study data and solutions in human readable format

=cut

sub printStudy {
	my ($self,$index) = @_;
	my $solutions = $self->gapfillingSolutions();
	my $numSolutions = @{$solutions};
	my $output = "*********************************************\n";
	$output .= "Gapfilling formulation: GF".$index."\n";
	$output .= "Media: ".$self->media()->id()."\n";
	if ($self->geneKOString() ne "") {
		$output .= "GeneKO: ".$self->geneKOString()."\n";
	}
	if ($self->reactionKOString() ne "") {
		$output .= "ReactionKO: ".$self->reactionKOString()."\n";
	}
	$output .= "---------------------------------------------\n";
	if ($numSolutions == 0) {
		$output .= "No gapfilling solutions found!\n";
		$output .= "---------------------------------------------\n";
	} else {
		$output .= $numSolutions." gapfilling solution(s) found.\n";
		$output .= "---------------------------------------------\n";
	}
	for (my $i=0; $i < @{$solutions}; $i++) {
		$output .= "New gapfilling solution: GF".$index.".".$i."\n";
		$output .= $solutions->[$i]->printSolution();
		$output .= "---------------------------------------------\n";
	}
	return $output;
}

sub reactionPriorities {
	my ($self) = @_;
	return [qw(rxn01387 rxn00520 rxn08527 rxn01388 rxn08900 rxn01241 rxn00257 rxn00441 rxn00973 rxn00505 rxn00306 rxn00799 rxn08901 rxn00285 rxn00974 rxn08528 rxn05939 rxn00199 rxn09272 rxn00935 rxn01872 rxn02376 rxn01200 rxn00604 rxn03643 rxn01333 rxn01116 rxn01975 rxn01477 rxn03644 rxn00785 rxn01187 rxn00770 rxn00777 rxn01115 rxn00548 rxn01476 rxn00018 rxn01345 rxn00786 rxn05105 rxn00782 rxn01870 rxn00781 rxn01331 rxn01334 rxn00549 rxn01111 rxn01100 rxn00747 rxn05734 rxn02853 rxn00459 rxn01457 rxn01830 rxn01122 rxn07191 rxn03885 rxn01171 rxn00506 rxn01775 rxn10116 rxn00216 rxn01107 rxn01123 rxn01121 rxn01169 rxn01459 rxn01080 rxn01108 rxn00779 rxn01106 rxn05735 rxn00148 rxn00221 rxn01109 rxn01275 rxn01286 rxn00290 rxn01654 rxn00330 rxn00910 rxn00690 rxn00251 rxn00272 rxn00422 rxn01211 rxn01453 rxn00331 rxn01355 rxn04954 rxn00692 rxn00907 rxn00602 rxn02889 rxn02480 rxn03079 rxn01102 rxn01653 rxn00247 rxn00336 rxn00802 rxn01434 rxn00192 rxn02465 rxn01019 rxn00469 rxn01636 rxn01917 rxn07295 rxn02484 rxn01539 rxn01537 rxn02305 rxn00269 rxn09997 rxn00440 rxn00438 rxn01538 rxn03075 rxn03108 rxn01302 rxn01301 rxn01069 rxn00260 rxn03446 rxn01300 rxn00337 rxn01643 rxn02339 rxn01637 rxn01973 rxn05012 rxn00649 rxn05153 rxn05733 rxn00953 rxn05176 rxn09240 rxn05239 rxn00423 rxn00742 rxn00566 rxn00361 rxn00623 rxn05256 rxn00806 rxn09310 rxn00283 rxn07292 rxn01575 rxn00904 rxn00903 rxn00191 rxn00902 rxn01573 rxn00737 rxn00898 rxn03437 rxn03062 rxn03435 rxn02187 rxn03194 rxn02186 rxn02789 rxn03436 rxn03068 rxn00804 rxn01045 rxn02185 rxn02811 rxn01790 rxn03841 rxn03175 rxn01682 rxn02507 rxn01964 rxn00474 rxn00726 rxn00727 rxn02508 rxn01257 rxn00791 rxn00187 rxn00193 rxn03409 rxn03407 rxn12822 rxn00085 rxn00340 rxn00184 rxn00189 rxn00182 rxn00347 rxn00416 rxn03406 rxn00342 rxn02160 rxn02834 rxn00527 rxn02320 rxn02835 rxn00863 rxn02159 rxn02473 rxn00838 rxn00493 rxn00789 rxn03135 rxn04659 rxn06802 rxn04656 rxn02466 rxn03034 rxn06675 rxn02224 rxn04657 rxn01420 rxn01423 rxn03324 rxn04660 rxn00202 rxn04658 rxn02227 rxn02226 rxn01663 rxn00510 rxn01991 rxn01974 rxn07441 rxn00313 rxn01972 rxn01644 rxn03030 rxn03031 rxn02929 rxn03086 rxn03087 rxn06078 rxn05614 rxn03052 rxn02302 rxn00952 rxn05958 rxn05219 rxn06799 rxn00693 rxn02028 rxn01304 rxn01303 rxn11944 rxn00126 rxn00740 rxn05957 rxn05613 rxn00141 rxn01816 rxn00452 rxn05183 rxn01256 rxn00929 rxn02356 rxn02373 rxn00179 rxn00931 rxn02358 rxn01101 R02607 rxn02914 rxn03445 rxn00420 rxn02212 rxn02331 rxn01332 rxn00525 rxn01364 rxn02213 rxn01255 rxn00526 rxn01269 rxn01739 rxn01740 rxn01268 rxn10125 rxn02988 rxn10060 rxn01438 rxn00262 rxn05117 rxn02155 rxn00938 rxn01927 rxn05119 rxn01437 rxn10181 rxn00138 rxn00338 rxn02177 rxn00941 rxn00775 rxn00105 rxn00076 rxn02989 rxn01265 rxn00083 rxn01930 rxn01671 rxn02402 rxn00077 rxn00190 rxn00478 rxn04139 rxn03395 rxn12224 rxn11946 rxn00966 rxn03394 rxn03893 rxn01258 rxn08333 rxn11702 rxn05024 rxn02831 rxn02832 rxn11703 rxn04673 rxn02898 rxn00143 rxn01858 rxn00203 rxn01022 rxn01021 rxn01137 R06860 rxn10044 rxn03492 rxn07586 rxn05054 rxn02775 rxn02897 rxn04046 rxn04052 rxn04045 rxn07587 rxn04384 rxn04413 rxn03537 rxn03514 rxn03536 rxn03150 rxn04385 rxn06979 rxn04048 rxn04050 rxn03513 rxn05029 rxn03538 rxn11544 rxn03540 rxn04047 rxn03512 rxn00100 rxn02341 rxn09177 rxn01791 rxn12510 rxn02128 R04233 rxn10180 rxn00912 rxn12512 rxn02175 rxn00346 rxn03541 rxn05187 rxn11545 rxn00074 rxn07589 rxn03534 rxn03491 rxn08194 rxn10476 rxn02287 rxn07588 rxn03535 rxn10147 rxn11650 rxn05515 rxn00124 rxn03909 rxn01807 rxn01396 rxn00123 rxn00208 rxn05144 rxn00209 rxn04070 rxn03951 rxn01398 rxn02939 rxn03638 rxn01483 rxn00555 rxn00461 rxn01505 rxn01485 rxn00293 rxn02285 rxn01316 rxn00292 rxn00297 rxn00827 rxn06299 rxn07307 rxn03962 rxn00642 rxn04599 rxn11932 rxn04598 rxn08707 rxn04600 rxn03991 rxn05189 rxn10133 rxn04597 rxn03990 rxn03419 rxn00302 rxn01351 rxn01518 rxn00689 rxn00299 rxn02200 rxn01519 rxn01143 rxn03168 rxn03174 rxn01602 rxn02986 rxn01520 rxn02201 rxn02504 rxn01962 rxn02503 rxn03173 rxn01521 rxn02518 rxn00463 rxn03421 rxn00686 rxn00301 rxn00514 rxn01603 rxn01210 rxn02056 rxn00029 rxn03384 rxn09180 rxn02774 rxn04704 rxn01629 rxn02288 rxn00060 rxn00599 rxn06591 rxn06937 rxn00224 rxn02304 rxn02264 rxn02303 rxn02866 rxn00872 rxn00991 rxn00988 rxn01504 rxn00947 rxn05249 rxn02296 rxn05250 rxn05252 rxn08180 rxn09449 rxn05247 rxn05223 rxn02297 rxn05248 rxn05251 rxn05736 rxn00792 rxn02277 rxn09448 rxn02312 rxn09450 rxn10318 rxn10324 rxn10320 rxn10319 rxn10191 rxn10321 rxn10322 rxn10316 rxn10317 rxn10323 rxn05229 rxn02937 rxn03137 rxn00832 rxn03136 rxn03147 rxn03084 rxn00800 rxn00790 rxn04783 rxn02938 rxn03004 rxn02895 rxn01018 rxn00710 rxn00711 rxn01360 rxn01465 rxn01361 rxn00414 rxn08335 rxn01362 rxn08336 rxn05391 rxn05330 rxn05408 rxn05422 rxn05448 rxn05415 rxn05328 rxn05372 rxn05341 rxn05412 rxn05460 rxn05346 rxn05335 rxn05381 rxn05386 rxn05428 rxn05334 rxn06022 rxn05354 rxn05376 rxn05342 rxn05350 rxn05437 rxn05463 rxn05396 rxn05363 rxn05324 rxn05464 rxn05359 rxn05322 rxn05416 rxn05458 rxn05453 rxn05337 rxn05367 rxn05385 rxn05443 rxn05434 rxn05432 rxn05417 rxn05436 rxn05397 rxn05421 rxn05329 rxn05427 rxn05392 rxn05340 rxn05403 rxn05461 rxn05356 rxn05368 rxn05351 rxn05362 rxn05418 rxn06023 rxn05355 rxn05393 rxn05440 rxn05345 rxn05444 rxn05431 rxn05382 rxn05433 rxn05373 rxn05465 rxn05452 rxn05336 rxn05325 rxn05407 rxn05449 rxn05377 rxn05459 rxn05357 rxn05323 rxn05398 rxn05333 rxn05383 rxn05441 rxn05426 rxn05364 rxn05419 rxn05430 rxn05402 rxn05413 rxn05348 rxn05370 rxn05445 rxn05369 rxn05446 rxn05435 rxn05361 rxn05456 rxn05410 rxn06673 rxn05394 rxn05378 rxn05326 rxn05455 rxn05344 rxn05387 rxn05349 rxn05374 rxn05388 rxn05429 rxn05424 rxn05406 rxn05352 rxn05365 rxn05439 rxn05339 rxn05451 rxn05401 rxn05371 rxn05347 rxn05338 rxn05400 rxn05442 rxn05425 rxn05358 rxn05332 rxn05447 rxn05399 rxn05360 rxn05438 rxn05409 rxn05420 rxn05414 rxn05390 rxn05405 rxn05327 rxn05423 rxn05404 rxn05462 rxn05450 rxn05375 rxn05457 rxn05411 rxn06672 rxn05379 rxn05384 rxn05389 rxn05366 rxn05380 rxn05331 rxn05395 rxn05454 rxn05343 rxn05353 rxn10295 rxn10304 rxn03852 rxn10277 rxn10288 rxn10193 rxn10281 rxn10297 rxn10292 rxn10278 rxn10280 rxn10308 rxn10302 rxn10311 rxn10296 rxn10273 rxn10305 rxn03901 rxn10287 rxn10192 rxn10271 rxn10315 rxn10309 rxn10298 rxn10274 rxn10306 rxn10284 rxn10303 rxn10195 rxn10283 rxn10286 rxn10279 rxn10272 rxn10299 rxn00621 rxn10293 rxn10197 rxn10300 rxn10275 rxn10307 rxn10285 rxn10312 rxn10290 rxn10310 rxn10194 rxn10291 rxn10294 rxn10314 rxn10282 rxn10276 rxn08040 rxn10289 rxn10301 rxn10196 rxn10313 rxn03907 rxn09996 rxn00211 rxn00433 rxn05184 rxn05193 rxn01867 rxn05181 rxn05505 rxn05192 rxn01868 rxn05504 rxn00752 rxn05180 rxn00756 rxn10770 rxn06729 rxn02404 rxn03159 rxn06865 rxn02405 rxn01117 rxn03439 rxn06848 rxn03146 rxn03130 rxn03181 rxn03182 rxn06723 rxn00612 rxn03975 rxn00611 rxn00351 rxn02792 rxn01981 rxn00646 rxn00350 rxn02791 rxn00186 rxn01834 rxn01274 rxn00748 rxn00205 rxn00086 rxn02762 rxn02521 rxn02522 rxn03483 rxn01403 rxn02377 rxn01675 rxn01997 rxn09289 rxn01999 rxn08954 rxn03511 rxn08713 rxn03916 rxn08709 rxn03919 rxn08712 rxn08620 rxn08619 rxn08708 rxn03918 rxn08583 rxn08618 rxn08711 rxn03917 rxn08710 rxn03910 rxn00829 rxn03908 rxn04308 rxn01607 rxn04113 rxn04996 rxn03958 rxn00830 rxn08756 rxn05293 rxn01501 rxn01454 rxn08352 rxn02322 rxn03843 rxn10199 rxn02286 rxn02008 rxn03933 rxn03408 rxn02011 rxn03904 rxn03903 rxn00851 rxn01270 rxn01000 rxn00490 rxn01134 rxn00605 rxn02004 rxn00497 rxn01833 rxn01715 rxn01450 rxn00529 rxn00484 rxn10011 rxn02949 rxn03241 rxn10014 rxn03245 rxn02911 rxn10010 rxn02167 rxn10013 rxn05732 rxn03250 rxn01452 rxn02527 rxn02934 rxn03240 rxn03247 rxn10012 rxn00868 rxn04713 rxn02345 rxn01923 rxn02933 rxn00990 rxn04750 rxn03244 rxn01451 rxn00875 rxn03239 rxn03246 rxn03242 rxn02168 rxn00871 rxn01480 rxn03249 rxn01236 rxn06777 rxn02268 rxn12008 rxn01486 rxn11684 rxn03892 rxn05287 rxn03891 rxn07468 rxn05028 rxn00541 rxn00471 rxn05300 rxn00274 rxn01068 rxn00671 rxn07430 rxn07435 rxn07434 rxn06586 rxn01924 rxn07431 rxn03433 rxn07432 rxn06335 rxn07433 rxn01925 rxn02270 rxn03422 rxn00503 rxn00405 rxn02944 rxn05164 rxn00183 rxn00601 rxn00470 rxn00853 rxn00291 rxn00395 rxn05303 rxn02927 rxn05156 rxn05151 rxn00322 rxn00856 rxn00467 rxn00394 rxn05154 rxn10131 rxn01029 rxn00114 rxn00858 rxn00999 rxn03055 rxn02366 rxn05306 rxn01315 rxn02883 rxn01203 rxn02885 rxn03041 rxn00473 rxn00479 rxn05663 rxn04989 rxn03040 rxn05301 rxn01685 rxn00640 rxn00638 rxn05574 rxn05673 rxn01329 rxn01737 rxn00577 rxn00558 rxn00704 rxn00222 rxn02380 rxn09978 rxn02760 rxn09979 rxn01977 rxn00213 rxn00225 rxn00670 rxn00173 rxn01199 rxn01753 rxn05671 rxn01751 rxn01041 rxn01649 rxn05680 rxn01548 rxn01859 rxn08471 rxn05621 rxn05656 rxn05171 rxn05737 rxn05585 rxn08467 rxn03630 rxn05172 rxn10067 rxn05594 rxn05552 rxn08468 rxn05599 rxn05512 rxn05620 rxn03974 rxn08469 rxn08470 rxn00327 rxn01747 rxn00010 rxn03842 rxn01746 rxn02102 rxn01280 rxn01748 rxn02103 rxn01281 rxn08851 rxn08800 rxn08823 rxn08807 rxn08809 rxn09134 rxn08844 rxn09125 rxn08814 rxn08816 rxn09157 rxn09128 rxn08803 rxn09142 rxn08840 rxn09161 rxn08822 rxn09147 rxn08847 rxn08812 rxn08808 rxn08806 rxn08841 rxn09164 rxn09152 rxn09124 rxn09131 rxn08815 rxn09133 rxn08817 rxn08799 rxn09138 rxn09143 rxn09153 rxn08838 rxn08821 rxn09160 rxn08850 rxn09158 rxn08802 rxn08848 rxn09148 rxn09144 rxn08842 rxn09150 rxn09130 rxn08818 rxn09149 rxn09163 rxn08810 rxn09159 rxn09132 rxn08805 rxn09127 rxn09140 rxn08813 rxn08796 rxn08845 rxn08849 rxn09145 rxn09137 rxn08801 rxn09154 rxn08820 rxn08819 rxn08811 rxn09151 rxn09146 rxn08804 rxn09123 rxn09139 rxn08839 rxn08843 rxn08798 rxn08797 rxn08846 rxn09126 rxn09141 rxn09135 rxn09136 rxn09155 rxn09162 rxn09129 rxn09156 rxn12500 rxn08179 rxn10128 rxn10127 rxn08178 rxn10120 rxn01893 rxn00540 rxn00171 rxn00560 rxn05667 rxn00101 rxn05214 rxn00265 rxn05213 rxn05589 rxn10150 rxn05226 rxn05655 rxn00787 rxn05563 rxn10188 rxn10187 rxn00691 rxn00598 rxn05168 rxn05179 rxn05161 rxn05536 rxn05544 rxn12848 rxn12851 rxn05539 rxn05541 rxn05537 rxn05543 rxn12849 rxn05533 rxn05540 rxn05534 rxn05547 rxn05546 rxn05542 rxn05535 rxn12850 rxn05545 rxn05538 rxn05152 rxn05146 rxn05155 rxn10473 rxn00102 rxn06077 rxn05225 rxn00607 rxn04020 rxn05611 rxn00007 rxn00606 rxn01967 rxn02005 rxn05573 rxn05555 rxn05149 rxn05618 rxn05619 rxn05174 rxn05150 rxn10481 rxn05528 rxn05177 rxn05645 rxn05145 rxn02166 rxn00743 rxn03167 rxn05560 rxn05647 rxn05485 rxn05501 rxn05289 rxn01094 rxn01093 rxn10855 rxn05557 rxn05217 rxn05298 rxn05507 rxn05305 rxn09699 rxn05561 rxn05204 rxn05622 rxn10892 rxn10857 rxn05526 rxn05605 rxn10868 rxn05159 rxn05508 rxn05669 rxn05566 rxn05654 rxn05215 rxn05559 rxn05216 rxn05506 rxn05244 rxn05516 rxn05514 rxn05527 rxn10343 rxn05211 rxn05167 rxn10344 rxn05625 rxn05243 rxn10895 rxn01277 rxn02363 rxn01945 rxn02113 rxn02115 rxn02112 rxn00702 rxn01871 rxn01750 rxn02632 rxn09953 rxn00763 rxn00543 rxn02275 rxn03869 rxn02222 rxn01843 rxn00231 rxn03839 rxn00849 rxn05466 rxn09313 rxn08354 rxn03126 rxn11934 rxn08356 rxn09315 rxn01466 rxn01213 rxn01943 rxn02411 rxn01840 rxn02971 rxn02143 rxn02782 rxn00588 rxn00584 rxn00959 rxn03898 rxn03897 rxn05518 rxn03481 rxn00020 rxn09992 rxn00608 rxn03482 rxn08025 rxn06526 rxn05937 rxn05616 rxn10474 rxn08258 rxn05031 rxn01489 rxn02945 rxn02144 rxn02788 rxn00892 rxn00552 rxn00016 rxn01484 rxn02733 rxn04152 rxn04162 rxn04153 rxn02716 rxn11942 rxn04160 rxn04158 rxn04161 rxn04705 rxn04154 rxn11940 rxn02959 rxn04159 rxn11941 rxn04602 rxn02416 rxn04601 rxn01895 rxn04604 rxn04603 rxn03038 rxn05315 rxn04016 rxn05517 rxn00717 rxn01025 rxn05292 rxn05063 rxn10132 rxn10046 rxn01368 rxn01800 rxn12636 rxn07584 rxn00011 rxn02342 rxn00567 rxn05890 rxn01806 rxn11937 rxn05316 R02299 rxn01648 rxn01986 rxn09687 rxn05317 rxn00772 rxn01987 rxn01146 rxn05198 rxn09688 rxn05199 rxn05200 rxn01366 rxn00784 rxn09685 rxn05318 rxn00778 rxn05205 rxn05572 rxn01634 rxn02346 rxn03887 rxn07845 rxn01990 rxn01989 rxn05565 rxn00783 rxn10160 rxn02173 rxn02429 rxn01857 rxn05681 rxn03954 rxn03953 rxn01291 rxn05571 rxn01279 rxn08345 rxn10167 rxn01278 rxn00744 rxn05581 rxn00745 rxn00615 rxn00634 rxn00883 rxn00882 rxn00881 rxn00609 rxn01819 rxn13783 rxn05549 rxn05160 rxn05644 rxn09661 rxn02313 rxn03886 rxn10184 rxn05648 rxn05567 rxn00545 rxn03856 rxn01343 rxn02000 rxn02003 rxn00095 rxn00776 rxn05551 rxn00539 rxn10042 rxn10161 rxn10162 rxn10163 rxn00499 rxn00146 rxn08783 rxn08792 rxn01057 rxn00145 rxn08793 rxn00500 not_in_KEGG rxn00157 rxn10114 rxn00371 rxn10118 rxn03236 rxn05147 rxn05173 rxn00818 rxn10169 rxn03838 rxn00817 rxn02596 rxn05170 rxn01492 rxn02314 rxn00547 rxn10155 rxn10157 rxn00288 rxn00656 rxn08291 rxn05126 rxn05127 rxn02925 rxn00816 rxn01205 rxn02171 rxn00194 rxn03641 rxn01201 rxn00069 rxn01252 rxn00509 rxn01204 rxn03642 rxn01851 rxn00508 rxn10136 rxn05564 rxn03906 rxn04745 rxn00589 rxn04748 rxn04724 rxn01011 rxn00512 rxn00324 rxn01013 rxn01015 rxn01416 rxn01073 rxn00762 rxn05158 rxn08669 rxn00616 rxn08557 rxn00758 rxn08556 rxn00066 rxn08558 rxn00614 rxn00768 rxn02235 rxn00769 rxn10215 rxn09104 rxn08297 rxn10266 rxn10230 rxn10225 rxn10259 rxn08311 rxn09200 rxn10340 rxn08294 rxn09103 rxn09208 rxn08202 rxn10219 rxn10206 rxn10255 rxn09107 rxn08203 rxn10334 rxn10203 rxn08298 rxn08549 rxn09111 rxn08089 rxn10212 rxn10337 rxn10235 rxn10221 rxn09199 rxn08083 rxn10209 rxn09105 rxn08204 rxn08551 rxn08308 rxn08199 rxn10214 rxn10338 rxn10263 rxn10341 rxn10269 rxn09207 rxn09114 rxn08309 rxn08312 rxn09210 rxn10256 rxn10211 rxn10205 rxn10218 rxn10335 rxn10229 rxn08300 rxn09110 rxn08552 rxn10267 rxn10236 rxn10222 rxn08295 rxn09203 rxn10204 rxn08086 rxn09206 rxn10227 rxn09113 rxn08547 rxn10233 rxn10342 rxn10217 rxn08307 rxn08205 rxn10264 rxn10208 rxn09108 rxn08299 rxn10261 rxn10232 rxn08296 rxn09202 rxn09197 rxn10339 rxn10226 rxn10237 rxn10223 rxn10210 rxn09101 rxn08087 rxn10268 rxn10253 rxn09205 rxn08548 rxn08546 rxn09112 rxn08088 rxn10265 rxn09102 rxn10234 rxn10202 rxn08200 rxn10207 rxn08306 rxn08085 rxn09109 rxn10258 rxn10228 rxn10216 rxn09211 rxn08550 rxn10336 rxn10257 rxn09209 rxn09198 rxn09106 rxn10270 rxn10224 rxn10231 rxn10262 rxn08310 rxn08201 rxn09201 rxn08084 rxn10260 rxn10254 rxn10213 rxn10220 rxn06377 rxn05649 rxn00166 rxn05307 rxn00165 rxn06600 rxn06493 rxn05494 rxn09296 rxn08941 rxn08126 rxn08615 rxn08129 rxn08127 rxn08128 rxn08943 rxn00695 rxn05740 rxn08942 rxn00979 rxn08657 rxn05470 rxn08655 rxn00980 rxn08656 rxn00551 rxn00147 rxn00151 rxn00248 rxn03884 rxn00328 rxn00256 rxn05148 rxn05188 rxn00546 rxn00375 rxn01642 rxn01641 rxn01640 rxn01639 rxn02085 rxn05299 rxn00867 rxn00001 rxn01626 rxn00654 rxn03188 rxn02190 rxn09657 rxn05197 rxn05682 rxn10117 rxn10119 rxn03393 rxn05596 rxn00379 rxn00137 rxn05902 rxn05651 rxn00879 rxn05593 rxn02007 rxn00502 rxn00501 rxn00880 rxn01176 rxn00065 rxn06510 rxn03248 rxn00676 rxn02804 rxn00874 rxn03243 rxn00178 rxn02680 rxn00675 rxn00175 rxn00986 rxn05938 rxn05602 rxn00295 rxn00214 rxn02332 rxn02318 rxn10865 rxn00355 rxn00808 rxn05162 rxn01763 rxn05500 rxn01292 rxn01114 rxn04082 rxn01828 rxn09988 rxn01633 rxn01289 rxn04928 rxn01911 rxn01912 rxn02321 rxn02319 rxn02263 rxn01620 rxn01615 rxn05646 rxn01053 rxn01390 rxn02161 rxn01761 rxn05598 rxn01621 rxn10148 rxn00321 rxn00312 rxn01578 rxn01729 rxn01662 rxn11943 rxn01630 rxn01580 rxn00511 rxn00320 rxn02344 rxn01579 rxn01631 rxn01581 rxn12206 rxn12432 rxn08934 rxn05746 rxn08935 rxn10174 rxn01133 rxn01259 rxn08936 rxn05608 rxn00575 rxn01966 rxn01132 rxn08933 rxn00022 rxn05607 rxn09989 rxn05617 rxn00629 rxn00641 rxn00975 rxn05610 rxn05612 rxn00847 rxn03020 rxn11938 rxn03085 rxn03127 rxn02431 rxn05106 rxn02894 rxn05104 rxn03057 rxn05092 rxn05108 rxn03061 rxn00669 rxn03060 rxn00289 rxn00679 rxn01618 rxn00239 rxn09562 rxn01509 rxn13784 rxn05209 rxn09167 rxn00672 rxn05313 rxn10121 rxn03978 rxn00568 rxn05893 rxn00569 rxn05627 rxn00400 rxn00082 rxn06874 rxn00369 rxn00720 rxn00715 rxn01028 rxn00709 rxn00368 rxn00365 rxn00713 rxn00056 rxn00006 rxn07438 rxn01842 rxn02449 rxn05312 rxn11268 rxn02900 rxn00537 rxn05493 rxn09264 rxn01406 rxn10182 rxn05687 rxn00127 rxn02061 rxn09265 rxn05683 rxn12405 rxn05484 rxn00038 rxn00992 rxn00994 rxn10168 rxn05206 rxn10945 rxn09188 rxn02071 rxn01635 rxn00933 rxn05221 rxn02029 rxn02946 rxn00196 rxn05638 rxn02360 rxn02359 rxn00932 rxn01709 rxn00985 rxn01879 rxn01996 rxn12644 rxn12637 rxn12844 rxn12640 rxn12645 rxn12845 rxn12641 rxn12633 rxn00650 rxn12646 rxn12846 rxn12642 rxn12634 rxn12639 rxn12847 rxn12638 rxn12643 rxn12635 rxn02483 rxn01192 rxn02369 rxn01313 rxn01314 rxn02985 rxn01324 rxn01367 rxn00835 rxn01678 rxn00117 rxn00915 rxn00839 rxn01508 rxn01139 rxn00409 rxn01673 rxn01127 rxn00134 rxn01507 rxn01298 rxn00916 rxn00836 rxn01524 rxn02400 rxn01670 rxn00363 rxn00927 rxn00708 rxn01444 rxn00515 rxn00917 rxn01218 rxn01299 rxn01226 rxn01704 rxn00834 rxn00926 rxn00837 rxn00131 rxn10052 rxn00097 rxn00139 rxn01445 rxn01512 rxn01549 rxn01225 rxn00913 rxn01352 rxn01145 rxn01545 rxn00914 rxn01353 rxn01544 rxn00132 rxn00237 rxn01961 rxn00063 rxn00831 rxn01523 rxn05202 rxn01522 rxn01297 rxn05201 rxn02761 rxn04453 rxn01674 rxn00797 rxn01370 rxn01813 rxn00362 rxn01706 rxn01223 rxn00408 rxn00120 rxn01222 rxn00366 rxn00714 rxn01221 rxn01516 rxn01677 rxn01219 rxn00410 rxn00116 rxn01515 rxn01510 rxn01511 rxn04464 rxn01513 rxn00364 rxn01672 rxn01220 rxn00712 rxn01128 rxn01679 rxn01129 rxn01514 rxn00118 rxn01705 rxn00412 rxn01541 rxn00707 rxn01517 rxn00407 rxn00160 rxn10152 rxn00252 rxn05207 rxn10154 rxn00161 rxn10151 rxn00305 rxn00162 rxn10153 rxn01285 rxn04143 rxn00250 rxn01847 rxn00159 rxn05604 rxn05208 rxn01103 rxn00544 rxn00227 rxn9167 rxn00152 rxn00172 rxn01188 rxn00206 rxn10122 rxn08978 rxn08977 rxn10123 rxn08976 rxn08975 rxn08971 rxn10124 rxn08979 rxn00430 rxn00431 rxn01383 rxn03883 rxn01385 rxn00048 rxn02474 rxn05039 rxn00122 rxn00392 rxn02475 rxn00300 rxn03080 rxn05040 rxn05232 rxn05231 rxn05236 rxn05234 rxn06076 rxn05235 rxn05233 rxn06075 rxn13782 rxn02569 rxn01506 rxn01322 rxn01951 rxn00897 rxn02046 rxn00303 rxn00242 rxn10806 rxn10126 rxn10113 rxn01044 rxn00223 rxn05023 rxn10043 rxn00058 rxn00449 rxn02279 rxn00245 rxn02122 rxn04794 rxn04454 rxn04938 rxn04712 rxn05297)];
}

__PACKAGE__->meta->make_immutable;
1;
