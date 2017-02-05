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
has cp => ( is => 'rw', isa => 'Int',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcp'  );
has cn => ( is => 'rw', isa => 'Int',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcn'  );
has fp => ( is => 'rw', isa => 'Int',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfp'  );
has fn => ( is => 'rw', isa => 'Int',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfn'  );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcp {
	my ($self) = @_;
	return $self->class_count("CP");
}
sub _buildfp {
	my ($self) = @_;
	return $self->class_count("FP");
}
sub _buildcn {
	my ($self) = @_;
	return $self->class_count("CN");
}
sub _buildfn {
	my ($self) = @_;
	return $self->class_count("FN");
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub class_count {
    my $self = shift;
    my $class = shift;
    my $count = 0;
   	my $phenos = $self->phenotypeSimulations();
   	for (my $i=0; $i < @{$phenos}; $i++) {
   		if ($phenos->[$i]->phenoclass() eq $class) {
   			$count++;
   		}
   	}
   	return $count;
}

sub export {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["format"], {file => 0,path => undef}, @_);
	if (lc($args->{format}) eq "tsv") {
		return $self->printTSV($args);
	} elsif (lc($args->{format}) eq "excel") {
		return $self->printExcel($args);
	}
	Bio::KBase::ObjectAPI::utilities::error("Unrecognized type for export: ".$args->{format});
}

sub printTSV {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([], {file => 0,path => undef}, @_);
	my $output = ["geneko\tmediaws\tmedia\taddtlCpd\tgrowth\tsimulated growth\tsimulated growth fraction\tgapfilled reaction count\tgapfilled reactions"];
	my $phenotypes = $self->phenotypeSimulations();
	for (my $i=0; $i < @{$phenotypes}; $i++) {
		push(@{$output},$phenotypes->[$i]->phenotype()->geneKOString()."\t".$phenotypes->[$i]->phenotype()->media()->_wsworkspace()."\t".$phenotypes->[$i]->phenotype()->media()->_wsname()."\t".$phenotypes->[$i]->phenotype()->additionalCpdString()."\t".$phenotypes->[$i]->phenotype()->normalizedGrowth()."\t".$phenotypes->[$i]->simulatedGrowth()."\t".$phenotypes->[$i]->simulatedGrowthFraction()."\t".$phenotypes->[$i]->numGapfilledReactions()."\t".join(";",@{$phenotypes->[$i]->gapfilledReactions()}));
	}
	if ($args->{file} == 1) {
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($args->{path}."/".$self->id().".tsv",$output);
		return [$args->{path}."/".$self->id().".tsv"];
	}
	return $output;
}

sub printExcel {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([], {file => 0,path => undef}, @_);
	my $output = $self->printTSV();	
	require "Spreadsheet/WriteExcel.pm";
	my $wkbk = Spreadsheet::WriteExcel->new($args->{path}."/".$self->id().".xls") or die "can not create workbook: $!";
	my $sheet = $wkbk->add_worksheet("Phenotypes");
	for (my $i=0; $i < @{$output}; $i++) {
		my $row = [split(/\t/,$output->[$i])];
		for (my $j=0; $j < @{$row}; $j++) {
			if (defined($row->[$j])) {
				$row->[$j] =~ s/=/-/g;
			}
		}
		$sheet->write_row($i,0,$row);
	}
	$wkbk->close();
	if ($args->{file} == 0) {
		Bio::KBase::error("Export to excel is only supported as a file output!");
	}
	return [$args->{path}."/".$self->id().".xls"];
}

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
