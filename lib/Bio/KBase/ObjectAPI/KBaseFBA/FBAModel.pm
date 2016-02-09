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
	my $mdlcpd = $self->queryObject("modelcompounds",{compound_ref => $args->{compound}->_reference(),modelcompartment_ref => "~/modelcompartments/id/".$args->{modelCompartment}->id()});
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
					$rgtcmp = $self->addCompartmentToModel({compartment => $rgt->templatecompcompound()->templatecompartment(),pH => 7,potential => 0,compartmentIndex => 0});
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
	    		my $cmp = $self->template()->searchForCompartment($compartment);
	    		if (!defined($cmp)) {
	    			Bio::KBase::ObjectAPI::utilities::error("Unrecognized compartment in equation:".$compartment."!");
	    		}
	    		my $mdlcmp = $self->getObject("modelcompartments",$compartment.$index);
	    		if (!defined($mdlcmp)) {
	    			$mdlcmp = $self->add("modelcompartments",{
	    				id => $compartment.$index,
						compartment_ref => $cmp->_reference(),
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

=head3 integrateGapfillSolution

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->integrateGapfillSolution({
		gapfll => string
	});
Description:
	Integrates a gapfilling solution into the model
	
=cut

sub integrateGapfillSolution {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["gapfill"], { solution => undef,rxnProbGpr => undef }, @_);
	Bio::KBase::ObjectAPI::utilities::verbose("Now integrating gapfill solution into model");
	my $gfmeta = $self->getObject("gapfillings",$args->{gapfill});
	if (!defined($gfmeta)) {
		Bio::KBase::ObjectAPI::utilities::error("Gapfill ".$args->{gapfill}." not found!");
	}
	if ($gfmeta->integrated() == 1) {
		Bio::KBase::ObjectAPI::utilities::error("Gapfill ".$args->{gapfill}." already integrated!");
	}
	$self->_clearIndex();
	my $gf;
	if (defined($gfmeta->fba_ref())) {
		$gf = $gfmeta->fba();
	} else {
		$gf = $gfmeta->gapfill();
	}
	if (!defined($args->{solution})) {
		$args->{solution} = $gf->gapfillingSolutions()->[0]->id();
	}
	$gfmeta->integrated(1);
	$gfmeta->integrated_solution($args->{solution});
	$args->{gapfill} = $gf;
	return $self->integrateGapfillSolutionFromObject($args);
}

sub integrateGapfillSolutionFromObject {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["gapfill"], { solution => undef,rxnProbGpr => undef }, @_);
	my $gf = $args->{gapfill};
	my $sol;
	if (!defined($args->{solution})) {
		$args->{solution} = $gf->gapfillingSolutions()->[0]->id();
	}
	$sol = $gf->getObject("gapfillingSolutions",$args->{solution});
	if (!defined($sol)) {
		Bio::KBase::ObjectAPI::utilities::error("Solution ".$args->{solution}." not found in gapfill ".$args->{gapfill}."!");
	}
	#Integrating biomass removals into model
	if (defined($sol->biomassRemovals()) && @{$sol->biomassRemovals()} > 0) {
		my $removals = $sol->biomassRemovals();
		foreach my $rem (@{$removals}) {
            my $biomass = $self->biomasses()->[0];
			my $biocpds = $biomass->biomasscompounds();
			foreach my $biocpd (@{$biocpds}) {
				if ($biocpd->modelcompound()->_reference() eq $rem) {
					Bio::KBase::ObjectAPI::logging::log(
						"Removing ".$biocpd->modelcompound()->id()." from model biomass."
					);
					$biomass->remove("biomasscompounds",$biocpd);
					last;
				}
			}
		}
	}	
	#Integrating new reactions into model
	my $rxns = $sol->gapfillingSolutionReactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		my $rxnid = $rxn->reaction()->id();
		my $mdlrxn;
		my $ismdlrxn = 0;
		if ($rxnid =~ m/.+_[a-zA-Z]\d+$/) {
			$ismdlrxn = 1;
			$mdlrxn = $self->getObject("modelreactions",$rxnid);
		} else {
			$mdlrxn = $self->getObject("modelreactions",$rxnid.$rxn->compartmentIndex());
		}
		if (defined($mdlrxn) && $rxn->direction() ne $mdlrxn->direction()) {
			Bio::KBase::ObjectAPI::logging::log(
				"Making ".$mdlrxn->id()." reversible."
			);
			$mdlrxn->gapfill_data()->{$gf->id()} = "reversed:".$rxn->direction();
			$mdlrxn->direction("=");
		} else {
			Bio::KBase::ObjectAPI::logging::log(
				"Adding ".$rxnid.$rxn->compartmentIndex()." to model in ".$rxn->direction()." direction."
			);
			if ($ismdlrxn == 1) {
				if (!defined($self->getObject("modelcompartments",$rxn->reaction()->modelcompartment()->id()))) {
					$self->add("modelcompartments",$rxn->reaction()->modelcompartment()->cloneObject());
				}
				$mdlrxn = $self->add("modelreactions",$rxn->reaction()->cloneObject());
				$mdlrxn->gapfill_data()->{$gf->id()} = "added:".$rxn->direction();
				$mdlrxn->parent($rxn->reaction()->parent());
				my $prots = $mdlrxn->modelReactionProteins();
				for (my $m=0; $m < @{$prots}; $m++) {
					$mdlrxn->remove("modelReactionProteins",$prots->[$m]);
				}
				my $rgts = $mdlrxn->modelReactionReagents();
				for (my $m=0; $m < @{$rgts}; $m++) {
					if (!defined($self->getObject("modelcompounds",$rgts->[$m]->modelcompound()->id()))) {
						$self->add("modelcompounds",$rgts->[$m]->modelcompound()->cloneObject());		
						if (!defined($self->getObject("modelcompartments",$rgts->[$m]->modelcompound()->modelcompartment()->id()))) {
							$self->add("modelcompartments",$rgts->[$m]->modelcompound()->modelcompartment()->cloneObject());
						}
					}
				}
				$mdlrxn->parent($self);
			} else {
				$mdlrxn = $self->addModelReaction({
					reaction => $rxn->reaction()->msid(),
					compartment => $rxn->reaction()->templatecompartment()->id(),
					compartmentIndex => $rxn->compartmentIndex(),
					direction => $rxn->direction()
				});
				$mdlrxn->gapfill_data()->{$gf->id()} = "added:".$rxn->direction();
			}
			# If RxnProbs object is defined, use it to assign GPRs to the integrated reactions.
			if (defined($args->{rxnProbGpr}) && defined($args->{rxnProbGpr}->{$rxnid})) {
			    $mdlrxn->loadGPRFromString($args->{rxnProbGpr}->{$rxnid});
			}
		}
	}
	#Checking if gapfilling formulation is in the unintegrated list 
	return {};
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
	my $parameters = Bio::KBase::ObjectAPI::utilities::args(["models"], {}, @_);
	my $genomeObj = Bio::KBase::ObjectAPI::KBaseGenomes::Genome->new({
		id => $parameters->{output_file}.".genome",
		scientific_name => $parameters->{output_file}." genome",
		domain => "Community",
		genetic_code => 11,
		dna_size => 0,
		num_contigs => 0,
		contig_lengths => [],
		contig_ids => [],
		source => Bio::KBase::ObjectAPI::config::source(),
		source_id => $parameters->{output_file}.".genome",
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
	my $totalAbundance = 0;
	for (my $i=0; $i < @{$parameters->{models}}; $i++) {
		$totalAbundance += $parameters->{models}->[$i]->[1];
	}
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
	my $biomassCompound = $self->template()->biochemistry()->getObject("compounds","cpd11416");
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
	for (my $i=0; $i < @{$parameters->{models}}; $i++) {
		print "Loading model ".$parameters->{models}->[$i]->[0]."\n";
		my $model = $self->getLinkedObject($parameters->{models}->[$i]->[0]);
		my $biomassCpd = $self->getObject("modelcompounds","cpd11416_c0");
		#Adding genome, features, and roles to master mapping and annotation
		my $mdlgenome = $self->genome();
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
				$cmpsHash->{$cmps->[$j]->compartment()->id()} = $self->addCompartmentToModel({
					compartment => $cmps->[$j]->compartment(),
					pH => 7,
					potential => 0,
					compartmentIndex => ($i+1)
				});
			}
		}
		#Adding compounds to community model
		my $translation = {};
		Bio::KBase::ObjectAPI::logging::log("Loading compounds");
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
					modelcompartment_ref => "~/modelcompartments/id/".$cmpsHash->{$cpd->modelcompartment()->compartment()->id()}->id(),
				});
			}
			$translation->{$cpd->id()} = $comcpd->id();
		}
		Bio::KBase::ObjectAPI::logging::log("Loading reactions");
		#Adding reactions to community model
		my $rxns = $model->modelreactions();
		for (my $j=0; $j < @{$rxns}; $j++) {
			my $rxn = $rxns->[$j];
			my $rootid = $rxn->reaction()->id();
			if ($rxn->id() =~ m/(.+)_([a-zA-Z]\d+)/) {
				$rootid = $1;
			}
			my $originalcmpid = $rxn->modelcompartment()->compartment()->id();
			if ($originalcmpid eq "e0") {
				$originalcmpid = "c0";
			}
			if (!defined($self->getObject("modelreactions",$rootid."_".$cmpsHash->{$originalcmpid}->id()))) {
				my $comrxn = $self->add("modelreactions",{
					id => $rootid."_".$cmpsHash->{$originalcmpid}->id(),
					reaction_ref => $rxn->reaction_ref(),
					direction => $rxn->direction(),
					protons => $rxn->protons(),
					modelcompartment_ref => "~/modelcompartments/id/".$cmpsHash->{$originalcmpid}->id(),
					probability => $rxn->probability()
				});
				for (my $k=0; $k < @{$rxn->modelReactionProteins()}; $k++) {
					$comrxn->add("modelReactionProteins",$rxn->modelReactionProteins()->[$k]);
				}
				for (my $k=0; $k < @{$rxn->modelReactionReagents()}; $k++) {
					$comrxn->add("modelReactionReagents",{
						modelcompound_ref => "~/modelcompounds/id/".$translation->{$rxn->modelReactionReagents()->[$k]->modelcompound()->id()},
						coefficient => $rxn->modelReactionReagents()->[$k]->coefficient()
					});
				}
			}
		}
		Bio::KBase::ObjectAPI::logging::log("Loading biomass");
		#Adding biomass to community model
		my $bios = $model->biomasses();
		for (my $j=0; $j < @{$bios}; $j++) {
			my $bio = $bios->[$j]->cloneObject();
			$bio->parent($self);
			for (my $k=0; $k < @{$bio->biomasscompounds()}; $k++) {
				$bio->biomasscompounds()->[$k]->modelcompound_ref("~/modelcompounds/id/".$translation->{$bios->[$j]->biomasscompounds()->[$k]->modelcompound()->id()});
			}
			$bio = $self->add("biomasses",$bio);
			$biocount++;
			$bio->id("bio".$biocount);
			$bio->name("bio".$biocount);
		}
		Bio::KBase::ObjectAPI::logging::log("Loading primary biomass");
		#Adding biomass component to primary composite biomass reaction
		$primbio->add("biomasscompounds",{
			modelcompound_ref => "~/modelcompounds/id/".$translation->{$biomassCpd->id()},
			coefficient => -1*$parameters->{models}->[$i]->[1]/$totalAbundance
		});
		return $genomeObj;
	}
	Bio::KBase::ObjectAPI::logging::log("Merge complete!");	
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

__PACKAGE__->meta->make_immutable;
1;
