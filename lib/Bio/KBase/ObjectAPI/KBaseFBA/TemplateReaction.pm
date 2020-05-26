########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TemplateReaction - This is the moose object corresponding to the TemplateReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-04-26T05:53:23
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateReaction;
package Bio::KBase::ObjectAPI::KBaseFBA::TemplateReaction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateReaction';
use Bio::KBase::ObjectAPI::utilities;
#use Digest::MD5::md5_hex;

#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has equation => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequation' );
has definition => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefinition' );
has complexIDs => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcomplexIDs' );
has isBiomassTransporter => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisBiomassTransporter' );
has inSubsystem => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildinSubsystem' );
has msid => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmsid' );
has msname => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmsname' );
has msabbreviation => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmsabbreviation' );
has isTransporter => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisTransporter' );
has stoichiometry => ( is => 'rw', isa => 'ArrayRef', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildstoichiometry' );
has equationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequationcode' );
has revEquationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildrevequationcode' );
has reaction_ref => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreaction_ref' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildequationcode {
	my ($self) = @_;
	return $self->createEquation({format=>"codeid",hashed=>1,protons=>0,direction=>0});
}
sub _buildrevequationcode {
	my ($self) = @_;
	return $self->createEquation({format=>"codeid",hashed=>1,protons=>0,reverse=>1,direction=>0});
}
sub _builddefinition {
	my ($self) = @_;
	return $self->createEquation({format=>"name"});
}
sub _buildequation {
	my ($self) = @_;
	return $self->createEquation({format=>"id"});
}
sub _buildreaction_ref {
	my ($self) = @_;
	my $array = [split(/_/,$self->id())];
	return $self->parent()->biochemistry_ref()."/reactions/id/".$array->[0];
}
sub _buildmsid {
	my ($self) = @_;
	my $array = [split(/_/,$self->id())];
	return $array->[0];
}
sub _buildmsname {
	my ($self) = @_;
	my $array = [split(/_/,$self->name())];
	return $array->[0];
}
sub _buildmsabbreviation {
	my ($self) = @_;
	my $array = [split(/_/,$self->abbreviation())];
	return $array->[0];
}
sub _buildcomplexIDs {
	my ($self) = @_;
	my $output = [];
	my $cpxs = $self->templatecomplexs();
	for (my $i=0; $i <@{$cpxs}; $i++) {
		my $cpx = $cpxs->[$i];
		push(@{$output},$cpx->id());
	}
	return $output;
}
sub _buildisBiomassTransporter {
	my ($self) = @_;
	my $rgts = $self->templateReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->templatecompcompound()->isBiomassCompound() == 1) {
			for (my $j=$i+1; $j < @{$rgts}; $j++) {
				my $rgtc = $rgts->[$j];
				if ($rgt->templatecompcompound()->templatecompound_ref() eq $rgtc->templatecompcompound()->templatecompound_ref()) {
					if ($rgt->templatecompcompound()->templatecompartment_ref() ne $rgtc->templatecompcompound()->templatecompartment_ref()) {
						return 1;
					}
				}
			}
		}
	}
	return 0;
}
sub _buildinSubsystem {
	my ($self) = @_;
	my $rolesshash = $self->parent()->roleSubsystemHash();
	my $complexes = $self->templatecomplexs();
	foreach my $complex (@{$complexes}) {
		my $cpxroles = $complex->complexroles();
		foreach my $cpxrole (@{$cpxroles}) {
			my $role = $cpxrole->templaterole();
			if (defined($rolesshash->{$role->id()})) {
				return 1;
			}
		}
	}
	return 0;
}
sub _buildisTransporter {
	my ($self) = @_;
	my $rgts = $self->templateReactionReagents();
	my $initrgt = $rgts->[0];
	for (my $i=1; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->templatecompcompound()->templatecompartment_ref() ne $initrgt->templatecompcompound()->templatecompartment_ref()) {
			return 1;	
		}
	}
	return 0;
}

sub _buildstoichiometry {
	my ($self) = @_;
	my $stoichiometry = [];
	foreach my $reagent (@{$self->templateReactionReagents()}) {
		push(@{$stoichiometry},[$reagent->coefficient(),$reagent->templatecompcompound()->templatecompound()->name(),$reagent->templatecompcompound()->id()]);
	}
	return $stoichiometry;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 createEquation
Definition:
	string = Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction->createEquation({
		format => string(id),
		hashed => 0/1(0)
	});
Description:
	Creates an equation for the model reaction with compounds specified according to the input format

=cut

sub createEquation {
    my ($self,$args) = @_;
    $args = Bio::KBase::ObjectAPI::utilities::args([], { 
    	indecies => 1,
		format => 'id',
        hashed => 0,
        water => 1,
		compts=>1,
		reverse=>0,
		direction=>1,
		protons => 1,
		generalized => 0,
		stoichiometry => 0
    }, $args);
	
	my $rgts = $self->templateReactionReagents();
	my $rgtHash;
	my $objhash;
    my $rxnCompID = $self->templatecompartment()->id();
    my $hcpd = $self->parent()->checkForProton();
 	if (!defined($hcpd) && $args->{hashed}==1) {
	    Bio::KBase::ObjectAPI::utilities::error("Could not find proton in biochemistry!");
	}
	my $wcpd = $self->parent()->checkForWater();
 	if (!defined($wcpd) && $args->{water}==1) {
	    Bio::KBase::ObjectAPI::utilities::error("Could not find water in biochemistry!");
	}
	
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		my $id = $rgt->templatecompcompound()->templatecompound()->id();
		if ($id eq "cpd00000") {
			$id = $rgt->templatecompcompound()->id();
		}

		next if $args->{protons} == 0 && $id eq $hcpd->id() && !$self->isTransporter();
		next if $args->{water} == 0 && $id eq $wcpd->id();

		if (!defined($rgtHash->{$id}->{$rgt->templatecompcompound()->templatecompartment()->id()})) {
			$rgtHash->{$id}->{$rgt->templatecompcompound()->templatecompartment()->id()} = 0;
		}
		$rgtHash->{$id}->{$rgt->templatecompcompound()->templatecompartment()->id()} += $rgt->coefficient();
		$objhash->{$id}->{$rgt->templatecompcompound()->templatecompartment()->id()} = $rgt;
		$rgtHash->{$id}->{"name"} = $rgt->templatecompcompound()->templatecompound()->name();
	}

    my @reactcode = ();
    my @productcode = ();
    my $sign = " <=> ";

    if($args->{direction}==1){
		$sign = " => " if $self->direction() eq ">";
		$sign = " <= " if $self->direction() eq "<";
    }
	
    my %FoundComps=();
    my $CompCount=0;

    my $sortedCpd = [sort(keys(%{$rgtHash}))];
    for (my $i=0; $i < @{$sortedCpd}; $i++) {
		#No matter what "print ID" is selected, the reagents will be sorted by cpd ID first
		my $comps = [sort(keys(%{$rgtHash->{$sortedCpd->[$i]}}))];
		for (my $j=0; $j < @{$comps}; $j++) {
		    if ($comps->[$j] =~ m/([a-z])/ && $comps->[$j] ne "name") {
			    my $printId = $sortedCpd->[$i];
			    my $cpd = $objhash->{$sortedCpd->[$i]}->{$comps->[$j]}->templatecompcompound()->templatecompound();
			    if($args->{format} ne "id") {
				    if($args->{format} eq "name"){
						$printId = $cpd->name();
				    } elsif ($args->{format} eq "msid"){
				    	$printId = $cpd->msid();
				     } elsif ($args->{format} eq "codeid"){
				    	$printId = $cpd->codeid();
				    }elsif($args->{format} ne "uuid" && $args->{format} ne "formula") {
						$printId = $cpd->getAlias($args->{format});
				    }elsif($args->{format} eq "formula"){
						$printId = $cpd->formula();
				    }
				}
		    
				my $comp = $1;
				my $index = 0;
				my $compartment = $comp;
		
				if($args->{generalized} && !exists($FoundComps{$comp})){
				    $compartment = $CompCount;
				    $FoundComps{$comp}=$CompCount;
				    $CompCount++;
				}elsif($args->{generalized} && exists($FoundComps{$comp})){
				    $compartment = $FoundComps{$comp};
				}
				
				#if ($args->{indecies} == 0) {
				    $compartment = "[".$compartment."]" if !$args->{stoichiometry};
				#}else{
				#    $compartment = "[".$compartment.$index."]" if !$args->{stoichiometry};
				#}
		
				$compartment= "" if !$args->{compts};
		
				if ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} < 0) {
				    my $coef = -1*$rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
				    my $reactcode = "(".$coef.") ".$printId.$compartment;
					if($args->{stoichiometry}==1){
				    	my $name = $rgtHash->{$sortedCpd->[$i]}->{name};
					    $coef = $rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
					    $reactcode = join(":",($coef,$printId,$compartment,'0',"\"".$name."\""));
					}
				    push(@reactcode,$reactcode);
		
				} elsif ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} > 0) {
				    my $coef = $rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
				    
				    my $productcode .= "(".$coef.") ".$printId.$compartment;
					if($args->{stoichiometry}==1){
					    my $name = $rgtHash->{$sortedCpd->[$i]}->{name};
					    $productcode = join(":",($coef,$printId,$compartment,'0',"\"".$name."\""));
					}
				    push(@productcode, $productcode);
				}
		    }
		}
    }
    

    my $reaction_string = join(" + ",@reactcode).$sign.join(" + ",@productcode);

	if($args->{stoichiometry} == 1){
		$reaction_string = join(";",@reactcode,@productcode);
	}

    if($args->{reverse}==1){
	$reaction_string = join(" + ",@productcode).$sign.join(" + ",@reactcode);
    }

    if ($args->{hashed} == 1) {
	#return Digest::MD5::md5_hex($reaction_string);
    }
    return $reaction_string;
}

sub compute_penalties {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([],{
		no_KEGG_penalty => 1,
		no_KEGG_map_penalty => 1,
		functional_role_penalty => 2,
		subsystem_penalty => 1,
		transporter_penalty => 1,
		unknown_structure_penalty => 1,
		biomass_transporter_penalty => 1,
		single_compound_transporter_penalty => 1,
		direction_penalty => 1,
		unbalanced_penalty => 10,
		no_delta_G_penalty => 1
	}, @_);
	my $thermopenalty = 0; 
	my $coefficient = 1;
	my $rxnhash = Bio::KBase::utilities::reaction_hash();
	my $id = "rxn00000";
	if ($self->reaction_ref() =~ m/(rxn\d+)/) {
		$id = $1;
	}
	if (!defined($rxnhash->{$id})) {
		$coefficient += $args->{no_KEGG_penalty} +
			$args->{no_KEGG_map_penalty} +
			$args->{no_delta_G_penalty} +
			$args->{functional_role_penalty} +
			$args->{subsystem_penalty} +
			$args->{unknown_structure_penalty};
	} else {
		my $rxnobj = $rxnhash->{$id};
		if (!defined($rxnobj->{deltag}) || $rxnobj->{deltag} == 10000000) {
			$coefficient += $args->{no_delta_G_penalty}+$args->{unknown_structure_penalty};
		}
		if (!defined($rxnobj->{kegg_aliases})) {
			$coefficient += $args->{no_KEGG_penalty};
		}
		if (!defined($rxnobj->{kegg_pathways})) {
			$coefficient += $args->{no_KEGG_map_penalty};
		}
		if (!defined($rxnobj->{roles})) {
			$coefficient += $args->{functional_role_penalty};
		}
		if (!defined($rxnobj->{subsystems})) {
			$coefficient += $args->{subsystem_penalty};
		}
		if ($rxnobj->{status} ne "OK") {
			$coefficient += $args->{unbalanced_penalty};
		}
		if ($rxnobj->{reversibility} eq ">") {
			$self->forward_penalty(0);
			$self->reverse_penalty($args->{direction_penalty}+$thermopenalty);
		} elsif ($rxnobj->{reversibility} eq "<") {
			$self->reverse_penalty(0);
			$self->forward_penalty($args->{direction_penalty}+$thermopenalty);
		} else {
			$self->forward_penalty(0);
			$self->reverse_penalty(0);
		}
	}
	if ($self->isTransporter()) {
		$coefficient += $args->{transporter_penalty};
		if (@{$self->templateReactionReagents()} <= 2) {
			$coefficient += $args->{single_compound_transporter_penalty};
		}
	}
	$self->base_cost($coefficient);
}

sub ProcessAnnotationData {
	my $self = shift;
	my $args = shift;
	$args = Bio::KBase::ObjectAPI::utilities::args(["data"],{
		probability => 0,
		coverage => 0,
		gene_count => 0,
		proteins => [],
		reaction_hash => 0,
		non_gene_probability => 0,
		non_gene_coverage => 0
	}, $args);
	#If features are not provided, load probability, coverage, and counts from base data
	if (!defined($args->{data}->{features})) {
		$args->{probability} = ($args->{gene_count}*$args->{probability}+$args->{data}->{hit_count}*$args->{data}->{non_gene_probability});
		$args->{gene_count} += $args->{data}->{hit_count};
		if ($args->{gene_count} > 0) {
			$args->{probability} = $args->{probability}/$args->{gene_count};
		}
		$args->{coverage} += $args->{data}->{non_gene_coverage};
		return;
	}
	if ($args->{reaction_hash} == 1) {
		foreach my $ftr (keys(%{$args->{data}->{features}})) {
			my $ftrdata = $args->{data}->{features}->{$ftr};
			my $anno_name = $self->msid();
			if (defined($ftrdata->{sources})) {
				$anno_name = "";
				foreach my $source (keys(%{$ftrdata->{sources}})) {
					if (length($anno_name) > 0) {
						$anno_name .= ";";
					}
					$anno_name .= $source.":".$ftrdata->{sources}->{$source};
				}
			}
			push(@{$args->{proteins}},{
				subunits => {
					$anno_name => {
						triggering => 1,
						optionalSubunit => 1,
						genes => {
							$ftrdata->{feature_ref} => {
								probability => $ftrdata->{probability},
								coverage => $ftrdata->{coverage}
							}
						}
					}
				},
				cpx => undef,
				note => ""
			});
		}
	} else {
		#Go through the complexes associated with this template reaciton
		my $cpxs = $self->templatecomplexs();
		for (my $i=0; $i < @{$cpxs}; $i++) {
			#For each complex, see if it contains the role associated with the input data
			my $cpx = $cpxs->[$i];
			my $complexroles = $cpx->complexroles();
			for (my $j=0; $j < @{$complexroles}; $j++) {
				my $cpxrole = $complexroles->[$j];
				if ($args->{role} eq $cpxrole->templaterole()->id()) {
					#The complex includes the role associated with the input data
					#Now let's see if this complex has already been added to the protein list for this reaction
					my $found = 0;
					for (my $k=0; $k < @{$args->{proteins}}; $k++) {
						if ($args->{proteins}->[$k]->{cpx} == $cpx) {
							$found = 1;
							#The complex has been found - if the role has not been captured already then add a subunit
							if (!defined($args->{proteins}->[$k]->{subunits}->{$args->{role}})) {
								#The role has not been captured yet. We now add it to the protein structure
								$args->{proteins}->[$k]->{subunits}->{$args->{role}} = {
									triggering => $cpxrole->triggering(),
									optionalSubunit => $cpxrole->optional_role(),
									genes => {}
								};
							}
							#Now populate the genes attribute in the subunit
							foreach my $ftr (keys(%{$args->{data}->{features}})) {
								my $ftrdata = $args->{data}->{features}->{$ftr};
								$args->{proteins}->[$k]->{subunits}->{$args->{role}}->{genes}->{$ftrdata->{feature_ref}} = {
									probability => $ftrdata->{probability},
									coverage => $ftrdata->{coverage}
								};
							}
							last;
						}
					}
					#If a protein has not already been added for this complex, then we add it now
					if ($found == 0) {
						my $new_protein = {
							subunits => {
								$args->{role} => {
									triggering => $cpxrole->triggering(),
									optionalSubunit => $cpxrole->optional_role(),
									genes => {}
								}
							},
							cpx => $cpx,
							note => ""
						};
						foreach my $ftr (keys(%{$args->{data}->{features}})) {
							my $ftrdata = $args->{data}->{features}->{$ftr};
							$new_protein->{subunits}->{$args->{role}}->{genes}->{$ftrdata->{feature_ref}} = {
								probability => $ftrdata->{probability},
								coverage => $ftrdata->{coverage}
							};
						}
						push(@{$args->{proteins}},$new_protein);
					}
					last;
				}
			}	
		}
	}
}

sub AddRxnToModelFromAnnotations {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["model"],{
		no_features => 0,
		fulldb => 0,
		function_hash => {},
		reaction_hash => {}
	}, @_);
	my $anno_args = {proteins => []};
	#Checking function hash for additional gene associations to add
	my $cpxs = $self->templatecomplexs();
	for (my $i=0; $i < @{$cpxs}; $i++) {
		my $complexroles = $cpxs->[$i]->complexroles();
		for (my $j=0; $j < @{$complexroles}; $j++) {
			my $cpxrole = $complexroles->[$j];
			my $roleid = $cpxrole->templaterole()->id();
			if (defined($args->{function_hash}->{$roleid})) {
				foreach my $compartment (keys(%{$args->{function_hash}->{$roleid}})) {
					if ($compartment eq "u" || $compartment eq $self->templatecompartment()->id()) {
						$anno_args->{role} = $roleid;
						$anno_args->{data} = $args->{function_hash}->{$roleid}->{$compartment};
					
					}
				}
				if (defined($anno_args->{data})) {
					$self->ProcessAnnotationData($anno_args);
					delete $anno_args->{data};
				}
			}	
		}
	}
	#Checking reaction hash for additional gene associations to add
	if (defined($args->{reaction_hash}->{$self->msid()})) {
		foreach my $compartment (keys(%{$args->{reaction_hash}->{$self->msid()}})) {
			if ($compartment eq "u" || $compartment eq $self->templatecompartment()->id()) {
				$anno_args->{data} = $args->{reaction_hash}->{$self->msid()}->{$compartment};
				last;
			}
		}
	}
	if (defined($anno_args->{data})) {
		$anno_args->{reaction_hash} = 1;
		$self->ProcessAnnotationData($anno_args);
	}
	#Removing proteins that don't include triggering subunits
	my $genehash = {};
	my $protein_count = 0;
	for (my $i=0; $i < @{$anno_args->{proteins}}; $i++) {
		my $probabilty = 0;
		my $coverage = 0;
		my $found = 0;
		foreach my $role (keys(%{$anno_args->{proteins}->[$i]->{subunits}})) {
			if ($anno_args->{proteins}->[$i]->{subunits}->{$role}->{triggering} == 1) {
				$found = 1;
				last;
			}
		}
		if ($found == 1 || !defined($anno_args->{proteins}->[$i]->{cpx})) {
			$protein_count++;
			my $protein_gene_count = 0;
			my $subunit_count = 0;
			my $protein_coverage = 0;
			my $protein_probability = 0;
			foreach my $role (keys(%{$anno_args->{proteins}->[$i]->{subunits}})) {
				$subunit_count++;
				my $subunit_probability = 0;
				my $subunit_genecount = 0;
				foreach my $generef (keys(%{$anno_args->{proteins}->[$i]->{subunits}->{$role}->{genes}})) {
					$protein_gene_count++;
					$genehash->{$generef} = 1;
					$subunit_genecount++;
					$protein_coverage += $anno_args->{proteins}->[$i]->{subunits}->{$role}->{genes}->{$generef}->{coverage};
					$subunit_probability += $anno_args->{proteins}->[$i]->{subunits}->{$role}->{genes}->{$generef}->{probability};
				}
				if ($subunit_genecount > 0) {
					$subunit_probability = $subunit_probability/$subunit_genecount;
				}
				$protein_probability += $subunit_probability;
			}
			if ($subunit_count > 0) {
				$protein_coverage = $protein_coverage/$subunit_count;
				$protein_probability = $protein_probability/$subunit_count;
			}
			if ($protein_gene_count > 0) {
				$anno_args->{coverage} += $protein_coverage;
				$anno_args->{probability} += $protein_probability;
			}
		} else {
			splice(@{$anno_args->{proteins}}, $i, 1);
		}
	}
	my $total_protein_gene_count = keys(%{$genehash});
	if ($protein_count > 0 && $total_protein_gene_count > 0) {
		$anno_args->{probability} = $anno_args->{probability}/$protein_count;
		$anno_args->{gene_count} += $total_protein_gene_count;
	}
	#Now adding reaction to model if it meets the necessary criteria
	if ((!defined($anno_args->{proteins}) || @{$anno_args->{proteins}} == 0) && 
		(!defined($anno_args->{gene_count}) || $anno_args->{gene_count} == 0) && 
		$self->type() ne "universal" && 
		$self->type() ne "spontaneous" && 
		$args->{fulldb} == 0) {
		return undef;
	}
	return $self->AddReactionToModel({
		model => $args->{model},
		proteins => $anno_args->{proteins},
		probability => $anno_args->{probability},
		gene_count => $anno_args->{gene_count},
		coverage => $anno_args->{coverage}
	});
}

sub AddReactionToModel {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["model"],{
		proteins => [],
		probability => 1,
		gene_count => 0,
		coverage => 0
	}, @_);
	#print $args->{probability}."\t".$args->{gene_count}."\t".$args->{coverage}."\n";
	my $mdlcmp = $args->{model}->addCompartmentToModel({compartment => $self->templatecompartment(),pH => 7,potential => 0,compartmentIndex => 0});
    my $mdlrxn = $args->{model}->getObject("modelreactions", $self->msid()."_".$mdlcmp->id());
    if(!$mdlrxn) {
		$mdlrxn = $args->{model}->add("modelreactions",{
			id => $self->msid()."_".$mdlcmp->id(),
			probability => $args->{probability},
			gene_count => $args->{gene_count},
			coverage => $args->{coverage},
			reaction_ref => "~/template/reactions/id/".$self->id(),
			direction => $self->direction(),
			modelcompartment_ref => "~/modelcompartments/id/".$mdlcmp->id(),
			modelReactionReagents => [],
			modelReactionProteins => []
		});
		my $rgts = $self->templateReactionReagents();
		for (my $i=0; $i < @{$rgts}; $i++) {
			my $rgt = $rgts->[$i];
			my $rgtcmp = $args->{model}->addCompartmentToModel({compartment => $rgt->templatecompcompound()->templatecompartment(),pH => 7,potential => 0,compartmentIndex => 0});
			my $coefficient = $rgt->coefficient();
			my $mdlcpd = $args->{model}->addCompoundToModel({
				compound => $rgt->templatecompcompound()->templatecompound(),
				modelCompartment => $rgtcmp,
			});
			$mdlrxn->addReagentToReaction({
				coefficient => $coefficient,
				modelcompound_ref => "~/modelcompounds/id/".$mdlcpd->id()
			});
		}
	} else {
		$mdlrxn->coverage($args->{coverage});
		$mdlrxn->probability($args->{probability});
		$mdlrxn->gene_count($args->{gene_count});
	}
    if (@{$args->{proteins}} > 0 && scalar(@{$mdlrxn->modelReactionProteins()})==0) {
		foreach my $protein (@{$args->{proteins}}) {
	    		if (defined($protein->{cpx})) {
		    		$mdlrxn->addModelReactionProtein({
					proteinDataTree => $protein,
					complex_ref => "~/template/complexes/id/".$protein->{cpx}->id()
				});
	    		} else {
	    			$mdlrxn->addModelReactionProtein({
					proteinDataTree => $protein,
					complex_ref => "~/template/complexes/id/cpx00000"
				});
	    		}
		}
    } elsif (scalar(@{$mdlrxn->modelReactionProteins()})==0) {
		$mdlrxn->addModelReactionProtein({
	    		proteinDataTree => {note => $self->type()},
		});
    }
    return $mdlrxn;
}

sub OldAddRxnToModel {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["role_features","model"],{
		fulldb => 0,
		probabilities => {},
		reaction_hash => {}
	}, @_);
	my $mdl = $args->{model};
	#Gathering roles from annotation
	my $roleFeatures = $args->{role_features};
	my $cpxs = $self->templatecomplexs();
	my $probability = 0;
	my $proteins = [];
	for (my $i=0; $i < @{$cpxs}; $i++) {
		my $cpx = $cpxs->[$i];
		my $complexroles = $cpx->complexroles();
		my $complex_present = 0;
		my $subunits;
		for (my $j=0; $j < @{$complexroles}; $j++) {
			my $cpxrole = $complexroles->[$j];
			if (defined($roleFeatures->{$cpxrole->templaterole()->id()})) {
				if (defined($args->{probabilities}->{$cpxrole->templaterole()->id()})) {
					if ($probability < $args->{probabilities}->{$cpxrole->templaterole()->id()}) {
						$probability = $args->{probabilities}->{$cpxrole->templaterole()->id()};
					}
				}
				foreach my $compartment (keys(%{$roleFeatures->{$cpxrole->templaterole()->id()}})) {
				    my $role_cpt_present=0;
					if ($compartment eq "u" || $compartment eq $self->templatecompartment()->id()) {
						if ($cpxrole->triggering() == 1) {
							$complex_present = 1;
							$role_cpt_present = 1;
						}
					}
				    if($role_cpt_present == 1){
						$subunits->{$cpxrole->templaterole()->name()}->{triggering} = $cpxrole->triggering();
						$subunits->{$cpxrole->templaterole()->name()}->{optionalSubunit} = $cpxrole->optional_role();
						if (!defined($roleFeatures->{$cpxrole->templaterole()->id()}->{$compartment}->[0]) || $roleFeatures->{$cpxrole->templaterole()->id()}->{$compartment}->[0] eq "Role-based-annotation") {
							$subunits->{$cpxrole->templaterole()->name()}->{note} = "Role-based-annotation";
						} else {
							foreach my $feature (@{$roleFeatures->{$cpxrole->templaterole()->id()}->{$compartment}}) {
								$subunits->{$cpxrole->templaterole()->name()}->{genes}->{"~/genome/features/id/".$feature->id()} = $feature;	
							}
						}
				    }
				}
			}
		}
		if ($complex_present == 1) {
			for (my $j=0; $j < @{$complexroles}; $j++) {
				my $cpxrole = $complexroles->[$j];
				if ($cpxrole->optional_role() == 0 && !defined($subunits->{$cpxrole->templaterole()->name()})) {
					$subunits->{$cpxrole->templaterole()->name()}->{triggering} = $cpxrole->triggering();
					$subunits->{$cpxrole->templaterole()->name()}->{optionalSubunit} = $cpxrole->optional_role();
					$subunits->{$cpxrole->templaterole()->name()}->{note} = "Complex-based-gapfilling";
				}
			}
			if (defined($subunits)) {
				push(@{$proteins},{subunits => $subunits,cpx => $cpx});
			}
		}
	}
	#Checking reaction hash for additional gene associations to add
	if (defined($args->{reaction_hash}->{$self->msid()})) {
		my $anno_source_hash = {};
		foreach my $geneid (keys(%{$args->{reaction_hash}->{$self->msid()}})) {
			if (!defined($anno_source_hash->{join(";",keys(%{$args->{reaction_hash}->{$self->msid()}->{$geneid}}))}->{$geneid})) {
				#Checking if gene is already included in an existing complex
				my $found = 0;
				for (my $i=0; $i < @{$proteins}; $i++) {
					foreach my $name (keys($proteins->[$i]->{subunits})) {
						foreach my $gene (keys(%{$proteins->[$i]->{subunits}->{$name}->{genes}})) {
							if ($proteins->[$i]->{subunits}->{$name}->{genes}->{$gene}->id() eq $geneid) {
								$found = 1;
							}	
						}
					}
				}
				if ($found == 0) {
					$anno_source_hash->{join(";",keys(%{$args->{reaction_hash}->{$self->msid()}->{$geneid}}))}->{$geneid} = 1;
				}
			}
		}
		foreach my $anno_name (keys(%{$anno_source_hash})) {
			my $genehash = {};
			my $all_anno_sources = {};
			foreach my $gene (keys(%{$anno_source_hash->{$anno_name}})) {
				my $ftr = $args->{model}->genome()->getObject("features",$gene);
				if (defined($ftr)) {
					$genehash->{"~/genome/features/id/".$ftr->id()} = $ftr;
				}
			}
			push(@{$proteins},{
				subunits => {
					$anno_name => {
						triggering => 1,
						optionalSubunit => 1,
						genes => $genehash
					}
				},
				cpx => undef,
				note => ""
			});
		}
	}
	#Adding reaction
	if (@{$proteins} == 0 && $self->type() ne "universal" && $self->type() ne "spontaneous" && $args->{fulldb} == 0) {
		return;
	}
    
}

__PACKAGE__->meta->make_immutable;
1;
