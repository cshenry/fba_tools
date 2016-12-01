########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBAModel - This is the moose object corresponding to the Model object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use YAML::XS;
use XML::LibXML;
use File::Temp;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAModel;
package Bio::KBase::ObjectAPI::KBaseFBA::FBAModel;
use Moose;
use namespace::autoclean;
use Class::Autouse qw(
    Graph::Undirected
);
use Bio::KBase::ObjectAPI::utilities;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAModel';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has features => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfeatures' );
has featureHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfeatureHash' );
has compound_reaction_hash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompound_reaction_hash' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcompound_reaction_hash {
	my ($self) = @_;
	my $hash = {};
	my $rxns = $self->modelreactions();
	foreach my $rxn (@{$rxns}) {
		my $rgts = $rxn->modelReactionReagents();
		foreach my $rgt (@{$rgts}) {
			$hash->{$rgt->modelcompound()->id()}->{$rxn->id()} = $rgt->coefficient();
		}
	}
	return $hash;
}

sub _buildfeatures {
	my ($self) = @_;
	#Retrieving list of genes in model
	my $rxns = $self->modelreactions();
	my $ftrhash = {};
	for (my $i=0; $i < @{$rxns};$i++) {
		my $rxn = $rxns->[$i];
		my $ftrs = $rxn->featureUUIDs();
		foreach my $ftr (@{$ftrs}) {
			$ftrhash->{$ftr} = 1;
		}
	}
	return [keys(%{$ftrhash})];
}

sub _buildfeatureHash {
	my ($self) = @_;
	my $ftrhash = {};
	my $rxns = $self->modelreactions();
	for (my $i=0; $i < @{$rxns};$i++) {
		my $rxn = $rxns->[$i];
		my $ftrs = $rxn->featureUUIDs();
		foreach my $ftr (@{$ftrs}) {
			$ftrhash->{$ftr}->{$rxn->_reference()} = $rxn;
		}
	}
	return $ftrhash;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub gene_count {
	my $self = shift;
	my $ftrhash = {};
	my $rxns = $self->modelreactions();
	for (my $i=0; $i < @{$rxns};$i++) {
		my $rxn = $rxns->[$i];
		my $ftrs = $rxn->featureUUIDs();
		foreach my $ftr (@{$ftrs}) {
			$ftrhash->{$ftr}->{$rxn->_reference()} = $rxn;
		}
	}
	my $count = keys(%{$ftrhash});
	return $count;
}

sub gapfilled_reaction_count {
	my $self = shift;
	my $reactions = $self->modelreactions();
	my $count = 0;
	for (my $i=0; $i < @{$reactions}; $i++) {
		my $gfhash = $reactions->[$i]->gapfill_data();
		foreach my $key (keys(%{$gfhash})) {
			if ($gfhash->{$key} =~ m/added/) {
				$count++;
			}
		}
	}
	return $count;
}

sub gene_associated_reaction_count {
	my $self = shift;
	my $reactions = $self->modelreactions();
	my $count = 0;
	for (my $i=0; $i < @{$reactions}; $i++) {
		my $rxnprots = $reactions->[$i]->modelReactionProteins();
		if (@{$rxnprots} > 0) {
			$count++;
		}
	}
	return $count;
}

sub biomass_compound_count {
	my $self = shift;
	my $bios = $self->biomasses();
	my $biohash;
	for (my $i=0; $i < @{$bios}; $i++) {
		my $biocpds = $bios->[$i]->biomasscompounds();
		for (my $j=0; $j < @{$biocpds}; $j++) {
			$biohash->{$biocpds->[$j]->modelcompound_ref()} = 1;
		}
	}
	my $count = keys(%{$biohash});
	return $count;
}

sub integrated_gapfill_count {
	my $self = shift;
	my $gfs = $self->gapfillings();
	my $count = 0;
	for (my $i=0; $i < @{$gfs}; $i++) {
		if ($gfs->[$i]->integrated() == 1) {
			$count++;
		}
	}
	return $count;
}

sub unintegrated_gapfill_count {
	my $self = shift;
	my $gfs = $self->gapfillings();
	my $count = 0;
	for (my $i=0; $i < @{$gfs}; $i++) {
		if ($gfs->[$i]->integrated() == 0) {
			$count++;
		}
	}
	return $count;
}

=head3 addCompartmentToModel

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->addCompartmentToModel({
		Compartment => REQUIRED,
		pH => 7,
		potential => 0,
		compartmentIndex => 0
	});
Description:
	Adds a compartment to the model after checking that the compartment isn't already there

=cut
#REFACTOR NEEDED HERE
sub addCompartmentToModel {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["compartment"],{
		pH => 7,
		potential => 0,
		compartmentIndex => 0
	}, @_);
	my $mdlcmp = $self->queryObject("modelcompartments",{compartment_ref => $args->{compartment}->_reference(),compartmentIndex => $args->{compartmentIndex}});
	if (!defined($mdlcmp)) {
		$mdlcmp = $self->add("modelcompartments",{
			id => $args->{compartment}->id().$args->{compartmentIndex},
			compartment_ref => $args->{compartment}->_reference(),
			label => $args->{compartment}->name()."_".$args->{compartmentIndex},
			pH => $args->{pH},
			compartmentIndex => $args->{compartmentIndex},
		});
	}
	return $mdlcmp;
}

=head3 addCompoundToModel

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound = Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound->addCompoundToModel({
		compound => REQUIRED,
		modelCompartment => REQUIRED,
		charge => undef (default values will be pulled from input compound),
		formula => undef (default values will be pulled from input compound)
	});
Description:
	Adds a compound to the model after checking that the compound isn't already there

=cut
#REFACTOR NEEDED HERE
sub addCompoundToModel {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["compound","modelCompartment"],{
		charge => undef,
		formula => undef
	}, @_);
	my $cpdid = $args->{compound}->id()."_".$args->{modelCompartment}->id();
	my $mdlcpd = $self->getObject("modelcompounds",$cpdid);
	if (!defined($mdlcpd)) {
		if (!defined($args->{charge})) {
			$args->{charge} = $args->{compound}->defaultCharge();
		}
		if (!defined($args->{formula})) {
			$args->{formula} = $args->{compound}->formula();
		}
		$mdlcpd = $self->add("modelcompounds",{
			id => $args->{compound}->id()."_".$args->{modelCompartment}->id(),
			modelcompartment_ref => "~/modelcompartments/id/".$args->{modelCompartment}->id(),
			compound_ref => $args->{compound}->_reference(),
			charge => $args->{charge},
			formula => $args->{formula},
		});
	}
	return $mdlcpd;
}

=head3 adjustBiomassReaction

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->adjustBiomassReaction({
		biomass => string
		compound => string,
		compartment => string,
		compartmentIndex => integer,
		coefficient => float
	});
Description:
	Modifies the biomass reaction to adjust a compound, add a compound, or remove a compound
	
=cut
#REFACTOR NEEDED HERE
sub adjustBiomassReaction {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args([],{
    	compound => undef,
    	coefficient => undef,
    	biomass => "bio1",
    	compartment => "c",
    	compartmentIndex => 0,
    	compounds => {},
    	equation => undef
    }, @_);
    my $bio = $self->searchForBiomass($args->{biomass});
	if (defined($args->{equation})) {
		if (!defined($bio)) {
			$bio = $self->add("biomasses",{
				id => $args->{biomass},
				name => "Biomass",
				other => 1,
				dna => 0,
				rna => 0,
				protein => 0,
				cellwall => 0,
				lipid => 0,
				cofactor => 0,
				energy => 0,
				biomasscompounds => []
			});
		}
		$self->LoadExternalReactionEquation({biomass => $bio,equation => $args->{equation},compounds => $args->{compounds}});
	} else {
		if (!defined($bio)) {
	    	Bio::KBase::ObjectAPI::utilities::error("Biomass ".$args->{biomass}." not found!");
	    }
		my $mdlcpd = $self->searchForCompound($args->{compound},$args->{compartment},$args->{compartmentIndex});
	    if (!defined($mdlcpd)) {
	    	my $cpdobj = $self->template()->searchForCompound($args->{compound});
	    	if (!defined($cpdobj)) {
	    		Bio::KBase::ObjectAPI::utilities::error("Compound ".$args->{compound}." not found!");
	    	}
	    	my $mdlcmp = $self->getObject("modelcompartments",$args->{compartment}.$args->{compartmentIndex});
	    	if (!defined($mdlcmp)) {
	    		my $cmp = $self->template()->searchForCompartment($args->{compartment});
		    	if (!defined($cmp)) {
		    		Bio::KBase::ObjectAPI::utilities::error("Unrecognized compartment in equation:".$args->{compartment}."!");
		    	}
	    		$mdlcmp = $self->add("modelcompartments",{
	    			id => $args->{compartment}.$args->{compartmentIndex},
					compartment_ref => $cmp->_reference(),
					compartmentIndex => $args->{compartmentIndex},
					label => $args->{compartment}.$args->{compartmentIndex},
					pH => 7,
					potential => 0,
	    		});
	    	}
	    	$mdlcpd = $self->add("modelcompounds",{
	    		id => $cpdobj->id()."_".$args->{compartment}.$args->{compartmentIndex},
				compound_ref => $cpdobj->_reference(),
				name => $cpdobj->name()."_".$args->{compartment}.$args->{compartmentIndex},
				charge => $cpdobj->defaultCharge(),
				formula => $cpdobj->formula(),
				modelcompartment_ref => "~/modelcompartments/id/".$mdlcmp->id()
			});
		}
	    $bio->adjustBiomassReaction({
	    	coefficient => $args->{coefficient},
			modelcompound => $mdlcpd
	    });
	}
}

=head3 removeModelReaction

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->removeModelReaction({
		reaction => string,
	});
Description:
	
=cut
sub removeModelReaction {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["reaction"],{}, @_);
	my $rxnid = $args->{reaction};
	my $mdlrxn = $self->getObject("modelreactions",$rxnid);
	if (!defined($mdlrxn)) {
		Bio::KBase::ObjectAPI::utilities::error("Specified reaction not found:".$rxnid."!");
	}
	$self->remove("modelreactions",$mdlrxn);
}

=head3 adjustModelReaction

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->adjustModelReaction({
		reaction => string,
		direction => string,
    	gpr => string,
    	enzyme => string,
    	pathway => string,
    	name => string,
    	reference => string
	});
Description:
	
=cut
sub adjustModelReaction {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["reaction"],{
    	direction => undef,
    	gpr => undef,
    	enzyme => undef,
    	pathway => undef,
    	name => undef,
    	reference => undef
    }, @_);
	my $rxnid = $args->{reaction};
	my $mdlrxn = $self->getObject("modelreactions",$rxnid);
	if (!defined($mdlrxn)) {
		Bio::KBase::ObjectAPI::utilities::error("Specified reaction not found:".$rxnid."!");
	}
	if (defined($args->{direction})){
		$mdlrxn->direction($args->{direction});
	}
	if (defined($args->{gpr})){
		$mdlrxn->loadGPRFromString($args->{gpr});
	}
	if (!defined($args->{name}) && !defined($mdlrxn->name()) && length($mdlrxn->name()) == 0)  {
    	$args->{name} = $rxnid;
    }
	if (defined($args->{name}) && $args->{name} ne $rxnid){
		$mdlrxn->name($args->{name});
	}
	if (defined($args->{enzyme})){
		$mdlrxn->enzyme($args->{enzyme});
	}
	if (defined($args->{pathway})){
		$mdlrxn->pathway($args->{pathway});
	}
	if (defined($args->{reference})){
		$mdlrxn->reference($args->{reference});
	}
}

=head3 addModelReaction

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->addModelReaction({
		reaction => string,
		direction => string,
    	gpr => string,
    	enzyme => string,
    	pathway => string,
    	name => string,
    	reference => string
	});
Description:
	
=cut

#REFACTOR NEEDED HERE
sub addModelReaction {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["reaction"],{
    	equation => undef,
    	direction => undef,
    	compartment => "c",
    	compartmentIndex => 0,
    	gpr => undef,
    	removeReaction => 0,
    	addReaction => 0,
    	compounds => {},
    	enzyme => undef,
    	pathway => undef,
    	name => undef,
    	reference => undef
    }, @_);
    my $rootid = $args->{reaction};
	if ($rootid =~ m/(.+)_([a-zA-Z])(\d+)$/) {
		$rootid = $1;
		$args->{compartment} = $2;
    	$args->{compartmentIndex} = $3;
	}
	if ($rootid =~ m/^(.+)\[([a-zA-Z]+)\]$/) {
    	$rootid = $1;
    	$args->{compartment} = lc($2);
    } elsif ($rootid =~ m/^(.+)\[([a-zA-Z]+)(\d+)\]$/) {
    	$rootid = $1;
    	$args->{compartment} = lc($2);
    	$args->{compartmentIndex} = $3;
    }
    my $eq;
    if (defined($args->{equation})) {
    	$eq = $args->{equation};
    	if ($eq =~ m/\[([a-zA-Z])\]\s*:\s*(.+)/) {
    		$args->{compartment} = lc($1);
    		$eq = $2;
    	}
    }
    my $fullid = $rootid."_".$args->{compartment}.$args->{compartmentIndex};
    #Checking if a reaction with the same ID is already in the model
    if (defined($self->getObject("modelreactions",$fullid))) {
    	Bio::KBase::ObjectAPI::utilities::error("Reaction with specified ID ".$rootid." already in model. Remove reaction before attempting to add again!");
    }
    #Standardizing and fetching compartment
    if ($args->{compartment} =~ m/^([a-z]+)(\d+)$/) {
    	$args->{compartment} = $1;
    	$args->{compartmentIndex} = $2;
    }
	my $cmp = $self->template()->searchForCompartment($args->{compartment});
    if (!defined($cmp)) {
    	Bio::KBase::ObjectAPI::utilities::error("Unrecognized compartment ".$args->{compartment}." in reaction: ".$args->{reaction});
    }
    #Fetching or adding model compartment
    my $mdlcmp = $self->addCompartmentToModel({compartment => $cmp,pH => 7,potential => 0,compartmentIndex => $args->{compartmentIndex}});
	#Finding reaction reference
	my $reference = $self->template()->_reference()."/reactions/id/rxn00000_c";
	my $coefhash = {};
	if ($rootid =~ m/^rxn\d+$/) {
		my $rxnobj = $self->template()->searchForReaction($rootid);
		if (!defined($rxnobj) && !defined($eq)) {
			Bio::KBase::ObjectAPI::utilities::error("Specified reaction ".$rootid." not found and no equation provided!");
		} else {
			$reference = $rxnobj->_reference();
			my $rgts = $rxnobj->templateReactionReagents();
			my $cmpchange = 0;
			for (my $i=0; $i < @{$rgts}; $i++) {
				if ($rgts->[$i]->templatecompcompound()->templatecompartment()->id() ne "c") {
					$cmpchange = 1;
					last;
				}
			}
			for (my $i=0; $i < @{$rgts}; $i++) {
				my $rgt = $rgts->[$i];
				my $rgtcmp = $mdlcmp;
				if ($cmpchange == 1) {
					if ($rgt->templatecompcompound()->templatecompartment()->id() eq "e") {
						$rgtcmp = $self->addCompartmentToModel({compartment => $rgt->templatecompcompound()->templatecompartment(),pH => 7,potential => 0,compartmentIndex => 0});
					} else {
						$rgtcmp = $self->addCompartmentToModel({compartment => $rgt->templatecompcompound()->templatecompartment(),pH => 7,potential => 0,compartmentIndex => $args->{compartmentIndex}});
					}
				}
				my $coefficient = $rgt->coefficient();
				my $mdlcpd = $self->addCompoundToModel({
					compound => $rgt->templatecompcompound()->templatecompound(),
					modelCompartment => $rgtcmp,
				});
				$coefhash->{"~/modelcompounds/id/".$mdlcpd->id()} = $coefficient;
			}
		}
	}
	#Adding reaction
	my $mdlrxn = $self->add("modelreactions",{
		id => $fullid,
		reaction_ref => $reference,
		direction => $args->{direction},
		protons => 0,
		modelcompartment_ref => "~/modelcompartments/id/".$mdlcmp->id(),
		probability => 0,
		modelReactionReagents => [],
		modelReactionProteins => []
	});
	#Setting reagents from database reaction or equation
	if (!defined($eq)) {
		foreach my $rgt (keys(%{$coefhash})) {
			$mdlrxn->addReagentToReaction({
				coefficient => $coefhash->{$rgt},
				modelcompound_ref => $rgt
			});
		}	
	} else {
		$self->LoadExternalReactionEquation({reaction => $mdlrxn,equation => $eq,compounds => $args->{compounds}});
		if ($mdlrxn->id() =~ m/rxn\d+/) {
			$mdlrxn->addAlias($fullid,"id");
		}
	}
	#Adjusting model reaction
	$self->adjustModelReaction({
		reaction => $mdlrxn->id(),
    	gpr => $args->{gpr},
    	enzyme => $args->{enzyme},
    	pathway => $args->{pathway},
    	reference => $args->{reference}
	});
	return $mdlrxn;
}

#REFACTOR NEEDED HERE
sub LoadExternalReactionEquation {
	my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["equation","compounds"],{
    	biomass => undef,
    	reaction => undef
    }, @_);
	$args->{equation} =~ s/\s*\<*[-=]+\>\s*/ = /g;
	$args->{equation} =~ s/\s*\<[-=]+\s*/ = /g;
    $args->{equation} =~ s/\s*\+\s*/ + /g;
    #print "Equation:".$args->{equation}."\n";
    my $array = [];
    if ($args->{equation} =~ m/^(.*)\s=\s(.*)$/) {
    	$array->[0] = $1;
    	$array->[1] = $2;
    } else {
		Bio::KBase::ObjectAPI::utilities::error("No equal sign in ".$args->{equation}."!");
	}
    #print "Reference:".$bio->_reference()."\n";
    my $compoundhash = {};
    for (my $i=0; $i < @{$array}; $i++) {
    	if (length($array->[$i]) > 0) {
	    	my $compounds = [split(/\s\+\s/,$array->[$i])];
	    	foreach my $cpd (@{$compounds}) {
	    		$cpd  =~ s/^\s+//;
	    		$cpd  =~ s/\s+$//;
	    		my $coef = 1;
	    		my $compartment = "c";
	    		if (defined($args->{reaction})) {
	    			$compartment = $args->{reaction}->modelcompartment()->compartment()->id();
	    		}
	    		my $index = 0;
	    		if ($cpd =~ m/^\(*(\d+\.*\d*[eE]*-*\d*)\)*\s+(.+)/) {
	    			$coef = $1;
	    			$cpd = $2;
	    		}
	    		if ($cpd =~ m/^(.+)\[([a-z]\d*)\]$/) {
	    			$cpd = $1;
	    			$compartment = $2;	
	    		}
	    		if ($cpd =~m/(.+)_([a-z]\d+)$/) {
	    			$cpd = $1;
	    		}
	    		if ($compartment =~ m/([a-z])(\d+)/) {
	    			$index = $2;
	    			$compartment = $1;	
	    		}
	    		if ($i == 0) {
	    			$coef = -1*$coef;
	    		}
	    		my $cpdobj;
	    		if (defined($args->{compounds}->{$cpd})) {
	    			my $name = $args->{compounds}->{$cpd}->[3];
	    			if ($name =~ m/^(.+)\[([a-z])\]$/) {
	    				$compartment = $2;
	    				$name = $1;
	    			}
	    			$cpdobj = $self->template()->searchForCompound($name);
	    			if (!defined($cpdobj) && defined($args->{compounds}->{$cpd}->[4])) {
	    				my $aliases = [split(/\|/,$args->{compounds}->{$cpd}->[4])];
	    				foreach my $alias (@{$aliases}) {
	    					if ($alias =~ m/^(.+):(.+)/) {
	    						$alias = $2;
	    					}
	    					$cpdobj = $self->template()->searchForCompound($alias);
	    					if (defined($cpdobj)) {
	    						last;
	    					}
	    				}
	    			}
	    			if (!defined($cpdobj)) {
	    				$cpdobj = $self->template()->searchForCompound($cpd);
	    			}
	    		} else {
	    			$cpdobj = $self->template()->searchForCompound($cpd);
	    		}
	    		my $mdlcmp = $self->getObject("modelcompartments",$compartment.$index);
	    		if (!defined($mdlcmp)) {
	    			$mdlcmp = $self->add("modelcompartments",{
	    				id => $compartment.$index,
						compartment_ref => "~/template/compartments/id/".$compartment,
						compartmentIndex => $index,
						label => $compartment.$index,
						pH => 7,
						potential => 0,
	    			});
	    		}
	    		my $mdlcpd;
	    		if (defined($cpdobj)) {
	    			$mdlcpd = $self->searchForCompound($cpdobj->id()."_".$compartment.$index);
	    			if (!defined($mdlcpd)) {
	    				$mdlcpd = $self->add("modelcompounds",{
	    					id => $cpdobj->id()."_".$compartment.$index,
							compound_ref => $cpdobj->_reference(),
							name => $cpdobj->name()."_".$compartment.$index,
							charge => $cpdobj->defaultCharge(),
							formula => $cpdobj->formula(),
							modelcompartment_ref => "~/modelcompartments/id/".$mdlcmp->id(),
							aliases => ["mdlid:".$cpd]
	    				});
	    			} else {
	    				my $aliases = $mdlcpd->aliases();
	    				foreach my $alias (@{$aliases}) {
	    					if ($alias =~ m/^mdlid:(.+)/) {
	    						if ($1 ne $cpd) {
	    							print STDERR "Possibly erroneously consolidating ".$cpd." with ".$1."\n";
	    						}
	    					}
	    				}
	    			}
	    		} else {
	    			#print $cpd." not found!\n";
	    			$mdlcpd = $self->searchForCompound($cpd."_".$compartment.$index);
	    			if (!defined($mdlcpd)) {
	    				if (!defined($args->{compounds}->{$cpd})) {
	    					print STDERR "Ill defined compound:".$cpd."!\n";
	    					$cpd =~ s/[^\w]/_/g;
	    					$mdlcpd = $self->searchForCompound($cpd."_".$compartment.$index);
	    					#Bio::KBase::ObjectAPI::utilities::error("Ill defined compound:".$cpd."!");
	    				}
	    				if (!defined($mdlcpd)) {
		    				$mdlcpd = $self->add("modelcompounds",{
		    					id => $cpd."_".$compartment.$index,
								compound_ref => $self->template()->_reference()."/compounds/id/cpd00000",
								name => $cpd."_".$compartment.$index,
								charge => 0,
								formula => "",
								modelcompartment_ref => "~/modelcompartments/id/".$mdlcmp->id(),
		    					aliases => ["mdlid:".$cpd]
		    				});
	    				} else {
		    				my $aliases = $mdlcpd->aliases();
		    				foreach my $alias (@{$aliases}) {
		    					if ($alias =~ m/^mdlid:(.+)/) {
		    						if ($1 ne $cpd) {
		    							print STDERR "Possibly erroneously consolidating ".$cpd." with ".$1."\n";
		    						}
		    					}
		    				}
		    			}
	    			}
	    		}
	    		if (!defined($compoundhash->{$mdlcpd->id()})) {
	    			$compoundhash->{$mdlcpd->id()} = 0;
	    		}
	    		$compoundhash->{$mdlcpd->id()} += $coef;
	    	}
    	}
    } 
    if (defined($args->{biomass})) {
    	$args->{biomass}->ImportExternalEquation({reagents => $compoundhash});
    } elsif (defined($args->{reaction})) {
    	$args->{reaction}->ImportExternalEquation({reagents => $compoundhash});
    } else {
    	Bio::KBase::ObjectAPI::utilities::error("Must call this function with either reaction or biomass selected!");
    }
}

=head3 labelBiomassCompounds

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->labelBiomassCompounds();
Description:
	Labels all model compounds indicating whether or not they are biomass components

=cut

sub labelBiomassCompounds {
	my $self = shift;
	for (my $i=0; $i < @{$self->modelcompounds()}; $i++) {
		my $cpd = $self->modelcompounds()->[$i];
		$cpd->isBiomassCompound(0);
	}
	for (my $i=0; $i < @{$self->biomasses()}; $i++) {
		my $bio = $self->biomasses()->[$i];
		for (my $j=0; $j < @{$bio->biomasscompounds()}; $j++) {
			my $biocpd = $bio->biomasscompounds()->[$j];
			$biocpd->modelcompound()->isBiomassCompound(1);
		}
	}
}

=head3 printSBML

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->printSBML();
Description:
	Prints the model in SBML format

=cut

sub printSBML {
    my $self = shift;
	# convert ids to SIds
    my $idToSId = sub {
        my $id = shift @_;
        my $cpy = $id;
        # SIds must begin with a letter
        $cpy =~ s/^([^a-zA-Z])/A_$1/;
        # SIDs must only contain letters numbers or '_'
        $cpy =~ s/[^a-zA-Z0-9_]/_/g;
        return $cpy;
    };
	#Printing header to SBML file
	my $ModelName = $idToSId->($self->id());
	my $output;
	push(@{$output},'<?xml version="1.0" encoding="UTF-8"?>');
	push(@{$output},'<sbml xmlns="http://www.sbml.org/sbml/level2" level="2" version="1" xmlns:html="http://www.w3.org/1999/xhtml">');
	my $name = $self->name()." SEED model";
	$name =~ s/[\s\.]/_/g;
	push(@{$output},'<model id="'.$ModelName.'" name="'.$name.'">');

	#Printing the unit data
	push(@{$output},"<listOfUnitDefinitions>");
	push(@{$output},"\t<unitDefinition id=\"mmol_per_gDW_per_hr\">");
	push(@{$output},"\t\t<listOfUnits>");
	push(@{$output},"\t\t\t<unit kind=\"mole\" scale=\"-3\"/>");
	push(@{$output},"\t\t\t<unit kind=\"gram\" exponent=\"-1\"/>");
	push(@{$output},"\t\t\t<unit kind=\"second\" multiplier=\".00027777\" exponent=\"-1\"/>");
	push(@{$output},"\t\t</listOfUnits>");
	push(@{$output},"\t</unitDefinition>");
	push(@{$output},"</listOfUnitDefinitions>");

	#Printing compartments for SBML file
	push(@{$output},'<listOfCompartments>');
	for (my $i=0; $i < @{$self->modelcompartments()}; $i++) {
		my $cmp = $self->modelcompartments()->[$i];
    	push(@{$output},'<compartment '.$self->CleanNames("id",$cmp->id()).' '.$self->CleanNames("name",$cmp->label()).' />');
    }
	push(@{$output},'</listOfCompartments>');
	#Printing the list of metabolites involved in the model
	push(@{$output},'<listOfSpecies>');
	for (my $i=0; $i < @{$self->modelcompounds()}; $i++) {
		my $cpd = $self->modelcompounds()->[$i];
		push(@{$output},'<species '.$self->CleanNames("id",$cpd->id()).' '.$self->CleanNames("name",$cpd->name()).' compartment="'.$cpd->modelCompartmentLabel().'" charge="'.$cpd->charge().'" boundaryCondition="false"/>');
		if ($cpd->msid() eq "cpd11416" || $cpd->msid() eq "cpd15302" || $cpd->msid() eq "cpd08636") {
			push(@{$output},'<species '.$self->CleanNames("id",$cpd->msid()."_b").' '.$self->CleanNames("name",$cpd->name()."_b").' compartment="'.$cpd->modelCompartmentLabel().'" charge="'.$cpd->charge().'" boundaryCondition="true"/>');
		}
	}
	for (my $i=0; $i < @{$self->modelcompounds()}; $i++) {
		my $cpd = $self->modelcompounds()->[$i];
		if ($cpd->modelCompartmentLabel() =~ m/^e/) {
			push(@{$output},'<species '.$self->CleanNames("id",$cpd->msid()."_b").' '.$self->CleanNames("name",$cpd->name()."_b").' compartment="'.$cpd->modelCompartmentLabel().'" charge="'.$cpd->charge().'" boundaryCondition="true"/>');
		}
	}
	push(@{$output},'</listOfSpecies>');
	push(@{$output},'<listOfReactions>');
	my $mdlrxns = $self->modelreactions();
	for (my $i=0; $i < @{$mdlrxns}; $i++) {
		my $rxn = $mdlrxns->[$i];
		my $reversibility = "true";
		my $lb = -1000;
		if ($rxn->direction() ne "=") {
			$lb = 0;
			$reversibility = "false";
		}
		push(@{$output},'<reaction '.$self->CleanNames("id",$rxn->id()).' '.$self->CleanNames("name",$rxn->name()).' '.$self->CleanNames("reversible",$reversibility).'>');
		push(@{$output},"<notes>");
		my $ec = $rxn->enzyme();
		my $keggID = $rxn->kegg();
		my $GeneAssociation = $rxn->gprString;
		my $ProteinAssociation = $rxn->gprString;
		push(@{$output},"<html:p>GENE_ASSOCIATION:".$GeneAssociation."</html:p>");
		push(@{$output},"<html:p>PROTEIN_ASSOCIATION:".$ProteinAssociation."</html:p>");
		if (defined($keggID)) {
			push(@{$output},"<html:p>KEGG_RID:".$keggID."</html:p>");
		}
		if (defined($ec)) {
			push(@{$output},"<html:p>PROTEIN_CLASS:".$ec."</html:p>");
		}
		push(@{$output},"</notes>");
		my $firstreact = 1;
		my $firstprod = 1;
		my $prodoutput = [];
		my $rgts = $rxn->modelReactionReagents();
		my $sign = 1;
		if ($rxn->direction() eq "<") {
			$sign = -1;
		}
		for (my $j=0; $j < @{$rgts}; $j++) {
			my $rgt = $rgts->[$j];
			if ($sign*$rgt->coefficient() < 0) {
				if ($firstreact == 1) {
					$firstreact = 0;
					push(@{$output},"<listOfReactants>");
				}
				push(@{$output},'<speciesReference '.$self->CleanNames("species",$rgt->modelcompound()->id()).' stoichiometry="'.-1*$sign*$rgt->coefficient().'"/>');	
			} else {
				if ($firstprod == 1) {
					$firstprod = 0;
					push(@{$prodoutput},"<listOfProducts>");
				}
				push(@{$prodoutput},'<speciesReference '.$self->CleanNames("species",$rgt->modelcompound()->id()).' stoichiometry="'.$sign*$rgt->coefficient().'"/>');
			}
		}
		if ($firstreact != 1) {
			push(@{$output},"</listOfReactants>");
		}
		if ($firstprod != 1) {
			push(@{$prodoutput},"</listOfProducts>");
		}
		push(@{$output},@{$prodoutput});
		push(@{$output},"<kineticLaw>");
		push(@{$output},"\t<math xmlns=\"http://www.w3.org/1998/Math/MathML\">");
		push(@{$output},"\t\t\t<ci> FLUX_VALUE </ci>");
		push(@{$output},"\t</math>");
		push(@{$output},"\t<listOfParameters>");
		push(@{$output},"\t\t<parameter id=\"LOWER_BOUND\" value=\"".$lb."\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t\t<parameter id=\"UPPER_BOUND\" value=\"1000\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t\t<parameter id=\"OBJECTIVE_COEFFICIENT\" value=\"0\"/>");
		push(@{$output},"\t\t<parameter id=\"FLUX_VALUE\" value=\"0.0\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t</listOfParameters>");
		push(@{$output},"</kineticLaw>");
		push(@{$output},'</reaction>');
	}
	my $bios = $self->biomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $rxn = $bios->[$i];
		my $obj = 0;
		if ($i==0) {
			$obj = 1;
		}
		my $reversibility = "false";
		push(@{$output},'<reaction '.$self->CleanNames("id","biomass".$i).' '.$self->CleanNames("name",$rxn->name()).' '.$self->CleanNames("reversible",$reversibility).'>');
		push(@{$output},"<notes>");
		push(@{$output},"<html:p>GENE_ASSOCIATION: </html:p>");
		push(@{$output},"<html:p>PROTEIN_ASSOCIATION: </html:p>");
		push(@{$output},"<html:p>SUBSYSTEM: </html:p>");
		push(@{$output},"<html:p>PROTEIN_CLASS: </html:p>");
		push(@{$output},"</notes>");
		my $firstreact = 1;
		my $firstprod = 1;
		my $prodoutput = [];
		my $biocpds = $rxn->biomasscompounds();
		for (my $j=0; $j < @{$biocpds}; $j++) {
			my $rgt = $biocpds->[$j];
			if ($rgt->coefficient() < 0) {
				if ($firstreact == 1) {
					$firstreact = 0;
					push(@{$output},"<listOfReactants>");
				}
				push(@{$output},'<speciesReference '.$self->CleanNames("species",$rgt->modelcompound()->id()).' stoichiometry="'.-1*$rgt->coefficient().'"/>');	
			} else {
				if ($firstprod == 1) {
					$firstprod = 0;
					push(@{$prodoutput},"<listOfProducts>");
				}
				push(@{$prodoutput},'<speciesReference '.$self->CleanNames("species",$rgt->modelcompound()->id()).' stoichiometry="'.$rgt->coefficient().'"/>');
			}
		}
		if ($firstreact != 1) {
			push(@{$output},"</listOfReactants>");
		}
		if ($firstprod != 1) {
			push(@{$prodoutput},"</listOfProducts>");
		}
		push(@{$output},@{$prodoutput});
		push(@{$output},"<kineticLaw>");
		push(@{$output},"\t<math xmlns=\"http://www.w3.org/1998/Math/MathML\">");
		push(@{$output},"\t\t\t<ci> FLUX_VALUE </ci>");
		push(@{$output},"\t</math>");
		push(@{$output},"\t<listOfParameters>");
		push(@{$output},"\t\t<parameter id=\"LOWER_BOUND\" value=\"0.0\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t\t<parameter id=\"UPPER_BOUND\" value=\"1000\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t\t<parameter id=\"OBJECTIVE_COEFFICIENT\" value=\"".$obj."\"/>");
		push(@{$output},"\t\t<parameter id=\"FLUX_VALUE\" value=\"0.0\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t</listOfParameters>");
		push(@{$output},"</kineticLaw>");
		push(@{$output},'</reaction>');
	}
	my $cpds = $self->modelcompounds();
	for (my $i=0; $i < @{$cpds}; $i++) {
		my $cpd = $cpds->[$i];
		my $lb = -1000;
		my $ub = 1000;
		if ($cpd->modelCompartmentLabel() =~ m/^e/ || $cpd->msid() eq "cpd08636" || $cpd->msid() eq "cpd11416" || $cpd->msid() eq "cpd15302") {
			push(@{$output},'<reaction '.$self->CleanNames("id",'EX_'.$cpd->id()).' '.$self->CleanNames("name",'EX_'.$cpd->name()).' reversible="true">');
			push(@{$output},"\t".'<notes>');
			push(@{$output},"\t\t".'<html:p>GENE_ASSOCIATION: </html:p>');
			push(@{$output},"\t\t".'<html:p>PROTEIN_ASSOCIATION: </html:p>');
			push(@{$output},"\t\t".'<html:p>PROTEIN_CLASS: </html:p>');
			push(@{$output},"\t".'</notes>');
			push(@{$output},"\t".'<listOfReactants>');
			push(@{$output},"\t\t".'<speciesReference '.$self->CleanNames("species",$cpd->id()).' stoichiometry="1.000000"/>');
			push(@{$output},"\t".'</listOfReactants>');
			push(@{$output},"\t".'<listOfProducts>');
			push(@{$output},"\t\t".'<speciesReference '.$self->CleanNames("species",$cpd->msid()."_b").' stoichiometry="1.000000"/>');
			push(@{$output},"\t".'</listOfProducts>');
			push(@{$output},"\t".'<kineticLaw>');
			push(@{$output},"\t\t".'<math xmlns="http://www.w3.org/1998/Math/MathML">');
			push(@{$output},"\t\t\t\t".'<ci> FLUX_VALUE </ci>');
			push(@{$output},"\t\t".'</math>');
			push(@{$output},"\t\t".'<listOfParameters>');
			push(@{$output},"\t\t\t".'<parameter id="LOWER_BOUND" value="'.$lb.'" units="mmol_per_gDW_per_hr"/>');
			push(@{$output},"\t\t\t".'<parameter id="UPPER_BOUND" value="'.$ub.'" units="mmol_per_gDW_per_hr"/>');
			push(@{$output},"\t\t\t".'<parameter id="OBJECTIVE_COEFFICIENT" value="0"/>');
			push(@{$output},"\t\t\t".'<parameter id="FLUX_VALUE" value="0.000000" units="mmol_per_gDW_per_hr"/>');
			push(@{$output},"\t\t".'</listOfParameters>');
			push(@{$output},"\t".'</kineticLaw>');
			push(@{$output},'</reaction>');
		}	
	}
	#Closing out the file
	push(@{$output},'</listOfReactions>');
	push(@{$output},'</model>');
	push(@{$output},'</sbml>');
	return join("\n",@{$output});
}

sub CleanNames {
		my ($self,$name,$value) = @_;
		$value =~ s/[\s:,-]/_/g;
		$value =~ s/\W//g;
		return $name.'="'.$value.'"';
}

=head3 export

Definition:
	string = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->export();
Description:
	Exports model data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["format"], {}, @_);
	if (lc($args->{format}) eq "sbml") {
		return $self->printSBML();
	} elsif (lc($args->{format}) eq "exchange") {
		return $self->printExchange();
	} elsif (lc($args->{format}) eq "genes") {
		return $self->printGenes();
	} elsif (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	} elsif (lc($args->{format}) eq "cytoseed") {
		return $self->printCytoSEED($args->{fbas});
	} elsif (lc($args->{format}) eq "modelseed") {
		return $self->printModelSEED();
	} elsif (lc($args->{format}) eq "excel") {
		return $self->printExcel();
	} elsif (lc($args->{format}) eq "condensed") {
		return $self->toCondensed();
	}
	Bio::KBase::ObjectAPI::utilities::error("Unrecognized type for export: ".$args->{format});
}

#***********************************************************************************************************
# ANALYSIS FUNCTIONS:
#***********************************************************************************************************

=head3 deleteGapfillSolution

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->deleteGapfillSolution({
		gapfll => string
	});
Description:
	Deletes a gapfilling solution in the model
	
=cut

sub deleteGapfillSolution {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["gapfill"], {}, @_);
	my $gfmeta = $self->getObject("gapfillings",$args->{gapfill});
	if (!defined($gfmeta)) {
		Bio::KBase::ObjectAPI::utilities::error("Gapfill ".$args->{gapfill}." not found!");
	}
	if ($gfmeta->integrated() == 1) {
		$self->unintegrateGapfillSolution({
			gapfill => $args->{gapfill}
		});
	}
	$self->remove("gapfillings",$gfmeta);
}

=head3 unintegrateGapfillSolution

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->unintegrateGapfillSolution({
		solution => Bio::KBase::ObjectAPI::KBaseFBA::Gapfilling*
	});
Description:
	Unintegrates a gapfilling solution in the model
	
=cut

sub unintegrateGapfillSolution {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["gapfill"], {}, @_);
	Bio::KBase::ObjectAPI::utilities::verbose("Now integrating gapfill solution into model");
	my $gfmeta = $self->getObject("gapfillings",$args->{gapfill});
	if (!defined($gfmeta)) {
		Bio::KBase::ObjectAPI::utilities::error("Gapfill ".$args->{gapfill}." not found!");
	}
	if ($gfmeta->integrated() == 0) {
		Bio::KBase::ObjectAPI::utilities::error("Gapfill ".$args->{gapfill}." not currently integrated!");
	}
	$self->_clearIndex();
	$gfmeta->integrated(0);
	$gfmeta->integrated_solution(-1);
	my $rxns = $self->modelreactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		if (defined($rxn->gapfill_data()->{$gfmeta->id()})) {
			#making sure no other integrated gapfillings operate in the same direction
			my $gfdata = $rxn->gapfill_data()->{$gfmeta->id()};
			my $gfarray = [split(/:/,$gfdata)];
			my $found = 0;
			foreach my $gfid (keys(%{$rxn->gapfill_data()})) {
				if ($gfid ne $gfmeta->id()) {
					my $data = $rxn->gapfill_data()->{$gfid};
					my $array = [split(/:/,$data)];
					if ($array->[1] eq $gfarray->[1]) {
						$found = 1;
						last;
					}
				}
			}
			#deleting entry
			delete $rxn->gapfill_data()->{$gfmeta->id()};
			#removing direction if no other gapfilling was found
			if ($found == 0) {
				if ($rxn->direction() eq $gfarray->[1]) {
					$self->remove("modelreactions",$rxn);
				} elsif ($gfarray->[1] eq ">" && $rxn->direction() eq "=") {
					$rxn->direction("<");
				} elsif ($gfarray->[1] eq "<" && $rxn->direction() eq "=") {
					$rxn->direction(">");
				}
			}
		}
	}
	return $gfmeta;
}

=head3 add_gapfilling

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->add_gapfilling({
		object => Bio::KBase::ObjectAPI::KBaseFBA::FBA,
		solution_to_integrate => int
	});
Description:
	Adds a gapfilling object
	
=cut

sub add_gapfilling {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["object","id"], {solution_to_integrate => undef}, @_);
	Bio::KBase::utilities::log("Integrating gapfill solution into model","stdout");
	#Adding gapfill object to model
	my $gfobj = {
		id => $args->{id},
		gapfill_id => $args->{object}->id(),
		integrated => 0,
		media_ref => $args->{object}->media()->_reference()
	};
	if (defined($args->{solution_to_integrate})) {
		$gfobj->{integrated} = 1;
		$gfobj->{integrated_solution} = $args->{solution_to_integrate};
	}
	$self->add("gapfillings",$gfobj);
	#Integrating biomass removal information into biomass compounds
	my $biomass_removals = $args->{object}->biomassRemovals();
	my $brkeys = [keys(%{$biomass_removals})];
	if (@{$brkeys} > 0) {
		my $biomass = "bio1";
		if (!defined($biomass_removals->{bio1})) {
			$biomass = $brkeys->[0];
		}
		$biomass_removals = $biomass_removals->{$biomass};
		my $bioobj = $self->getObject("biomasses",$biomass);
		for (my $i=0; $i < @{$biomass_removals}; $i++) {
			my $biocpds = $bioobj->biomasscompounds();
			my $selectedcpd;
			for (my $j=0; $j < @{$biocpds}; $j++) {
				if ($biocpds->[$j]->modelcompound()->id() eq $biomass_removals->[$i]) {
					$selectedcpd = $biocpds->[$j];
					last;
				}
			}
			if (defined($args->{solution_to_integrate})) {
				$selectedcpd->gapfill_data()->{$args->{id}} = 1;
				$bioobj->add("removedcompounds",$selectedcpd);
				$bioobj->remove("biomasscompounds",$selectedcpd);
			} else {
				$selectedcpd->gapfill_data()->{$args->{id}} = 0;
			}
		}
	}
	#Integrating reaction addition information into model
	my $solutions = $args->{object}->gapfillingSolutions();
	for (my $i=0; $i < @{$solutions}; $i++) {
		my $solution = $solutions->[$i];
		my $integrated = 0;
		if (defined($args->{solution_to_integrate}) && $args->{solution_to_integrate} eq $i) {
			$integrated = 1;
		}
		my $rxns = $solution->gapfillingSolutionReactions();
		for (my $j=0; $j < @{$rxns}; $j++) {
			my $rxn = $rxns->[$j];
			my $rxnid = $rxn->reaction()->id();
			my $mdlrxn;
			my $ismdlrxn = 0;
			if ($rxnid =~ m/(.+)_([a-zA-Z]+)(\d+)$/) {
				my $idindex = $3;
				if ($idindex != $rxn->compartmentIndex()) {
					$rxnid = $1."_".$2.$rxn->compartmentIndex();
				}
				$ismdlrxn = 1;
				$mdlrxn = $self->getObject("modelreactions",$rxnid);
			} else {
				$mdlrxn = $self->getObject("modelreactions",$rxnid.$rxn->compartmentIndex());
			}
			if (defined($mdlrxn)) {
				$mdlrxn->gapfill_data()->{$args->{id}}->{$i} = [$rxn->direction(),$integrated,[]];
				if ($rxn->direction() ne $mdlrxn->direction() && $integrated == 1) {
					$mdlrxn->direction("=");
				}
			} else {
				if ($rxnid =~ m/.+_[a-zA-Z]\d+$/) {
					$ismdlrxn = 1;
					$mdlrxn = $self->getObject("gapfilledcandidates",$rxnid);
				} else {
					$mdlrxn = $self->getObject("gapfilledcandidates",$rxnid.$rxn->compartmentIndex());
				}
				if (defined($mdlrxn)) {
					$mdlrxn->gapfill_data()->{$args->{id}}->{$i} = [$rxn->direction(),$integrated,[]];
					if ($integrated == 1) {
						$self->add("modelreactions",$mdlrxn);
						$mdlrxn->direction() = $rxn->direction();
						$self->removed("gapfilledcandidates",$mdlrxn);
					}
				}
			}
			if (!defined($mdlrxn)) {
				if ($ismdlrxn == 1) {
					if (!defined($self->getObject("modelcompartments",$rxn->compartment()->id().$rxn->compartmentIndex()))) {
						$self->add("modelcompartments",{
							id => $rxn->compartment()->id().$rxn->compartmentIndex(),
							compartment_ref => $rxn->compartment()->_reference(),
							label => $rxn->compartment()->name()."_".$rxn->compartmentIndex(),
							pH => 7,
							compartmentIndex => $rxn->compartmentIndex()
						});
					}
					$mdlrxn = $rxn->reaction()->cloneObject();
					$mdlrxn->parent($rxn->reaction()->parent());
					$mdlrxn->gapfill_data({});
					my $prots = $mdlrxn->modelReactionProteins();
					for (my $m=0; $m < @{$prots}; $m++) {
						$mdlrxn->remove("modelReactionProteins",$prots->[$m]);
					}
					$mdlrxn->direction($rxn->direction());
					my $newrgts = [];
					my $rgts = $mdlrxn->modelReactionReagents();
					for (my $m=0; $m < @{$rgts}; $m++) {
						if ($rgts->[$m]->modelcompound_ref =~ m/\/([^\/]+)_([a-z]+)(\d+)$/) {
							my $cmpid = $2;
							my $mdlcpdid = $1."_".$cmpid.$rxn->compartmentIndex();
							my $mdlcmpdid = $cmpid.$rxn->compartmentIndex();
							my $index = $rxn->compartmentIndex();
							if ($cmpid eq "e") {
								$mdlcpdid = $1."_".$cmpid."0";
								$mdlcmpdid = $cmpid."0";
								$index = 0;
							}
							push(@{$newrgts},{
								modelcompound_ref => "~/modelcompounds/id/".$mdlcpdid,
								coefficient => $rgts->[$m]->coefficient()
							});
							if (!defined($self->getObject("modelcompounds",$mdlcpdid))) {
								if (!defined($self->getObject("modelcompartments",$mdlcmpdid))) {
									$self->add("modelcompartments",{
										id => $mdlcmpdid,
										compartment_ref => "~/template/compartments/id/".$cmpid,
										label => $cmpid."_".$index,
										pH => 7,
										compartmentIndex => $index
									});
								}
								my $name = $rgts->[$m]->modelcompound()->name();
								$name =~ s/_[a-z]+\d+$/_$mdlcmpdid/;
								my $mdlcpd = $self->add("modelcompounds",{
									id => $mdlcpdid,
									compound_ref => $rgts->[$m]->modelcompound()->compound_ref(),
									name => $name,
									aliases => $rgts->[$m]->modelcompound()->aliases(),
									charge => $rgts->[$m]->modelcompound()->charge(),
									maxuptake => $rgts->[$m]->modelcompound()->maxuptake(),
									formula => $rgts->[$m]->modelcompound()->formula(),
									modelcompartment_ref => "~/modelcompartments/id/".$mdlcmpdid,
								});		
							}
						}
						$mdlrxn->remove("modelReactionReagents",$rgts->[$m]);
					}
					for (my $m=0; $m < @{$newrgts}; $m++) {
						$mdlrxn->add("modelReactionReagents",$newrgts->[$m]);
					}
					$mdlrxn->parent($self);
					$mdlrxn->gapfill_data()->{$args->{id}}->{$i} = [$rxn->direction(),$integrated,[]];
					if ($integrated == 1) {
						$mdlrxn = $self->add("modelreactions",$mdlrxn);
					} else {
						$mdlrxn = $self->add("gapfilledcandidates",$mdlrxn);
					}
				} else {
					$mdlrxn = $self->addModelReaction({
						reaction => $rxn->reaction()->msid(),
						compartment => $rxn->reaction()->templatecompartment()->id(),
						compartmentIndex => $rxn->compartmentIndex(),
						direction => $rxn->direction()
					});
					$mdlrxn->gapfill_data()->{$args->{id}}->{$i} = [$rxn->direction(),$integrated,[]];
					if ($integrated == 0) {
						$self->add("gapfilledcandidates",$mdlrxn);
						$self->removed("modelreactions",$mdlrxn);
					}
				}
			}
		}	
	}
}

=head3 searchForCompound

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound->searchForCompound(string:id);
Description:
	Search for compound in model
	
=cut

sub searchForCompound {
    my $self = shift;
    my $id = shift;
    my $compartment = shift;
    my $index = shift;
    if ($id =~ m/^(.+)_([a-z]+)(\d*)$/) {
    	$id = $1;
    	$compartment = $2;
    	$index = $3;
    }
    if ($id =~ m/^(.+)\[([a-z]+)(\d*)]$/) {
    	$id = $1;
    	$compartment = $2;
    	$index = $3;
    }
    if (!defined($compartment)) {
    	$compartment = "c";
    }
    if (!defined($index)) {
    	$index = 0;
    }
    my $mdlcpd = $self->getObject("modelcompounds",$id."_".$compartment.$index);
    if (!defined($mdlcpd)) {
	    my $cpd = $self->template()->searchForCompound($id);
	    if (!defined($cpd)) {
	    	return undef;
	    }
	    my $mdlcmp = $self->queryObject("modelcompartments",{label => $compartment.$index});
	    if (!defined($mdlcmp)) {
	    	return undef;
	    }
	    return $self->queryObject("modelcompounds",{
	    	modelcompartment_ref => $mdlcmp->_reference(),
	    	msid => $cpd->msid()
	    });
    }
    return $mdlcpd;
}

=head3 searchForBiomass

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::Biomass Bio::KBase::ObjectAPI::KBaseFBA::Biomass->searchForBiomass(string:id);
Description:
	Search for biomass in model
	
=cut

sub searchForBiomass {
    my $self = shift;
    my $id = shift;
    my $obj = $self->queryObject("biomasses",{id => $id});
    if (!defined($obj)) {
    	$obj = $self->queryObject("biomasses",{name => $id});
    }
    return $obj;
}

=head3 searchForReaction

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::Biomass Bio::KBase::ObjectAPI::KBaseFBA::Biomass->searchForReaction(string:id);
Description:
	Search for reaction in model
	
=cut

sub searchForReaction {
    my $self = shift;
    my $id = shift;
    my $compartment = shift;
    my $index = shift;
    if ($id =~ m/^(.+)\[([a-z]+)(\d*)]$/) {
    	$id = $1;
    	$compartment = $2;
    	$index = $3;
    } elsif ($id =~ m/^(.+)_([a-z]+)(\d+)$/) {
    	$id = $1;
    	$compartment = $2;
    	$index = $3;
    }
    if (!defined($compartment)) {
    	$compartment = "c";
    }
    if (!defined($index)) {
    	$index = 0;
    }
    my $mdlrxn = $self->getObject("modelreactions",$id."_".$compartment.$index);
    if (!defined($mdlrxn)) {
    	my $rxn = $self->template()->searchForReaction($id);
	    if (!defined($rxn)) {
	    	return undef;
	    }
	    $mdlrxn = $self->getObject("modelreactions",$rxn->msid()."_".$compartment.$index);
    }
    return $mdlrxn;
}

=head3 searchForCompartment

Definition:
  Bio::KBase::ObjectAPI::KBaseFBA::Biomass Bio::KBase::ObjectAPI::KBaseFBA::Biomass->searchForCompartment(string:id);
Description:
        Search for compartment in model

=cut

sub searchForCompartment {
    my $self = shift;
    my $id = shift;
    my $index = shift;
    if ($id =~ m/^([a-z]+)(\d*)$/) {
        $id = $1;
        $index = $2;
    } elsif ($id =~ m/^([a-z]+)(\d+)$/) {
        $id = $1;
        $index = $2;
    }
    if (!defined($index)) {
        $index = 0;
    }
    my $mdlcmp = $self->getObject("modelcompartments",$id.$index);
    if (!defined($mdlcmp)) {
        my $cmp = $self->template()->searchForCompartment($id);
            if (!defined($cmp)) {
                return undef;
            }
            $mdlcmp = $self->getObject("modelcompartments",$cmp->id().$index);
    }
    return $mdlcmp;
}

sub merge_models {
	my $self = shift;
	my $parameters = Bio::KBase::ObjectAPI::utilities::args(["models","fbamodel_output_id"], {mixed_bag_model => 0}, @_);
	my $genomeObj = Bio::KBase::ObjectAPI::KBaseGenomes::Genome->new({
		id => $parameters->{fbamodel_output_id}.".genome",
		scientific_name => $parameters->{fbamodel_output_id}." genome",
		domain => "Community",
		genetic_code => 11,
		dna_size => 0,
		num_contigs => 0,
		contig_lengths => [],
		contig_ids => [],
		source => Bio::KBase::utilities::conf("ModelSEED","source"),
		source_id => $parameters->{fbamodel_output_id}.".genome",
		md5 => "",
		taxonomy => "Community",
		gc_content => 0,
		complete => 0,
		publications => [],
		features => [],
    });
    $genomeObj->parent($self->parent());
    $genomeObj->_reference($self->genome_ref());
    $self->genome($genomeObj);
    my $cmpsHash = {
		e => $self->addCompartmentToModel({
			compartment => $self->template()->biochemistry()->getObject("compartments","e"),
			pH => 7,
			potential => 0,
			compartmentIndex => 0
		}),
		c => $self->addCompartmentToModel({
			compartment => $self->template()->biochemistry()->getObject("compartments","c"),
			pH => 7,
			potential => 0,
			compartmentIndex => 0
		})
	};
	my $totalAbundance = @{$parameters->{models}};
	my $biocount = 1;
	my $primbio = $self->add("biomasses",{
		id => "bio1",
		name => "bio1",
		other => 1,
		dna => 0,
		rna => 0,
		protein => 0,
		cellwall => 0,
		lipid => 0,
		cofactor => 0,
		energy => 0
	});
	my $biomassCompound = $self->template()->getObject("compounds","cpd11416");
	if ($parameters->{mixed_bag_model} == 0) {
		my $biocpd = $self->add("modelcompounds",{
			id => $biomassCompound->id()."_".$cmpsHash->{c}->id(),
			compound_ref => $biomassCompound->_reference(),
			charge => 0,
			modelcompartment_ref => "~/modelcompartments/id/".$cmpsHash->{c}->id()
		});
		$primbio->add("biomasscompounds",{
			modelcompound_ref => "~/modelcompounds/id/".$biocpd->id(),
			coefficient => 1
		});
	}
	my $biohash = {};
	for (my $i=0; $i < @{$parameters->{models}}; $i++) {
		print "Loading model ".$parameters->{models}->[$i]."\n";
		my $model = $self->getLinkedObject($parameters->{models}->[$i]);
		my $biomassCpd = $model->getObject("modelcompounds","cpd11416_c0");
		#Adding genome, features, and roles to master mapping and annotation
		my $mdlgenome = $model->genome();
		$genomeObj->dna_size($genomeObj->dna_size()+$mdlgenome->dna_size());
		$genomeObj->num_contigs($genomeObj->num_contigs()+$mdlgenome->num_contigs());
		$genomeObj->gc_content($genomeObj->gc_content()+$mdlgenome->dna_size()*$mdlgenome->gc_content());
		push(@{$genomeObj->{contig_lengths}},@{$mdlgenome->{contig_lengths}});
		push(@{$genomeObj->{contig_ids}},@{$mdlgenome->{contig_ids}});	
		print "Loading features\n";
		for (my $j=0; $j < @{$mdlgenome->features()}; $j++) {
			if (!defined($mdlgenome->features()->[$j]->quality())) {
				$mdlgenome->features()->[$j]->quality({});
			}
			$genomeObj->add("features",$mdlgenome->features()->[$j]);
		}
		$self->template_refs()->[$i+1] = $model->template_ref();
		#Adding compartments to community model
		my $cmps = $model->modelcompartments();
		print "Loading compartments\n";
		for (my $j=0; $j < @{$cmps}; $j++) {
			if ($cmps->[$j]->compartment()->id() ne "e") {
				my $index = ($i+1);
				if ($parameters->{mixed_bag_model} == 1) {
					$index = 0;
				}
				$cmpsHash->{$cmps->[$j]->compartment()->id()} = $self->addCompartmentToModel({
					compartment => $cmps->[$j]->compartment(),
					pH => 7,
					potential => 0,
					compartmentIndex => $index
				});
			}
		}
		#Adding compounds to community model
		my $translation = {};
		print "Loading compounds\n";
		my $cpds = $model->modelcompounds();
		for (my $j=0; $j < @{$cpds}; $j++) {
			my $cpd = $cpds->[$j];
			my $rootid = $cpd->compound()->id();
			if ($cpd->id() =~ m/(.+)_([a-zA-Z]\d+)/) {
				$rootid = $1;
			}
			my $comcpd = $self->getObject("modelcompounds",$rootid."_".$cmpsHash->{$cpd->modelcompartment()->compartment()->id()}->id());
			if (!defined($comcpd)) {
				$comcpd = $self->add("modelcompounds",{
					id => $rootid."_".$cmpsHash->{$cpd->modelcompartment()->compartment()->id()}->id(),
					compound_ref => $cpd->compound_ref(),
					charge => $cpd->charge(),
					formula => $cpd->formula(),
					modelcompartment_ref => "~/modelcompartments/id/".$cmpsHash->{$cpd->modelcompartment()->compartment()->id()}->id()
				});
			}
			$translation->{$cpd->id()} = $comcpd->id();
		}
		print "Loading reactions";
		#Adding reactions to community model
		my $rxns = $model->modelreactions();
		for (my $j=0; $j < @{$rxns}; $j++) {
			my $rxn = $rxns->[$j];
			my $rootid = $rxn->reaction()->msid();
			if ($parameters->{mixed_bag_model} == 1) {
				if ($rootid eq "rxn00000" && $rxn->id() =~ m/(.+)_([a-zA-Z]\d+)/) {
					$rootid = $1;
				}
			} else {
				if ($rxn->id() =~ m/(.+)_([a-zA-Z]\d+)/) {
					$rootid = $1;
				}
			}
			my $originalcmpid = $rxn->modelcompartment()->compartment()->id();
			if ($originalcmpid eq "e0") {
				$originalcmpid = "c0";
			}
			my $comrxn = $self->getObject("modelreactions",$rootid."_".$cmpsHash->{$originalcmpid}->id());
			if (!defined($comrxn)) {
				$comrxn = $self->add("modelreactions",{
					id => $rootid."_".$cmpsHash->{$originalcmpid}->id(),
					reaction_ref => $rxn->reaction_ref(),
					direction => $rxn->direction(),
					protons => $rxn->protons(),
					modelcompartment_ref => "~/modelcompartments/id/".$cmpsHash->{$originalcmpid}->id(),
					probability => $rxn->probability()
				});
				for (my $k=0; $k < @{$rxn->modelReactionReagents()}; $k++) {
					$comrxn->add("modelReactionReagents",{
						modelcompound_ref => "~/modelcompounds/id/".$translation->{$rxn->modelReactionReagents()->[$k]->modelcompound()->id()},
						coefficient => $rxn->modelReactionReagents()->[$k]->coefficient()
					});
				}
			}
			for (my $k=0; $k < @{$rxn->modelReactionProteins()}; $k++) {
				$comrxn->add("modelReactionProteins",$rxn->modelReactionProteins()->[$k]);
			}
		}
		print "Loading biomass";
		#Adding biomass to community model
		my $bios = $model->biomasses();
		for (my $j=0; $j < @{$bios}; $j++) {
			if ($parameters->{mixed_bag_model} == 0) {
				my $bio = $bios->[$j]->cloneObject();
				$bio->parent($self);
				for (my $k=0; $k < @{$bio->biomasscompounds()}; $k++) {
					$bio->biomasscompounds()->[$k]->modelcompound_ref("~/modelcompounds/id/".$translation->{$bios->[$j]->biomasscompounds()->[$k]->modelcompound()->id()});
				}
				$bio = $self->add("biomasses",$bio);
				$biocount++;
				$bio->id("bio".$biocount);
				$bio->name("bio".$biocount);
			} elsif ($j == 0) {
				for (my $k=0; $k < @{$bios->[$j]->biomasscompounds()}; $k++) {	
					if (defined($biohash->{$translation->{$bios->[$j]->biomasscompounds()->[$k]->modelcompound()->id()}})) {
						$biohash->{$translation->{$bios->[$j]->biomasscompounds()->[$k]->modelcompound()->id()}}->coefficient($biohash->{$translation->{$bios->[$j]->biomasscompounds()->[$k]->modelcompound()->id()}}->coefficient() + $bios->[$j]->biomasscompounds()->[$k]->coefficient()); 
					} else {
						$biohash->{$translation->{$bios->[$j]->biomasscompounds()->[$k]->modelcompound()->id()}} = $primbio->add("biomasscompounds",{
							modelcompound_ref => "~/modelcompounds/id/".$translation->{$bios->[$j]->biomasscompounds()->[$k]->modelcompound()->id()},
							coefficient => $bios->[$j]->biomasscompounds()->[$k]->coefficient()
						});
					}
				}
			}
		}
		print "Loading primary biomass";
		#Adding biomass component to primary composite biomass reaction
		if ($parameters->{mixed_bag_model} == 0) {
			$primbio->add("biomasscompounds",{
				modelcompound_ref => "~/modelcompounds/id/".$translation->{$biomassCpd->id()},
				coefficient => -1/$totalAbundance
			});
		}
	}
	if ($parameters->{mixed_bag_model} == 1) {
		for (my $k=0; $k < @{$primbio->biomasscompounds()}; $k++) {	
			$primbio->biomasscompounds()->[$k]->coefficient($primbio->biomasscompounds()->[$k]->coefficient()/$totalAbundance);
		}
	}
	print "Merge complete!";
	return $genomeObj;
}

=head3 edit_metabolic_model

Definition:
    $self->edit_metabolic_model({
    	reactions_to_remove => [],
    	reactions_to_add => [],
    	reactions_to_modify => []
    });
Description:
    Function for manually editing a metabolic model

=cut
sub edit_metabolic_model {
	my ($self,$params) = @_;
    $params = Bio::KBase::ObjectAPI::utilities::args([], {
    	biomass_changes => [],
    	reactions_to_remove => [],
    	reactions_to_add => [],
    	reactions_to_modify => []
    },$params);
	my $uuid = Data::UUID->new()->create_str();
	my $added = [];
	my $removed = [];
	my $changed = [];
	my $biomass_added = [];
	my $biomass_changed = [];
	my $biomass_removed = [];
	my $det_added = [];
	my $det_removed = [];
	my $det_changed = [];
	my $det_biomass_added = [];
	my $det_biomass_changed = [];
	my $det_biomass_removed = [];
	#Removing reactions specified for removal
	Bio::KBase::utilities::log("Changing specified biomass compounds");
	if (defined($params->{biomass_changes})) {
		for (my $i=0; $i < @{$params->{biomass_changes}}; $i++) {
	    	my $biomass = $self->getObject("biomasses",$params->{biomass_changes}->[$i]->[0]);
	    	if (!defined($biomass)) {
	    		$biomass = $self->add("biomasses",{
	    			id => $params->{biomass_changes}->[$i]->[0],
					name => $params->{biomass_changes}->[$i]->[0],
					other => 1,
					dna => 0,
					rna => 0,
					protein => 0,
					cellwall => 0,
					lipid => 0,
					cofactor => 0,
					energy => 0,
					biomasscompounds => [],
					removedcompounds => []
	    		});
	    	}
    		my $biocpds = $biomass->biomasscompounds();
    		my $biocpd;
    		for (my $j=0; $j < @{$biocpds}; $j++) {
    			if ($biocpds->[$j]->modelcompound()->id() eq $params->{biomass_changes}->[$i]->[1]) {
    				$biocpd = $biocpds->[$j];
    			}
    		}
    		if (defined($biocpd)) {
    			if ($params->{biomass_changes}->[$i]->[2] != 0) {
    				push(@{$biomass_changed},[$params->{biomass_changes}->[$i]->[0],$params->{biomass_changes}->[$i]->[1]]);
    				$biocpd->edits()->{$uuid} = {
    					status => "modified",
    					compound => $params->{biomass_changes}->[$i]->[1],
    					coefficient => [$biocpd->coefficient(),$params->{biomass_changes}->[$i]->[2]]
    				};
    				push(@{$det_biomass_changed},$biocpd->edits()->{$uuid});
    				$biocpd->coefficient($params->{biomass_changes}->[$i]->[2]);
    				
    			} else {
    				push(@{$biomass_removed},[$params->{biomass_changes}->[$i]->[0],$params->{biomass_changes}->[$i]->[1]]);
    				$biomass->remove("biomasscompounds",$biocpd);
    				if (!defined($biomass->deleted_compounds()->{$biocpd->modelcompound()->id()})) {
    					$biomass->deleted_compounds()->{$biocpd->modelcompound()->id()} = $biocpd->serializeToDB();
    				}
    				$biomass->deleted_compounds()->{$biocpd->modelcompound()->id()}->{edits}->{$uuid} = {
    					status => "deleted",
    					compound => $params->{biomass_changes}->[$i]->[1],
    					coefficient => [$biocpd->coefficient(),undef]
    				};
    				push(@{$det_biomass_removed},$biomass->deleted_compounds()->{$biocpd->modelcompound()->id()}->{edits}->{$uuid});
    				if (@{$biomass->biomasscompounds()} == 0) {
    					$self->remove("biomasses",$biomass);
    					if (!defined($self->delete_biomasses()->{$biomass->id()})) {
			    			$self->delete_biomasses()->{$biomass->id()} = $biomass->serializeToDB();
			    		}
			    		$self->delete_biomasses()->{$biomass->id()}->{edits}->{$uuid} = {
							status => "deleted",
							compound => $params->{biomass_changes}->[$i]->[1],
    						coefficient => [$biocpd->coefficient(),undef]
						};
    				}
    			}
    		} elsif ($params->{biomass_changes}->[$i]->[2] != 0) {
    			my $cpdobj = $self->getObject("modelcompounds",$params->{biomass_changes}->[$i]->[1]);
    			if (!defined($cpdobj)) {
    				my $cpdref = "~/template/compounds/id/cpd00000";
    				my $cpdarray = [split(/_/,$params->{biomass_changes}->[$i]->[1])];
    				my $mdlcmp = $self->getObject("modelcompartments",$cpdarray->[1]);
    				if (!defined($mdlcmp)) {
    					my $index = 0;
    					my $label = $cpdarray->[1];
    					if ($cpdarray->[1] =~ m/([a-z]+)(\d+)/) {
    						$index = $2;
    						$label = $1;
    					}
    					$self->add("modelcompartments",{
	    					id => $label.$index,
							compartment_ref => "~/template/compartment/id/".$label,
							compartmentIndex => $index,
							label => $label.$index,
							pH => 7,
							potential => 0
	    				});
    				}
    				my $name = $cpdarray->[0];
    				my $charge = 0;
    				my $formula = "";
    				if ($cpdarray->[0] =~ m/cpd\d+/) {
    					my $tmpcpd = $self->template()->getObject("compounds",$cpdarray->[0]);
    					if (defined($tmpcpd)) {
    						$cpdref = "~/template/compounds/id/".$cpdarray->[0];
    						$name = $tmpcpd->name();
		    				$charge = $tmpcpd->charge();
		    				$formula = $tmpcpd->formula();
    					}
    				}
    				$self->add("modelcompounds",{
    					id => $params->{biomass_changes}->[$i]->[1],
						compound_ref => $cpdref,
						name => $name,
						charge => $charge,
						formula => $formula,
						modelcompartment_ref => "~/modelcompartments/id/".$mdlcmp->id()
    				});
    			}    			
    			push(@{$biomass_added},[$params->{biomass_changes}->[$i]->[0],$params->{biomass_changes}->[$i]->[1]]);
    			my $biocpd = $biomass->add("biomasscompounds",{
    				modelcompound_ref => "~/modelcompounds/id/".$params->{biomass_changes}->[$i]->[1],
					coefficient => $params->{biomass_changes}->[$i]->[2],
					gapfill_data => {},
					edits => {
						$uuid => {
							status => "added",
							compound => $params->{biomass_changes}->[$i]->[1],
							coefficient => [undef,$params->{biomass_changes}->[$i]->[2]]
						}
					}
    			});
    			push(@{$det_biomass_added},$biocpd->edits()->{$uuid});
    		}
	    }
	}
	#Removing reactions specified for removal
	Bio::KBase::utilities::log("Removing specified reactions");
	if (defined($params->{reactions_to_remove})) {
		for (my $i=0; $i < @{$params->{reactions_to_remove}}; $i++) {
	    	my $rxnobj = $self->getObject("modelreactions",$params->{reactions_to_remove}->[$i]);
	    	if (defined($rxnobj)) {
	    		if (!defined($self->deleted_reactions()->{$rxnobj->id()})) {
	    			$self->deleted_reactions()->{$rxnobj->id()} = $rxnobj->serializeToDB();
	    		}
	    		$self->deleted_reactions()->{$rxnobj->id()}->{edits}->{$uuid} = {
					status => "deleted",
					reaction => $params->{reactions_to_remove}->[$i],
				    compartment => $rxnobj->modelCompartmentLabel(),
				    direction => [$rxnobj->direction(),undef],
				    gpr => [$rxnobj->gprString(),undef],
				    equation => [$rxnobj->equation(),undef],
				    pathway => [$rxnobj->pathway(),undef],
				    name => [$rxnobj->name(),undef],
				    reference => [$rxnobj->reference(),undef],
				};
	    		push(@{$removed},$rxnobj->id());
	    		push(@{$det_removed},$self->deleted_reactions()->{$rxnobj->id()}->{edits}->{$uuid});
	    		$self->remove("modelreactions",$rxnobj);
	    	}
	    }
	}
	#Adding reactions specified for addition
	Bio::KBase::utilities::log("Adding specified reactions");
	#($params->{reactions},my $compoundhash) = $self->util_process_reactions_list($params->{reactions},$params->{compounds});
	if (defined($params->{reactions_to_add})) {
		for (my $i=0; $i < @{$params->{reactions_to_add}}; $i++) {
	    	my $rxn = $params->{reactions_to_add}->[$i];
		    $rxn->[0] =~ s/[^\w]/_/g;
	    	if (defined($rxn->[8])) {
	    		if ($rxn->[8] =~ m/^\[([A-Za-z])\]\s*:\s*(.+)/) {
	    			$rxn->[2] = lc($1);
	    			$rxn->[8] = $2;
	    		}
	    		my $eqn = "| ".$rxn->[8]." |";
	    		my $species_array = [split(/[\s\+<>=]+/,$rxn->[8])];
	    		my $translation = {};
	    		for (my $j=0; $j < @{$species_array}; $j++) {
	    			$species_array->[$j] =~ s/\[.+\]$//g;
	    			$species_array->[$j] =~ s/^\(\d+\)\s*//g;
	    			my $id = $species_array->[$j];
			    	if ($id =~ m/[^\w]/) {
			    		$species_array->[$j] =~ s/[^\w]/_/g;
			    	}
			    	if ($id =~ m/-/) {
			    		$species_array->[$j] =~ s/-/_/g;
			    	}
			    	$translation->{$id} = $species_array->[$j];
	    		}
	    		foreach my $cpd (keys(%{$translation})) {
	    			if (index($eqn,$cpd) >= 0 && $cpd ne $translation->{$cpd}) {
	    				my $origcpd = $cpd;
	    				$cpd =~ s/\+/\\+/g;
	    				$cpd =~ s/\(/\\(/g;
	    				$cpd =~ s/\)/\\)/g;
	    				my $array = [split(/\s$cpd\s/,$eqn)];
	    				$eqn = join(" ".$translation->{$origcpd}." ",@{$array});
	    				$array = [split(/\s$cpd\[/,$eqn)];
	    				$eqn = join(" ".$translation->{$origcpd}."[",@{$array});
	    			}
	    		}
	    		$eqn =~ s/^\|\s//;
	    		$eqn =~ s/\s\|$//;
	    		while ($eqn =~ m/\[([A-Z])\]/) {
	    			my $reqplace = "[".lc($1)."]";
	    			$eqn =~ s/\[[A-Z]\]/$reqplace/;
	    		}
	    		if ($eqn =~ m/<[-=]+>/) {
	    			if (!defined($rxn->[1])) {
	    				$rxn->[1] = "=";
	    			}
	    		} elsif ($eqn =~ m/[-=]+>/) {
	    			if (!defined($rxn->[1])) {
	    				$rxn->[1] = ">";
	    			}
	    		} elsif ($eqn =~ m/<[-=]+/) {
	    			if (!defined($rxn->[1])) {
	    				$rxn->[1] = "<";
	    			}
	    		}
	    		$rxn->[8] = $eqn;
	    	}
	    	my $rxnobj = $self->addModelReaction({
			    reaction => $rxn->[0],
			    direction => $rxn->[2],
			    compartment => $rxn->[1],
			    gpr => $rxn->[3],
			    compounds => {},
			    equation => $rxn->[8],
			    pathway => $rxn->[4],
			    name => $rxn->[5],
			    reference => $rxn->[6],
			    enzyme => $rxn->[7]
			});
			$rxnobj->edits()->{$uuid} = {
				status => "added",
				reaction => $rxn->[0],
				compartment => $rxn->[1],
			    direction => [undef,$rxn->[2]],
			    gpr => [undef,$rxn->[3]],
			    equation => [undef,$rxn->[8]],
			    pathway => [undef,$rxn->[4]],
			    name => [undef,$rxn->[5]],
			    reference => [undef,$rxn->[6]],
			    enzyme => [undef,$rxn->[7]]
			};
			push(@{$added},$rxnobj->id());
			push(@{$det_added},$rxnobj->edits()->{$uuid});
	    }
	}
	#Modifying reactions specified for modification
	Bio::KBase::utilities::log("Modifying specified reactions");
	if (defined($params->{reactions_to_modify})) {
		for (my $i=0; $i < @{$params->{reactions_to_modify}}; $i++) {
	    	my $rxnobj = $self->getObject("modelreactions",$params->{reactions_to_modify}->[$i]->[0]);
	    	my $editdata = {
				status => "modified",
			    reaction => $params->{reactions_to_modify}->[$i]->[0],
			    compartment => $rxnobj->modelCompartmentLabel(),
			    equation => [$rxnobj->equation(),$params->{reactions_to_modify}->[$i]->[7]],
			    direction => [$rxnobj->direction(),$params->{reactions_to_modify}->[$i]->[1]],
			    gpr => [$rxnobj->gprString(),$params->{reactions_to_modify}->[$i]->[2]],
			    pathway => [$rxnobj->pathway(),$params->{reactions_to_modify}->[$i]->[3]],
			    name => [$rxnobj->name(),$params->{reactions_to_modify}->[$i]->[4]],
			    reference => [$rxnobj->reference(),$params->{reactions_to_modify}->[$i]->[5]],
			    enzyme => [undef,$params->{reactions_to_modify}->[$i]->[6]]
			};
	    	$self->adjustModelReaction({
			    reaction => $params->{reactions_to_modify}->[$i]->[0],
			    direction => $params->{reactions_to_modify}->[$i]->[1],
			    gpr => $params->{reactions_to_modify}->[$i]->[2],
			    pathway => $params->{reactions_to_modify}->[$i]->[3],
			    name => $params->{reactions_to_modify}->[$i]->[4],
			    reference => $params->{reactions_to_modify}->[$i]->[5],
			    enzyme => $params->{reactions_to_modify}->[$i]->[6]
			});
			$rxnobj->edits()->{$uuid} = $editdata;
			push(@{$changed},$rxnobj->id());
			push(@{$det_changed},$rxnobj->edits()->{$uuid});
	    }
	}
	my $newedit = {
    	id => $uuid,
    	timestamp => DateTime->now()->datetime(),
    	reactions_removed  => $removed,
    	reactions_added => $added,
    	reactions_modified => $changed,
    	biomass_added => $biomass_added,
		biomass_changed => $biomass_changed,
		biomass_removed => $biomass_removed
    };
    my $detailededit = {
    	id => $uuid,
    	timestamp => DateTime->now()->datetime(),
    	reactions_removed  => $det_removed,
    	reactions_added => $det_added,
    	reactions_modified => $det_changed,
    	biomass_added => $det_biomass_added,
		biomass_changed => $det_biomass_changed,
		biomass_removed => $det_biomass_removed
    };
    print Data::Dumper->Dump([$detailededit]);
    push(@{$self->model_edits()},$newedit);
	return ($newedit,$detailededit);
}

=head3 undo_edit

Definition:
    $self->undo_edit({});
Description:
    Undoes and removes the last edit from the model

=cut
sub undo_edit {
	my ($params) = @_;
	$params = Bio::KBase::ObjectAPI::utilities::args([], {}, @_);
	
}

=head3 translate_model

Definition:
    $self->translate_model(ProteomeComparison:comparison);
Description:
    Translates model to new genome based on proteome comparison

=cut
sub translate_model {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["proteome_comparison"], {
		keep_nogene_rxn => 1,
		translation_policy => "translate_only"
	}, @_);
	my $protcomp = $args->{proteome_comparison};
	my $genome = $self->genome();
	my $ftrs = $genome->features();
	my $numftrs = @{$ftrs};
	my $ftrhash;
	for (my $i=0; $i < @{$ftrs}; $i++) {
		$ftrhash->{$ftrs->[$i]->id()} = 1;
	}
	my $onewgenome = $self->getLinkedObject($protcomp->{genome1ref});
	$ftrs = $onewgenome->features();
	my $matchcount = 0;
	for (my $i=0; $i < @{$ftrs}; $i++) {
		if (defined($ftrhash->{$ftrs->[$i]->id()})) {
			$matchcount++;
		}
	}
	my $newgenome = $self->getLinkedObject($protcomp->{genome2ref});
	$ftrs = $newgenome->features();
	my $omatchcount = 0;
	for (my $i=0; $i < @{$ftrs}; $i++) {
		if (defined($ftrhash->{$ftrs->[$i]->id()})) {
			$omatchcount++;
		}
	}
	my $ref = $protcomp->{genome2ref};
	my $map = $protcomp->{proteome1map};
	my $list = $protcomp->{proteome1names};
	my $data = $protcomp->{data1};
	my $omap = $protcomp->{proteome2map};
	my $olist = $protcomp->{proteome2names};
	my $odata = $protcomp->{data2};
	if ($omatchcount >  $matchcount) {
		$newgenome = $onewgenome;
		$matchcount = $omatchcount;
		$ref = $protcomp->{genome1ref};
		$map = $protcomp->{proteome2map};
		$list = $protcomp->{proteome2names};
		$data = $protcomp->{data2};
		$omap = $protcomp->{proteome1map};
		$olist = $protcomp->{proteome1names};
		$odata = $protcomp->{data1};
	}
	if ($numftrs == 0) {
		Bio::KBase::ObjectAPI::utilities::error("The model is associated with a genome that contains no features!");
	}
	print "Fraction of matching features between model genomes and proteome comparison:".$matchcount/$numftrs."\n";
	if ($matchcount/$numftrs < 0.8) {
		Bio::KBase::ObjectAPI::utilities::error("Proteome comparison does not involve genome used in model!");
	}
	my $translate;
	$ftrhash = {};
	for(my $i=0; $i < @{$data}; $i++) {
		for (my $j=0; $j < @{$data->[$i]}; $j++) {
			if ($data->[$i]->[$j]->[2] == 100) {
				push(@{$translate->{$list->[$i]}},$olist->[$data->[$i]->[$j]->[0]]);
				if ($args->{translation_policy} eq "add_reactions_for_unique_genes") {
					$ftrhash->{$olist->[$data->[$i]->[$j]->[0]]} = 1;
				}
			}
		}
	}
	my $reactions = $self->modelreactions();
	for (my $i=0; $i < @{$reactions}; $i++) {
		my $rxn = $reactions->[$i];
		my $prots = $rxn->modelReactionProteins();
		my $keeprxn = 0;
		my $rxnftrs = 0;
		for (my $j=0; $j < @{$prots}; $j++) {
			my $sus = $prots->[$j]->modelReactionProteinSubunits();
			my $keep = 0;
			for (my $k=0; $k < @{$sus}; $k++) {
				my $ftrs = $sus->[$k]->features();
				my $newftrs = [];
				for (my $m=0; $m < @{$ftrs}; $m++) {
					$rxnftrs = 1;
					if (defined($translate->{$ftrs->[$m]->id()})) {
						foreach my $gene (@{$translate->{$ftrs->[$m]->id()}}) {
							my $newftr = $newgenome->getObject("features",$gene);
							if ($args->{translation_policy} eq "reconcile") {
								$ftrhash->{$newftr->id()} = 1;
							}
							push(@{$newftrs},$newftr->_reference());
						}
					}
				}
				if (@{$newftrs} > 0) {
					$keep = 1;
					$keeprxn = 1;
				}
				$sus->[$k]->feature_refs($newftrs);
			}
			if ($keep == 0) {
				$rxn->removeLinkArrayItem("modelReactionProteins",$prots->[$j]);
			}
		}
		if (@{$rxn->modelReactionProteins()} == 0 || $keeprxn == 0) {
			if ($rxnftrs == 1 || $args->{keep_nogene_rxn} == 0) {
				$self->remove("modelreactions",$rxn);
			}
		}
	}
	$self->genome_ref($ref);
	$self->name($newgenome->scientific_name());
	$self->genome($newgenome);
	if ($args->{translation_policy} ne "translate_only") {
		my $extra_features = [];
		$ftrs = $newgenome->features();
		for (my $i=0; $i < @{$ftrs}; $i++) {
			if (!defined($ftrhash->{$ftrs->[$i]->id()})) {
				push(@{$extra_features},$ftrs->[$i]);
			}
		}
		$self->template()->extend_model_from_features({
			model => $self,
			features => $extra_features
		});
	}
	return {};
}

sub translate_to_localrefs {
	my $self = shift;
	my $compartments = $self->modelcompartments();
    for (my $i=0; $i < @{$compartments}; $i++) {
		if ($compartments->[$i]->compartment_ref() =~ m/\/([^\/]+)$/) {
    		$compartments->[$i]->compartment_ref("~/template/compartments/id/".$1);
		}
    }
	my $compounds = $self->modelcompounds();
    for (my $i=0; $i < @{$compounds}; $i++) {
		if ($compounds->[$i]->compound_ref() =~ m/\/([^\/]+)$/) {
			$compounds->[$i]->compound_ref("~/template/compounds/id/".$1);
		}
    }
    my $reactions = $self->modelreactions();
    for (my $i=0; $i < @{$reactions}; $i++) {
		my $array = [split(/_/,$reactions->[$i]->id())];
	 	my $comp = pop(@{$array});
	 	$comp =~ s/\d+//;
		if ($reactions->[$i]->reaction_ref() =~ m/\/([^\/]+)$/) {
			$reactions->[$i]->reaction_ref("~/template/reactions/id/".$1."_".$comp);
		}
		my $prots = $reactions->[$i]->modelReactionProteins();
    	for (my $j=0; $j < @{$prots}; $j++) {
    		if ($prots->[$j]->complex_ref() =~ m/\/([^\/]+)$/) {
    			$prots->[$j]->complex_ref("~/template/complexes/name/".$1);
    		}
    		my $subunits = $prots->[$j]->modelReactionProteinSubunits();
    		for (my $k=0; $k < @{$subunits}; $k++) {
    			my $ftrrefs = $subunits->[$k]->feature_refs();
    			for (my $m=0; $m < @{$ftrrefs}; $m++) {
    				if ($ftrrefs->[$m] =~ m/\/([^\/]+)$/) {
    					$ftrrefs->[$m] = "~/genome/features/id/".$1;
    				}
    			}
    		}
    	}
    }
}

sub update_from_old_versions {
	my $self = shift;
	my $gfs = $self->gapfillings();
	my $updated = 1;
	for (my $i=0; $i < @{$gfs}; $i++) {
		if (length($gfs->[$i]->gapfill_ref()) > 0) {
			$updated = 0;
		} elsif (length($gfs->[$i]->fba_ref()) > 0) {
			$updated = 0;
		}
	}
	if ($updated == 0) {
		print "Updating model gapfilling data!\n";
		for (my $i=0; $i < @{$gfs}; $i++) {
			$self->remove("gapfillings",$gfs->[$i]);	
		}
		for (my $i=0; $i < @{$gfs}; $i++) {
			my $fbobj;
			if (length($gfs->[$i]->gapfill_ref()) > 0) {
				$fbobj = $gfs->[$i]->gapfill();
			} elsif (length($gfs->[$i]->fba_ref()) > 0) {
				$fbobj = $gfs->[$i]->fba();
			}
			if (defined($fbobj) && defined($fbobj->gapfillingSolutions()->[0])) {
				print "Updating older style model gapfilling to new formats.\n";
				$fbobj->fbamodel($self);
				$self->add_gapfilling({
					object => $fbobj,
					id => "gf.".$i,
					solution_to_integrate => 0
				});
			}
		}
	}
}

__PACKAGE__->meta->make_immutable;
1;
