########################################################################
# Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSet - This is the moose object corresponding to the KBasePhenotypes.PhenotypeSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-01-05T15:36:51
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSet;
package Bio::KBase::ObjectAPI::KBasePhenotypes::PhenotypeSet;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBasePhenotypes::DB::PhenotypeSet';
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

sub import_phenotype_table {
	my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["data","biochem"], {}, @_ );
	my $genomeObj = $self->genome();
	my $genehash = {};
	my $ftrs = $genomeObj->features();
    for (my $i=0; $i < @{$ftrs}; $i++) {
    	my $ftr = $ftrs->[$i];
    	$genehash->{$ftr->id()} = $ftr;
    	if ($ftr->id() =~ m/\.(peg\.\d+)/) {
    		$genehash->{$1} = $ftr;
    	}
    	for (my $j=0; $j < @{$ftr->aliases()}; $j++) {
    		$genehash->{$ftr->aliases()->[$j]} = $ftr;
    	}
    }
    #Validating media, genes, and compounds
    my $missingMedia = {};
    my $missingGenes = {};
    my $missingCompounds = {};
    my $mediaChecked = {};
    my $cpdChecked = {};
    my $data = $args->{data};
    my $bio = $args->{biochem};
    my $count = 1;
    my $mediaHash = {};
    for (my $i=0; $i < @{$data}; $i++) {
    	$mediaHash->{$data->[$i]->[2]}->{$data->[$i]->[1]} = 0;
    }
    my $output = $self->parent()->workspace()->list_objects({
    	workspaces => [keys(%{$mediaHash})],
		type => "KBaseBiochem.Media",
    });
    for (my $i=0; $i < @{$output}; $i++) {
    	if (defined($mediaHash->{$output->[$i]->[7]}->{$output->[$i]->[1]})) {
    		$mediaHash->{$output->[$i]->[7]}->{$output->[$i]->[1]} = $output->[$i]->[6]."/".$output->[$i]->[0];
    	}
    }		
    for (my $i=0; $i < @{$data}; $i++) {
    	my $phenotype = $data->[$i];
    	#Validating gene IDs
    	my $allfound = 1;
    	my $generefs = [];
    	for (my $j=0;$j < @{$phenotype->[0]};$j++) {
    		if (!defined($genehash->{$phenotype->[0]->[$j]})) {
    			$missingGenes->{$phenotype->[0]->[$j]} = 1;
    			$allfound = 0;
    		} else {
    			$generefs->[$j] = $genehash->{$phenotype->[0]->[$j]}->_reference();
    		}
    	}
    	if ($allfound == 0) {
    		next;
    	}
    	#Validating compounds
    	$allfound = 1;
    	my $cpdrefs = [];
    	for (my $j=0;$j < @{$phenotype->[3]};$j++) {
    		my $cpd = $bio->searchForCompound($phenotype->[3]->[$j]);
    		if (!defined($cpd)) {
    			$missingCompounds->{$phenotype->[3]->[$j]} = 1;
    			$allfound = 0;
    		} else {
    			$cpdrefs->[$j] = $cpd->_reference();
    		}
    	}
    	if ($allfound == 0) {
    		next;
    	}
    	#Validating media
    	if ($mediaHash->{$phenotype->[2]}->{$phenotype->[1]} eq "0") {
    		$missingMedia->{$phenotype->[2]."/".$phenotype->[1]} = 1;
    		next;
    	}
    	#Adding phenotype to object
    	$self->add("phenotypes",{
    		id => $self->id().".phe.".$count,
			media_ref => $mediaHash->{$phenotype->[2]}->{$phenotype->[1]},
			geneko_refs => $generefs,
			additionalcompound_refs => $cpdrefs,
			normalizedGrowth => $phenotype->[4],
			name => $self->id().".phe.".$count
    	});
    	$count++;
    }
    #Printing error if any entities could not be validated
    my $msg = "";
    if (keys(%{$missingCompounds}) > 0) {
    	$msg .= "Could not find compounds:".join(";",keys(%{$missingCompounds}))."\n";
    }
    if (keys(%{$missingGenes}) > 0) {
    	$msg .= "Could not find genes:".join(";",keys(%{$missingGenes}))."\n";
    }
    if (keys(%{$missingMedia}) > 0) {
    	$msg .= "Could not find media:".join(";",keys(%{$missingMedia}))."\n";
    }
    $self->importErrors($msg);
}

__PACKAGE__->meta->make_immutable;
1;
