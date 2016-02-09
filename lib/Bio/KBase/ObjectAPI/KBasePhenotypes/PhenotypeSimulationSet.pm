########################################################################
# Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulationSet - This is the moose object corresponding to the KBasePhenotypes.PhenotypeSimulationSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-01-05T15:36:51
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSimulationSet;
package Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSimulationSet;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSimulationSet';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************


#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************



#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub export_text {	
	my $self = shift;
	my $output = "Phenosim ID\tPheno ID\tMedia\tKO\tAdditional compounds\tObserved growth\tSimulated growth\tSimulated growth fraction\tClass\n";
    my $phenos = $self->phenotypeSimulations();
    foreach my $pheno (@{$phenos}) {
    	$output .= $pheno->id()."\t".$pheno->phenotype()->id()."\t".
    		$pheno->phenotype()->media()->_wsworkspace()."/".$pheno->phenotype()->media()->_wsname().
    		"\t".$pheno->phenotype()->geneKOString()."\t".$pheno->phenotype()->additionalCpdString().
    		"\t".$pheno->phenotype()->normalizedGrowth()."\t".$pheno->simulatedGrowth()."\t".$pheno->simulatedGrowthFraction().
    		"\t".$pheno->phenoclass()."\n";
    }
    return $output;
}

__PACKAGE__->meta->make_immutable;
1;
