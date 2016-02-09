########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomass - This is the moose object corresponding to the TemplateBiomass object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-04-26T05:53:23
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateBiomass;
package Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomass;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateBiomass';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has compoundTuples => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundTuples' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcompoundTuples {
	my ($self) = @_;
	my $compounds = [];
	my $cpds = $self->templateBiomassComponents();
	for (my $i=0; $i <@{$cpds}; $i++) {
		my $cpd = $cpds->[$i];
		my $links = [];
		my $linkcpds = $cpd->linked_compounds();
		for (my $j=0;$j < @{$linkcpds};$j++) {
			push(@{$links},[$cpd->link_coefficients()->[$j],$linkcpds->[$j]->id()]);
		}
		push(@{$compounds},[
			$cpd->compound()->id(),$cpd->compartment()->id(),$cpd->class(),1,$cpd->coefficient_type(),$cpd->coefficient(),
			$links
		]);
	}
	return $compounds;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub addBioToModel {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["gc","model"],{}, @_);
	my $mdl = $args->{model};
	my $gc = $args->{gc};
	if ($gc > 1) {
		$gc = 0.01*$gc;	
	}
	if ($gc > 1) {
		$gc = 0.5;	
	} 
	my $count = @{$mdl->biomasses()};
	my $bio = $mdl->add("biomasses",{
		name => $self->name()." auto biomass",
		id => "bio".($count+1)
	});
	my $list = ["dna","rna","protein","lipid","cellwall","cofactor","energy","other"];
	for (my $i=0; $i < @{$list}; $i++) {
		my $function = $list->[$i];
		$bio->$function($self->$function());
	}
	my $comps = $self->templateBiomassComponents();
	my $classifiers;
	my $compoundHash;
	#Calculating the mols of nucleotides present based on gc
	my $includedComps = [];
	my $classCounts = {};
	my $classMol = {};
	my $classMW = {};
	my $classMassSplitMol = {};
	my $classMassFractionMoles = {};
	my $classMolSplitMW = {};
	my $classMassSplitFraction = {};
	my $classMolSplitFraction = {};
	my $classMassSplitCount = {};
	my $classMolSplitCount = {};
	my $classMassFraction = {};
	my $classMolFraction = {};
	my $classHash = {};
	#Identifying included compounds and adding up components and mass in each class
	for (my $i=0; $i < @{$comps}; $i++) {
		my $comp = $comps->[$i];
		$classHash->{$comp->class()} = 1;
		push(@{$includedComps},$comp);
		if ($comp->coefficient_type() eq "MOLFRACTION") {
			if (!defined($classMolFraction->{$comp->class()})) {
				$classMolFraction->{$comp->class()} = 0;
			}
			$classMolFraction->{$comp->class()} += -1*$comp->coefficient();
			if (defined($comp->templatecompcompound()->templatecompound()->mass()) && $comp->templatecompcompound()->templatecompound()->mass() > 0) {
				if (!defined($classMW->{$comp->class()})) {
					$classMW->{$comp->class()} = 0;
				}
				$classMW->{$comp->class()} += -1*$comp->templatecompcompound()->templatecompound()->mass()*$comp->coefficient();
			}
		} elsif ($comp->coefficient_type() eq "MASSFRACTION") {
			if (!defined($comp->templatecompcompound()->templatecompound()->mass()) || $comp->compound()->mass() == 0) {
				Bio::KBase::ObjectAPI::utilities::error("Biomass template with MASSFRACTION of compound with no mass.");
			}
			if (!defined($classMassFraction->{$comp->class()})) {
				$classMassFraction->{$comp->class()} = 0;
			}
			$classMassFraction->{$comp->class()} += -1*$comp->coefficient();
			my $class = $comp->class();
			if (!defined($classMassFractionMoles->{$comp->class()})) {
				$classMassFractionMoles->{$comp->class()} = 0;
			}
			$classMassFractionMoles->{$comp->class()} += -1*$comp->coefficient()*$self->$class()/$comp->templatecompcompound()->templatecompound()->mass();
		} elsif ($comp->coefficient_type() eq "AT") {
			if (!defined($classMolFraction->{$comp->class()})) {
				$classMolFraction->{$comp->class()} = 0;
			}
			$classMolFraction->{$comp->class()} += (1-$gc)/2;
			if (defined($comp->templatecompcompound()->templatecompound()->mass()) && $comp->templatecompcompound()->templatecompound()->mass() > 0) {
				if (!defined($classMW->{$comp->class()})) {
					$classMW->{$comp->class()} = 0;
				}
				$classMW->{$comp->class()} += $comp->templatecompcompound()->templatecompound()->mass()*(1-$gc)/2;
			}
		} elsif ($comp->coefficient_type() eq "GC") {
			if (!defined($classMolFraction->{$comp->class()})) {
				$classMolFraction->{$comp->class()} = 0;
			}
			$classMolFraction->{$comp->class()} += $gc/2;
			if (defined($comp->templatecompcompound()->templatecompound()->mass()) && $comp->templatecompcompound()->templatecompound()->mass() > 0) {
				if (!defined($classMW->{$comp->class()})) {
					$classMW->{$comp->class()} = 0;
				}
				$classMW->{$comp->class()} += $comp->templatecompcompound()->templatecompound()->mass()*$gc/2;
			}
		} elsif ($comp->coefficient_type() eq "MULTIPLIER") {
			#DO NOTHING
		} elsif ($comp->coefficient_type() eq "EXACT") {
			#DO NOTHING
		} elsif ($comp->coefficient_type() eq "MOLSPLIT") {
			if (!defined($classMolSplitCount->{$comp->class()})) {
				$classMolSplitCount->{$comp->class()} = 0;
			}
			$classMolSplitCount->{$comp->class()}++;
			if (defined($comp->templatecompcompound()->templatecompound()->mass()) && $comp->templatecompcompound()->templatecompound()->mass() > 0) {
				if (!defined($classMolSplitMW->{$comp->class()})) {
					$classMolSplitMW->{$comp->class()} = 0;
				}
				$classMolSplitMW->{$comp->class()} += $comp->templatecompcompound()->templatecompound()->mass();
			}
		} elsif ($comp->coefficient_type() eq "MASSSPLIT") {
			if (!defined($comp->templatecompcompound()->templatecompound()->mass()) || $comp->templatecompcompound()->templatecompound()->mass() == 0) {
				Bio::KBase::ObjectAPI::utilities::error("Biomass template with MASSFRACTION of compound with no mass.");
			}
			if (!defined($classMassSplitCount->{$comp->class()})) {
				$classMassSplitCount->{$comp->class()} = 0;
			}
			$classMassSplitCount->{$comp->class()}++;
			my $class = $comp->class();
			if (!defined($classMassSplitMol->{$comp->class()})) {
				$classMassSplitMol->{$comp->class()} = 0;
			}
			$classMassSplitMol->{$comp->class()} += $self->$class()/$comp->templatecompcompound()->templatecompound()->mass();
		}
	}
	foreach my $class (keys(%{$classHash})) {
		if (!defined($classMassFraction->{$class})) {
			$classMassFraction->{$class} = 0;
		}
		if (!defined($classMolFraction->{$class})) {
			$classMolFraction->{$class} = 0;
		}
		if (!defined($classMW->{$class})) {
			$classMW->{$class} = 0;
		}
		if (!defined($classMol->{$class})) {
			$classMol->{$class} = 0;
		}
		if (!defined($classMolSplitCount->{$class})) {
			$classMolSplitCount->{$class} = 0;
			$classMolSplitMW->{$class} = 0;
		}
		if (!defined($classMassSplitCount->{$class})) {
			$classMassSplitCount->{$class} = 0;
			$classMassSplitMol->{$class} = 0;
		}
		my $totalSplt = $classMolSplitCount->{$class}+$classMassSplitCount->{$class};
		my $mass = (1-$classMassFraction->{$class})*$self->$class();
		if ($mass > 0) {
			my $remainingMolFraction = (1-$classMolFraction->{$class});
			if ($totalSplt > 0) {
				my $massSplitMolFraction = $remainingMolFraction*$classMassSplitCount->{$class}/$totalSplt;
				my $molSplitMolFraction = $remainingMolFraction*$classMolSplitCount->{$class}/$totalSplt;
				$classMW->{$class} += $molSplitMolFraction*$classMolSplitMW->{$class}/$classMolSplitCount->{$class};
				if ($classMassSplitCount->{$class} > 0) {
					$classMW->{$class} += $massSplitMolFraction*$self->$class()/($classMassSplitMol->{$class}/$classMassSplitCount->{$class});
				}
				$classMassSplitFraction->{$class} = $massSplitMolFraction;
				$classMolSplitFraction->{$class} = $molSplitMolFraction;
			}
			if ($classMW->{$class} > 0) {
				$classMol->{$class} = $mass/$classMW->{$class};
			} else {
				$classMol->{$class} = 1;
			}
		}
	}
	#Computing actual coefficients	
	for (my $i=0; $i < @{$includedComps}; $i++) {
		my $comp = $includedComps->[$i];
		my $coef = $comp->coefficient();
		my $class = $comp->class();
		if ($comp->coefficient_type() eq "MOLFRACTION") {
			$coef = $coef*$classMol->{$comp->class()}*1000;
		} elsif ($comp->coefficient_type() eq "MASSFRACTION") {
			my $class = $comp->class();
			$coef = $coef*$self->$class()/$comp->compound()->mass()*1000;
		} elsif ($comp->coefficient_type() eq "AT") {
			$coef = $coef*$classMol->{$comp->class()}*(1-$gc)/2*1000;
		} elsif ($comp->coefficient_type() eq "GC") {
			$coef = $coef*$gc*$classMol->{$comp->class()}/2*1000;
		} elsif ($comp->coefficient_type() eq "MULTIPLIER") {
			$coef = $coef*$self->$class();
		} elsif ($comp->coefficient_type() eq "EXACT") {
			$coef = $coef;
		} elsif ($comp->coefficient_type() eq "MOLSPLIT") {
			$coef = $coef*$classMol->{$comp->class()}*$classMolSplitFraction->{$comp->class()}*1000/$classMolSplitCount->{$comp->class()};			
		} elsif ($comp->coefficient_type() eq "MASSSPLIT") {
			$coef = $coef*$self->$class()*$classMassSplitFraction->{$comp->class()}/$classMassSplitCount->{$comp->class()}/$comp->compound()->mass()*1000;
		}
		#Adding compound to total biomass compound hash
		my $cpd = $comp->templatecompcompound()->templatecompound();
		if (!defined($compoundHash->{$comp->templatecompcompound_ref()})) {
			$compoundHash->{$comp->templatecompcompound_ref()} = 0;
		}
		$compoundHash->{$comp->templatecompcompound_ref()} += $coef;
		#Adding linked compounds to total biomass compound hash
		my $cpds = $comp->linked_compound_refs();
		for (my $j=0; $j < @{$cpds}; $j++) {
			$cpd = $cpds->[$j];
			if (!defined($compoundHash->{$cpd})) {
				$compoundHash->{$cpd} = 0;
			}
			$compoundHash->{$cpd} += $coef*$comp->link_coefficients()->[$j];
		}
	}
	#Setting biomass components
	foreach my $cpd_uuid (keys(%{$compoundHash})) {
		if ($compoundHash->{$cpd_uuid} != 0) {
			my $cpd = $self->getLinkedObject($cpd_uuid);
			my $mdlcmp = $mdl->addCompartmentToModel({compartment => $cpd->templatecompartment(),pH => 7,potential => 0,compartmentIndex => 0});
			my $mdlcpd = $mdl->addCompoundToModel({
				compound => $cpd->templatecompound(),
				modelCompartment => $mdlcmp,
			});
			$bio->add("biomasscompounds",{
				modelcompound_ref => $mdlcpd->_reference(),
				coefficient => $compoundHash->{$cpd_uuid}
			});
		}
	}
}

__PACKAGE__->meta->make_immutable;
1;
