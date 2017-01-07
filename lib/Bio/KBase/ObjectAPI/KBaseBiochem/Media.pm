########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::Media - This is the moose object corresponding to the Media object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::Media;
package Bio::KBase::ObjectAPI::KBaseBiochem::Media;
use Moose;
use namespace::autoclean;
use Bio::KBase::ObjectAPI::utilities;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::Media';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has compoundListString => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundListString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcompoundListString {
	my ($self) = @_;
	my $compoundListString = "";
	my $mediacpds = $self->mediacompounds();
	for (my $i=0; $i < @{$mediacpds}; $i++) {
		if (length($compoundListString) > 0) {
			$compoundListString .= ";"	
		}
		my $cpd = $mediacpds->[$i];
		$compoundListString .= $cpd->compound()->name();
	}
	return $compoundListString;
}


#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 export

Definition:
	string = Bio::KBase::ObjectAPI::KBaseBiochem::Media->export({
		format => readable/html/json/exchange
	});
Description:
	Exports media data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["format"], {}, @_);
	if (lc($args->{format}) eq "exchange") {
		return $self->printExchange();
	} elsif (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	} elsif (lc($args->{format}) eq "tsv") {
		return $self->printTSV($args);
	} elsif (lc($args->{format}) eq "excel") {
		return $self->printExcel($args);
	}
	Bio::KBase::ObjectAPI::utilities::error("Unrecognized type for export: ".$args->{format});
}

sub printTSV {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([], {file => 0,path => undef}, @_);
	my $output = ["compounds\tname\tformula\tminFlux\tmaxFlux\tconcentration"];
	my $compounds = $self->mediacompounds();
	for (my $i=0; $i < @{$compounds}; $i++) {
		push(@{$output},$compounds->[$i]->compound()->id()."\t".$compounds->[$i]->compound()->name()."\t".$compounds->[$i]->compound()->formula()."\t".$compounds->[$i]->minFlux()."\t".$compounds->[$i]->maxFlux()."\t".$compounds->[$i]->concentration());
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
	my $sheet = $wkbk->add_worksheet("MediaCompounds");
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

=head3 printExchange

Definition:
	string:Exchange format = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->printExchange();
Description:
	Returns a string with the media

=cut

sub printExchange {
    my $self = shift;
	my $output = "Media{\n";
	$output .= "attributes(in\tname\tisDefined\tisMinimal\ttype\tbiochemistry){\n";
	$output .= $self->id()."\t".$self->name()."\t".$self->isDefined()."\t".$self->isMinimal()."\t".$self->type()."\t".$self->parent()->uuid()."\n";
	$output .= "}\n";
	$output .= "compounds(id\tminFlux\tmaxFlux\tconcentration){\n";
	my $mediacpds = $self->mediacompounds();
	foreach my $cpd (@{$mediacpds}) {
		$output .= $cpd->compound()->id()."\t".$cpd->minFlux()."\t".$cpd->maxFlux()."\t".$cpd->concentration()."\n";
	}
	$output .= "}\n";
	$output .= "}\n";
	return $output;
}

__PACKAGE__->meta->make_immutable;
1;
