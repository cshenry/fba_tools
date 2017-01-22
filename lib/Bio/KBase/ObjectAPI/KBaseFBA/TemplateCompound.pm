########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompound - This is the moose object corresponding to the KBaseFBA.TemplateCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-10-16T03:20:25
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompound;
package Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompound;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompound';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has biomass_coproducts  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_biomass_coproducts' );
has class  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_class' );
has codeid  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcodeid' );
has searchnames  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_searchnames' );

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
sub _build_searchnames {
	my ($self) = @_;
	my $hash = {$self->nameToSearchname($self->name()) => 1};
	my $names = $self->aliases();
	foreach my $name (@{$names}) {
		$hash->{$self->nameToSearchname($name)} = 1;
	}
	return [keys(%{$hash})];
}
sub _buildcodeid {
	my ($self) = @_;
	#if ($self->compound_ref() =~ m/(cpd\d+)/) {
	#	my $id = $1;
	#	if ($id ne "cpd00000") {
	#		return $id;
	#	}
	#}
	return $self->id();
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub msid {
	my ($self) = @_;
	return $self->id();
}

=head3 nameToSearchname

Definition:
	string:searchname = nameToSearchname(string:name);
Description:
	Converts input name into standard formated searchname

=cut

sub nameToSearchname {
	my ($self,$InName) = @_;
	if (!defined($InName) && !ref($self) && $self ne "Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompound") {
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
	$InName =~ s/�//g;
	$InName =~ s/'//g;
	$InName =~ s/\;//g;
	$InName .= $ending;
	$InName =~ s/icacid/ate/g;
	if($OriginalName =~ /^an? /){
		$InName =~ s/^an?(.*)$/$1/;
	}
	return $InName;
}

__PACKAGE__->meta->make_immutable;
1;
