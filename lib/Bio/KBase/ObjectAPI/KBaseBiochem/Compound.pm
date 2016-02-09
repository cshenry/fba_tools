########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::Reaction - This is the moose object corresponding to the Reaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::Compound;
package Bio::KBase::ObjectAPI::KBaseBiochem::Compound;
use Bio::KBase::ObjectAPI::utilities;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::Compound';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has mapped_uuid  => ( is => 'rw', isa => 'ModelSEED::uuid',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_mapped_uuid' );
has searchnames  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_searchnames' );
has biomass_coproducts  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_biomass_coproducts' );
has class  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_class' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _build_class {
	my ($self) = @_;
	my $classhash = {
		cpd00023 => "amino_acid",
		cpd00033 => "amino_acid",
		cpd00035 => "amino_acid",
		cpd00039 => "amino_acid",
		cpd00041 => "amino_acid",
		cpd00051 => "amino_acid",
		cpd00053 => "amino_acid",
		cpd00054 => "amino_acid",
		cpd00060 => "amino_acid",
		cpd00065 => "amino_acid",
		cpd00066 => "amino_acid",
		cpd00069 => "amino_acid",
		cpd00084 => "amino_acid",
		cpd00107 => "amino_acid",
		cpd00119 => "amino_acid",
		cpd00129 => "amino_acid",
		cpd00132 => "amino_acid",
		cpd00156 => "amino_acid",
		cpd00161 => "amino_acid",
		cpd00322 => "amino_acid",
		cpd00115 => "deoxynucleotide",
		cpd00241 => "deoxynucleotide",
		cpd00356 => "deoxynucleotide",
		cpd00357 => "deoxynucleotide",
		cpd00002 => "nucleotide",
		cpd00038 => "nucleotide",
		cpd00052 => "nucleotide",
		cpd00062 => "nucleotide",
		cpd15793 => "lipid",
		cpd15794 => "lipid",
		cpd15795 => "lipid",
		cpd15722 => "lipid",
		cpd15723 => "lipid",
		cpd15540 => "lipid",
		cpd15533 => "lipid",
		cpd15695 => "lipid",
		cpd15696 => "lipid",
		cpd15748 => "cellwall",
		cpd15757 => "cellwall",
		cpd15766 => "cellwall",
		cpd15775 => "cellwall",
		cpd15749 => "cellwall",
		cpd15758 => "cellwall",
		cpd15767 => "cellwall",
		cpd15776 => "cellwall",
		cpd15750 => "cellwall",
		cpd15759 => "cellwall",
		cpd15768 => "cellwall",
		cpd15777 => "cellwall",
		cpd15667 => "cellwall",
		cpd15668 => "cellwall",
		cpd15669 => "cellwall",
		cpd11459 => "cellwall",
		cpd15432 => "cellwall",
		cpd02229 => "cellwall",
		cpd15665 => "cellwall",
		cpd15666 => "cellwall",
		cpd01997 => "cofactor",
		cpd03422 => "cofactor",
		cpd00201 => "cofactor",
		cpd00087 => "cofactor",
		cpd00345 => "cofactor",
		cpd00042 => "cofactor",
		cpd00028 => "cofactor",
		cpd00557 => "cofactor",
		cpd00264 => "cofactor",
		cpd00118 => "cofactor",
		cpd00056 => "cofactor",
		cpd15560 => "cofactor",
		cpd15352 => "cofactor",
		cpd15500 => "cofactor",
		cpd00166 => "cofactor",
		cpd12370 => "cofactor",
		cpd00010 => "cofactor",
		cpd11493 => "cofactor",
		cpd00003 => "cofactor",
		cpd00006 => "cofactor",
		cpd00205 => "cofactor",
		cpd00254 => "cofactor",
		cpd10516 => "cofactor",
		cpd00063 => "cofactor",
		cpd00009 => "cofactor",
		cpd00099 => "cofactor",
		cpd00149 => "cofactor",
		cpd00058 => "cofactor",
		cpd00015 => "cofactor",
		cpd10515 => "cofactor",
		cpd00030 => "cofactor",
		cpd00048 => "cofactor",
		cpd00034 => "cofactor",
		cpd00016 => "cofactor",
		cpd00220 => "cofactor",
		cpd00017 => "cofactor"		
	};
	if (defined($classhash->{$self->id()})) {
		return $classhash->{$self->id()};
	}
	return "unknown";
}

sub _build_biomass_coproducts {
	my ($self) = @_;
	my $biocoproducts = {
		cpd11493 => [["cpd12370",-1]],
		cpd15665 => [["cpd15666",-1]],
		cpd15667 => [["cpd15666",-1]],
		cpd15668 => [["cpd15666",-1]],
		cpd15669 => [["cpd15666",-1]],
		cpd00166 => [["cpd01997",-1],["cpd03422",-1]],
	};
	if (defined($biocoproducts->{$self->id()})) {
		return $biocoproducts->{$self->id()};
	}
	return [];
}

sub _build_mapped_uuid {
	my ($self) = @_;
	return "00000000-0000-0000-0000-000000000000";
}
sub _build_searchnames {
	my ($self) = @_;
	my $hash = {$self->nameToSearchname($self->name()) => 1};
	my $names = $self->getAliases("name");
	foreach my $name (@{$names}) {
		$hash->{$self->nameToSearchname($name)} = 1;
	}
	return [keys(%{$hash})];
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub getAlias {
    my ($self,$set) = @_;
    my $aliases = $self->getAliases($set);
    return (@$aliases) ? $aliases->[0] : undef;
}

sub getAliases {
    my ($self,$setName) = @_;
    return [] unless(defined($setName));
    my $output = [];
    my $aliases = $self->parent()->compound_aliases()->{$self->id()};
    if (defined($aliases) && defined($aliases->{$setName})) {
    	return $aliases->{$setName};
    }
    return $output;
}

sub allAliases {
	my ($self) = @_;
    my $output = [];
    my $aliases = $self->parent()->compound_aliases()->{$self->id()};
    if (defined($aliases)) {
    	foreach my $set (keys(%{$aliases})) {
    		push(@{$output},@{$aliases->{$set}});
    	}
    }
    return $output;
}

sub hasAlias {
    my ($self,$alias,$setName) = @_;
    my $aliases = $self->parent()->compound_aliases()->{$self->id()};
    if (defined($aliases) && defined($aliases->{$setName})) {
    	foreach my $searchalias (@{$aliases->{$setName}}) {
    		if ($searchalias eq $alias) {
    			return 1;
    		}
    	}
    }
    return 0;
}

=head3 addStructure

Definition:
	Bio::KBase::ObjectAPI::Structure = addStructure({
		data => string:structure data*
		type => string:type of structure*
		overwrite => 0/1(0)
	});
Description:
	Adds the specified structure to the compound
	
=cut

sub addStructure {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["data","type"], { overwrite => 0 }, @_);
	#Checking that parent exists and has linked BiochemistryStructures
	if (!defined($self->parent()) || !defined($self->parent()->biochemistrystructures())) {
		Bio::KBase::ObjectAPI::utilities::ERROR("Cannot add structure to a compound with no accessible BiochemistryStructures object. Make sure you have a BiochemistryStructures object in the parent biochemistry.");
	}
	my $bs = $self->parent()->biochemistrystructures();
	#Checking if a structure of the same type already exists
	my $index = -1;
	if (defined($self->structure_uuids()->[0])) {
		my $structs = $self->structures();
		my $type = $args->{type};
		for (my $i=0; $i < @{$structs}; $i++) {
			if ($structs->[$i]->type() eq $args->{type}) {
				if ($args->{overwrite} == 1) {
					$index = $i;
					last;
				} else {
					Bio::KBase::ObjectAPI::utilities::ERROR("Compound already has structure of type '$type'. Cannot overwrite without setting overwrite flag.");
				}
			}
		}
	}
	#Getting structure
	my $structure = $bs->getCreateStructure({
		data => $args->{data},
		type => $args->{type},
	});
	#Adding the structure
	if ($index == -1) {
		push(@{$self->structure_uuids()},$structure->uuid());
	} else {
		$self->structure_uuids()->[$index] = $structure->uuid();
	}
	$self->clear_structures();
	return $structure;
}

=head3 calculateAtomsFromFormula

Definition:
	{string:atom => int:count} = Bio::KBase::ObjectAPI::KBaseBiochem::Reaction->calculateAtomsFromFormula();
Description:
	Determines the count of each atom type based on the formula

=cut

sub calculateAtomsFromFormula {
        my ($self) = @_;
	my $atoms = {};
	my $formula = $self->formula();
	if ($formula eq "noformula" || $formula eq "null"){
		$atoms->{error} = "No formula";
	} else {
	    foreach my $component ( split(/\./,$formula) ){
		#remove problematic characters
		$component =~ s/\)n//g;
		$component =~ s/[\(\)]//g;
		$component =~ s/\*\d?//g;
		$component =~ s/([A-Z][a-z]*)/|$1/g;
		$component =~ s/([\d]+)/:$1/g;
		my $array = [split(/\|/,$component)];
		for (my $i=1; $i < @{$array}; $i++) {
			my $arrayTwo = [split(/:/,$array->[$i])];
			if (defined($arrayTwo->[1])) {
				if ($arrayTwo->[1] !~ m/^\d+$/) {
					$atoms->{error} = "Invalid formula:".$self->formula();
				}else{
				    $atoms->{$arrayTwo->[0]} += $arrayTwo->[1];
				}
			} else {
				$atoms->{$arrayTwo->[0]} += 1;
			}
		}
	    }
	}
	return $atoms;
}

#***********************************************************************************************************
# CLASS FUNCTIONS:
#***********************************************************************************************************

=head3 nameToSearchname

Definition:
	string:searchname = nameToSearchname(string:name);
Description:
	Converts input name into standard formated searchname

=cut

sub nameToSearchname {
	my ($self,$InName) = @_;
	if (!defined($InName) && !ref($self) && $self ne "Bio::KBase::ObjectAPI::KBaseBiochem::Compound") {
		$InName = $self;
	}
	my $OriginalName = $InName;
	my $ending = "";
	if ($InName =~ m/-$/) {
		$ending = "-";
	}
	$InName = lc($InName);
	$InName =~ s/\s//g;
	$InName =~ s/,//g;
	$InName =~ s/-//g;
	$InName =~ s/_//g;
	$InName =~ s/\(//g;
	$InName =~ s/\)//g;
	$InName =~ s/\{//g;
	$InName =~ s/\}//g;
	$InName =~ s/\[//g;
	$InName =~ s/\]//g;
	$InName =~ s/\://g;
	$InName =~ s/’//g;
	$InName =~ s/'//g;
	$InName =~ s/\;//g;
	$InName .= $ending;
	$InName =~ s/icacid/ate/g;
	if($OriginalName =~ /^an? /){
		$InName =~ s/^an?(.*)$/$1/;
	}
	return $InName;
}

=head3 recognizeReference

Definition:
	string:formated ref = recognizeReference(string:rawref);
Description:
	Converts a raw reference into a fully formatted and typed reference

=cut

sub recognizeReference {
	my ($self,$reference) = @_;
	if (!defined($reference) && !ref($self) && $self ne "Bio::KBase::ObjectAPI::KBaseBiochem::Compound") {
		$reference = $self;
	}
	if ($reference =~ m/^Compound\/[^\/]+\/[^\/]+$/) {
		return $reference;
	}
	if ($reference =~ m/^[^\/]+\/[^\/]+$/) {
		return "Compound/".$reference;
	}
	if ($reference =~ m/^Compound\/([^\/]+)$/) {
		$reference = $1;
	}
	my $type = "searchnames";
	if ($reference =~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
		$type = "uuid";
	} elsif ($reference =~ m/^cpd\d+$/) {
		$type = "ModelSEED";
	} elsif ($reference =~ m/^C\d+$/) {
		$type = "KEGG";
	}
	if ($type eq "searchnames") {
		$reference = Bio::KBase::ObjectAPI::KBaseBiochem::Compound->nameToSearchname($reference);
	}
	return "Compound/".$type."/".$reference;
}

__PACKAGE__->meta->make_immutable;
1;
